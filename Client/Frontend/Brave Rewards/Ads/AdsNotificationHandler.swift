// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveCore
import pop
import SnapKit
import BraveShared

public class AdsNotificationHandler: BraveAdsNotificationHandler {
  /// An ad was tapped and a URL should be opened
  public var actionOccured: ((AdNotification?, BraveNotificationAction) -> Void)?
  /// The ads object
  public let ads: BraveAds
  /// Whether or not we should currently show ads currently based on exteranl
  /// factors such as private mode
  public var canShowNotifications: (() -> Bool)?
  /// The controller which we will show notifications on top of
  public private(set) weak var presentingController: UIViewController?

  /// Create a handler instance with the given ads instance.
  ///
  /// - note: This method automatically sets `notificationsHandler` on BATBraveAds
  /// to itself
  public init(ads: BraveAds, presentingController: UIViewController) {
    self.ads = ads
    self.ads.notificationsHandler = self
    self.presentingController = presentingController
  }
    
  private lazy var notificationsController = BraveNotificationsController()
  
  private func display(notification: BraveNotification) {
    guard let presentingController = presentingController else { return }
    guard let window = presentingController.view.window else { return }
    
    if notificationsController.parent == nil {
      window.addSubview(notificationsController.view)
      notificationsController.view.snp.makeConstraints {
        $0.edges.equalTo(window.safeAreaLayoutGuide.snp.edges)
      }
    }
    
    if let rewards = notification as? RewardsNotification {
      notificationsController.display(notification: rewards) { [weak self] in
        guard let self = self else { return }
        self.notificationsController.willMove(toParent: nil)
        self.notificationsController.view.removeFromSuperview()
        self.notificationsController.removeFromParent()
      }
    } else if let wallet = notification as? WalletNotification {
      notificationsController.display(notification: wallet) { [weak self] in
        guard let self = self else { return }
        self.notificationsController.willMove(toParent: nil)
        self.notificationsController.view.removeFromSuperview()
        self.notificationsController.removeFromParent()
      }
    }
  }
  
  // This method can be used to display a wallet connection prompt when we detect users are visiting
  // a web3 site.
  public func showWalletConnectionNotification() {
    let walletNotification = WalletNotification(priority: .low) { [weak self] action in
      guard let self = self else { return }
      
      self.actionOccured?(nil, .wallet(action))
      
      if let nextNotification = self.notificationsController.notificationsQueue.popLast() {
        self.display(notification: nextNotification)
      }
    }
    notificationsController.safeInsert(notification: walletNotification)
    display(notification: notificationsController.notificationsQueue.popLast()!)
  }
  
  public func showNotification(_ notification: AdNotification) {
    let rewardsNotification = RewardsNotification(ad: notification) { [weak self] action in
      guard let self = self else { return }
      switch action {
      case .opened:
        self.ads.reportAdNotificationEvent(notification.uuid, eventType: .clicked)
      case .dismissed:
        self.ads.reportAdNotificationEvent(notification.uuid, eventType: .dismissed)
      case .timedOut:
        self.ads.reportAdNotificationEvent(notification.uuid, eventType: .timedOut)
      case .disliked:
        self.ads.reportAdNotificationEvent(notification.uuid, eventType: .dismissed)
        self.ads.toggleThumbsDown(forAd: notification.uuid, advertiserId: notification.advertiserID)
      }
      self.actionOccured?(notification, .rewards(action))
      
      if let nextNotification = self.notificationsController.notificationsQueue.popLast() {
        self.display(notification: nextNotification)
      }
    }
    
    ads.reportAdNotificationEvent(notification.uuid, eventType: .viewed)
    notificationsController.safeInsert(notification: rewardsNotification)
    display(notification: notificationsController.notificationsQueue.popLast()!)
  }

  public func clearNotification(withIdentifier identifier: String) {
    notificationsController.removeRewardsNotification(with: identifier)
  }

  public func shouldShowNotifications() -> Bool {
    guard let presentingController = presentingController,
      let rootVC = presentingController.currentScene?.browserViewController
    else { return false }
    func topViewController(startingFrom viewController: UIViewController) -> UIViewController {
      var top = viewController
      if let navigationController = top as? UINavigationController,
        let vc = navigationController.visibleViewController {
        return topViewController(startingFrom: vc)
      }
      if let tabController = top as? UITabBarController,
        let vc = tabController.selectedViewController {
        return topViewController(startingFrom: vc)
      }
      while let next = top.presentedViewController {
        top = next
      }
      return top
    }
    let isTopController = presentingController == topViewController(startingFrom: rootVC)
    let isTopWindow = presentingController.view.window?.isKeyWindow == true
    let canShowAds = canShowNotifications?() ?? true
    return isTopController && isTopWindow && canShowAds
  }
}
