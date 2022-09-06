/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import BraveShared
import BraveCore
import Data
import UniformTypeIdentifiers

private let log = Logger.browserLogger

class SyncPairWordsViewController: SyncViewController {

  // MARK: Internal
  
  weak var delegate: SyncPairControllerDelegate?
  
  private var scrollView = UIScrollView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
  }
  
  private var containerView = UIView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .braveBackground
    $0.layer.shadowColor = UIColor.braveSeparator.cgColor
    $0.layer.shadowRadius = 0
    $0.layer.shadowOpacity = 1.0
    $0.layer.shadowOffset = CGSize(width: 0, height: 0.5)
  }
  
  private var codewordsView = SyncCodewordsView(data: [])
  
  private var loadingView = UIView().then {
    $0.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
    $0.isHidden = true
  }
  
  private let loadingSpinner = UIActivityIndicatorView(style: .large)
  
  private lazy var wordCountLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
    label.textColor = .braveLabel
    label.text = String(format: Strings.wordCount, 0)
    return label
  }()

  private lazy var useCameraButton = UIButton().then {
    $0.setTitle(Strings.syncSwitchBackToCameraButton, for: .normal)
    $0.addTarget(self, action: #selector(useCameraButtonTapped), for: .touchDown)
    $0.setTitleColor(.braveLabel, for: .normal)
    $0.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
  }
  
//  private lazy var copyPasteButton: UIButton = {
//    let button = UIButton()
//    button.setImage(UIImage(named: "copy_paste", in: .current, compatibleWith: nil)?.template, for: .normal)
//    button.addTarget(self, action: #selector(pasteKeywords), for: .touchUpInside)
//    button.tintColor = .braveLabel
//    return button
//  }()
  
  private let syncAPI: BraveSyncAPI

  // MARK: Lifecycle
  
  init(syncAPI: BraveSyncAPI) {
    self.syncAPI = syncAPI
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    containerView.layer.shadowColor = UIColor.braveSeparator.cgColor
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    edgesForExtendedLayout = UIRectEdge()
    title = Strings.syncAddDeviceWordsTitle
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.confirm, style: .done, target: self, action: #selector(done))

    view.addSubview(scrollView)
    scrollView.addSubview(containerView)

    codewordsView.wordCountChangeCallback = { [weak self] count in
      self?.wordCountLabel.text = String(format: Strings.wordCount, count)
    }
    containerView.addSubview(codewordsView)
    containerView.addSubview(wordCountLabel)
//    containerView.addSubview(copyPasteButton)

    loadingView.addSubview(loadingSpinner)

    view.addSubview(loadingView)
    view.addSubview(useCameraButton)

    scrollView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    containerView.snp.makeConstraints {
      // Making these edges based off of the scrollview removes selectability on codewords.
      //  This currently works for all layouts and enables interaction, so using `view` instead.
      $0.top.left.right.width.equalTo(view)
      $0.height.equalTo(295)
    }

    codewordsView.snp.makeConstraints {
      $0.edges.equalTo(containerView).inset(UIEdgeInsets(top: 0, left: 0, bottom: 45, right: 0))
    }

    wordCountLabel.snp.makeConstraints {
      $0.top.equalTo(codewordsView.snp.bottom)
      $0.left.equalTo(codewordsView).inset(24)
    }

//    copyPasteButton.snp.makeConstraints {
//      $0.size.equalTo(45)
//      $0.right.equalTo(containerView).inset(15)
//      $0.bottom.equalTo(containerView).inset(15)
//    }
//
//    copyPasteButton.isHidden = true
    
    if #available(iOS 16.0, *) {
//      let configuration = UIPasteControl.Configuration().then {
//        $0.displayMode = .iconOnly
//        $0.baseBackgroundColor = .clear
//        $0.baseForegroundColor = .white
//      }
      
      let pasteControl = UIPasteControl()
      pasteControl.target = self
      
      containerView.addSubview(pasteControl)
      pasteControl.translatesAutoresizingMaskIntoConstraints = false

      NSLayoutConstraint.activate([
        pasteControl.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        pasteControl.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
      ])
      
//      pasteControl.snp.makeConstraints {
////        $0.size.equalTo(45)
//        $0.right.equalTo(containerView).inset(15)
//        $0.bottom.equalTo(containerView).inset(15)
//      }
      
      pasteConfiguration = UIPasteConfiguration(acceptableTypeIdentifiers: [
          UTType.text.identifier,
          UTType.image.identifier,
      ])
    }

    loadingView.snp.makeConstraints {
      $0.edges.equalTo(loadingView.superview!)
    }

    loadingSpinner.snp.makeConstraints {
      $0.center.equalTo(loadingView)
    }

    useCameraButton.snp.makeConstraints {
      $0.top.equalTo(containerView.snp.bottom).offset(16)
      $0.left.right.centerX.equalTo(view)
    }
    
    loadingSpinner.startAnimating()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    codewordsView.becomeFirstResponder()
  }

  // MARK: Actions
  
  @objc func useCameraButtonTapped() {
    navigationController?.popViewController(animated: true)
  }
  
