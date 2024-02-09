// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import StoreKit
import Combine
import Preferences

public enum BraveStoreEnvironment: String {
  case production
  case sandbox
  case xcode
}

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
  
  public var skusWebSessionStorageKey: String {
    switch self {
    case .vpnMonthly, .vpnYearly: return "braveVpn.receipt"
    case .leoMonthly, .leoYearly: return "braveLeo.receipt"
    }
  }
  
  public var skusDomain: String {
    #if DEBUG
    switch self {
    case .vpnMonthly, .vpnYearly: return "vpn.bravesoftware.com"
    case .leoMonthly, .leoYearly: return "leo.bravesoftware.com"
    }
    #else
    switch self {
    case .vpnMonthly, .vpnYearly: return "vpn.brave.com"
    case .leoMonthly, .leoYearly: return "leo.brave.com"
    }
    #endif
  }
}

public class BraveStoreSDK: AppStoreSDK {
  
  public static let shared = BraveStoreSDK()
  
  // MARK: - VPN
  
  @Published
  private(set) var vpnMonthlyProduct: Product?
  
  @Published
  private(set) var vpnYearlyProduct: Product?
  
  @Published
  private(set) var vpnSubscriptionStatus: Product.SubscriptionInfo.Status?
  
  // MARK: - LEO
  
  @Published
  private(set) var leoMonthlyProduct: Product?
  
  @Published
  private(set) var leoYearlyProduct: Product?
  
  @Published
  private(set) var leoSubscriptionStatus: Product.SubscriptionInfo.Status?
  
  // MARK: - Private
  
  private var observers = [AnyCancellable]()
  
  private override init() {
    super.init()
    
    // Fetch the AppStore receipt
    Task.detached {
      try await AppStoreReceipt.sync()
    }
    
    observers.append($allProducts.sink(receiveValue: onProductsUpdated(_:)))
    observers.append($purchasedProducts.sink(receiveValue: onPurchasesUpdated(_:)))
  }
  
  // MARK: - Public
  
  public override var allAppStoreProducts: [any AppStoreProduct] {
    return BraveStoreProduct.allCases
  }
  
  public var enviroment: BraveStoreEnvironment {
    guard let renewalInfo = [vpnSubscriptionStatus, leoSubscriptionStatus].compactMap({ $0 }).first?.renewalInfo else {
      if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
        return .sandbox
      }
      
      if getppid() != 1 {
        return .xcode
      }
      
      return .production
    }
    
    switch renewalInfo {
    case .verified(let renewalInfo), .unverified(let renewalInfo, _):
      if #available(iOS 16.0, *) {
        return .init(rawValue: renewalInfo.environment.rawValue) ?? .production
      }
      
