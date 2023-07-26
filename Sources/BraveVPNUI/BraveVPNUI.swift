// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveVPN
import Strings
import GuardianConnect
import OSLog
import Preferences

extension BraveVPN {
  /// Name of the purchased vpn plan.
  public static var subscriptionName: String {
    guard let credential = GRDSubscriberCredential.current() else {
      logAndStoreError("subscriptionName: failed to retrieve subscriber credentials")
      return ""
    }
    let productId = credential.subscriptionType
    
    switch productId {
    case VPNProductInfo.ProductIdentifiers.monthlySub:
      return Strings.VPN.vpnSettingsMonthlySubName
    case VPNProductInfo.ProductIdentifiers.yearlySub:
      return Strings.VPN.vpnSettingsYearlySubName
    case VPNProductInfo.ProductIdentifiers.monthlySubSKU:
      return Strings.VPN.vpnSettingsMonthlySubName
    default:
      assertionFailure("Can't get product id")
      return ""
    }
  }
  
  public static func sendVPNWorksInBackgroundNotification() {
    switch vpnState {
    case .expired, .notPurchased:
      break
    case .purchased(let enabled):
      if !enabled || Preferences.VPN.vpnWorksInBackgroundNotificationShowed.value {
        break
      }
      
      let center = UNUserNotificationCenter.current()
      let notificationId = "vpnWorksInBackgroundNotification"
      
      center.requestAuthorization(options: [.provisional, .alert, .sound, .badge]) { granted, error in
        if let error = error {
          Logger.module.error("Failed to request notifications permissions: \(error.localizedDescription)")
          return
        }
        
        if !granted {
          Logger.module.info("Not authorized to schedule a notification")
          return
        }
        
        center.getPendingNotificationRequests { requests in
          if requests.contains(where: { $0.identifier == notificationId }) {
            // Already has one scheduled no need to schedule again.
            // Should not happens since we push the notification right away.
            return
          }
          
          let content = UNMutableNotificationContent()
          content.title = Strings.VPN.vpnBackgroundNotificationTitle
          content.body = Strings.VPN.vpnBackgroundNotificationBody
          
          // Empty `UNNotificationTrigger` sends the notification right away.
          let request = UNNotificationRequest(identifier: notificationId, content: content,
                                              trigger: nil)
          
          center.add(request) { error in
            if let error = error {
              Logger.module.error("Failed to add notification: \(error.localizedDescription)")
              return
            }
            
            Preferences.VPN.vpnWorksInBackgroundNotificationShowed.value = true
          }
        }
      }
    }
  }
  
}

extension BraveVPN.State {
  /// What view controller to show once user taps on `Enable VPN` button at one of places in the app.
  public var enableVPNDestinationVC: UIViewController? {
    switch self {
    case .notPurchased, .expired: return BuyVPNViewController(iapObserver: BraveVPN.iapObserver)
      // Show nothing, the `Enable` button will now be used to connect and disconnect the vpn.
    case .purchased: return nil
    }
  }
}
