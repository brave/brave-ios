/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import AVFoundation
import BraveShared
import BraveCore
import Data

protocol SyncPairControllerDelegate: AnyObject {
    func syncOnScannedHexCode(_ controller: UIViewController & NavigationPrevention, hexCode: String)
    func syncOnWordsEntered(_ controller: UIViewController & NavigationPrevention, codeWords: String)
}

class SyncPairCameraViewController: SyncViewController {
    private var cameraLocked = false
    
    weak var delegate: SyncPairControllerDelegate?
    var cameraView: SyncCameraView!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!
    var enterWordsButton: RoundInterfaceButton!
    
    var loadingView: UIView!
    let loadingSpinner = UIActivityIndicatorView(style: .large).then {
        $0.color = .white
    }
    
    private let syncAPI: BraveSyncAPI

    init(syncAPI: BraveSyncAPI) {
        self.syncAPI = syncAPI
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.scan

        let stackView = UIStackView().then {
            $0.axis = .vertical
            $0.distribution = .equalSpacing
            $0.alignment = .center
            $0.spacing = 4
        }
        
        view.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeArea.top).offset(16)
            make.left.right.equalTo(self.view).inset(16)
            make.bottom.equalTo(self.view.safeArea.bottom).inset(16)
        }
        
        cameraView = SyncCameraView().then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.backgroundColor = .black
            $0.layer.cornerRadius = 4
            $0.layer.cornerCurve = .continuous
            $0.layer.masksToBounds = true
            $0.scanCallback = { [weak self] data in
                self?.onQRCodeScanned(data: data)
            }
        }

        stackView.addArrangedSubview(cameraView)

        let titleDescriptionStackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 4
            $0.alignment = .center
            $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 250), for: .vertical)
        }
        
        titleLabel = UILabel().then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
            $0.text = Strings.syncToDevice
        }
        titleDescriptionStackView.addArrangedSubview(titleLabel)

        descriptionLabel = UILabel().then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
            $0.numberOfLines = 0
            $0.lineBreakMode = .byWordWrapping
            $0.textAlignment = .center
            $0.text = Strings.syncToDeviceDescription
        }
        titleDescriptionStackView.addArrangedSubview(descriptionLabel)

        let textStackView = UIStackView(arrangedSubviews: [UIView.spacer(.horizontal, amount: 16),
                                                           titleDescriptionStackView,
                                                           UIView.spacer(.horizontal, amount: 16)])

        stackView.addArrangedSubview(textStackView)

        enterWordsButton = RoundInterfaceButton(type: .roundedRect)
        enterWordsButton.translatesAutoresizingMaskIntoConstraints = false
        enterWordsButton.setTitle(Strings.enterCodeWords, for: .normal)
        enterWordsButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.semibold)
        enterWordsButton.addTarget(self, action: #selector(onEnterWordsPressed), for: .touchUpInside)
        stackView.addArrangedSubview(enterWordsButton)
        
        loadingSpinner.startAnimating()
        
        loadingView = UIView()
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        loadingView.isHidden = true
        loadingView.addSubview(loadingSpinner)
        cameraView.addSubview(loadingView)
        
        edgesForExtendedLayout = UIRectEdge()

        cameraView.snp.makeConstraints { (make) in
            if UIDevice.current.userInterfaceIdiom == .pad {
                make.size.equalTo(400)
            } else {
                make.size.equalTo(self.view.snp.width).multipliedBy(0.9)
            }
        }

        loadingView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalTo(cameraView)
        }
        
        loadingSpinner.snp.makeConstraints { make in
            make.center.equalTo(loadingSpinner.superview!)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { _ in
            self.cameraView.videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation(ui: UIApplication.shared.statusBarOrientation)
        }
    }
    
    @objc
    private func onEnterWordsPressed() {
        let wordsVC = SyncPairWordsViewController(syncAPI: syncAPI)
        wordsVC.delegate = delegate
        navigationController?.pushViewController(wordsVC, animated: true)
    }
    
    private func onQRCodeScanned(data: String) {
        // Guard against multi-scanning
        if cameraLocked { return }
        cameraLocked = true
        
        // Pause scanning
        cameraView.cameraOverlaySuccess()
        cameraView.stopRunning()
        
        // Vibrate.
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        // Forced timeout
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.cameraLocked = false
            self.cameraView.cameraOverlayError()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 25.0, execute: task)
        
        // Check Internet Connectivity
        if !DeviceInfo.hasConnectivity() {
            task.cancel()
            let alert = UIAlertController(title: Strings.syncNoConnectionTitle,
                                          message: Strings.syncNoConnectionBody,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.cameraLocked = false
                self.cameraView.cameraOverlayNormal()
                self.cameraView.startRunning()
            }))
            present(alert, animated: true)
            return
        }
        
        // QR Code (Unversioned - Version #1)
        if data.filter(\.isHexDigit).count == data.count {
            if Date().timeIntervalSince1970 >= TimeInterval(BraveSyncQRCodeModel.sunsetDate) {
                // Insecure version (Past the Sunset Date)
                cameraView.cameraOverlayError()
                showErrorAlert(error: .insecure)
            } else if syncAPI.isValidSyncCode(syncAPI.syncCode(fromHexSeed: data)) {
                // Valid Hex Code
                cameraView.cameraOverlaySuccess()
                self.delegate?.syncOnScannedHexCode(self, hexCode: data)
            } else {
                // Invalid Hex Code
                cameraView.cameraOverlayError()
                showErrorAlert(error: .invalidFormat)
            }
            return
        }
        
        // QR Code (Versioned - Version #2+)
        guard let model = BraveSyncQRCodeModel.from(string: data) else {
            cameraView.cameraOverlayError()
            showErrorAlert(error: .invalidFormat)
            return
        }
        
        // Validation
        let errorCode = model.validate(syncAPI: syncAPI)
        if errorCode != .none {
            cameraView.cameraOverlayError()
            showErrorAlert(error: errorCode)
            return
        }
        
        // Sync code is valid
        delegate?.syncOnScannedHexCode(self, hexCode: model.syncHexCode)
    }
    
    private func showErrorAlert(error: BraveSyncQRCodeError) {
        let errorMessage = { (error: BraveSyncQRCodeError) -> String in
            switch error {
            case .insecure: return Strings.syncInsecureVersionError
            case .newerVersion: return Strings.syncNewerVersionError
            case .olderVersion: return Strings.syncOlderVersionError
            case .invalidFormat: return Strings.syncInvalidVersionError
            case .expired: return Strings.syncExpiredError
            case .futureDate: return Strings.syncFutureVersionError
            default: return Strings.syncGenericError
            }
        }
        
        let alert = UIAlertController(title: Strings.syncUnableCreateGroup,
                                      message: errorMessage(error),
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.cameraLocked = false
            self.cameraView.cameraOverlayNormal()
            self.cameraView.startRunning()
        }))
        present(alert, animated: true)
    }
}

extension SyncPairCameraViewController: NavigationPrevention {
    func enableNavigationPrevention() {
        loadingView.isHidden = false
        navigationItem.hidesBackButton = true
        enterWordsButton.isEnabled = false
    }

    func disableNavigationPrevention() {
        loadingView.isHidden = true
        navigationItem.hidesBackButton = false
        enterWordsButton.isEnabled = true
    }
}

extension AVCaptureVideoOrientation {
    var uiInterfaceOrientation: UIInterfaceOrientation {
        get {
            switch self {
            case .landscapeLeft:        return .landscapeLeft
            case .landscapeRight:       return .landscapeRight
            case .portrait:             return .portrait
            case .portraitUpsideDown:   return .portraitUpsideDown
            @unknown default:           assertionFailure(); return .portrait
            }
        }
    }

    init(ui: UIInterfaceOrientation) {
        switch ui {
        case .landscapeRight:       self = .landscapeRight
        case .landscapeLeft:        self = .landscapeLeft
        case .portrait:             self = .portrait
        case .portraitUpsideDown:   self = .portraitUpsideDown
        default:                    self = .portrait
        }
    }
}
