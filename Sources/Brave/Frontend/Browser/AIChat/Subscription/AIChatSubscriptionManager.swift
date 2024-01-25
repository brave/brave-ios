// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// Singleton Manager handles subscriptions for AI Leo
public class AIChatSubscriptionManager: NSObject {
  
  /// In-app purchase subscription types
  public enum SubscriptionType {
    case monthly
    case yearly
    
    var title: String {
      switch self {
      case .monthly:
        return "Monthly"
      case .yearly:
        return "Yearly"
      }
    }
  }
  
  // MARK: Lifecycle
  
  public static var shared = AIChatSubscriptionManager()
  
  // TODO: Static Type and expiration for test development
  
  public var activesubscriptionType: SubscriptionType = .monthly
  
  public var subscriptionExpirationDate: Date = Date() + 5.minutes
}