//  @objc func pasteKeywords() {
//    if let contents = UIPasteboard.general.string, !contents.isEmpty {
//      // remove linebreaks and whitespace, split into codewords.
//      codewordsView.setCodewords(data: contents.separatedBy(" "))
//
//      UIPasteboard.general.clearPasteboard()
//    }
//  }

  @objc func done() {
    doIfConnected {
      self.checkCodes()
    }
  }

  private func checkCodes() {
    log.debug("check codes")

    func alert(title: String? = nil, message: String? = nil) {
      if syncAPI.isInSyncGroup {
        // No alert
        return
      }
      let title = title ?? Strings.unableToConnectTitle
      let message = message ?? Strings.unableToConnectDescription
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: nil))
      self.present(alert, animated: true, completion: nil)
    }

    let codes = self.codewordsView.codeWords().joined(separator: " ")
    let syncCodeValidation = syncAPI.getWordsValidationResult(codes)
    if syncCodeValidation == .wrongWordsNumber {
      alert(title: Strings.notEnoughWordsTitle, message: Strings.notEnoughWordsDescription)
      return
    }

    self.view.endEditing(true)
    enableNavigationPrevention()

    // forced timeout
    DispatchQueue.main.asyncAfter(
      deadline: DispatchTime.now() + Double(Int64(25.0) * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC),
      execute: {
        self.disableNavigationPrevention()
        alert()
      })

    if syncCodeValidation == .valid {
      let words = syncAPI.getWordsFromTimeLimitedWords(codes)
      delegate?.syncOnWordsEntered(self, codeWords: words)
    } else {
      alert(message: syncCodeValidation.errorDescription)
      disableNavigationPrevention()
    }

  }
}

// MARK: Navigation Prevention

extension SyncPairWordsViewController: NavigationPrevention {
  func enableNavigationPrevention() {
    loadingView.isHidden = false
    navigationItem.rightBarButtonItem?.isEnabled = false
    navigationItem.hidesBackButton = true
  }

  func disableNavigationPrevention() {
    loadingView.isHidden = true
    navigationItem.rightBarButtonItem?.isEnabled = true
    navigationItem.hidesBackButton = false

  }
}

extension SyncPairWordsViewController {
  override func paste(itemProviders: [NSItemProvider]) {
    for provider in itemProviders {
      if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
        _ = provider.loadObject(ofClass: String.self) { [weak self] providerContents, error in
          if let contents = providerContents, !contents.isEmpty {
            // remove linebreaks and whitespace, split into codewords.
            Task { @MainActor in
              self?.codewordsView.setCodewords(data: contents.separatedBy(" "))
              
              //UIPasteboard.general.clearPasteboard()
              print(contents as Any, error as Any)
            }
          }
        }
      } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
        _ = provider.loadObject(ofClass: UIImage.self) { img, error in
            print(img as Any, error as Any)
        }
      }
    }
  }
  
}
