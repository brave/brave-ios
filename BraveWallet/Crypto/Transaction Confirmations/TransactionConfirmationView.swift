// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import BraveUI
import BigNumber
import Shared

struct TransactionBacklogView: View {
  var confirmationStore: TransactionConfirmationStore
  var backedUpTx: BraveWallet.TransactionInfo?
  var replacementDone: Bool
  
  @Environment(\.openWalletURLAction) private var openWalletURL
  
  @State private var replaceBackedUpTx = false
  
  var body: some View {
    VStack(spacing: 15) {
      Text(Strings.Wallet.transactionBacklogTitle)
        .font(.title2.bold())
        .foregroundColor(Color(.braveLabel))
      VStack(spacing: 5) {
        Text(Strings.Wallet.transactionBacklogBody)
          .multilineTextAlignment(.center)
          .foregroundColor(Color(.braveLabel))
        Button(action: {
          guard let url = URL(string: "https://support.brave.com/hc/en-us/articles/4537540021389") else { return }
          openWalletURL?(url)
        }) {
          Text(Strings.Wallet.transactionBacklogLearnMoreButton)
            .fontWeight(.semibold)
            .foregroundColor(Color(.braveBlurpleTint))
        }
      }
      if replacementDone {
        Text(Strings.Wallet.transactionBacklogAfterReplacement)
          .multilineTextAlignment(.center)
          .foregroundColor(Color(.braveLabel))
      } else {
        HStack {
          Toggle(isOn: $replaceBackedUpTx) {
            Text(Strings.Wallet.transactionBacklogAcknowledgement)
              .font(.callout)
              .foregroundColor(Color(.secondaryBraveLabel))
          }
          .toggleStyle(SwitchToggleStyle(tint: Color(.braveOrange)))
        }
      }
      Button(action: {
        if replaceBackedUpTx, let backedUpTx = backedUpTx {
          confirmationStore.replaceBackedUpTx(tx: backedUpTx)
        } else {
          confirmationStore.txBacklogState = .normal
        }
      }) {
        Text(Strings.Wallet.continueButtonTitle)
      }
      .buttonStyle(BraveFilledButtonStyle(size: .large))
      .padding(.top, 10)
    }
    .padding(.horizontal, 23)
  }
}

struct TransactionConfirmationView: View {
  @ObservedObject var confirmationStore: TransactionConfirmationStore
  @ObservedObject var networkStore: NetworkStore
  @ObservedObject var keyringStore: KeyringStore
  
  @Environment(\.sizeCategory) private var sizeCategory
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  private enum ViewMode: Int {
    case transaction
    case details
  }
  
  @State private var viewMode: ViewMode = .transaction
  
  private func next() {
    if let index = confirmationStore.allUnapprovedTx.firstIndex(where: { $0.id == confirmationStore.activeTransactionId }) {
      var nextIndex = confirmationStore.allUnapprovedTx.index(after: index)
      if nextIndex == confirmationStore.allUnapprovedTx.endIndex {
        nextIndex = 0
      }
      confirmationStore.activeTransactionId = confirmationStore.allUnapprovedTx[nextIndex].id
    } else {
      confirmationStore.activeTransactionId = confirmationStore.allUnapprovedTx.first!.id
    }
  }
  
  private func rejectAll() {
    for transaction in confirmationStore.allUnapprovedTx {
      confirmationStore.reject(transaction: transaction)
    }
  }
  
  private var fromAccountName: String {
    NamedAddresses.name(for: confirmationStore.activeTransaction.fromAddress, accounts: keyringStore.keyring.accountInfos)
  }
  
  private var toAccountName: String {
    return NamedAddresses.name(for: confirmationStore.activeTransaction.ethTxToAddress, accounts: keyringStore.keyring.accountInfos)
  }
  
  private var transactionType: String {
    if confirmationStore.activeTransaction.txType == .erc20Approve {
      return Strings.Wallet.transactionTypeApprove
    }
    return confirmationStore.activeTransaction.isSwap ? Strings.Wallet.swap : Strings.Wallet.send
  }
  
  private var transactionDetails: String {
    if confirmationStore.activeTransaction.txArgs.isEmpty {
      let data = confirmationStore.activeTransaction.ethTxData
        .map { byte in
          String(format: "%02X", byte.uint8Value)
        }
        .joined()
      if data.isEmpty {
        return Strings.Wallet.inputDataPlaceholder
      }
      return "0x\(data)"
    } else {
      return zip(confirmationStore.activeTransaction.txParams, confirmationStore.activeTransaction.txArgs)
        .map { (param, arg) in
          "\(param): \(arg)"
        }
        .joined(separator: "\n\n")
    }
  }
  
