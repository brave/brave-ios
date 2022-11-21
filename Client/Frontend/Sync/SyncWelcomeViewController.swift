/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Data
import BraveShared
import BraveCore
import BraveUI

/// Sometimes during heavy operations we want to prevent user from navigating back, changing screen etc.
protocol NavigationPrevention {
  func enableNavigationPrevention()
  func disableNavigationPrevention()
}

class SyncWelcomeViewController: SyncViewController {
  private var overlayView: UIView?

  private var isLoading: Bool = false {
    didSet {
      overlayView?.removeFromSuperview()

      // Toggle 'restore' button.
      navigationItem.rightBarButtonItem?.isEnabled = !isLoading

      // Prevent dismissing the modal by swipe when migration happens.
      navigationController?.isModalInPresentation = isLoading == true

      if !isLoading { return }

      let overlay = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let activityIndicator = UIActivityIndicatorView().then { indicator in
          indicator.startAnimating()
          indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }

        $0.addSubview(activityIndicator)
      }

      view.addSubview(overlay)
      overlay.snp.makeConstraints {
        $0.edges.equalToSuperview()
      }

      overlayView = overlay
    }
  }

  private var syncServiceObserver: AnyObject?
  private var syncDeviceInfoObserver: AnyObject?
  private let tabManager: TabManager

  lazy var mainStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.distribution = .equalSpacing
    stackView.alignment = .fill
    stackView.spacing = 8
    return stackView
  }()

  lazy var syncImage: UIImageView = {
    let imageView = UIImageView(image: UIImage(named: "sync-art", in: .module, compatibleWith: nil))
    // Shrinking image a bit on smaller devices.
    imageView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 250), for: .vertical)
    imageView.contentMode = .scaleAspectFit

    return imageView
  }()

  lazy var textStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.spacing = 4
    return stackView
  }()

  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
    label.text = Strings.braveSync
    label.textAlignment = .center
    return label
  }()

  lazy var descriptionLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.textAlignment = .center
    label.text = Strings.braveSyncWelcome
    label.setContentHuggingPriority(UILayoutPriority(rawValue: 250), for: .horizontal)

    return label
  }()

  lazy var buttonsStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.spacing = 4
    return stackView
  }()

  lazy var newToSyncButton: RoundInterfaceButton = {
    let button = RoundInterfaceButton(type: .roundedRect)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(Strings.newSyncCode, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.bold)
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = .braveBlurple
    button.addTarget(self, action: #selector(newToSyncAction), for: .touchUpInside)

    button.snp.makeConstraints { make in
      make.height.equalTo(50)
    }

    return button
  }()

  lazy var existingUserButton: RoundInterfaceButton = {
    let button = RoundInterfaceButton(type: .roundedRect)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(Strings.scanSyncCode, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.semibold)
    button.setTitleColor(.braveLabel, for: .normal)
    button.addTarget(self, action: #selector(existingUserAction), for: .touchUpInside)
    return button
  }()

  private let syncAPI: BraveSyncAPI
  private let syncProfileServices: BraveSyncProfileServiceIOS

  init(syncAPI: BraveSyncAPI, syncProfileServices: BraveSyncProfileServiceIOS, tabManager: TabManager) {
    self.syncAPI = syncAPI
    self.syncProfileServices = syncProfileServices
    self.tabManager = tabManager
    
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = Strings.sync

    view.addSubview(mainStackView)
    mainStackView.snp.makeConstraints { make in
      make.top.equalTo(self.view.safeArea.top)
      // This VC doesn't rotate, no need to check for left and right safe area constraints.
      make.left.right.equalTo(self.view).inset(16)
      make.bottom.equalTo(self.view.safeArea.bottom).inset(32)
    }

    // Adding top margin to the image.
    let syncImageStackView = UIStackView(arrangedSubviews: [UIView.spacer(.vertical, amount: 60), syncImage])
    syncImageStackView.axis = .vertical
    mainStackView.addArrangedSubview(syncImageStackView)

    textStackView.addArrangedSubview(titleLabel)
    // Side margins for description text.
    let descriptionStackView = UIStackView(arrangedSubviews: [
      UIView.spacer(.horizontal, amount: 8),
      descriptionLabel,
      UIView.spacer(.horizontal, amount: 8),
    ])

    textStackView.addArrangedSubview(descriptionStackView)
    mainStackView.addArrangedSubview(textStackView)

    buttonsStackView.addArrangedSubview(newToSyncButton)
    buttonsStackView.addArrangedSubview(existingUserButton)
    mainStackView.addArrangedSubview(buttonsStackView)

    navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(onSyncInternalsTapped))
  }

  /// Sync setup failure is handled here because it can happen from few places in children VCs(new chain, qr code, codewords)
  /// This makes all presented Sync View Controllers to dismiss, cleans up any sync setup and shows user a friendly message.
  private func handleSyncSetupFailure() {
    syncServiceObserver = syncAPI.addServiceStateObserver { [weak self] in
      guard let self = self else { return }

      if !self.syncAPI.isInSyncGroup {
        let bvc = self.currentScene?.browserViewController
        self.dismiss(animated: true) {
          bvc?.present(SyncAlerts.initializationError, animated: true)
        }
      }
    }
  }

  @objc
  private func onSyncInternalsTapped() {
    let syncInternalsController = syncAPI.createSyncInternalsController().then {
      $0.title = Strings.braveSyncInternalsTitle
    }

    navigationController?.pushViewController(syncInternalsController, animated: true)
  }

  @objc func newToSyncAction() {
    handleSyncSetupFailure()
    let addDevice = SyncSelectDeviceTypeViewController()
    addDevice.syncInitHandler = { [weak self] (title, type) in
      guard let self = self else { return }

      func pushAddDeviceVC() {
        self.syncServiceObserver = nil
        guard self.syncAPI.isInSyncGroup else {
          addDevice.disableNavigationPrevention()
          let alert = UIAlertController(title: Strings.syncUnsuccessful, message: Strings.syncUnableCreateGroup, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: nil))
          addDevice.present(alert, animated: true, completion: nil)
          return
        }

        let view = SyncAddDeviceViewController(title: title, type: type, syncAPI: self.syncAPI)
        view.doneHandler = self.pushSettings
        view.navigationItem.hidesBackButton = true
        self.navigationController?.pushViewController(view, animated: true)
      }

      if self.syncAPI.isInSyncGroup {
        pushAddDeviceVC()
        return
      }

      addDevice.enableNavigationPrevention()
      self.syncDeviceInfoObserver = self.syncAPI.addDeviceStateObserver {
        self.syncDeviceInfoObserver = nil
        pushAddDeviceVC()
      }

      self.syncAPI.joinSyncGroup(codeWords: self.syncAPI.getSyncCode(), syncProfileService: self.syncProfileServices)
      self.syncAPI.requestSync()
      self.syncAPI.setSetupComplete()
    }

    self.navigationController?.pushViewController(addDevice, animated: true)
  }

  @objc func existingUserAction() {
    handleSyncSetupFailure()
    let pairCamera = SyncPairCameraViewController(syncAPI: syncAPI)
    pairCamera.delegate = self
    self.navigationController?.pushViewController(pairCamera, animated: true)
  }

  private func pushSettings() {
    if !DeviceInfo.hasConnectivity() {
      present(SyncAlerts.noConnection, animated: true)
      return
    }

    let syncSettingsVC = SyncSettingsTableViewController(
      showDoneButton: true,
      syncAPI: syncAPI,
      syncProfileService: syncProfileServices,
      tabManager: tabManager)
    navigationController?.pushViewController(syncSettingsVC, animated: true)
  }
}

extension SyncWelcomeViewController: SyncPairControllerDelegate {
  func syncOnScannedHexCode(_ controller: UIViewController & NavigationPrevention, hexCode: String) {
    syncOnWordsEntered(controller, codeWords: syncAPI.syncCode(fromHexSeed: hexCode))
  }

  func syncOnWordsEntered(_ controller: UIViewController & NavigationPrevention, codeWords: String) {
    controller.enableNavigationPrevention()
    syncDeviceInfoObserver = syncAPI.addDeviceStateObserver { [weak self] in
      guard let self = self else { return }
      self.syncServiceObserver = nil
      self.syncDeviceInfoObserver = nil
      controller.disableNavigationPrevention()
      self.pushSettings()
    }

    syncAPI.joinSyncGroup(codeWords: codeWords, syncProfileService: syncProfileServices)
    syncAPI.requestSync()
    syncAPI.setSetupComplete()
  }
}
