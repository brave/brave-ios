// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data

struct PrivacyReportsItem: Identifiable {
  var id: String {
    domainOrTracker
  }
  
  let domainOrTracker: String
  let faviconUrl: String?
  let count: Int
  let source: BlockedResource.Source?
  
  init(domainOrTracker: String, faviconUrl: String? = nil, count: Int, source: BlockedResource.Source? = nil) {
    self.domainOrTracker = domainOrTracker
    self.faviconUrl = faviconUrl
    self.count = count
    self.source = source
  }
  
  static func merge(shieldItems: Set<CountableEntity>,
                    vpnItems: Set<CountableEntity>) -> [PrivacyReportsItem] {
    
    let shieldsAndVPNBlockedItems = shieldItems.intersection(vpnItems).compactMap { item -> PrivacyReportsItem? in
      guard let secondValue = vpnItems.first(where: { item.name == $0.name })?.count else { return nil }
      
      return .init(domainOrTracker: item.name, count: item.count + secondValue, source: .both)
    }
    
    let shieldsOnlyBlockedItems = shieldItems.subtracting(vpnItems)
      .map { PrivacyReportsItem(domainOrTracker: $0.name, count: $0.count, source: .shields) }
    let vpnOnlyBlockedItems = vpnItems.subtracting(shieldItems)
      .map { PrivacyReportsItem(domainOrTracker: $0.name, count: $0.count, source: .vpn) }
    
    let allBlockedItems = shieldsAndVPNBlockedItems + shieldsOnlyBlockedItems + vpnOnlyBlockedItems
    
    return allBlockedItems.sorted(by: { $0.count > $1.count })
    
  }
}
