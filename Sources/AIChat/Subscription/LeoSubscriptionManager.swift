// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import StoreKit
import os.log

/// In-app purchase subscription types
enum SubscriptionType {
  case monthly
  case yearly
  
  var title: String {
    switch self {
    case .monthly:
      return "Monthly Subscription"
    case .yearly:
      return "Yearly Subscription"
    }
  }
}

/// In-app purchase subscription states
enum SubscriptionState: Equatable {
  case notPurchased
  case purchased
  case expired
  
  var actionTitle: String {
    switch self {
    case .notPurchased, .expired:
      return "Go Premium"
    case .purchased:
      return "Manage Subscription"
    }
  }
}

/// Singleton Manager handles subscriptions for AI Leo
class LeoSubscriptionManager: ObservableObject {
  
  // MARK: Lifecycle
  
  static var shared = LeoSubscriptionManager()
  
  init() {
    inAppPurchaseObserver.delegate = self
  }
  
  let inAppPurchaseObserver = LeoInAppPurchaseObserver()

  var isSandbox: Bool {
    Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
  }
  
  var expirationDateFormatted: String {
    let dateFormatter = DateFormatter().then {
      $0.locale = Locale.current
      $0.dateFormat = "MM/dd/yy"
    }

    return dateFormatter.string(from: expirationDate)
  }
      
  @Published var activeType: SubscriptionType = .monthly
  
  @Published var subscriptionState: SubscriptionState = .notPurchased
  
  @Published var expirationDate: Date = Date()
}

// MARK: Subscription Methods

extension LeoSubscriptionManager {
  
  func startSubscriptionAction(with type: SubscriptionType) {
    addPaymentForSubcription(type: type)
  }
  
  private func addPaymentForSubcription(type: SubscriptionType) {
    var subscriptionProduct: SKProduct?
    
    switch type {
    case .yearly:
      subscriptionProduct = LeoProductInfo.shared.yearlySubProduct
    case .monthly:
      subscriptionProduct = LeoProductInfo.shared.monthlySubProduct
    }
    
    guard let subscriptionProduct = subscriptionProduct else {
      Logger.module.error("Failed to retrieve \(type.title) subcription product")
      return
    }
    
    let payment = SKPayment(product: subscriptionProduct)
    SKPaymentQueue.default().add(payment)
  }
  
  func restorePurchasesAction() {
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
}

extension LeoSubscriptionManager: LeoInAppPurchaseObserverDelegate {
  func purchasedOrRestoredProduct(validateReceipt: Bool) {
    // Not needed in the singleton instance
  }
  
  func purchaseFailed(error: LeoInAppPurchaseObserver.PurchaseError) {
    // Not needed in the singleton instance
  }
}
