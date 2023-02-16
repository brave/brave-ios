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
 
  let onClose: () -> Void
  
  @Environment(\.openWalletURLAction) private var openWalletURL
  
  @ViewBuilder private var loadingTxView: some View {
    VStack {
      TxProgressView()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  @ViewBuilder private var signedOrSubmittedTxView: some View {
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
        onClose()
      } label: {
        Text(Strings.OKString)
          .padding(.horizontal, 8)
      }
      .padding(.top, 40)
      .buttonStyle(BraveFilledButtonStyle(size: .large))
      Button {
        if let baseURL = networkStore.selectedChain.blockExplorerUrls.first.map(URL.init(string:)),
           let url = baseURL?.appendingPathComponent("tx/\(confirmationStore.activeParsedTransaction.transaction.txHash)") {
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
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
  
  @ViewBuilder private var confirmedTxView: some View {
    VStack(spacing: 10) {
      Image("tx-confirmed", bundle: .module)
      Text(Strings.Wallet.confirmedTransactionTitle)
        .font(.title3.bold())
        .foregroundColor(Color(.braveLabel))
        .multilineTextAlignment(.center)
        .padding(.top, 10)
      Text(Strings.Wallet.confirmedTransactionDescription)
        .font(.subheadline)
        .foregroundColor(Color(.secondaryBraveLabel))
        .multilineTextAlignment(.center)
      HStack {
        Button {
          transactionDetails = confirmationStore.activeTxDetailsStore()
        } label: {
          Text(Strings.Wallet.confirmedTransactionReceiptButtonTitle)
        }
        .buttonStyle(BraveOutlineButtonStyle(size: .large))
        Button {
          onClose()
        } label: {
          Text(Strings.Wallet.confirmedTransactionCloseButtonTitle)
        }
        .buttonStyle(BraveFilledButtonStyle(size: .large))
      }
      .padding(.top, 40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
  
  var body: some View {
    if confirmationStore.isTxSubmitting {
      loadingTxView
    } else {
      switch confirmationStore.activeTxStatus {
      case .signed, .submitted:
        signedOrSubmittedTxView
      case .confirmed:
        confirmedTxView
      default:
        PendingTransactionView(
          confirmationStore: confirmationStore,
          networkStore: networkStore,
          keyringStore: keyringStore,
          isShowingGas: $isShowingGas,
          isShowingAdvancedSettings: $isShowingAdvancedSettings,
          onClose: onClose
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
      onClose: { }
    )
  }
}
#endif
