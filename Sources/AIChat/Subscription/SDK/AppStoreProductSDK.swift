// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import StoreKit

public protocol AppStoreProduct: RawRepresentable<String>, CaseIterable {
  var subscriptionGroup: String { get }
  var webSessionStorageKey: String { get }
  var skusDomain: String { get }
}

public class AppStoreProductSDK: ObservableObject {
  
  public var allAppStoreProducts: [any AppStoreProduct] {
    fatalError("Not Implemented - Implement via Inheritance")
  }
  
  @Published
  private(set) var consumableProducts = [Product]()
  
  @Published
  private(set) var nonConsumableProducts = [Product]()
  
  @Published
  private(set) var nonRenewableProducts = [Product]()
  
  @Published
  private(set) var autoRenewableProducts = [Product]()

  // MARK: - Private
  
  private var updateTask: Task<Void, Error>?
  
  public init() {
    // Start updater immediately
    updateTask = Task.detached {
      for await result in Transaction.updates {
        do {
          let transaction = try self.verify(result)
          await self.updateProducts()
          await transaction.finish()
        } catch {
          print("Transaction failed verification")
        }
      }
    }
    
    // Fetch initial products immediately
    Task {
      await fetchProducts()
      await updateProducts()
    }
  }
  
  deinit {
    updateTask?.cancel()
  }
  
  @MainActor
  func subscription(for product: any AppStoreProduct) async -> Product? {
    autoRenewableProducts.first(where: { $0.id == product.rawValue })
  }
  
  @MainActor
  func status(for product: any AppStoreProduct) async -> [Product.SubscriptionInfo.Status] {
    (try? await subscription(for: product)?.subscription?.status) ?? []
  }
  
  @MainActor
  func renewalState(for product: any AppStoreProduct) async -> Product.SubscriptionInfo.RenewalState? {
    await status(for: product).first?.state
  }
  
  /// Transaction History for a product
  @MainActor
  func latestTransaction(for product: any AppStoreProduct) async -> Transaction? {
    if let transaction = await Transaction.latest(for: product.rawValue) {
      do {
        return try verify(transaction)
      } catch {
        // TODO: Log Error - Unverified Transaction \(error)
      }
    }
    
    return nil
  }
  
  /// Transaction the user is entitled to, that unlocks the product
  @MainActor
  func currentTransaction(for product: any AppStoreProduct) async -> Transaction? {
    if let transaction = await Transaction.currentEntitlement(for: product.rawValue) {
      do {
        return try verify(transaction)
      } catch {
        // TODO: Log Error - Unverified Transaction \(error)
      }
    }
    
    return nil
  }
  
  func purchase(_ product: Product) async throws -> Transaction? {
    let result = try await product.purchase(options: [.simulatesAskToBuyInSandbox(true)])
    switch result {
    case .success(let result):
      let transaction = try verify(result)
      await updateProducts()
      await transaction.finish()
      return transaction
      
    case .userCancelled, .pending:
      return nil
      
    default:
      return nil
    }
  }
  
  func isPurchased(_ product: Product) async throws -> Bool {
    switch product.type {
    case .consumable:
      return consumableProducts.contains(product)
      
    case .nonConsumable:
      return nonConsumableProducts.contains(product)
      
    case .nonRenewable:
      return nonRenewableProducts.contains(product)
      
    case .autoRenewable:
      return autoRenewableProducts.contains(product)
      
    default:
      // TODO: Log Error - Unknown Product
      return false
    }
  }
  
  private func verify<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified(_, let error):
      throw error
      
    case .verified(let signedType):
      return signedType
    }
  }
  
  @MainActor
  private func fetchProducts() async {
    do {
      let products = try await Product.products(for: allAppStoreProducts.map({ $0.rawValue }))
      for product in products {
        switch product.type {
        case .consumable:
          consumableProducts.append(product)
          
        case .nonConsumable:
          nonConsumableProducts.append(product)
          
        case .nonRenewable:
          nonRenewableProducts.append(product)
          
        case .autoRenewable:
          autoRenewableProducts.append(product)
          
        default:
          // TODO: Log Error - Unknown Product
          break
        }
      }
    } catch {
      // TODO: Log Error - Unable to fetch Products: \(error)
    }
  }
  
  @MainActor
  private func updateProducts() async {
    var consumable = [Product]()
    var nonConsumable = [Product]()
    var nonRenewable = [Product]()
    var autoRenewable = [Product]()
    
    for await result in Transaction.currentEntitlements {
      do {
        let transaction = try verify(result)
        
        switch transaction.productType {
        case .consumable:
          if let product = consumableProducts.first(where: { $0.id == transaction.productID }) {
            consumable.append(product)
          }
          break
          
        case .nonConsumable:
          if let product = nonConsumableProducts.first(where: { $0.id == transaction.productID }) {
            nonConsumable.append(product)
          }
          
        case .nonRenewable:
          if let product = nonRenewableProducts.first(where: { $0.id == transaction.productID }) {
            // We can also filter non-renewable subscriptions by transaction.purchaseDate
            nonRenewable.append(product)
          }
          
        case .autoRenewable:
          if let product = autoRenewableProducts.first(where: { $0.id == transaction.productID }) {
            autoRenewable.append(product)
          }
          
        default:
          // TODO: Log Unknown Product Type
          break
        }
      } catch {
        // TODO: Log Error - Transaction Not Verified: \(error)
      }
    }
    
    consumableProducts = consumable
    nonConsumableProducts = nonConsumable
    nonRenewableProducts = nonRenewable
    autoRenewableProducts = autoRenewable
    
    
  }
}
