/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import BraveCore
import Combine
import SwiftUI
import BraveUI
import struct Shared.Strings

struct AccountsView: View {
  var cryptoStore: CryptoStore
  @ObservedObject var keyringStore: KeyringStore
  @State private var navigationController: UINavigationController?
  
  private var primaryAccounts: [BraveWallet.AccountInfo] {
    keyringStore.keyring.accountInfos.filter(\.isPrimary)
  }
  
  private var secondaryAccounts: [BraveWallet.AccountInfo] {
    keyringStore.keyring.accountInfos.filter(\.isImported)
  }
  
  @ViewBuilder
  private func accountView(for account: BraveWallet.AccountInfo) -> some View {
    // Using `NavigationLink` in iOS 14.0 here ends up with a bug where the cell doesn't deselect because
    // the navigation is a UINavigationController and this view is inside of a UIPageViewController
    let view = AccountView(address: account.address, name: account.name)
    let destination = AccountActivityView(
      keyringStore: keyringStore,
      activityStore: cryptoStore.accountActivityStore(for: account),
      networkStore: cryptoStore.networkStore
    )
      .onDisappear {
        cryptoStore.closeAccountActivityStore(for: account)
      }
    if #available(iOS 15.0, *) {
      ZStack {
        view
        NavigationLink(destination: destination) {
          EmptyView()
        }
        .opacity(0) // Design doesnt have a disclosure icon
      }
      .accessibilityAddTraits(.isButton)
      .accessibilityElement(children: .contain)
    } else {
      Button(action: {
        navigationController?.pushViewController(
          UIHostingController(rootView: destination),
          animated: true
        )
      }) {
        view
      }
    }
  }
  
  var body: some View {
    List {
      Section(
        header: AccountsHeaderView(keyringStore: keyringStore)
          .resetListHeaderStyle()
      ) {
      }
      Section(
        header: WalletListHeaderView(
          title: Text(Strings.Wallet.primaryCryptoAccountsTitle)
        )
      ) {
        ForEach(primaryAccounts) { account in
          accountView(for: account)
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
            accountView(for: account)
          }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
    }
    .listStyle(InsetGroupedListStyle())
    .osAvailabilityModifiers { content in
      if #available(iOS 15.0, *) {
        content
      } else {
        content
          .introspectNavigationController { nc in
            navigationController = nc
          }
      }
    }
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
