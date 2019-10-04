// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards

struct RewardsNotificationViewBuilder {
  
  static func get(notification: RewardsNotification) -> WalletNotificationView? {
    switch notification.kind {
    case .autoContribute:
      return RewardsNotificationViewBuilder.getAutoContribute(notification: notification)
    case .grant, .grantAds, .tipsProcessed, .verifiedPublisher:
      return RewardsNotificationViewBuilder.get(actionNotification: notification)
    case .insufficientFunds, .pendingNotEnoughFunds:
      return get(alertNotification: notification)
    default:
      return nil
    }
  }
  
  static var networkUnavailableNotification: WalletNotificationView {
    return WalletAlertNotificationView(
      notification: WalletAlertNotification(
        category: .error,
        title: RewardsStrings.NoNetworkTitle,
        body: RewardsStrings.NoNetworkBody
      )
    )
  }
  
  private static func getAutoContribute(notification: RewardsNotification) -> WalletNotificationView? {
    if let result = notification.userInfo["result"] as? Int, let amount = notification.userInfo["amount"] as? String, let batResult = Result(rawValue: result) {
      switch batResult {
      case .ledgerOk:
        return RewardsNotificationViewBuilder.get(actionNotification: notification, bodyText: String.localizedStringWithFormat(RewardsStrings.NotificationContributeSuccess, amount))
      default:
        let model = RewardsNotificationViewBuilder.alertModel(contributeResult: batResult)
        return RewardsNotificationViewBuilder.get(alertNotification: notification, model: model)
      }
    } else {
      assertionFailure("Auto Contribute notification has invalid userInfo")
      return nil
    }
  }
  
  private static func alertModel(contributeResult: Result) -> WalletAlertNotification {
    switch contributeResult {
    case .notEnoughFunds:
      return WalletAlertNotification(category: .warning, title: nil, body: RewardsStrings.NotificationAutoContributeNotEnoughFundsBody)
    case .tipError:
      return WalletAlertNotification(category: .error, title: RewardsStrings.NotificationErrorTitle, body: RewardsStrings.NotificationContributeTipError)
    default:
      return WalletAlertNotification(category: .error, title: RewardsStrings.NotificationErrorTitle, body: RewardsStrings.NotificationContributeError)
    }
  }
  
  private static func get(actionNotification: RewardsNotification, bodyText: String? = nil) -> WalletActionNotificationView? {
    let category: WalletActionNotification.Category
    let body: String
    
    switch actionNotification.kind {
    case .grant:
      body = RewardsStrings.NotificationGrantNotification
      category = .grant
    case .grantAds:
      body = RewardsStrings.NotificationEarningsClaimDefault
      category = .grant
    case .tipsProcessed:
      body = RewardsStrings.NotificationTipsProcessedBody
      category = .tipsProcessed
    case .verifiedPublisher:
      if let name = actionNotification.userInfo["name"] as? String {
        body = String.localizedStringWithFormat(RewardsStrings.NotificationVerifiedPublisherBody, name)// publisher name"
        category = .verifiedPublisher
      } else {
        assertionFailure("Verified publisher notification has invalid userInfo")
        return nil
      }
    case .autoContribute:
      guard let bodyText = bodyText else {
        assertionFailure("Auto Contribute notifications require bodyText")
        return nil
      }
      body = bodyText
      category = .contribute
    default:
      assertionFailure("Undefined case for action notification")
      return nil
    }
    let date = Date(timeIntervalSince1970: actionNotification.dateAdded)
    return WalletActionNotificationView(
      notification: WalletActionNotification(
        category: category,
        body: body,
        date: date))
  }

  private static func get(alertNotification: RewardsNotification, model: WalletAlertNotification? = nil) -> WalletAlertNotificationView? {
    let body: String
    var alertType: WalletAlertNotification.Category
    var title: String?
    switch alertNotification.kind {
    case .insufficientFunds:
      body = RewardsStrings.NotificationInsufficientFunds
      alertType = .warning
      title = RewardsStrings.NotificationInsufficientFundsTitle
    case .pendingNotEnoughFunds:
      body = RewardsStrings.NotificationPendingNotEnoughFunds
      alertType = .warning
    case .autoContribute:
      guard let model = model else {
        assertionFailure("Auto Contribute alerts require bodyText and type")
        return nil
      }
      return WalletAlertNotificationView(notification: model)
    default:
      assertionFailure("Undefined case for alert notification")
      return nil
    }
    
    return WalletAlertNotificationView(
      notification: WalletAlertNotification(
        category: alertType,
        title: title,
        body: body
      )
    )
  }
}
