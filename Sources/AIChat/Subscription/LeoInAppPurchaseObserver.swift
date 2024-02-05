// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import StoreKit
import Shared
import os.log
import Preferences

protocol LeoInAppPurchaseObserverDelegate: AnyObject {
  func purchasedOrRestoredProduct(validateReceipt: Bool)
  func purchaseFailed(error: LeoInAppPurchaseObserver.PurchaseError)
}

class LeoInAppPurchaseObserver: NSObject, SKPaymentTransactionObserver {

  enum PurchaseError {
    case transactionError(error: SKError?)
    case receiptError
  }

  weak var delegate: LeoInAppPurchaseObserverDelegate?
  
  // MARK: - Handling transactions
  
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    var observer = delegate
    
    transactions
      .sorted(using: KeyPathComparator(\.transactionDate, order: .reverse))
      .forEach { transaction in
        switch transaction.transactionState {
        case .purchased:
          Logger.module.debug("Received transaction state: purchased")
          SKPaymentQueue.default().finishTransaction(transaction)
          
          observer?.purchasedOrRestoredProduct(validateReceipt: true)
          observer = nil
          
        case .restored:
          Logger.module.debug("Received transaction state: restored")
          SKPaymentQueue.default().finishTransaction(transaction)
          
          // TODO: Receipt Validation Logic
          // Check the result of receipt validation and use
          // purchasedOrRestoredProduct(validateReceipt: false) or
          // purchaseFailed(error:) accordingly
          
          if let purchaseObserver = observer {
            observer = nil
            Task { @MainActor in
              do {
                try await LeoSubscriptionManager.shared.updateSkusPurchaseState()
                purchaseObserver.purchasedOrRestoredProduct(validateReceipt: false)
              } catch {
                purchaseObserver.purchaseFailed(error: .receiptError)
              }
            }
          }
          
        case .purchasing, .deferred:
          Logger.module.debug("Received transaction state: purchasing")
          
        case .failed:
          Logger.module.debug("Received transaction state: failed")
          SKPaymentQueue.default().finishTransaction(transaction)
          
          observer?.purchaseFailed(error: .transactionError(error: transaction.error as? SKError))
          observer = nil
          
        @unknown default:
          observer = nil
          assertionFailure("Unknown transactionState")
        }
      }
  }

  // MARK: - Transaction Restore
  
  // Used to handle restoring transaction error and return error
  func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
    Logger.module.debug("Restoring transaction failed")
    self.delegate?.purchaseFailed(error: .transactionError(error: error as? SKError))
  }
  
  // Used to handle restoring transaction error for users never purchased but trying to restore
  func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
    if queue.transactions.isEmpty {
      Logger.module.debug("Restoring transaction failed - Nothing to restore - Account never bought this product")

      let errorRestore = SKError(SKError.unknown, userInfo: ["detail": "not-purchased"])
      delegate?.purchaseFailed(error: .transactionError(error: errorRestore))
    }
  }
  
  // Sent when a user initiates an IAP buy from the App Store
  // Only used for VPN right now and this might change when Leo Ads start
  func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
    return false
  }
}
