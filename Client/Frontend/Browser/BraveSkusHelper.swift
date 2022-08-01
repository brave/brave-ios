// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared

private let log = Logger.browserLogger

class BraveSkusHelper {
  private let allowedHosts = ["account.brave.com", "account.bravesoftware.com", "account.brave.software"]
  private let requiredQueryItems: [URLQueryItem] =
  [.init(name: "intent", value: "connect-receipt"), .init(name: "product", value: "vpn")]
  
  private let url: URL
  
  /// Optional constructor. Returns nil if nothing should be injected to the page.
  /// Checks for few conditions like proper host and query parameters.
  init?(for url: URL) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let host = components.host,
            let scheme = components.scheme,
            let queryItems = components.queryItems else {
      return nil
    }

    if !allowedHosts.contains(host) || scheme != "https" { return nil }

    if requiredQueryItems.allSatisfy(queryItems.contains) {
      self.url = url
    } else {
      return nil
    }
  }
  
  fileprivate var receipt: String? {
    guard let receiptUrl = Bundle.main.appStoreReceiptURL else { return nil }
    
    do {
      return try Data(contentsOf: receiptUrl).base64EncodedString
    } catch {
      log.error("Failed to encode or get receipt data: \(error)")
      return nil
    }
  }
  
  /// Returns app's receipt and few other properties as a base64 encoded JSON.
  var receiptData: String? {
    guard let receipt = receipt else { return nil }
    
    struct ReceiptDataJson: Codable {
      let type: String
      let rawReceipt: String
      let package: String
      let subscriptionId: String
      
      enum CodingKeys: String, CodingKey {
        case type, package
        case rawReceipt = "raw_receipt"
        case subscriptionId = "subscription_id"
      }
    }
    
    let json = ReceiptDataJson(type: "ios",
                               rawReceipt: receipt,
                               package: "com.brave.browser",
                               subscriptionId: "brave-firewall-vpn-premium")
    
    do {
        return try JSONEncoder().encode(json).base64EncodedString
    } catch {
      assertionFailure("serialization error: \(error)")
      return nil
    }
  }
}

// MARK: - Test Files
class BraveSkusHelperMock: BraveSkusHelper {
  static let mockReceiptValue = "test-receipt"
  
  override var receipt: String? {
    Self.mockReceiptValue
  }
}
