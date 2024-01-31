// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import StoreKit

/// Singleton Manager handles subscriptions for AI Leo
class LeoSubscriptionManager: NSObject, ObservableObject {
  
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
  
  // MARK: Lifecycle
  
  static var shared = LeoSubscriptionManager()
  
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
  
  // TODO: Static Type and expiration for test development
  
  @Published var state: SubscriptionState = .purchased
  
  @Published var activeType: SubscriptionType = .monthly
  
  @Published var expirationDate: Date = Date() + 5.minutes
}

extension LeoSubscriptionManager: SKPaymentTransactionObserver {
  func restorePayments() {
    SKPaymentQueue.default().add(self)
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
  
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    let paymentQueue = SKPaymentQueue.default()
    
    // TODO: Finish Delegate stuff
    transactions.sorted(using: KeyPathComparator(\.transactionDate, order: .reverse)).forEach { transaction in
      switch transaction.transactionState {
      case .purchased:
        paymentQueue.finishTransaction(transaction)
      case .failed:
        paymentQueue.finishTransaction(transaction)
      case .restored:
        paymentQueue.finishTransaction(transaction)
      case .purchasing, .deferred:
        paymentQueue.finishTransaction(transaction)
      @unknown default:
        assertionFailure("Unknown Transaction State: \(transaction.transactionState)")
      }
    }
  }
}
