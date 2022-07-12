/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import BraveCore
import Combine
import SwiftUI
import BraveUI
import Strings

struct AccountsView: View {
  var cryptoStore: CryptoStore
  @ObservedObject var keyringStore: KeyringStore
  @State private var selectedAccount: BraveWallet.AccountInfo?
  
  @Environment(\.isPresentingCoinTypes) private var isPresentingCoinTypes: Binding<Bool>

  private var primaryAccounts: [BraveWallet.AccountInfo] {
    keyringStore.keyring.accountInfos.filter(\.isPrimary)
  }

  private var secondaryAccounts: [BraveWallet.AccountInfo] {
    keyringStore.keyring.accountInfos.filter(\.isImported)
  }

  var body: some View {
    List {
      Section(
        header: AccountsHeaderView(
          keyringStore: keyringStore,
          settingsStore: cryptoStore.settingsStore,
          networkStore: cryptoStore.networkStore,
          isPresentingCoinTypes: isPresentingCoinTypes
        )
        .resetListHeaderStyle()
      ) {
      }
      Section(
        header: WalletListHeaderView(
          title: Text(Strings.Wallet.primaryCryptoAccountsTitle)
        )
      ) {
        ForEach(primaryAccounts) { account in
          Button {
            selectedAccount = account
          } label: {
            AddressView(address: account.address) {
              AccountView(address: account.address, name: account.name)
            }
          }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header: WalletListHeaderView(
          title: Text(Strings.Wallet.secondaryCryptoAccountsTitle),
          subtitle: Text(Strings.Wallet.secondaryCryptoAccountsSubtitle)
        )
      ) {
        let accounts = secondaryAccounts
        if accounts.isEmpty {
          Text(Strings.Wallet.noSecondaryAccounts)
            .foregroundColor(Color(.secondaryBraveLabel))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .font(.footnote.weight(.medium))
        } else {
          ForEach(accounts) { account in
            Button {
              selectedAccount = account
            } label: {
              AddressView(address: account.address) {
                AccountView(address: account.address, name: account.name)
              }
            }
          }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
    }
    .background(
      NavigationLink(
        isActive: Binding(
          get: { selectedAccount != nil },
          set: { if !$0 { selectedAccount = nil } }
        ),
        destination: {
          if let account = selectedAccount {
            AccountActivityView(
              keyringStore: keyringStore,
              activityStore: cryptoStore.accountActivityStore(for: account),
              networkStore: cryptoStore.networkStore
            )
            .onDisappear {
              cryptoStore.closeAccountActivityStore(for: account)
            }
          }
        },
        label: {
          EmptyView()
        })
    )
    .listStyle(InsetGroupedListStyle())
  }
}

#if DEBUG
struct AccountsViewController_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      AccountsView(
        cryptoStore: .previewStore,
        keyringStore: .previewStoreWithWalletCreated
      )
    }
    .previewLayout(.sizeThatFits)
    .previewColorSchemes()
  }
}
#endif
