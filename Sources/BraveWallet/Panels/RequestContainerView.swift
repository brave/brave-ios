// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import BraveUI

/// A container to present when a webpage wants to present some request to the user such as transaction
/// confirmations, adding networks, switch networks, add tokens, sign message, etc.
struct RequestContainerView<DismissContent: ToolbarContent>: View {
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var cryptoStore: CryptoStore
  var toolbarDismissContent: DismissContent
  
  var onDismiss: () -> Void

  var body: some View {
    NavigationView {
      Group {
        if let pendingRequest = cryptoStore.pendingRequest {
          switch pendingRequest {
          case .transactions:
            TransactionConfirmationView(
              confirmationStore: cryptoStore.openConfirmationStore(),
              networkStore: cryptoStore.networkStore,
              keyringStore: keyringStore,
              onDismiss: onDismiss
            )
          case .addSuggestedToken(let request):
            AddSuggestedTokenView(
              token: request.token,
              originInfo: request.origin,
              cryptoStore: cryptoStore,
              onDismiss: onDismiss
            )
          case .switchChain(let request):
            SuggestedNetworkView(
              mode: .switchNetworks(chainId: request.chainId),
              originInfo: request.originInfo,
              cryptoStore: cryptoStore,
              keyringStore: keyringStore,
              networkStore: cryptoStore.networkStore,
              onDismiss: onDismiss
            )
          case .addChain(let request):
            SuggestedNetworkView(
              mode: .addNetwork(request.networkInfo),
              originInfo: request.originInfo,
              cryptoStore: cryptoStore,
              keyringStore: keyringStore,
              networkStore: cryptoStore.networkStore,
              onDismiss: onDismiss
            )
          case let .signMessage(requests):
            SignatureRequestView(
              requests: requests,
              keyringStore: keyringStore,
              cryptoStore: cryptoStore,
              onDismiss: onDismiss
            )
          case let .getEncryptionPublicKey(request):
            EncryptionView(
              request: .getEncryptionPublicKey(request),
              cryptoStore: cryptoStore,
              keyringStore: keyringStore,
              networkStore: cryptoStore.networkStore,
              onDismiss: onDismiss
            )
          case let .decrypt(request):
            EncryptionView(
              request: .decrypt(request),
              cryptoStore: cryptoStore,
              keyringStore: keyringStore,
              networkStore: cryptoStore.networkStore,
              onDismiss: onDismiss
            )
          case let .signTransaction(request):
            SignTransactionView(
              request: .signTransaction(request),
              cryptoStore: cryptoStore,
              onDismiss: onDismiss
            )
          case let .signAllTransactions(request):
            SignTransactionView(
              request: .signAllTransactions(request),
              cryptoStore: cryptoStore,
              onDismiss: onDismiss
            )
          }
        }
      }
      .toolbar {
        toolbarDismissContent
      }
    }
    .navigationViewStyle(.stack)
    .onAppear {
      // TODO: Fetch pending requests
    }
  }
}
