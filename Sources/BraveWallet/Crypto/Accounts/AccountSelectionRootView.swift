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
  var showsSelectAllButton: Bool
  var selectAccount: (BraveWallet.AccountInfo) -> Void
  
  init(
    navigationTitle: String,
    allAccounts: [BraveWallet.AccountInfo],
    selectedAccounts: [BraveWallet.AccountInfo],
    showsSelectAllButton: Bool,
    selectAccount: @escaping (BraveWallet.AccountInfo) -> Void
  ) {
    self.navigationTitle = navigationTitle
    self.allAccounts = allAccounts
    self.selectedAccounts = selectedAccounts
    self.showsSelectAllButton = showsSelectAllButton
    self.selectAccount = selectAccount
  }
  
  private var allSelected: Bool {
    allAccounts.allSatisfy({ account in
      selectedAccounts.contains(where: { $0.id == account.id && $0.coin == account.coin })
    })
  }
  
  private func selectAllButtonTitle(_ allSelected: Bool) -> String {
    if allSelected {
      return Strings.Wallet.deselectAllButtonTitle
    }
    return Strings.Wallet.selectAllButtonTitle
  }
  
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        HStack {
          Text(Strings.Wallet.accountsPageTitle)
            .font(.body.weight(.semibold))
            .foregroundColor(Color(uiColor: WalletV2Design.textPrimary))
          Spacer()
          if showsSelectAllButton {
            Button(action: {
              if allSelected { // deselect all
                allAccounts.forEach(selectAccount)
              } else { // select all
                let unselectedAccounts = allAccounts
                  .filter { account in
                    !selectedAccounts.contains(
                      where: { $0.id == account.id && $0.coin == account.coin }
                    )
                  }
                unselectedAccounts.forEach(selectAccount)
              }
            }) {
              Text(selectAllButtonTitle(allSelected))
                .font(.callout.weight(.semibold))
                .foregroundColor(Color(uiColor: WalletV2Design.textInteractive))
            }
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
      }
      ForEach(allAccounts) { account in
        AccountListRowView(
          account: account,
          selectedAccounts: selectedAccounts
        ) {
          selectAccount(account)
        }
      }
    }
    .listBackgroundColor(Color(uiColor: WalletV2Design.containerBackground))
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
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    .padding(.horizontal)
    .contentShape(Rectangle())
  }
}
