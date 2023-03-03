/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import BraveShared
import BraveCore
import Data
import os.log

class SyncPairWordsViewController: SyncViewController {

  weak var delegate: SyncPairControllerDelegate?
  var scrollView: UIScrollView!
  var containerView: UIView!
  var codewordsView: SyncCodewordsView!

  lazy var wordCountLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
    label.textColor = .braveLabel
    label.text = String(format: Strings.wordCount, 0)
    return label
  }()

  lazy var copyPasteButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(named: "copy_paste", in: .module, compatibleWith: nil)?.template, for: .normal)
    button.addTarget(self, action: #selector(SEL_paste), for: .touchUpInside)
    button.tintColor = .braveLabel
    return button
  }()

  lazy var useCameraButton = UIButton().then {
    $0.setTitle(Strings.syncSwitchBackToCameraButton, for: .normal)
    $0.addTarget(self, action: #selector(useCameraButtonTapped), for: .touchDown)
    $0.setTitleColor(.braveLabel, for: .normal)
    $0.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
  }

  var loadingView: UIView!
  let loadingSpinner = UIActivityIndicatorView(style: .large)

  private let syncAPI: BraveSyncAPI

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

    title = Strings.syncAddDeviceWordsTitle

    scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)

    containerView = UIView()
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.backgroundColor = .braveBackground
    containerView.layer.shadowColor = UIColor.braveSeparator.cgColor
    containerView.layer.shadowRadius = 0
    containerView.layer.shadowOpacity = 1.0
    containerView.layer.shadowOffset = CGSize(width: 0, height: 0.5)
    scrollView.addSubview(containerView)

    codewordsView = SyncCodewordsView(data: [])
    codewordsView.wordCountChangeCallback = { (count) in
      self.wordCountLabel.text = String(format: Strings.wordCount, count)
    }
    containerView.addSubview(codewordsView)
    containerView.addSubview(wordCountLabel)
    containerView.addSubview(copyPasteButton)

    loadingSpinner.startAnimating()

    loadingView = UIView()
    loadingView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
    loadingView.isHidden = true
    loadingView.addSubview(loadingSpinner)

    view.addSubview(loadingView)
    view.addSubview(useCameraButton)

    navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.confirm, style: .done, target: self, action: #selector(SEL_done))

    edgesForExtendedLayout = UIRectEdge()

    scrollView.snp.makeConstraints { (make) in
      make.edges.equalTo(self.view)
    }

    containerView.snp.makeConstraints { (make) in
      // Making these edges based off of the scrollview removes selectability on codewords.
      //  This currently works for all layouts and enables interaction, so using `view` instead.
      make.top.equalTo(self.view)
      make.left.equalTo(self.view)
      make.right.equalTo(self.view)
      make.height.equalTo(295)
      make.width.equalTo(self.view)
    }

    codewordsView.snp.makeConstraints { (make) in
      make.edges.equalTo(self.containerView).inset(UIEdgeInsets(top: 0, left: 0, bottom: 45, right: 0))
    }

    wordCountLabel.snp.makeConstraints { (make) in
      make.top.equalTo(codewordsView.snp.bottom)
      make.left.equalTo(codewordsView).inset(24)
    }

    copyPasteButton.snp.makeConstraints { (make) in
      make.size.equalTo(45)
      make.right.equalTo(containerView).inset(15)
      make.bottom.equalTo(containerView).inset(15)
    }

    loadingView.snp.makeConstraints { (make) in
      make.edges.equalTo(loadingView.superview!)
    }

    loadingSpinner.snp.makeConstraints { (make) in
      make.center.equalTo(loadingView)
    }

    useCameraButton.snp.makeConstraints { make in
      make.top.equalTo(containerView.snp.bottom).offset(16)
      make.left.equalTo(self.view)
      make.right.equalTo(self.view)
      make.centerX.equalTo(self.view)
    }
  }

  @objc func useCameraButtonTapped() {
    self.navigationController?.popViewController(animated: true)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    codewordsView.becomeFirstResponder()
  }

  @objc func SEL_paste() {
    if let contents = UIPasteboard.general.string, !contents.isEmpty {
      // remove linebreaks and whitespace, split into codewords.
      codewordsView.setCodewords(data: contents.separatedBy(" "))

      UIPasteboard.general.clearPasteboard()
    }
  }

  @objc func SEL_done() {
    doIfConnected {
      self.checkCodes()
    }
  }

  private func checkCodes() {
    Logger.module.debug("check codes")

    let codes = self.codewordsView.codeWords().joined(separator: " ")
    let syncCodeValidation = syncAPI.getWordsValidationResult(codes)
    if syncCodeValidation == .wrongWordsNumber {
      alert(title: Strings.notEnoughWordsTitle, message: Strings.notEnoughWordsDescription)
      return
    }

    view.endEditing(true)
    enableNavigationPrevention()

    if syncCodeValidation == .valid {
      let words = syncAPI.getWordsFromTimeLimitedWords(codes)
      delegate?.syncOnWordsEntered(self, codeWords: words)
    } else {
      alert(message: syncCodeValidation.errorDescription)
      disableNavigationPrevention()
    }
  }
  
  private func timeoutSyncSetup() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 25.0) {
      self.disableNavigationPrevention()
      self.alert()
    }
  }
  
  private func alert(title: String? = nil, message: String? = nil) {
    if syncAPI.isInSyncGroup {
      return
    }
    
    let title = title ?? Strings.unableToConnectTitle
    let message = message ?? Strings.unableToConnectDescription
    
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: nil))
    present(alert, animated: true, completion: nil)
  }
}

// MARK: NavigationPrevention

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
