// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

struct FilterList: Identifiable {
  /// The component ID of the "Fanboy's Mobile Notifications List"
  /// This is a special filter list that is enabled by default
  public static let mobileAnnoyancesComponentID = "bfpgedeaaibpoidldhjcknekahbikncb"
  /// The component id of the cookie consent notices filter list.
  /// This is a special filter list that has more accessible UI to control it
  public static let cookieConsentNoticesComponentID = "cdbbhgbmjhfnhnmgeddbliobbofkgdhe"
  /// A list of safe filter lists that can be automatically enabled if the user has the matching localization.
  /// - Note: These are regional fiter lists that are well maintained. For now we hardcode these values
  /// but it would be better if our component updater told us which ones are safe in the future.
  public static let maintainedRegionalComponentIDs = [
    "llgjaaddopeckcifdceaaadmemagkepi" // Japanese filter lists
  ]
  
  var id: String { return entry.uuid }
  var isEnabled: Bool = false
  let entry: AdblockFilterListCatalogEntry
  
  init(from entry: AdblockFilterListCatalogEntry, isEnabled: Bool) {
    self.entry = entry
    self.isEnabled = isEnabled
  }
}
