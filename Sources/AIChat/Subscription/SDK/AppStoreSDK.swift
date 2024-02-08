// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import StoreKit

public protocol AppStoreProduct: RawRepresentable<String>, CaseIterable {
  var subscriptionGroup: String { get }
}

@MainActor
public class AppStoreReceipt {
  private init() {}
  
  @MainActor
  static func sync() async throws {
    let fetcher = AppStoreReceiptRestorer()
    return try await withCheckedThrowingContinuation { @MainActor continuation in
      fetcher.restoreTransactions { error in
        DispatchQueue.main.async {
          if let error = error {
            continuation.resume(throwing: error)
            return
          }
          
          continuation.resume()
        }
      }
    }
  }
  
  private class AppStoreReceiptRestorer: NSObject, SKPaymentTransactionObserver {
    private let queue = SKPaymentQueue()
    private var onRefreshComplete: ((Error?) -> Void)?
    
    override init() {
      super.init()
      self.queue.add(self)
    }
    
    func restoreTransactions(with listener: @escaping (Error?) -> Void) {
      if onRefreshComplete == nil {
        self.onRefreshComplete = listener
        self.queue.restoreCompletedTransactions()
      }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
      if transactions.isEmpty {
        onRefreshComplete?(SKError(.storeProductNotAvailable))
        onRefreshComplete = nil
        return
      }
      
      var completion: (() -> Void)?
      
      transactions
        .sorted(using: KeyPathComparator(\.transactionDate, order: .reverse))
        .forEach { transaction in
          switch transaction.transactionState {
          case .purchased:
            if completion == nil {
              completion = { [weak self] in
                guard let self = self else { return }
                self.onRefreshComplete?(nil)
                self.onRefreshComplete = nil
              }
            }
            self.queue.finishTransaction(transaction)
            
          case .restored:
            if completion == nil {
              completion = { [weak self] in
                guard let self = self else { return }
                self.onRefreshComplete?(nil)
                self.onRefreshComplete = nil
              }
            }
            self.queue.finishTransaction(transaction)
            
          case .purchasing, .deferred:
            break
            
          case .failed:
            if completion == nil {
              completion = { [weak self] in
                guard let self = self else { return }
                self.onRefreshComplete?(SKError(.storeProductNotAvailable))
                self.onRefreshComplete = nil
              }
            }
            self.queue.finishTransaction(transaction)
            
          @unknown default:
            break
          }
        }
      
      self.queue.remove(self)
      completion?()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
      self.onRefreshComplete?(SKError(.storeProductNotAvailable))
      self.onRefreshComplete = nil
      self.queue.remove(self)
    }
  }
}

public class AppStoreSDK: ObservableObject {
  struct Products {
    let consumable: [Product]
    let nonConsumable: [Product]
    let nonRenewable: [Product]
    let autoRenewable: [Product]
    
    var all: [Product] {
      return consumable + nonConsumable +
             nonRenewable + autoRenewable
    }
    
    init() {
      self.consumable = []
      self.nonConsumable = []
      self.nonRenewable = []
      self.autoRenewable = []
    }
    
    init(consumable: [Product], nonConsumable: [Product], nonRenewable: [Product], autoRenewable: [Product]) {
      self.consumable = consumable
      self.nonConsumable = nonConsumable
      self.nonRenewable = nonRenewable
      self.autoRenewable = autoRenewable
    }
  }
  
  public var allAppStoreProducts: [any AppStoreProduct] {
    fatalError("Not Implemented - Implement via Inheritance")
  }
  
  // Products Available on the AppStore
  @Published
  private(set) var allProducts = Products()
  
  // Products the customer has purchased
  @Published
  private(set) var purchasedProducts = Products()

  // MARK: - Private
  
  private var updateTask: Task<Void, Error>?
  
  public init() {
    // Start updater immediately
    updateTask = Task.detached {
      for await result in Transaction.updates {
        do {
          // Verify the transaction
          let transaction = try self.verify(result)
          
          // Retrieve all products the user purchased
          let purchasedProducts = await self.fetchPurchasedProducts()
          
          // Transactions must be marked as completed once processed
          await transaction.finish()
          
          // Request the AppStore sync the receipt to our Main Bundle
          try? await AppStoreReceipt.sync()
          
          // Distribute the purchased products to the customer
          await MainActor.run {
            self.purchasedProducts = purchasedProducts
          }
        } catch {
          print("Transaction failed verification")
        }
      }
    }
    
    // Fetch initial products immediately
    Task.detached {
      // Retrieve all products the user purchased
      await self.fetchProducts()
      
      // Retrieve all products the user purchased
      let purchasedProducts = await self.fetchPurchasedProducts()
      
      // Request the AppStore sync the receipt to our Main Bundle
      try? await AppStoreReceipt.sync()
      
      // Distribute the purchased products to the customer
      await MainActor.run {
        self.purchasedProducts = purchasedProducts
      }
    }
  }
  
