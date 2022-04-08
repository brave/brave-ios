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
  
  @State private var customAllowance: String = "0"
  @State private var isShowingAlert = false
  @Environment(\.presentationMode) @Binding private var presentationMode
  @Environment(\.sizeCategory) private var sizeCategory
  
  private var activeTransaction: BraveWallet.TransactionInfo {
    confirmationStore.transactions.first(where: { $0.id == confirmationStore.activeTransactionId }) ?? (confirmationStore.transactions.first ?? .init())
  }
  
  private var customAllowanceAmountInWei: String {
    if customAllowance == Strings.Wallet.editPermissionsApproveUnlimited {
      // when user taps 'Set Unlimited' button we updated `customAllowance` to `Strings.Wallet.editPermissionsApproveUnlimited`
      return WalletConstants.MAX_UINT256
    }
    
    var decimals: Int = 18
    if let contractAddress = activeTransaction.txDataUnion.ethTxData1559?.baseData.to, let token = confirmationStore.token(for: contractAddress, in: networkStore.selectedChain) {
      decimals = Int(token.decimals)
    }
    let weiFormatter = WeiFormatter(decimalFormatStyle: .decimals(precision: decimals))
    let customAllowanceInWei = weiFormatter.weiString(from: customAllowance, radix: .decimal, decimals: decimals) ?? "0"
    return customAllowanceInWei.addingHexPrefix
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
        VStack(alignment: .leading) {
          Text(String.localizedStringWithFormat(Strings.Wallet.editPermissionsProposedAllowanceHeader, confirmationStore.state.symbol))
            .foregroundColor(Color(.bravePrimary))
            .font(.footnote.weight(.semibold))
          TextField("", text: Binding(get: { confirmationStore.state.value }, set: { _ in }))
            .disabled(true)
        }
      }
      
      Section(
        header: Text(Strings.Wallet.editPermissionsCustomAllowanceHeader)
          .foregroundColor(Color(.secondaryBraveLabel))
          .font(.footnote)
          .resetListHeaderStyle()
          .padding(.vertical)
      ) {
        HStack {
          TextField(
            "0.0 \(confirmationStore.state.symbol)",
            text: $customAllowance,
            onEditingChanged: { value in
              if value, customAllowance == Strings.Wallet.editPermissionsApproveUnlimited {
                customAllowance = ""
              }
            }
          )
            .keyboardType(.decimalPad)
            .foregroundColor(Color(.braveLabel))
          if proposedAllowance.caseInsensitiveCompare(WalletConstants.MAX_UINT256) != .orderedSame {
            Button(action: {
              customAllowance = Strings.Wallet.editPermissionsApproveUnlimited
              resignFirstResponder()
            }) {
              Text(Strings.Wallet.editPermissionsSetUnlimited)
                .foregroundColor(Color(.braveBlurpleTint))
                .font(.footnote)
            }
          }
        }
      }
      
      Button(action: {
        confirmationStore.editAllowance(
          txMetaId: activeTransaction.id,
          spenderAddress: activeTransaction.txArgs[safe: 0] ?? "",
          amount: customAllowanceAmountInWei) { success in
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
