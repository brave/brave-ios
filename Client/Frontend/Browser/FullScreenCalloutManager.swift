// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import BraveTelemetry

struct FullScreenCalloutManager {

  enum FullScreenCalloutType {
    case vpn, rewards, defaultBrowser, blockCookieConsentNotices

    /// The number of days passed to show certain type of callout
    var period: Int {
      switch self {
      case .blockCookieConsentNotices: return 0
      case .vpn: return 4
      case .rewards: return 8
      case .defaultBrowser: return 10
      }
    }

    /// The preference value stored for complete state
    var preferenceValue: Preferences.Option<Bool> {
      switch self {
      case .blockCookieConsentNotices: return Preferences.FullScreenCallout.blockCookieConsentNoticesCalloutCompleted
      case .vpn: return Preferences.FullScreenCallout.vpnCalloutCompleted
      case .rewards: return Preferences.FullScreenCallout.rewardsCalloutCompleted
      case .defaultBrowser: return Preferences.DefaultBrowserIntro.completed
      }
    }
  }

  /// It determines whether we should show show the designated callout or not and sets corresponding preferences accordingly.
  /// Returns true if the callout should be shown.
  static func shouldShowDefaultBrowserCallout(calloutType: FullScreenCalloutType) -> Bool {
    guard Preferences.General.isNewRetentionUser.value == true,
      let appRetentionLaunchDate = Preferences.DAU.appRetentionLaunchDate.value,
      !calloutType.preferenceValue.value
    else {
      return false
    }

    let rightNow = Date()

    let nextShowDate = appRetentionLaunchDate.addingTimeInterval(AppConstants.buildChannel.isPublic ? calloutType.period.days : calloutType.period.minutes)

    if rightNow > nextShowDate {
      calloutType.preferenceValue.value = true
      return true
    }

    return false
  }
}
