// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveShared

extension Preferences {
    final public class VPN {
      public static let popupShowed = Option<Bool>(key: "vpn.popup-showed", default: false)
      /// We get it from Guardian's servers.
      static let lastPurchaseProductId = Option<String?>(key: "vpn.last-purchase-id", default: nil)
      /// When the current subscription plan expires. It is nil if the user has not bought any vpn plan yet.
      /// In case of receipt expiration this date might be set to some old date(like year 1970)
      /// to make sure vpn expiration logic will be called.
      public static let expirationDate = Option<Date?>(key: "vpn.expiration-date", default: nil)
      /// Whether free trial for the vpn expired for the user.
      static let freeTrialUsed = Option<Bool>(key: "vpn.free-trial-used", default: false)
      /// First time after user background the app after after installing vpn, we show a notification to say that the vpn
      /// also works in background.
      public static let vpnWorksInBackgroundNotificationShowed =
        Option<Bool>(key: "vpn.vpn-bg-notification-showed", default: false)
      public static let vpnSettingHeaderWasDismissed =
        Option<Bool>(key: "vpn.vpn-header-dismissed", default: false)
      /// User can decide to choose their vpn region manually. If nil, automatic mode is used based on device timezone.
      static let vpnRegionOverride = Option<String?>(key: "vpn.region-override", default: nil)
      static let vpnHostDisplayName = Option<String?>(key: "vpn.host-location", default: nil)
      public static let skusCredential = Option<String?>(key: "skus.credential", default: nil)
      public static let skusCredentialDomain = Option<String?>(key: "skus.credential-domain", default: nil)
      public static let skusCredentialExpirationDate = Option<Date?>(key: "skus.credential-expiration", default: nil)
    }
}