  @ViewBuilder private var editGasFeeButton: some View {
    let titleView = Text(Strings.Wallet.editGasFeeButtonTitle)
      .fontWeight(.semibold)
      .foregroundColor(Color(.braveBlurpleTint))
    Group {
      if confirmationStore.activeTransaction.isEIP1559Transaction {
        if let gasEstimation = confirmationStore.gasEstimation1559 {
          NavigationLink(
            destination: EditPriorityFeeView(
              transaction: confirmationStore.activeTransaction,
              gasEstimation: gasEstimation,
              confirmationStore: confirmationStore
            )
          ) {
            titleView
          }
        }
      } else {
        NavigationLink(
          destination: EditGasFeeView(
            transaction: confirmationStore.activeTransaction,
            confirmationStore: confirmationStore
          )
        ) {
          titleView
        }
      }
    }
    .font(.footnote)
  }
  
  var body: some View {
    NavigationView {
      Group {
        switch confirmationStore.txBacklogState {
        case .normal:
          ScrollView(.vertical) {
            VStack {
              // Header
              HStack {
                Text(networkStore.selectedChain.shortChainName)
                Spacer()
                if confirmationStore.allUnapprovedTx.count > 1 {
                  let index = confirmationStore.allUnapprovedTx.firstIndex(of: confirmationStore.activeTransaction) ?? 0
                  Text(String.localizedStringWithFormat(Strings.Wallet.transactionCount, index + 1, confirmationStore.allUnapprovedTx.count))
                    .fontWeight(.semibold)
                  Button(action: next) {
                    Text(Strings.Wallet.nextTransaction)
                      .fontWeight(.semibold)
                      .foregroundColor(Color(.braveBlurpleTint))
                  }
                }
              }
              .font(.callout)
              // Summary
              VStack(spacing: 8) {
                VStack {
                  BlockieGroup(
                    fromAddress: confirmationStore.activeTransaction.fromAddress,
                    toAddress: confirmationStore.activeTransaction.ethTxToAddress,
                    size: 48
                  )
                  Group {
                    if sizeCategory.isAccessibilityCategory {
                      VStack {
                        Text(fromAccountName)
                        Image(systemName: "arrow.down")
                        Text(toAccountName)
                      }
                    } else {
                      HStack {
                        Text(fromAccountName)
                        Image(systemName: "arrow.right")
                        Text(toAccountName)
                      }
                    }
                  }
                  .foregroundColor(Color(.bravePrimary))
                  .font(.callout)
                }
                .accessibilityElement()
                .accessibility(addTraits: .isStaticText)
                .accessibility(
                  label: Text(String.localizedStringWithFormat(
                    Strings.Wallet.transactionFromToAccessibilityLabel, fromAccountName, toAccountName
                  ))
                )
                VStack(spacing: 4) {
                  Text(transactionType)
                    .font(.footnote)
                  Text("\(confirmationStore.state.value) \(confirmationStore.state.symbol)")
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.bravePrimary))
                  Text(confirmationStore.state.fiat) // Value in Fiat
                    .font(.footnote)
                }
                .padding(.vertical, 8)
              }
              // View Mode
              VStack(spacing: 12) {
                Picker("", selection: $viewMode) {
                  Text(Strings.Wallet.confirmationViewModeTransaction).tag(ViewMode.transaction)
                  Text(Strings.Wallet.confirmationViewModeDetails).tag(ViewMode.details)
                }
                .pickerStyle(SegmentedPickerStyle())
                Group {
                  switch viewMode {
                  case .transaction:
                    VStack(spacing: 0) {
                      HStack {
                        VStack(alignment: .leading) {
                          Text(Strings.Wallet.gasFee)
                            .foregroundColor(Color(.bravePrimary))
                          editGasFeeButton
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                          Text("\(confirmationStore.state.gasValue) \(confirmationStore.state.gasSymbol)")
                            .foregroundColor(Color(.bravePrimary))
                          Text(confirmationStore.state.gasFiat)
                            .font(.footnote)
                        }
                      }
                      .font(.callout)
                      .padding()
                      .accessibilityElement(children: .contain)
                      Divider()
                        .padding(.leading)
                      HStack {
                        Text(Strings.Wallet.total)
                          .foregroundColor(Color(.bravePrimary))
                          .font(.callout)
                          .accessibility(sortPriority: 1)
                        Spacer()
                        VStack(alignment: .trailing) {
                          Text(Strings.Wallet.amountAndGas)
                            .font(.footnote)
                            .foregroundColor(Color(.secondaryBraveLabel))
                          Text("\(confirmationStore.state.value) \(confirmationStore.state.symbol) + \(confirmationStore.state.gasValue) \(confirmationStore.state.gasSymbol)")
                            .foregroundColor(Color(.bravePrimary))
                          HStack(spacing: 4) {
                            if !confirmationStore.state.isBalanceSufficient {
                              Text(Strings.Wallet.insufficientBalance)
                                .foregroundColor(Color(.braveErrorLabel))
                            }
                            Text(confirmationStore.state.totalFiat)
                              .foregroundColor(
                                confirmationStore.state.isBalanceSufficient ? Color(.braveLabel) : Color(.braveErrorLabel)
                              )
                          }
                          .accessibilityElement(children: .contain)
                          .font(.footnote)
                        }
                      }
                      .padding()
                      .accessibilityElement(children: .contain)
                    }
                  case .details:
                    VStack(alignment: .leading) {
                      DetailsTextView(text: transactionDetails)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color(.tertiaryBraveGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                    .padding()
                  }
                }
                .frame(maxWidth: .infinity)
                .background(
                  Color(.secondaryBraveGroupedBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
              }
              if confirmationStore.allUnapprovedTx.count > 1 {
                Button(action: rejectAll) {
                  Text(String.localizedStringWithFormat(Strings.Wallet.rejectAllTransactions, confirmationStore.allUnapprovedTx.count))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.braveBlurpleTint))
                }
                .padding(.top, 8)
              }
              rejectConfirmContainer
                .padding(.top)
                .opacity(sizeCategory.isAccessibilityCategory ? 0 : 1)
                .accessibility(hidden: sizeCategory.isAccessibilityCategory)
            }
            .padding()
          }
          .overlay(
            Group {
              if sizeCategory.isAccessibilityCategory {
                rejectConfirmContainer
                  .frame(maxWidth: .infinity)
                  .padding(.top)
                  .background(
                    LinearGradient(
                      stops: [
                        .init(color: Color(.braveGroupedBackground).opacity(0), location: 0),
                        .init(color: Color(.braveGroupedBackground).opacity(1), location: 0.05),
                        .init(color: Color(.braveGroupedBackground).opacity(1), location: 1),
                      ],
                      startPoint: .top,
                      endPoint: .bottom
                    )
                      .ignoresSafeArea()
                      .allowsHitTesting(false)
                  )
              }
            },
            alignment: .bottom
          )
          .background(
            Color(.braveGroupedBackground).edgesIgnoringSafeArea(.all)
          )
        case .replacementReady(let backedUpTx):
          TransactionBacklogView(
            confirmationStore: confirmationStore,
            backedUpTx: backedUpTx,
            replacementDone: false
          )
        case .replacementDone:
          TransactionBacklogView(
            confirmationStore: confirmationStore,
            backedUpTx: nil,
            replacementDone: true
          )
        }
      }
      .navigationBarTitle(confirmationStore.allUnapprovedTx.count > 1 ? Strings.Wallet.confirmTransactionsTitle : Strings.Wallet.confirmTransactionTitle)
      .navigationBarTitleDisplayMode(.inline)
      .foregroundColor(Color(.braveLabel))
      .toolbar {
        ToolbarItemGroup(placement: .cancellationAction) {
          Button(action: { presentationMode.dismiss() }) {
            Text(Strings.cancelButtonTitle)
              .foregroundColor(Color(.braveOrange))
          }
        }
      }
    }
    .navigationViewStyle(StackNavigationViewStyle())
    .onAppear {
      confirmationStore.prepare(selectedAccount: keyringStore.selectedAccount)
    }
  }
  
