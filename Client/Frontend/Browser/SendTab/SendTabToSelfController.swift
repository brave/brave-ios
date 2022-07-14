/* Copyright 2022 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import BraveUI
import BraveCore
import BraveShared
import DesignSystem
import UIKit

struct DesignUX {
  static let informationRowHeight: CGFloat = 58
  static let standardItemHeight: CGFloat = 44
  static let contentInset: CGFloat = 20
}

public class SendTabToSelfController: UIViewController {
  private let contentNavigationController: UINavigationController
  private let sendTabContentController: SendTabToSelfContentController
  
  private let backgroundView = UIView().then {
    $0.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
  }

  public init(deviceList: [SendTabTargetDevice]) {
    sendTabContentController = SendTabToSelfContentController(deviceList: deviceList)
    contentNavigationController = UINavigationController(rootViewController: sendTabContentController)
    
    super.init(nibName: nil, bundle: nil)
        
    transitioningDelegate = self
    modalPresentationStyle = .overFullScreen
    addChild(contentNavigationController)
    contentNavigationController.didMove(toParent: self)
  }

  public override func viewDidLoad() {
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
      $0.height += (DesignUX.informationRowHeight + DesignUX.informationRowHeight)
    }
    
    contentNavigationController.view.snp.makeConstraints {
      $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(DesignUX.contentInset)
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
  
  // MARK: Section

  enum Section: Int, CaseIterable {
    case information
    case send
  }

  // MARK: Internal
  
  private var deviceList = [SendTabTargetDevice]()
  private var selectedIndex = 0
  
  // MARK: Lifecycle
  convenience init(deviceList: [SendTabTargetDevice]) {
    self.init(style: .plain)
    self.deviceList = deviceList
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

    navigationItem.title = "Send WebPage"
    navigationItem.leftBarButtonItem =
      UIBarButtonItem(title: Strings.cancelButtonTitle, style: .plain, target: self, action: #selector(cancel))

    tableView.do {
      $0.register(CenteredButtonCell.self)
      $0.register(TwoLineTableViewCell.self)
      $0.registerHeaderFooter(SettingsTableSectionHeaderFooterView.self)
    }
  }

  // MARK: UITableViewDelegate, UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return Section.allCases.count
  }  

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case Section.information.rawValue:
      return deviceList.count
    default:
      return 1
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    switch indexPath.section {
    case Section.information.rawValue:
      return DesignUX.informationRowHeight
    case Section.send.rawValue:
      return DesignUX.standardItemHeight
    default:
      return UITableView.automaticDimension
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch indexPath.section {
    case Section.information.rawValue:
      let device = deviceList[indexPath.row]
      
      let cell = tableView.dequeueReusableCell(for: indexPath) as TwoLineTableViewCell
      cell.do {
        $0.separatorInset = .zero
        $0.accessoryType = indexPath.row == selectedIndex ? .checkmark : .none
        $0.setLines(device.fullName, detailText: device.lastUpdatedTime.description)
        $0.imageView?.contentMode = .scaleAspectFit
        $0.imageView?.image = UIImage(systemName: "laptopcomputer")
      }
           
      return cell
    case Section.send.rawValue:
      let cell = tableView.dequeueReusableCell(for: indexPath) as CenteredButtonCell
      cell.do {
        $0.textLabel?.text = "Send To Your Device"
        $0.separatorInset = .zero
        $0.tintColor = .braveOrange
      }
      return cell
    default:
      assertionFailure("No cell available for index path: \(indexPath)")
    }

    return UITableViewCell()
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.section {
    case Section.information.rawValue:
      selectedIndex = indexPath.row
      tableView.reloadSections(IndexSet(integer: indexPath.section), with: .fade)
    case Section.send.rawValue:
      print("Send")
    default:
      assertionFailure("No cell available for index path: \(indexPath)")
    }
  }

  @objc func cancel() {
    dismiss(animated: true)
  }
}

// MARK: - BasicAnimationControllerDelegate

extension SendTabToSelfController: BasicAnimationControllerDelegate {
  public func animatePresentation(context: UIViewControllerContextTransitioning) {
    context.containerView.addSubview(view)

    backgroundView.alpha = 0.0
    contentNavigationController.view.transform =
      CGAffineTransform(translationX: 0, y: context.containerView.bounds.height)

    UIViewPropertyAnimator(duration: 0.35, dampingRatio: 1.0) { [self] in
      backgroundView.alpha = 1.0
      contentNavigationController.view.transform = .identity
    }.startAnimation()

    context.completeTransition(true)
  }

  public func animateDismissal(context: UIViewControllerContextTransitioning) {
    let animator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1.0) { [self] in
      backgroundView.alpha = 0.0
      contentNavigationController.view.transform =
        CGAffineTransform(translationX: 0, y: context.containerView.bounds.height)
    }
    animator.addCompletion { _ in
      self.view.removeFromSuperview()
      context.completeTransition(true)
    }
    animator.startAnimation()
  }
}

// MARK: - UIViewControllerTransitioningDelegate

extension SendTabToSelfController: UIViewControllerTransitioningDelegate {
  public func animationController(
    forPresented presented: UIViewController,
    presenting: UIViewController,
    source: UIViewController
  ) -> UIViewControllerAnimatedTransitioning? {
    return BasicAnimationController(delegate: self, direction: .presenting)
  }

  public func animationController(
    forDismissed dismissed: UIViewController
  ) -> UIViewControllerAnimatedTransitioning? {
    return BasicAnimationController(delegate: self, direction: .dismissing)
  }
}