  deinit {
    updateTask?.cancel()
  }
  
  // MARK: - Public
  
  @MainActor
  func subscription(for product: any AppStoreProduct) async -> Product? {
    allProducts.autoRenewable.first(where: { $0.id == product.rawValue })
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
    let result = try await product.purchase(options: [.simulatesAskToBuyInSandbox(false)])
    switch result {
    case .success(let result):
      // Verify the transaction
      let transaction = try self.verify(result)
      
      // Retrieve all products the user purchased
      let purchasedProducts = await self.fetchPurchasedProducts()
      
      // Transactions must be marked as completed once processed
      await transaction.finish()
      
      // Request the AppStore sync the receipt to our Main Bundle
      try? await AppStoreReceipt.sync()
      
      // Distribute the purchased products to the customer
      self.purchasedProducts = purchasedProducts
      
      // Return the processed transaction
      return transaction
      
    case .userCancelled, .pending:
      // The transaction is pending
      // Do nothing with the transaction
      return nil
      
    @unknown default:
      // Some future states for transactions have been added
      // Do nothing with the transaction
      return nil
    }
  }
  
  func isPurchased(_ product: Product) async throws -> Bool {
    switch product.type {
    case .consumable:
      return allProducts.consumable.contains(product)
      
    case .nonConsumable:
      return allProducts.nonConsumable.contains(product)
      
    case .nonRenewable:
      return allProducts.nonRenewable.contains(product)
      
    case .autoRenewable:
      return allProducts.autoRenewable.contains(product)
      
    default:
      // TODO: Log Error - Unknown Product
      return false
    }
  }
  
  // MARK: - Private
  
  private func verify<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified(_, let error):
      throw error
      
    case .verified(let signedType):
      return signedType
    }
  }

  private func fetchProducts() async {
    do {
      var consumable = [Product]()
      var nonConsumable = [Product]()
      var nonRenewable = [Product]()
      var autoRenewable = [Product]()
      
      let products = try await Product.products(for: allAppStoreProducts.map({ $0.rawValue }))
      for product in products {
        switch product.type {
        case .consumable:
          consumable.append(product)
          
        case .nonConsumable:
          nonConsumable.append(product)
          
        case .nonRenewable:
          nonRenewable.append(product)
          
        case .autoRenewable:
          autoRenewable.append(product)
          
        default:
          // TODO: Log Error - Unknown Product
          break
        }
      }
      
      let availableProducts = Products(consumable: consumable,
                                       nonConsumable: nonConsumable,
                                       nonRenewable: nonRenewable,
                                       autoRenewable: autoRenewable)
      await MainActor.run {
        self.allProducts = availableProducts
      }
    } catch {
      // TODO: Log Error - Unable to fetch Products: \(error)
    }
  }

  private func fetchPurchasedProducts() async -> Products {
    var consumable = [Product]()
    var nonConsumable = [Product]()
    var nonRenewable = [Product]()
    var autoRenewable = [Product]()
    
    for await result in Transaction.currentEntitlements {
      do {
        let transaction = try verify(result)
        
        switch transaction.productType {
        case .consumable:
          if let product = allProducts.consumable.first(where: { $0.id == transaction.productID }) {
            consumable.append(product)
          }
          break
          
        case .nonConsumable:
          if let product = allProducts.nonConsumable.first(where: { $0.id == transaction.productID }) {
            nonConsumable.append(product)
          }
          
        case .nonRenewable:
          if let product = allProducts.nonRenewable.first(where: { $0.id == transaction.productID }) {
            // We can also filter non-renewable subscriptions by transaction.purchaseDate
            nonRenewable.append(product)
          }
          
        case .autoRenewable:
          if let product = allProducts.autoRenewable.first(where: { $0.id == transaction.productID }) {
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
    
    return Products(consumable: consumable,
                    nonConsumable: nonConsumable,
                    nonRenewable: nonRenewable,
                    autoRenewable: autoRenewable)
  }
}
