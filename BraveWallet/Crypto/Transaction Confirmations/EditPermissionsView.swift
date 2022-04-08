// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveCore
import BraveUI
import struct Shared.Strings
import SwiftUI

struct EditPermissionsView: View {
  
  let proposedAllowance: String
  @ObservedObject var confirmationStore: TransactionConfirmationStore
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore
  
  private enum AllowanceKind: Hashable, Equatable {
    case proposedAllowance
    case customAllowance
  }
  
  @State private var allowanceKind: AllowanceKind = .proposedAllowance
  @State private var customAllowance: String = "0"
  @State private var isFieldFocused: Bool = false
  @State private var isShowingAlert = false
  @Environment(\.presentationMode) @Binding private var presentationMode
  @Environment(\.sizeCategory) private var sizeCategory
  
  private var activeTransaction: BraveWallet.TransactionInfo {
    confirmationStore.transactions.first(where: { $0.id == confirmationStore.activeTransactionId }) ?? (confirmationStore.transactions.first ?? .init())
  }
  
  private var allowanceAmountInWei: String {
    switch allowanceKind {
    case .proposedAllowance:
      return proposedAllowance
    case .customAllowance:
      let decimals: Int
      if let contractAddress = activeTransaction.txDataUnion.ethTxData1559?.baseData.to, let token = confirmationStore.token(for: contractAddress, in: networkStore.selectedChain) {
        decimals = Int(token.decimals)
      } else {
        decimals = 18
      }
      let weiFormatter = WeiFormatter(decimalFormatStyle: .decimals(precision: decimals))
      let customAllowanceInWei = weiFormatter.weiString(from: customAllowance, radix: .decimal, decimals: decimals) ?? "0"
      return customAllowanceInWei.addingHexPrefix
    }
  }
  
  private var accountName: String {
    NamedAddresses.name(for: activeTransaction.fromAddress, accounts: keyringStore.keyring.accountInfos)
  }
  
  init(
    proposedAllowance: String,
    confirmationStore: TransactionConfirmationStore,
    keyringStore: KeyringStore,
    networkStore: NetworkStore
  ) {
    self.proposedAllowance = proposedAllowance
    self.confirmationStore = confirmationStore
    self.keyringStore = keyringStore
    self.networkStore = networkStore
  }
  
  var body: some View {
    List {
      Section(
        header: Text(String.localizedStringWithFormat(Strings.Wallet.editPermissionsAllowanceHeader, accountName))
          .foregroundColor(Color(.secondaryBraveLabel))
          .font(.footnote)
          .resetListHeaderStyle()
          .padding(.vertical)
      ) {
        Picker(selection: $allowanceKind) {
          VStack(alignment: .leading) {
            Text(String.localizedStringWithFormat(Strings.Wallet.editPermissionsProposedAllowanceHeader, confirmationStore.state.symbol))
              .foregroundColor(Color(.bravePrimary))
              .font(.footnote.weight(.semibold))
            TextField("", text: Binding(get: { confirmationStore.state.value }, set: { _ in }))
              .disabled(true)
          }.tag(AllowanceKind.proposedAllowance)
          
          VStack(alignment: .leading) {
            Text(String.localizedStringWithFormat(Strings.Wallet.editPermissionsCustomAllowanceHeader, confirmationStore.state.symbol))
              .foregroundColor(Color(.bravePrimary))
              .font(.footnote.weight(.semibold))
            TextField("", text: $customAllowance)
              .keyboardType(.numberPad)
              .foregroundColor(Color(.braveLabel))
              .allowsHitTesting(allowanceKind == .customAllowance) // allow user to tap on this entire row in the `Picker`, we'll become first responder when `allowanceKind` changes to `.customAllowance`
              .foregroundColor(Color(.braveLabel))
              .introspectTextField { tf in
                if allowanceKind == .customAllowance && !isFieldFocused && !tf.isFirstResponder {
                  DispatchQueue.main.async {
                    isFieldFocused = tf.becomeFirstResponder()
                  }
                }
              }
          }.tag(AllowanceKind.customAllowance)
        } label: {
          EmptyView()
        }
        .accentColor(Color(.braveBlurpleTint))
        .pickerStyle(.inline)
        .foregroundColor(Color(.braveLabel))
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      
      Button(action: {
        confirmationStore.editAllowance(
          txMetaId: activeTransaction.id,
          spenderAddress: activeTransaction.txArgs[safe: 0] ?? "",
          amount: allowanceAmountInWei) { success in
            if success {
              presentationMode.dismiss()
            } else {
              isShowingAlert = true
            }
          }
      }) {
        Text(Strings.Wallet.saveButtonTitle)
      }
      .buttonStyle(BraveFilledButtonStyle(size: .large))
      .frame(maxWidth: .infinity)
      .opacity(sizeCategory.isAccessibilityCategory ? 0 : 1)
      .accessibility(hidden: sizeCategory.isAccessibilityCategory)
      .listRowBackground(Color(.braveGroupedBackground))
    }
    .listStyle(InsetGroupedListStyle())
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle(Strings.Wallet.editPermissionsTitle)
    .alert(isPresented: $isShowingAlert) {
      Alert(
        title: Text(Strings.Wallet.unknownError),
        message: Text(Strings.Wallet.editTransactionError),
        dismissButton: .default(Text(Strings.OKString))
      )
    }
    .onChange(of: allowanceKind) { allowanceKind in
      if allowanceKind != .customAllowance {
        isFieldFocused = false
        resignFirstResponder()
      }
    }
  }
  
  private func resignFirstResponder() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

#if DEBUG
struct EditPermissionsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      EditPermissionsView(
        proposedAllowance: WalletConstants.MAX_UINT256,
        confirmationStore: .previewStore,
        keyringStore: .previewStoreWithWalletCreated,
        networkStore: .previewStore
      )
    }
  }
}
#endif
