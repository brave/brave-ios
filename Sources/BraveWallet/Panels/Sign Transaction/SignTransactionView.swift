// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveCore
import DesignSystem
import SwiftUI

struct SignTransactionView: View {
  enum Request {
    case signTransaction(BraveWallet.SignTransactionRequest)
    case signAllTransactions(BraveWallet.SignAllTransactionsRequest)
  }
  
  var request: Request
  var cryptoStore: CryptoStore
  var onDismiss: () -> Void
  
  var navigationTitle: String {
    switch request {
    case .signTransaction:
      return "Sign Transaction"
    case .signAllTransactions:
      return "Sign All Transactions"
    }
  }
  
  var body: some View { // TODO: SignTransaction / SignAllTransactions panel #6005
    Color.gray
      .overlay(
        Button(action: {
          switch request {
          case let .signTransaction(request):
            cryptoStore.handleWebpageRequestResponse(
              .signTransaction(approved: false, id: request.id, signature: nil, error: "Error message")
            )
          case let .signAllTransactions(request):
            cryptoStore.handleWebpageRequestResponse(
              .signAllTransactions(approved: false, id: request.id, signatures: nil, error: "Error message")
            )
          }
          onDismiss()
        }) {
          Text("Reject")
        }
          .buttonStyle(BraveFilledButtonStyle(size: .large))
      )
      .navigationBarTitleDisplayMode(.inline)
      .navigationTitle(Text(navigationTitle))
  }
}
