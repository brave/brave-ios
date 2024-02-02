// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import StoreKit
import Shared
import os.log
import Preferences

public protocol LeoInAppPurchaseObserverDelegate: AnyObject {
  func purchasedOrRestoredProduct(validateReceipt: Bool)
  func purchaseFailed(error: LeoInAppPurchaseObserver.PurchaseError)
}

public class LeoInAppPurchaseObserver: NSObject, SKPaymentTransactionObserver {

  public enum PurchaseError {
    case transactionError(error: SKError?)
    case receiptError
  }

  public weak var delegate: LeoInAppPurchaseObserverDelegate?
  public var savedPayment: SKPayment?
  
  // MARK: - Handling transactions
  
  public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    // This helper variable helps to call the IAPObserverDelegate delegate purchased method only once
    // delegate purchased method only once similar logic with VPN in-app Purchase
    var canInvokePurchaseDelegate = true
    
    transactions
      .sorted(by: { $0.transactionDate ?? Date() > $1.transactionDate ?? Date() })
      .forEach { transaction in
      switch transaction.transactionState {
      case .purchased:
        Logger.module.debug("Received transaction state: purchased")
        
        SKPaymentQueue.default().finishTransaction(transaction)
        
        if canInvokePurchaseDelegate {
          self.delegate?.purchasedOrRestoredProduct(validateReceipt: true)
        }
        
        canInvokePurchaseDelegate = false
      case .restored:
        Logger.module.debug("Received transaction state: restored")

        SKPaymentQueue.default().finishTransaction(transaction)
        
        if canInvokePurchaseDelegate {
          // TODO: Receipt Validation Logic
          // Check the result of receipt validation and use
          // purchasedOrRestoredProduct(validateReceipt: false) or
          // purchaseFailed(error:) accordingly
        }
        
        canInvokePurchaseDelegate = false
      case .purchasing, .deferred:
        Logger.module.debug("Received transaction state: purchasing")
      case .failed:
        Logger.module.debug("Received transaction state: failed")
        
        SKPaymentQueue.default().finishTransaction(transaction)
        
        self.delegate?.purchaseFailed(
          error: .transactionError(error: transaction.error as? SKError))
      @unknown default:
        assertionFailure("Unknown transactionState")
      }
    }
  }

  // MARK: - Transaction Restore
  
  // Used to handle restoring transaction error and return error
  public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
    Logger.module.debug("Restoring transaction failed")
    self.delegate?.purchaseFailed(error: .transactionError(error: error as? SKError))
  }
  
  // Used to handle restoring transaction error for users never purchased but trying to restore
  public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
    if queue.transactions.isEmpty {
      Logger.module.debug("Restoring transaction failed - Nothing to restore - Account never bought this product")

      let errorRestore = SKError(SKError.unknown, userInfo: ["detail": "not-purchased"])
      delegate?.purchaseFailed(error: .transactionError(error: errorRestore))
    }
  }
}
