// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import struct Shared.Strings
import BraveShared
import BraveUI
import Data

struct EditSiteConnectionView: View {
  @ObservedObject var keyringStore: KeyringStore
  var originURL: URL
  var onDismiss: (_ permittedAccounts: [String]) -> Void
  
  @ScaledMetric private var faviconSize = 48
  
  @State private var permittedAccounts: [String] = []
  
  enum EditAction {
    case connect
    case disconnect
    case `switch`
    
    var title: String {
      switch self {
      case .connect:
        return Strings.Wallet.editSiteConnectionAccountActionConnect
      case .disconnect:
        return Strings.Wallet.editSiteConnectionAccountActionDisconnect
      case .switch:
        return Strings.Wallet.editSiteConnectionAccountActionSwitch
      }
    }
  }
  
  private func editAction(for account: BraveWallet.AccountInfo) -> EditAction {
    if permittedAccounts.contains(account.address) {
      if keyringStore.selectedAccount.id == account.id {
        // Disconnect - Connected and selected account
        return .disconnect
      } else {
        // Switch - Connected but not selected account
        return .`switch`
      }
    } else {
      // Connect - Not connected
      return .connect
    }
  }
  
  var body: some View {
    NavigationView {
      Form {
        Section {
          ForEach(keyringStore.keyring.accountInfos, id: \.self) { account in
            let action = editAction(for: account)
            HStack {
              AccountView(address: account.address, name: account.name)
              Spacer()
              Button {
                switch action {
                case .connect:
                  Domain.setEthereumPermissions(forUrl: originURL, account: account.address, grant: true)
                  permittedAccounts.append(account.address)
                  keyringStore.selectedAccount = account
                case .disconnect:
                  Domain.setEthereumPermissions(forUrl: originURL, account: account.address, grant: false)
                  permittedAccounts.removeAll(where: { $0 == account.address })
                  
                  if let firstAllowedAdd = permittedAccounts.first, let firstAllowedAccount = keyringStore.keyring.accountInfos.first(where: { $0.id == firstAllowedAdd }) {
                    keyringStore.selectedAccount = firstAllowedAccount
                  }
                case .switch:
                  keyringStore.selectedAccount = account
                }
              } label: {
                Text(action.title)
                  .foregroundColor(Color(.braveBlurpleTint))
                  .font(.footnote.weight(.semibold))
              }
            }
          }
        } header: {
          HStack(spacing: 12) {
            Image(systemName: "globe")
              .frame(width: faviconSize, height: faviconSize)
              .background(Color(.braveDisabled))
              .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
              Text(verbatim: originURL.absoluteDisplayString)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(.bravePrimary))
              Text(String.localizedStringWithFormat(Strings.Wallet.editSiteConnectionConnectedAccount, permittedAccounts.count, permittedAccounts.count == 1 ? Strings.Wallet.editSiteConnectionAccountSingular : Strings.Wallet.editSiteConnectionAccountPlural))
                .font(.footnote)
                .foregroundColor(Color(.braveLabel))
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .resetListHeaderStyle()
          .padding(.vertical)
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
      }
      .navigationTitle(Strings.Wallet.editSiteConnectionScreenTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .confirmationAction) {
          Button {
            onDismiss(permittedAccounts)
          } label: {
            Text(Strings.done)
              .foregroundColor(Color(.braveOrange))
          }
        }
      }
      .onAppear {
        if let accounts = Domain.ethereumPermissions(forUrl: originURL) {
          permittedAccounts = accounts
        }
      }
    }
  }
}

#if DEBUG
struct EditSiteConnectionView_Previews: PreviewProvider {
  static var previews: some View {
    EditSiteConnectionView(
      keyringStore: {
        let store = KeyringStore.previewStoreWithWalletCreated
        store.addPrimaryAccount("Account 2", completion: nil)
        store.addPrimaryAccount("Account 3", completion: nil)
        return store
      }(),
      originURL: URL(string: "https://app.uniswap.org")!,
      onDismiss: { _ in }
    )
  }
}
#endif
