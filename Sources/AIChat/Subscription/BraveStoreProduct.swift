// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public enum BraveStoreProduct: String, AppStoreProduct, CaseIterable {
  case vpnMonthly = "bravevpn.monthly"
  case vpnYearly = "bravevpn.yearly"
  
  case leoMonthly = "braveleo.monthly"
  case leoYearly = "braveleo.yearly"
  
  public var subscriptionGroup: String {
    switch self {
    case .vpnMonthly, .vpnYearly: return "Brave VPN"
    case .leoMonthly, .leoYearly: return "Brave Leo"
    }
  }
  
  public var webSessionStorageKey: String {
    switch self {
    case .vpnMonthly, .vpnYearly: return "braveVpn.receipt"
    case .leoMonthly, .leoYearly: return "braveLeo.receipt"
    }
  }
  
  public var skusDomain: String {
    #if DEBUG
    return "vpn.bravesoftware.com"
    #else
    return "vpn.brave.com"
    #endif
  }
}

public class BraveStoreSDK: AppStoreProductSDK {
  
  public static let shared = BraveStoreSDK()
  
  private override init() {
    super.init()
  }
  
  public override var allAppStoreProducts: [any AppStoreProduct] {
    return BraveStoreProduct.allCases
  }
}
