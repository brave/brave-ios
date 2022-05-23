// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import StoreKit
import Shared
import BraveShared

private let log = Logger.browserLogger

protocol IAPObserverDelegate: AnyObject {
  func purchasedOrRestoredProduct()
  func purchaseFailed(error: IAPObserver.PurchaseError)
}

class IAPObserver: NSObject, SKPaymentTransactionObserver {

  enum PurchaseError {
    case transactionError(error: SKError?)
    case receiptError
  }

  weak var delegate: IAPObserverDelegate?

  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    // This helper variable helps to call the IAPObserverDelegate delegate purchased method only once.
    // Reason is when restoring or sometimes when purchasing a product there's multiple transactions
    // that are returned in `transactions` array.
    // Apple advices to call `finishTransaction` for all of them,
    // but to show the UI we only want to call the delegate method once.
    var callPurchaseDelegateOnce = true
    
    transactions.forEach { transaction in
      switch transaction.transactionState {
      case .purchased, .restored:
        log.debug("Received transaction state: purchased or restored")
        SKPaymentQueue.default().finishTransaction(transaction)
        if callPurchaseDelegateOnce {
          self.delegate?.purchasedOrRestoredProduct()
        }
        callPurchaseDelegateOnce = false
      case .purchasing, .deferred:
        log.debug("Received transaction state: purchasing")
      case .failed:
        log.debug("Received transaction state: failed")
        SKPaymentQueue.default().finishTransaction(transaction)
        self.delegate?.purchaseFailed(
          error: .transactionError(error: transaction.error as? SKError))
      @unknown default:
        assertionFailure("Unknown transactionState")
      }
    }
  }

  func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
    log.debug("Restoring transaction failed")
    self.delegate?.purchaseFailed(error: .transactionError(error: error as? SKError))
  }
}