  @ViewBuilder private var rejectConfirmContainer: some View {
    if sizeCategory.isAccessibilityCategory {
      VStack {
        rejectConfirmButtons
      }
    } else {
      HStack {
        rejectConfirmButtons
      }
    }
  }
  
  @ViewBuilder private var rejectConfirmButtons: some View {
    Button(action: {
      confirmationStore.reject(transaction: confirmationStore.activeTransaction)
    }) {
      Label(Strings.Wallet.rejectTransactionButtonTitle, systemImage: "xmark")
    }
    .buttonStyle(BraveOutlineButtonStyle(size: .large))
    Button(action: {
      confirmationStore.confirm(transaction: confirmationStore.activeTransaction)
    }) {
      Label(Strings.Wallet.confirmTransactionButtonTitle, systemImage: "checkmark.circle.fill")
    }
    .buttonStyle(BraveFilledButtonStyle(size: .large))
    .disabled(!confirmationStore.state.isBalanceSufficient)
  }
}

/// We needed a `TextEditor` that couldn't be edited and had a clear background color
/// so we have to fallback to UIKit for this
private struct DetailsTextView: UIViewRepresentable {
  var text: String
  
  func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
    textView.text = text
    textView.isEditable = false
    textView.backgroundColor = .tertiaryBraveGroupedBackground
    textView.font = {
      let metrics = UIFontMetrics(forTextStyle: .body)
      let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
      let font = UIFont.monospacedSystemFont(ofSize: desc.pointSize, weight: .regular)
      return metrics.scaledFont(for: font)
    }()
    textView.adjustsFontForContentSizeCategory = true
    textView.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
    return textView
  }
  func updateUIView(_ uiView: UITextView, context: Context) {
    uiView.text = text
  }
}

#if DEBUG
struct TransactionConfirmationView_Previews: PreviewProvider {
  static var previews: some View {
    TransactionConfirmationView(
      confirmationStore: .previewStore,
      networkStore: .previewStore,
      keyringStore: .previewStoreWithWalletCreated
    )
      .previewLayout(.sizeThatFits)
  }
}
#endif
