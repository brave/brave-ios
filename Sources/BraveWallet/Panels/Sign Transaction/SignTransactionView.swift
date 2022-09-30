// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveCore
import DesignSystem
import SwiftUI

class SignTransactionRequestUnion {
  let id: Int32
  let originInfo: BraveWallet.OriginInfo
  let fromAddress: String
  let txDatas: [BraveWallet.TxDataUnion]
  let rawMessage: [BraveWallet.ByteArrayStringUnion]
  
  init(
    id: Int32,
    originInfo: BraveWallet.OriginInfo,
    fromAddress: String,
    txDatas: [BraveWallet.TxDataUnion],
    rawMessage: [BraveWallet.ByteArrayStringUnion]
  ) {
    self.id = id
    self.originInfo = originInfo
    self.fromAddress = fromAddress
    self.txDatas = txDatas
    self.rawMessage = rawMessage
  }
}

struct SignTransactionView: View {
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore
  
  enum Request {
    case signTransaction([BraveWallet.SignTransactionRequest])
    case signAllTransactions([BraveWallet.SignAllTransactionsRequest])
  }
  
  var request: Request
  var cryptoStore: CryptoStore
  var onDismiss: () -> Void
  
  @State private var txIndex: Int = 0
  @State private var showWarning: Bool = true
  @Environment(\.sizeCategory) private var sizeCategory
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.openWalletURLAction) private var openWalletURL
  @ScaledMetric private var blockieSize = 54
  private let maxBlockieSize: CGFloat = 108
  private let normalizedRequests: [SignTransactionRequestUnion]
  
  init(
    keyringStore: KeyringStore,
    networkStore: NetworkStore,
    request: Request,
    cryptoStore: CryptoStore,
    onDismiss: @escaping () -> Void
  ) {
    self.keyringStore = keyringStore
    self.networkStore = networkStore
    self.request = request
    self.cryptoStore = cryptoStore
    self.onDismiss = onDismiss
    switch self.request {
    case .signTransaction(let requests):
      self.normalizedRequests = requests.map {
        SignTransactionRequestUnion(
          id: $0.id,
          originInfo: $0.originInfo,
          fromAddress: $0.fromAddress,
          txDatas: [$0.txData],
          rawMessage: [$0.rawMessage]
        )
      }
    case .signAllTransactions(let requests):
      self.normalizedRequests = requests.map {
        SignTransactionRequestUnion(
          id: $0.id,
          originInfo: $0.originInfo,
          fromAddress: $0.fromAddress,
          txDatas: $0.txDatas,
          rawMessage: $0.rawMessages
        )
      }
    }
  }
  
  var navigationTitle: String {
    switch request {
    case .signTransaction:
      return Strings.Wallet.signTransactionTitle
    case .signAllTransactions:
      return Strings.Wallet.signAllTransactionsTitle
    }
  }
  
  private var currentRequest: SignTransactionRequestUnion {
    normalizedRequests[txIndex]
  }
  
  private var instructions: [[BraveWallet.SolanaInstruction]] {
    return currentRequest.txDatas.map { $0.solanaTxData?.instructions ?? [] }
    //      switch self {
    //      case let .signTransaction(request):
    //        if let instructions = request.txData.solanaTxData?.instructions {
    //          return [instructions]
    //        }
    //        return []
    //      case let .signAllTransactions(request):
    //        return request.txDatas.map { $0.solanaTxData?.instructions ?? [] }
    //      }
  }

  private func instructionsDisplayString() -> String {
    instructions
     .map { instructionsForOneTx in
       instructionsForOneTx
         .map { TransactionParser.parseSolanaInstruction($0).toString }
         .joined(separator: "\n\n") // separator between each instruction
     }
     .joined(separator: "\n\n\n\n") // separator between each transaction
  }

  private var account: BraveWallet.AccountInfo {
    keyringStore.allAccounts.first(where: { $0.address == currentRequest.fromAddress }) ?? keyringStore.selectedAccount
  }
  
  var body: some View {
    ScrollView(.vertical) {
      VStack {
        VStack(spacing: 12) {
          HStack {
            Text(networkStore.selectedChain.chainName)
              .font(.subheadline)
              .foregroundColor(Color(.braveLabel))
            Spacer()
            if normalizedRequests.count > 1 {
              HStack {
                Spacer()
                Text(String.localizedStringWithFormat(Strings.Wallet.transactionCount, txIndex + 1, normalizedRequests.count))
                  .fontWeight(.semibold)
                Button(action: next) {
                  Text(Strings.Wallet.next)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.braveBlurpleTint))
                }
              }
            }
          }
          VStack(spacing: 12) {
            Blockie(address: account.address)
              .frame(width: min(blockieSize, maxBlockieSize), height: min(blockieSize, maxBlockieSize))
            Text(urlOrigin: currentRequest.originInfo.origin)
              .font(.caption)
              .foregroundColor(Color(.braveLabel))
              .multilineTextAlignment(.center)
            AddressView(address: account.address) {
              VStack(spacing: 4) {
                Text(account.name)
                  .font(.subheadline.weight(.semibold))
                  .foregroundColor(Color(.braveLabel))
              }
            }
          }
          .accessibilityElement(children: .combine)
          Text(Strings.Wallet.signatureRequestSubtitle)
            .font(.title3.weight(.semibold))
            .foregroundColor(Color(.bravePrimary))
            .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        if showWarning {
          warningView
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
        } else {
          divider
            .padding(.top, 8)
          StaticTextView(text: instructionsDisplayString(), isMonospaced: false)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(Color(.tertiaryBraveGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .padding()
            .background(
              Color(.secondaryBraveGroupedBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        buttonsContainer
          .padding(.top)
          .opacity(sizeCategory.isAccessibilityCategory ? 0 : 1)
          .accessibility(hidden: sizeCategory.isAccessibilityCategory)
      }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text(navigationTitle))
    }
  }
  
  @ViewBuilder private var buttonsContainer: some View {
    if sizeCategory.isAccessibilityCategory {
      VStack {
        buttons
      }
    } else {
      HStack {
        buttons
      }
    }
  }
  
  @ViewBuilder private var buttons: some View {
    if showWarning {
      Button(action: { // cancel
        switch request {
        case .signTransaction(_):
          cryptoStore.handleWebpageRequestResponse(.signTransaction(approved: false, id: currentRequest.id, signature: nil, error: nil))
          onDismiss()
        case .signAllTransactions(_):
          cryptoStore.handleWebpageRequestResponse(.signAllTransactions(approved: false, id: currentRequest.id, signatures: nil, error: nil))
        }
      }) {
        Text(Strings.cancelButtonTitle)
      }
      .buttonStyle(BraveOutlineButtonStyle(size: .large))
      Button(action: { // Continue
        showWarning = false
      }) {
        Text(Strings.Wallet.continueButtonTitle)
          .imageScale(.large)
      }
      .buttonStyle(BraveFilledButtonStyle(size: .large))
    } else {
      Button(action: { // cancel
        switch request {
        case .signTransaction(_):
          cryptoStore.handleWebpageRequestResponse(.signTransaction(approved: false, id: currentRequest.id, signature: nil, error: nil))
          onDismiss()
        case .signAllTransactions(_):
          cryptoStore.handleWebpageRequestResponse(.signAllTransactions(approved: false, id: currentRequest.id, signatures: nil, error: nil))
        }
      }) {
        Text(Strings.cancelButtonTitle)
      }
      .buttonStyle(BraveOutlineButtonStyle(size: .large))
      //    .disabled(isButtonsDisabled)
      Button(action: { // approve
        switch request {
        case .signTransaction(_):
          cryptoStore.handleWebpageRequestResponse(.signTransaction(approved: true, id: currentRequest.id, signature: nil, error: nil))
          onDismiss()
        case .signAllTransactions(_):
          cryptoStore.handleWebpageRequestResponse(.signAllTransactions(approved: true, id: currentRequest.id, signatures: nil, error: nil))
        }
      }) {
        Label(Strings.Wallet.sign, braveSystemImage: "brave.key")
          .imageScale(.large)
      }
      .buttonStyle(BraveFilledButtonStyle(size: .large))
      //    .disabled(isButtonsDisabled)
    }
  }
  
  @ViewBuilder private var divider: some View {
    VStack {
      Text("Details")
        .font(.subheadline.weight(.semibold))
        .foregroundColor(Color(.bravePrimary))
      HStack {
        LinearGradient(braveGradient: colorScheme == .dark ? .darkGradient02 : .lightGradient02)
      }
      .frame(height: 4)
      .padding(.horizontal, 20)
    }
  }
  
  @ViewBuilder private var warningView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Group {
        Label("Sign at your own risk", systemImage: "exclamationmark.triangle")
          .font(.subheadline.weight(.semibold))
          .foregroundColor(Color(.braveErrorLabel))
          .padding(.top, 12)
        Text("Note that Brave can’t verify what will happen if you sign. A signature could authorize nearly any operation in your account or on your behalf, including (but not limited to) giving total control of your account and crypto assets to the site making the request. Only sign if you’re sure you want to take this action, and trust the requesting site.")
          .font(.subheadline)
          .foregroundColor(Color(.braveErrorLabel))
        Button(action: {
          openWalletURL?(WalletConstants.signTransactionRiskLink)
        }) {
          Text(Strings.Wallet.learnMoreButton)
            .font(.subheadline)
            .foregroundColor(Color(.braveBlurpleTint))
        }
        .padding(.bottom, 12)
      }
      .padding(.horizontal, 12)
    }
    .background(
      Color(.braveErrorBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    )
  }
  
  private func next() {
    if txIndex + 1 < normalizedRequests.count {
      txIndex += 1
    } else {
      txIndex = 0
    }
  }
}

#if DEBUG
struct SignTransaction_Previews: PreviewProvider {
  static var previews: some View {
    SignTransactionView(
      keyringStore: .previewStore,
      networkStore: .previewStore,
      request: .signTransaction([BraveWallet.SignTransactionRequest(
        originInfo: .init(),
        id: 0,
        fromAddress: "2xyURwxRjuLZh89YGjywEJauh2fxnkbtUEyAU9pdvHA1",
        txData: .init(),
        rawMessage: .init(),
        coin: .sol
      )]),
      cryptoStore: .previewStore,
      onDismiss: {}
    )
    .previewColorSchemes()
  }
}
#endif