      return .init(rawValue: renewalInfo.environmentStringRepresentation) ?? .production
    }
  }
  
  public var isVpnProductsLoaded: Bool {
    if vpnMonthlyProduct != nil || vpnYearlyProduct != nil {
      return true
    }
    
    return false
  }
  
  public var isLeoProductsLoaded: Bool {
    if leoMonthlyProduct != nil || leoYearlyProduct != nil {
      return true
    }
    
    return false
  }
  
  public func refreshAllSkusOrders() {
//    Task { @MainActor in
//      if let orderId = Preferences.AIChat.subscriptionOrderId.value {
//        try await SkusSDK(product: .leoMonthly).refreshOrder(orderId: orderId)
//      }
//    }
  }
  
  public func restorePurchase(_ product: BraveStoreProduct) async -> Bool {
    // SKPaymentQueue.default().restoreCompletedTransactions()
    if await currentTransaction(for: product) != nil {
      try? await AppStoreReceipt.sync()
      return true
    }
    
    return false
  }
  
  @MainActor
  public func restorePurchases() async -> Bool {
    #if STOREKIT2
    var didRestore = false
    for await result in Transaction.currentEntitlements {
      if case .verified(let transaction) = result {
        if let product = BraveStoreProduct(rawValue: transaction.productID) {
          switch product {
          case .vpnMonthly, .vpnYearly:
            vpnSubscriptionStatus = await transaction.subscriptionStatus
          case .leoMonthly, .leoYearly:
            leoSubscriptionStatus = await transaction.subscriptionStatus
          }
          
          // Update SkusSDK
          do {
            try await self.updateSkusPurchaseState(for: product)
            didRestore = true
          } catch {
            // TODO: Log Error
          }
        }
      }
    }
    return didRestore
    #else
    do {
      for product in BraveStoreProduct.allCases {
        try await self.updateSkusPurchaseState(for: product)
      }
      return true
    } catch {
      return false
    }
    #endif
  }
  
  @MainActor
  public func purchase(product: BraveStoreProduct) async throws {
    if let subscription = await subscription(for: product) {
      if let transaction = try await super.purchase(subscription) {
        if transaction.productID == BraveStoreProduct.leoMonthly.rawValue ||
            transaction.productID == BraveStoreProduct.leoYearly.rawValue {
          // Preferences.AIChat.subscriptionExpirationDate.value = transaction.expirationDate

          try await self.updateSkusPurchaseState(for: product)
        }
      }
    }
  }
  
  // MARK: - Internal
  
  private func onProductsUpdated(_ products: Products) {
    // Process only subscriptions at this time as Brave has no other products
    let products = products.all.filter({ $0.type == .autoRenewable })
    
    if products.isEmpty {
      return
    }

    // Update vpn products
    vpnMonthlyProduct = products.first(where: { $0.id == BraveStoreProduct.vpnMonthly.rawValue })
    vpnYearlyProduct = products.first(where: { $0.id == BraveStoreProduct.vpnYearly.rawValue })
    
    // Update leo products
    leoMonthlyProduct = products.first(where: { $0.id == BraveStoreProduct.leoMonthly.rawValue })
    leoYearlyProduct = products.first(where: { $0.id == BraveStoreProduct.leoYearly.rawValue })
  }
  
  private func onPurchasesUpdated(_ products: Products) {
    // Process only subscriptions at this time as Brave has no other products
    let products = products.all.filter({ $0.type == .autoRenewable }).filter({ $0.subscription != nil })
    
    if products.isEmpty {
      return
    }
    
    Task { @MainActor [weak self] in
      guard let self = self else { return }
      
      let vpnSubscriptions = products.filter({ $0.id == BraveStoreProduct.vpnMonthly.rawValue || $0.id == BraveStoreProduct.vpnYearly.rawValue }).compactMap({ $0.subscription })
      let leoSubscriptions = products.filter({ $0.id == BraveStoreProduct.leoMonthly.rawValue || $0.id == BraveStoreProduct.leoYearly.rawValue }).compactMap({ $0.subscription })
      
      // Statuses apply the entire group
      vpnSubscriptionStatus = try? await vpnSubscriptions.first?.status.first
      leoSubscriptionStatus = try? await leoSubscriptions.first?.status.first
      
      // Update SkusSDK
      /*let storeProducts = products.compactMap({ BraveStoreProduct(rawValue: $0.id) })
      for product in storeProducts {
        try? await self.refreshOrder(for: product)
      }*/
    }
  }
  
  @MainActor
  private func refreshOrder(for product: BraveStoreProduct) async throws {
    // This SDK currently only supports Leo
    // until we update the VPN code to use it
    switch product {
    case .vpnMonthly, .vpnYearly: return
    case .leoMonthly, .leoYearly: break
    }
    
    if AppStoreReceipt.receipt == nil {
      try await AppStoreReceipt.sync()
    }
    
    let skusSDK = SkusSDK(product: product)
    
    // Retrieve the cached Order-ID or create a new order
    if let orderId = Preferences.AIChat.subscriptionOrderId.value {
      try await skusSDK.refreshOrder(orderId: orderId)
      return
    }
    
    throw SkusSDK.SkusError.cannotCreateOrder
  }
  
  @MainActor
  private func updateSkusPurchaseState(for product: BraveStoreProduct) async throws {
    // This SDK currently only supports Leo
    // until we update the VPN code to use it
    switch product {
    case .vpnMonthly, .vpnYearly: return
    case .leoMonthly, .leoYearly: break
    }
    
    if AppStoreReceipt.receipt == nil {
      try await AppStoreReceipt.sync()
    }
    
    let skusSDK = SkusSDK(product: product)
    
    // Retrieve the cached Order-ID or create a new order
    var orderId = Preferences.AIChat.subscriptionOrderId.value
    if orderId == nil {
      orderId = try await skusSDK.createOrder()
      Preferences.AIChat.subscriptionOrderId.value = orderId
    }
    
    guard let orderId = orderId else {
      throw SkusSDK.SkusError.cannotCreateOrder
    }

    // There's an existing order refresh it if it's expired
    var expiryDate = Preferences.AIChat.subscriptionExpirationDate.value
    if expiryDate == nil {
      let order = try await skusSDK.refreshOrder(orderId: orderId)
      expiryDate = order.expiresAt
      Preferences.AIChat.subscriptionExpirationDate.value = expiryDate
    }
    
    guard let expiryDate = expiryDate else {
      throw SkusSDK.SkusError.cannotCreateOrder
    }
    
    // If the order is expired, refresh it
    if Date() > expiryDate {
      let order = try await skusSDK.refreshOrder(orderId: orderId)
      Preferences.AIChat.subscriptionExpirationDate.value = order.expiresAt
      return
    }
    
    // There is an order, and an expiry date, but no credentials
    // Fetch the credentials
    if !Preferences.AIChat.subscriptionHasCredentials.value {
      let errorCode = try await skusSDK.fetchCredentials(orderId: orderId)
      Preferences.AIChat.subscriptionHasCredentials.value = errorCode.isEmpty
      
      if !errorCode.isEmpty {
        throw SkusSDK.SkusError.invalidReceiptData
      }
    }
  }
}
