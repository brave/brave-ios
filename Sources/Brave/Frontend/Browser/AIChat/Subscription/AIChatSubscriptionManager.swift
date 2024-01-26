// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// Singleton Manager handles subscriptions for AI Leo
class AIChatSubscriptionManager: ObservableObject {
  
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
  
  static var shared = AIChatSubscriptionManager()
  
  
  var isSandbox: Bool {
    Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
  }
  
  // TODO: Static Type and expiration for test development
  
  @Published var state: SubscriptionState = .purchased
  
  @Published var activeType: SubscriptionType = .monthly
  
  @Published var expirationDate: Date = Date() + 5.minutes
}
