// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import StoreKit
import Shared
import os.log

public class LeoProductInfo: NSObject, ObservableObject {
  @Published
  var monthlySubProduct: SKProduct?
  
  @Published
  var yearlySubProduct: SKProduct?
  
  public static let shared = LeoProductInfo()

  public var isComplete: Bool {
    switch LeoSubscriptionManager.shared.state {
    case .purchased:
      return true
    case .notPurchased, .expired:
      guard let monthlyPlan = monthlySubProduct, let yearlyPlan = yearlySubProduct else {
        return false
      }
      
      return monthlyPlan.price.frontSymbolCurrencyFormatted(with: monthlyPlan.priceLocale) != nil
        && yearlyPlan.price.frontSymbolCurrencyFormatted(with: yearlyPlan.priceLocale) != nil
    }
  }

  private let productRequest: SKProductsRequest

  /// These product ids work only on release channel.
  struct ProductIdentifiers {
    /// Apple's monthly IAP
    static let monthlySub = "braveleo.monthly"
    /// Apple's yearly IAP
    static let yearlySub = "braveleo.yearly"
    /// account.brave.com  monthly subscription product
    static let monthlySubSKU = "brave-premium"

    static let all = Set<String>(arrayLiteral: monthlySub, yearlySub)
  }

  private override init() {
    productRequest = SKProductsRequest(productIdentifiers: ProductIdentifiers.all)
    super.init()
    productRequest.delegate = self
    
    load()
  }

  public func load() {
    productRequest.start()
  }
}

extension LeoProductInfo: SKProductsRequestDelegate {
  public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    response.products.forEach {
      switch $0.productIdentifier {
      case ProductIdentifiers.monthlySub:
        monthlySubProduct = $0
      case ProductIdentifiers.yearlySub:
        yearlySubProduct = $0
      default:
        assertionFailure("Found product identifier that doesn't match")
      }
    }
  }

  public func request(_ request: SKRequest, didFailWithError error: Error) {
    Logger.module.error("SKProductsRequestDelegate error: \(error.localizedDescription)")
  }
}
