/* Copyright 2022 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import BraveUI
import BraveCore
import BraveShared

class SendTabToSelfController: UIViewController {
  
  struct UX {
    static let contentInset: CGFloat = 20
    static let preferredSizePadding: CGFloat = 60
  }
  
  let contentNavigationController: UINavigationController
  let sendTabContentController: SendTabToSelfContentController
  
  let backgroundView = UIView().then {
    $0.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
  }

  init(sendTabAPI: BraveSendTabAPI, dataSource: SendableTabInfoDataSource) {
    sendTabContentController = SendTabToSelfContentController(sendTabAPI: sendTabAPI, dataSource: dataSource)
    contentNavigationController = UINavigationController(rootViewController: sendTabContentController).then {
      $0.view.layer.cornerRadius = 10.0
      $0.view.layer.cornerCurve = .continuous
      $0.view.clipsToBounds = true
    }
    
    super.init(nibName: nil, bundle: nil)
        
    transitioningDelegate = self
    modalPresentationStyle = .overFullScreen
    addChild(contentNavigationController)
    contentNavigationController.didMove(toParent: self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .clear
    view.addSubview(backgroundView)
    view.addSubview(contentNavigationController.view)

    backgroundView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    let preferredSize = sendTabContentController.view.systemLayoutSizeFitting(
      CGSize(width: view.bounds.size.width, height: view.frame.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    ).with {
      $0.height += UX.preferredSizePadding
    }
    
    contentNavigationController.view.snp.makeConstraints {
      $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(UX.contentInset)
      $0.centerX.centerY.equalToSuperview()
      $0.height.equalTo(preferredSize.height)
    }
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
}

class SendTabToSelfContentController: UITableViewController {
  
  struct UX {
    static let standardItemHeight: CGFloat = 44
  }

  // MARK: Internal
  
  private var dataSource: SendableTabInfoDataSource?
  private var sendTabAPI: BraveSendTabAPI?

  // MARK: Lifecycle
  
  convenience init(sendTabAPI: BraveSendTabAPI, dataSource: SendableTabInfoDataSource) {
    self.init(style: .plain)
    
    self.dataSource = dataSource
    self.sendTabAPI = sendTabAPI
  }

  override init(style: UITableView.Style) {
    super.init(style: style)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = "Send Webpage"
    navigationItem.leftBarButtonItem =
      UIBarButtonItem(title: Strings.cancelButtonTitle, style: .plain, target: self, action: #selector(cancel))

    tableView.do {
      $0.tableHeaderView = UIView()
      $0.register(CenteredButtonCell.self)
      $0.register(TwoLineTableViewCell.self)
      $0.registerHeaderFooter(SendTabToSelfContentHeaderFooterView.self)
      tableView.tableFooterView = SendTabToSelfContentHeaderFooterView(
        frame: CGRect(width: tableView.bounds.width, height: UX.standardItemHeight)).then {
        $0.titleLabel.text = "Send To Your Device"
        $0.titleLabel.isUserInteractionEnabled = true
        $0.titleLabel.addGestureRecognizer(UITapGestureRecognizer(
          target: self,
          action: #selector(tappedSendLabel(_:))))
      }
    }
  }
  
  @objc func cancel() {
    dismiss(animated: true)
  }
}

// MARK: UITableViewDataSource - UITableViewDelegate

extension SendTabToSelfContentController {
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let dataSource = dataSource else { return 0 }

    return dataSource.numberOfDevices()
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(for: indexPath) as TwoLineTableViewCell

    if let device = dataSource?.deviceInformation(for: indexPath) {
      var deviceTypeImage: UIImage?
      
      switch device.deviceType {
      case .mobile:
        deviceTypeImage = UIImage(systemName: "ipad.and.iphone")
      case .PC:
        deviceTypeImage = UIImage(systemName: "laptopcomputer")
      default:
        deviceTypeImage = UIImage(systemName: "laptopcomputer.and.iphone")
      }
      
      cell.do {
        $0.backgroundColor = .clear
        $0.accessoryType = indexPath.row == dataSource?.selectedIndex ? .checkmark : .none
        $0.setLines(device.fullName, detailText: device.lastUpdatedTime.formattedActivePeriodDate)
        $0.imageView?.contentMode = .scaleAspectFit
        $0.imageView?.tintColor = .braveLabel
        $0.imageView?.image = deviceTypeImage?.template
      }
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let dataSource = dataSource else { return }
    
    dataSource.selectedIndex = indexPath.row
    tableView.reloadSections(IndexSet(integer: indexPath.section), with: .fade)
  }
  
  @objc private func tappedSendLabel(_ gesture: UITapGestureRecognizer) {
    guard let dataSource = dataSource, gesture.state == .ended else { return }

    if let deviceCacheId = dataSource.deviceCacheID() {
      sendTabAPI?.sendActiveTab(
        toDevice: deviceCacheId,
        tabTitle: dataSource.displayTitle,
        activeURL: dataSource.sendableURL)
    }
    
    dismiss(animated: true)
  }
}

class SendTabToSelfContentHeaderFooterView: UITableViewHeaderFooterView, TableViewReusable {
  private struct UX {
    static let horizontalPadding: CGFloat = 15
    static let verticalPadding: CGFloat = 6
  }
  
  var titleLabel = UILabel().then {
    $0.font = .preferredFont(forTextStyle: .body)
    $0.numberOfLines = 0
    $0.textColor = .braveOrange
    $0.textAlignment = .center
  }

  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    addSubview(titleLabel)

    titleLabel.snp.remakeConstraints {
      $0.left.right.greaterThanOrEqualTo(self).inset(UX.horizontalPadding)
      $0.top.bottom.greaterThanOrEqualTo(self).inset(UX.verticalPadding)
      $0.centerX.centerY.equalToSuperview()
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
