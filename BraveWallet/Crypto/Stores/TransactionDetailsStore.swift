// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

class TransactionDetailsStore {
  /// A boolean indicates if this store is loading
  @Published var isLoading = false
  
  private let txController: BraveWalletEthTxController
  
  init(txController: BraveWalletEthTxController) {
    self.txController = txController
  }
  
  func speedUpTx(txMetaId: String) {
    isLoading = true
    txController.speedupOrCancelTransaction(txMetaId, cancel: false) { [weak self] success, txMetaId, error in
      self?.isLoading = false
      guard success else {
        return
      }
    }
  }
  
  func cancelTx(txMetaId: String) {
    isLoading = true
    txController.speedupOrCancelTransaction(txMetaId, cancel: true) { [weak self] success, txMetaId, error in
      self?.isLoading = false
      guard success else {
        return
      }
    }
  }
  
  func retryTx(txMetaId: String) {
    isLoading = true
    txController.retryTransaction(txMetaId) { [weak self] success, txMetaId, error in
      self?.isLoading = false
      guard success else {
        return 
      }
    }
  }
}
