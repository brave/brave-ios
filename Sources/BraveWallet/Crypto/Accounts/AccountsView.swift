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
  @State private var isPresentingBackup: Bool = false
  @State private var isPresentingAddAccount: Bool = false

  private var primaryAccounts: [BraveWallet.AccountInfo] {
    keyringStore.allAccounts.filter(\.isPrimary)
  }

  private var secondaryAccounts: [BraveWallet.AccountInfo] {
    keyringStore.allAccounts.filter(\.isImported)
  }

  var body: some View {
    List {
      Section(
        header: AccountsHeaderView(
          keyringStore: keyringStore,
          settingsStore: cryptoStore.settingsStore,
          networkStore: cryptoStore.networkStore,
          isPresentingBackup: $isPresentingBackup,
          isPresentingAddAccount: $isPresentingAddAccount
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
              AccountView(address: account.address, name: account.name, blockieShape: .rectangle)
            }
          }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
      }
      Section(
        header: WalletListHeaderView(
          title: Text(Strings.Wallet.secondaryCryptoAccountsTitle),
          subtitle: Text(Strings.Wallet.secondaryCryptoAccountsSubtitle)
        )
      ) {
        Group {
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
              activityStore: cryptoStore.accountActivityStore(
                for: account,
                observeAccountUpdates: false
              ),
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
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .background(
      Color.clear
        .sheet(isPresented: $isPresentingBackup) {
          NavigationView {
            BackupWalletView(
              password: nil,
              keyringStore: keyringStore
            )
          }
          .navigationViewStyle(StackNavigationViewStyle())
          .environment(\.modalPresentationMode, $isPresentingBackup)
          .accentColor(Color(.braveBlurpleTint))
        }
    )
    .background(
      Color.clear
        .sheet(isPresented: $isPresentingAddAccount) {
          NavigationView {
            AddAccountView(
              keyringStore: keyringStore,
              networkStore: cryptoStore.networkStore
            )
          }
          .navigationViewStyle(StackNavigationViewStyle())
        }
    )
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
