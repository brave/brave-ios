// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import struct Shared.Strings
import BraveUI

struct AccountSelectionRootView: View {
  
  let navigationTitle: String
  let allAccounts: [BraveWallet.AccountInfo]
  let selectedAccounts: [BraveWallet.AccountInfo]
  let selectAccount: (BraveWallet.AccountInfo) -> Void
  
  var body: some View {
    List {
      Section(
        header: WalletListHeaderView(title: Text(Strings.Wallet.accountsPageTitle))
      ) {
        ForEach(allAccounts) { account in
          AccountListRowView(
            account: account,
            selectedAccounts: selectedAccounts
          ) {
            selectAccount(account)
          }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
      }
    }
    .listStyle(.insetGrouped)
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .navigationTitle(navigationTitle)
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct AccountListRowView: View {
  
  var account: BraveWallet.AccountInfo
  var selectedAccounts: [BraveWallet.AccountInfo]
  let didSelect: () -> Void
  
  init(
    account: BraveWallet.AccountInfo,
    selectedAccounts: [BraveWallet.AccountInfo],
    didSelect: @escaping () -> Void
  ) {
    self.account = account
    self.selectedAccounts = selectedAccounts
    self.didSelect = didSelect
  }
  
  private var isSelected: Bool {
    selectedAccounts.contains(where: { $0.id == account.id && $0.coin == account.coin })
  }
  
  private var checkmark: some View {
    Image(braveSystemName: "leo.check.normal")
      .resizable()
      .aspectRatio(contentMode: .fit)
      .hidden(isHidden: !isSelected)
      .foregroundColor(Color(.braveBlurpleTint))
      .frame(width: 14, height: 14)
  }
  
  var body: some View {
    AddressView(address: account.address) {
      Button(action: didSelect) {
        HStack {
          AccountView(address: account.address, name: account.name)
          checkmark
        }
      }
    }
  }
}
