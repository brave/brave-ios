// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import struct Shared.Strings
import BraveUI

/// Displays all accounts and allows multiple selection for filtering by accounts.
struct AccountFilterView: View {
  
  @State var accounts: [Selectable<BraveWallet.AccountInfo>]
  let saveAction: ([Selectable<BraveWallet.AccountInfo>]) -> Void
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  private var allSelected: Bool {
    accounts.allSatisfy(\.isSelected)
  }
  
  var body: some View {
    AccountSelectionRootView(
      navigationTitle: "Select Accounts",
      allAccounts: accounts.map(\.model),
      selectedAccounts: accounts.filter(\.isSelected).map(\.model),
      selectAccount: selectAccount
    )
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(action: {
          saveAction(accounts)
          presentationMode.dismiss()
        }) {
          Text(Strings.Wallet.saveButtonTitle)
            .foregroundColor(Color(.braveBlurpleTint))
        }
      }
    }
    .toolbar {
      ToolbarItemGroup(placement: .bottomBar) {
        Spacer()
        Button(action: selectAll) {
          Text(allSelected ? Strings.Wallet.deselectAllButtonTitle : Strings.Wallet.selectAllButtonTitle)
            .foregroundColor(Color(.braveBlurpleTint))
        }
      }
    }
  }
  
  private func selectAccount(_ network: BraveWallet.AccountInfo) {
    DispatchQueue.main.async {
      if let index = accounts.firstIndex(
        where: { $0.model.id == network.id && $0.model.coin == network.coin }
      ) {
        accounts[index] = .init(isSelected: !accounts[index].isSelected, model: accounts[index].model)
      }
    }
  }
  
  private func selectAll() {
    DispatchQueue.main.async {
      accounts = accounts.map {
        .init(isSelected: !allSelected, model: $0.model)
      }
    }
  }
}
