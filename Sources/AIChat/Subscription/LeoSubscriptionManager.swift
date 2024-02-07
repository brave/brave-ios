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
public enum SubscriptionType {
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
public enum SubscriptionState: Equatable {
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
public class LeoSubscriptionManager: ObservableObject {
  
  // MARK: Lifecycle
  
  public static var shared = LeoSubscriptionManager()
  
  public init() {
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
  
  var skuSDKActive: SkusSDK {
    switch activeType {
    case .monthly:
      return SkusSDK(product: BraveStoreProduct.leoMonthly)
    case .yearly:
      return SkusSDK(product: BraveStoreProduct.leoYearly)
    }
  }
}

// MARK: Subscription Methods

public extension LeoSubscriptionManager {
  
  @MainActor
  func updateSkusPurchaseState() async throws {
    var skuSDKActive: SkusSDK
    
    switch activeType {
    case .monthly:
      skuSDKActive = SkusSDK(product: BraveStoreProduct.leoMonthly)
    case .yearly:
      skuSDKActive = SkusSDK(product: BraveStoreProduct.leoYearly)
    }
    
    do {
      let purchaseOrder = try await skuSDKActive.fetchAndRefreshOrderDetails()
      Preferences.AIChat.subscriptionExpirationDate.value = purchaseOrder.orderDetails.expiresAt
      Preferences.AIChat.subscriptionOrderId.value = purchaseOrder.orderId
    } catch {
      throw error
    }
  }
  
  @MainActor
  func checkExpirationAndRefreshOrder() async {
    // Check If user subscribed to AIChat
    if let aiChatExpiryDate = Preferences.AIChat.subscriptionExpirationDate.value,
       let aiChatOrderId = Preferences.AIChat.subscriptionOrderId.value {
      // If the order is expired - refresh
      if Date() > aiChatExpiryDate {
        do {
          try await skuSDKActive.refreshOrder(orderId: aiChatOrderId)
        } catch {
          Logger.module.error("Failed while refreshing order using orderID \(aiChatOrderId) subcription product")
        }
      }
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
