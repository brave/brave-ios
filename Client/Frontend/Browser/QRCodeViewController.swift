/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AVFoundation
import SnapKit
import Shared

private let log = Logger.browserLogger

private struct QRCodeViewControllerUX {
    static let navigationBarBackgroundColor = UIColor.black
    static let navigationBarTitleColor = UIColor.Photon.white100
    static let maskViewBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    static let isLightingNavigationItemColor = UIColor(red: 0.45, green: 0.67, blue: 0.84, alpha: 1)
}

protocol QRCodeViewControllerDelegate {
    func didScanQRCodeWithURL(_ url: URL)
    func didScanQRCodeWithText(_ text: String)
}

class QRCodeViewController: UIViewController {
    var qrCodeDelegate: QRCodeViewControllerDelegate?

    fileprivate lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.high
        return session
    }()

    private lazy var captureDevice: AVCaptureDevice? = {
        return AVCaptureDevice.default(for: AVMediaType.video)
    }()

    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private let scanLine: UIImageView = UIImageView(image: #imageLiteral(resourceName: "qrcode-scanLine"))
    private let scanBorder: UIImageView = UIImageView(image: #imageLiteral(resourceName: "qrcode-scanBorder"))
    private lazy var instructionsLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.scanQRCodeInstructionsLabel
        label.textColor = UIColor.Photon.white100
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    private var maskView: UIView = UIView()
    private var isAnimationing: Bool = false
    private var isLightOn: Bool = false
    private var shapeLayer: CAShapeLayer = CAShapeLayer()

    private var scanRange: CGRect {
        let size = UIDevice.current.userInterfaceIdiom == .pad ?
            CGSize(width: view.frame.width / 2, height: view.frame.width / 2) :
            CGSize(width: view.frame.width / 3 * 2, height: view.frame.width / 3 * 2)
        var rect = CGRect(size: size)
        rect.center = UIScreen.main.bounds.center
        return rect
    }

    private var scanBorderHeight: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ?
            view.frame.width / 2 : view.frame.width / 3 * 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let captureDevice = self.captureDevice else {
            dismiss(animated: false)
            return
        }

        self.navigationItem.title = Strings.scanQRCodeViewTitle

        // Setup the NavigationBar
        self.navigationController?.navigationBar.barTintColor = QRCodeViewControllerUX.navigationBarBackgroundColor
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: QRCodeViewControllerUX.navigationBarTitleColor]

        // Setup the NavigationItem
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "qrcode-goBack"), style: .plain, target: self, action: #selector(goBack))
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.Photon.white100

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "qrcode-light"), style: .plain, target: self, action: #selector(openLight))
        if captureDevice.hasTorch {
            self.navigationItem.rightBarButtonItem?.tintColor = UIColor.Photon.white100
        } else {
            self.navigationItem.rightBarButtonItem?.tintColor = UIColor.Photon.grey50
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }

        let getAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if getAuthorizationStatus != .denied {
            setupCamera()
        } else {
            let alert = UIAlertController(title: "", message: Strings.scanQRCodePermissionErrorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.scanQRCodeErrorOKButton, style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        maskView.backgroundColor = QRCodeViewControllerUX.maskViewBackgroundColor
        self.view.addSubview(maskView)
        self.view.addSubview(scanBorder)
        self.view.addSubview(scanLine)
        self.view.addSubview(instructionsLabel)

        setupConstraints()
        let rectPath = UIBezierPath(rect: UIScreen.main.bounds)
        rectPath.append(UIBezierPath(rect: scanRange).reversing())
        shapeLayer.path = rectPath.cgPath
        maskView.layer.mask = shapeLayer

        isAnimationing = true
        startScanLineAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
        stopScanLineAnimation()
    }

    private func setupConstraints() {
        maskView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            scanBorder.snp.makeConstraints { (make) in
                make.center.equalTo(self.view)
                make.width.height.equalTo(view.frame.width / 2)
            }
        } else {
            scanBorder.snp.makeConstraints { (make) in
                make.center.equalTo(self.view)
                make.width.height.equalTo(view.frame.width / 3 * 2)
            }
        }
        scanLine.snp.makeConstraints { (make) in
            make.left.equalTo(scanBorder.snp.left)
            make.top.equalTo(scanBorder.snp.top).offset(6)
            make.width.equalTo(scanBorder.snp.width)
            make.height.equalTo(6)
        }

        instructionsLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.view.layoutMarginsGuide)
            make.top.equalTo(scanBorder.snp.bottom).offset(30)
        }
    }

    @objc func startScanLineAnimation() {
        if !isAnimationing {
            return
        }
        self.view.layoutIfNeeded()
        self.view.setNeedsLayout()
        UIView.animate(withDuration: 2.4, animations: {
            self.scanLine.snp.updateConstraints({ (make) in
                make.top.equalTo(self.scanBorder.snp.top).offset(self.scanBorderHeight - 6)
            })
            self.view.layoutIfNeeded()
        }) { (value: Bool) in
            self.scanLine.snp.updateConstraints({ (make) in
                make.top.equalTo(self.scanBorder.snp.top).offset(6)
            })
            self.perform(#selector(self.startScanLineAnimation), with: nil, afterDelay: 0)
        }
    }

    func stopScanLineAnimation() {
        isAnimationing = false
    }

    @objc func goBack() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func openLight() {
        guard let captureDevice = self.captureDevice else {
            return
        }

        if isLightOn {
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.torchMode = AVCaptureDevice.TorchMode.off
                captureDevice.unlockForConfiguration()
                navigationItem.rightBarButtonItem?.image = #imageLiteral(resourceName: "qrcode-light")
                navigationItem.rightBarButtonItem?.tintColor = UIColor.Photon.white100
            } catch {
                print(error)
            }
        } else {
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.torchMode = AVCaptureDevice.TorchMode.on
                captureDevice.unlockForConfiguration()
                navigationItem.rightBarButtonItem?.image = #imageLiteral(resourceName: "qrcode-isLighting")
                navigationItem.rightBarButtonItem?.tintColor = QRCodeViewControllerUX.isLightingNavigationItemColor
            } catch {
                print(error)
            }
        }
        isLightOn = !isLightOn
    }

    func setupCamera() {
        guard let captureDevice = self.captureDevice else {
            dismiss(animated: false)
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
        } catch {
            print(error)
        }
        let output = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        }
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(videoPreviewLayer)
        self.videoPreviewLayer = videoPreviewLayer
        captureSession.startRunning()

    }

    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        shapeLayer.removeFromSuperlayer()
        let rectPath = UIBezierPath(rect: UIScreen.main.bounds)
        rectPath.append(UIBezierPath(rect: scanRange).reversing())
        shapeLayer.path = rectPath.cgPath
        maskView.layer.mask = shapeLayer

        guard let videoPreviewLayer = self.videoPreviewLayer else {
            return
        }
        videoPreviewLayer.frame = UIScreen.main.bounds
        switch toInterfaceOrientation {
        case .portrait:
            videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        }
    }
}

extension QRCodeViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.isEmpty {
            self.captureSession.stopRunning()
            let alert = AlertController(title: "", message: Strings.scanQRCodeInvalidDataErrorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.scanQRCodeErrorOKButton, style: .default, handler: { (UIAlertAction) in
                self.captureSession.startRunning()
            }), accessibilityIdentifier: "qrCodeAlert.okButton")
            self.present(alert, animated: true, completion: nil)
        } else {
            self.captureSession.stopRunning()
            stopScanLineAnimation()
            self.dismiss(animated: true, completion: {
                guard let metaData = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let qrCodeDelegate = self.qrCodeDelegate, let text = metaData.stringValue else {
                    log.debug("Unable to scan QR code")
                        return
                }

                if let url = URIFixup.getURL(text) {
                    qrCodeDelegate.didScanQRCodeWithURL(url)
                } else {
                    qrCodeDelegate.didScanQRCodeWithText(text)
                }
            })
        }
    }
}

class QRCodeNavigationController: UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
