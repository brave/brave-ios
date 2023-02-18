// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import BigNumber
import Strings
import DesignSystem

struct TransactionStatusView: View {
  @ObservedObject var confirmationStore: TransactionConfirmationStore
  let networkStore: NetworkStore
  let keyringStore: KeyringStore
  @Binding var isShowingGas: Bool
  @Binding var isShowingAdvancedSettings: Bool
  @Binding var transactionDetails: TransactionDetailsStore?
 
  let onDismiss: () -> Void
  
  @Environment(\.openWalletURLAction) private var openWalletURL
  
  @ViewBuilder private var loadingTxView: some View {
    VStack {
      TxProgressView()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  @ViewBuilder private var signedOrSubmittedTxView: some View {
    GeometryReader { geometry in
      ScrollView(.vertical) {
        VStack(spacing: 10) {
          Image("tx-submitted", bundle: .module)
          Text(confirmationStore.activeTxStatus == .signed ? Strings.Wallet.signedTransactionTitle : Strings.Wallet.submittedTransactionTitle)
            .font(.title3.bold())
            .foregroundColor(Color(.braveLabel))
            .multilineTextAlignment(.center)
            .padding(.top, 10)
          Text(confirmationStore.activeTxStatus == .signed ? Strings.Wallet.signedTransactionDescription : Strings.Wallet.submittedTransactionDescription)
            .font(.subheadline)
            .foregroundColor(Color(.secondaryBraveLabel))
            .multilineTextAlignment(.center)
          Button {
            onDismiss()
          } label: {
            Text(Strings.OKString)
              .padding(.horizontal, 8)
          }
          .padding(.top, 40)
          .buttonStyle(BraveFilledButtonStyle(size: .large))
          Button {
            if let baseURL = networkStore.selectedChain.blockExplorerUrls.first.map(URL.init(string:)),
               let tx = confirmationStore.allTxs.first(where: { $0.id == confirmationStore.activeTransactionId }),
               let url = baseURL?.appendingPathComponent("tx/\(tx.txHash)") {
              openWalletURL?(url)
            }
          } label: {
            HStack {
              Text(Strings.Wallet.viewOnBlockExplorer)
              Image(systemName: "arrow.up.forward.square")
            }
            .foregroundColor(Color(.braveBlurpleTint))
            .font(.subheadline.bold())
          }
          .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: geometry.size.height)
        .padding()
      }
    }
  }
  
  @ViewBuilder private var confirmedOrFailedTxView: some View {
    GeometryReader { geometry in
      ScrollView(.vertical) {
        VStack(spacing: 10) {
          Image(confirmationStore.activeTxStatus == .confirmed ? "tx-confirmed" : "tx-failed", bundle: .module)
          Text(confirmationStore.activeTxStatus == .confirmed ? Strings.Wallet.confirmedTransactionTitle : Strings.Wallet.failedTransactionTitle)
            .font(.title3.bold())
            .foregroundColor(confirmationStore.activeTxStatus == .confirmed ? Color(.braveLabel) : Color(.braveErrorLabel))
            .multilineTextAlignment(.center)
            .padding(.top, 10)
          Text(confirmationStore.activeTxStatus == .confirmed ? Strings.Wallet.confirmedTransactionDescription : Strings.Wallet.failedTransactionDescription)
            .font(.subheadline)
            .foregroundColor(Color(.secondaryBraveLabel))
            .multilineTextAlignment(.center)
          if confirmationStore.activeTxStatus == .error, let txProviderError = confirmationStore.transactionProviderErrorRegistry[confirmationStore.activeTransactionId] {
            StaticTextView(text: "\(txProviderError.code): \(txProviderError.message)")
              .frame(maxWidth: .infinity)
              .frame(height: 100)
              .background(Color(.tertiaryBraveGroupedBackground))
              .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
              .padding()
              .background(
                Color(.secondaryBraveGroupedBackground)
              )
              .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
              .padding(.top, 10)
          }
          HStack {
            if confirmationStore.activeTxStatus == .confirmed {
              Button {
                transactionDetails = confirmationStore.activeTxDetailsStore()
              } label: {
                Text(Strings.Wallet.confirmedTransactionReceiptButtonTitle)
              }
              .buttonStyle(BraveOutlineButtonStyle(size: .large))
            }
            Button {
              onDismiss()
            } label: {
              Text(Strings.Wallet.confirmedTransactionCloseButtonTitle)
            }
            .buttonStyle(BraveFilledButtonStyle(size: .large))
          }
          .padding(.top, 40)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: geometry.size.height)
        .padding()
      }
    }
  }
  
  var body: some View {
    if confirmationStore.isTxSubmitting {
      loadingTxView
    } else {
      switch confirmationStore.activeTxStatus {
      case .signed, .submitted:
        signedOrSubmittedTxView
      case .confirmed, .error:
        confirmedOrFailedTxView
      default:
        PendingTransactionView(
          confirmationStore: confirmationStore,
          networkStore: networkStore,
          keyringStore: keyringStore,
          isShowingGas: $isShowingGas,
          isShowingAdvancedSettings: $isShowingAdvancedSettings,
          onDismiss: onDismiss
        )
      }
    }
  }
}

/// A custom loader needed during the process of submitting a transaction
private struct TxProgressView: View {
  @State private var isAnimating = false
  
  var body: some View {
    Image("tx-loading", bundle: .module)
      .rotationEffect(.degrees(isAnimating ? 360 : 0))
      .animation(isAnimating ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default)
      .onAppear { isAnimating = true }
      .onDisappear { isAnimating = false }
  }
}

#if DEBUG
struct TransactionStatusView_Previews: PreviewProvider {
  static var previews: some View {
    TransactionStatusView(
      confirmationStore: .previewStore,
      networkStore: .previewStore,
      keyringStore: .previewStore,
      isShowingGas: .constant(false),
      isShowingAdvancedSettings: .constant(false),
      transactionDetails: .constant(nil),
      onDismiss: { }
    )
  }
}
#endif
