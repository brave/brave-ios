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
  /// The controller that display, hide and manage notifications
  private let notificationsPresenter: BraveNotificationsPresenter

  /// Create a handler instance with the given ads instance.
  ///
  /// - note: This method automatically sets `notificationsHandler` on BATBraveAds
  /// to itself
  public init(
    ads: BraveAds,
    presentingController: UIViewController,
    notificationsPresenter: BraveNotificationsPresenter
  ) {
    self.ads = ads
    self.notificationsPresenter = notificationsPresenter
    self.presentingController = presentingController
    self.ads.notificationsHandler = self
  }
    
  public func showNotification(_ notification: AdNotification) {
    guard let presentingController = presentingController else { return }
  
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
    }
    
    ads.reportAdNotificationEvent(notification.uuid, eventType: .viewed)
    notificationsPresenter.display(notification: rewardsNotification, presentingController: presentingController)
  }

  public func clearNotification(withIdentifier identifier: String) {
    notificationsPresenter.removeRewardsNotification(with: identifier)
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
