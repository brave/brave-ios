// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import StoreKit
import os.log
import SwiftUI
import Preferences

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
  
  private init() {
    SKPaymentQueue.default().add(purchaseObserver)
  }
  
  let purchaseObserver = LeoInAppPurchaseObserver()

  var isSandbox: Bool {
    Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
  }
  
  var expirationDateFormatted: String? {
    let dateFormatter = DateFormatter().then {
      $0.locale = Locale.current
      $0.dateFormat = "MM/dd/yy"
    }

    if let date = expirationDate {
      return dateFormatter.string(from: date)
    }
    
    return nil
  }
      
  // Not used right now since the only available option is monthly
  // But when yearly is activated it will dynmically effect paywall
  @Published var activeType: SubscriptionType = .monthly
  
  // Subscription State is updated together with model premiumStatus
  @Published var subscriptionState: SubscriptionState = .notPurchased
  
  @Published var expirationDate: Date? = Preferences.AIChat.subscriptionExpirationDate.value
}

// MARK: Subscription Methods

extension LeoSubscriptionManager {
  
  @MainActor
  func updateSkusPurchaseState() async throws {
    var skuSDKActive: LeoSkusSDK
    
    switch activeType {
    case .monthly:
      skuSDKActive = LeoSkusSDK(product: .leoMonthly, isPrivateMode: false)
    case .yearly:
      skuSDKActive = LeoSkusSDK(product: .leoYearly, isPrivateMode: false)
    }
    
    do {
      let purchaseOrder = try await skuSDKActive.fetchAndRefreshOrderDetails()
      Preferences.AIChat.subscriptionExpirationDate.value = purchaseOrder.orderDetails.expiresAt
      Preferences.AIChat.subscriptionOrderId.value = purchaseOrder.orderId
    } catch {
      throw error
    }
  }
  
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

class PaymentObserverDelegate: ObservableObject, LeoInAppPurchaseObserverDelegate {
  
  enum PaymentStatus {
    case ongoing, success, failure
  }
  
  @Published
  var purchasedStatus: (status: PaymentStatus, error: LeoInAppPurchaseObserver.PurchaseError?) = (.success, nil)
    
  @Published
  var isShowingPurchaseAlert = false
  
  @Published
  var shouldDismiss: Bool = false

  func purchasedOrRestoredProduct(validateReceipt: Bool) {
    if validateReceipt {
      Task { @MainActor in
        do {
          try await LeoSubscriptionManager.shared.updateSkusPurchaseState()
          purchasedStatus = (.success, nil)
          shouldDismiss.toggle()
        } catch {
          purchasedStatus = (.failure, .receiptError)
          isShowingPurchaseAlert.toggle()
        }
      }
    } else {
      purchasedStatus = (.success, nil)
      shouldDismiss.toggle()
    }
  }
  
  func purchaseFailed(error: LeoInAppPurchaseObserver.PurchaseError) {
    purchasedStatus = (.failure, error)
    
    // User intentionally tapped to cancel purchase, no need to show any alert on our side
    if case .transactionError(let err) = error, err?.code == SKError.paymentCancelled {
      return
    }
    
    isShowingPurchaseAlert.toggle()
  }
}
