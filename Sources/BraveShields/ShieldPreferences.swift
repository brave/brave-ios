// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Preferences

public class ShieldPreferences {
  private static let defaultBlockAdsAndTrackingLevel: ShieldLevel = .standard
  
  /// Get the level of the adblock and tracking protection as a stored preference
  /// - Warning: You should not access this directly but  through ``blockAdsAndTrackingLevel``
  public static var blockAdsAndTrackingLevelRaw = Preferences.Option<String>(
    key: "shields.block-ads-and-tracking-level",
    default: defaultBlockAdsAndTrackingLevel.rawValue
  )
  
  /// Get the level of the adblock and tracking protection
  public static var blockAdsAndTrackingLevel: ShieldLevel {
    get { ShieldLevel(rawValue: blockAdsAndTrackingLevelRaw.value) ?? defaultBlockAdsAndTrackingLevel }
    set { blockAdsAndTrackingLevelRaw.value = newValue.rawValue }
  }
}

// MARK: - Youtube warning

extension ShieldPreferences {
  /// The bool detemining if adblock warning was shown
  public static let hasSeenAntiAdBlockWarning = Preferences.Option<Bool>(
    key: "shields.has-seen-anti-ad-block-warning",
    default: false
  )
}

// MARK: - BravePlayer

extension ShieldPreferences {
  /// The bool detemining if we should use the brave player
  public static let useBravePlayer = Preferences.Option<Bool>(
    key: "shields.use-brave-player",
    default: false
  )
}
