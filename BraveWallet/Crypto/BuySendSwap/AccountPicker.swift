// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import struct Shared.Strings

struct AccountPicker: View {
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore
  
  @State private var isPresentingPicker: Bool = false
  @State private var isPresentingAddAccount: Bool = false
  @Environment(\.sizeCategory) private var sizeCategory
  @ScaledMetric private var avatarSize = 24.0
  
  var body: some View {
    Group {
      if sizeCategory.isAccessibilityCategory {
        VStack(alignment: .leading) {
          networkPickerView
          accountPickerView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        HStack {
          accountPickerView
          Spacer()
          networkPickerView
        }
      }
    }
    .sheet(isPresented: $isPresentingPicker) {
      pickerList
    }
  }
  
  private var accountView: some View {
    HStack {
      Blockie(address: keyringStore.selectedAccount.address)
        .frame(width: avatarSize, height: avatarSize)
      VStack(alignment: .leading, spacing: 2) {
        Text(keyringStore.selectedAccount.name)
          .fontWeight(.semibold)
          .foregroundColor(Color(.bravePrimary))
          .multilineTextAlignment(.leading)
        Text(keyringStore.selectedAccount.address.truncatedAddress)
          .foregroundColor(Color(.braveLabel))
          .multilineTextAlignment(.leading)
      }
      .font(.caption)
      Image(systemName: "chevron.down.circle")
        .font(.footnote.weight(.medium))
        .foregroundColor(Color(.primaryButtonTint))
    }
    .padding(.vertical, 6)
  }
  
  private func copyAddress() {
    UIPasteboard.general.string = keyringStore.selectedAccount.address
  }

  @available(iOS, introduced: 14.0, deprecated: 15.0)
  @State private var isPresentingCopyAddressActionSheet: Bool = false
  
  
  @ViewBuilder private var accountPickerView: some View {
    if #available(iOS 15.0, *) {
      Menu {
        Button(action: copyAddress) {
          Label(Strings.Wallet.copyAddressButtonTitle, image: "brave.clipboard")
        }
      } label: {
        accountView
      } primaryAction: {
        isPresentingPicker = true
      }
    } else {
      Button(action: {
        isPresentingPicker = true
      }) {
        accountView
      }
      // Context Menus are not supported inside `List`/`Form` section headers/footers so we must replace
      // this with a long press gesture + action sheet on iOS 14
      .simultaneousGesture(
        LongPressGesture(minimumDuration: 0.3)
          .onEnded { _ in
            isPresentingCopyAddressActionSheet = true
          }
      )
      .actionSheet(isPresented: $isPresentingCopyAddressActionSheet) {
        .init(title: Text(keyringStore.selectedAccount.address), message: nil, buttons: [
          .default(Text(Strings.Wallet.copyAddressButtonTitle), action: copyAddress),
          .cancel()
        ])
      }
    }
  }
  
  private var networkPickerView: some View {
    NetworkPicker(
      networks: networkStore.ethereumChains,
      selectedNetwork: networkStore.selectedChainBinding
    )
  }
  
  private var pickerList: some View {
    NavigationView {
      List {
        Section(
          header: WalletListHeaderView(title: Text(Strings.Wallet.accountsPageTitle))
        ) {
          ForEach(keyringStore.keyring.accountInfos) { account in
            Button(action: {
              keyringStore.selectedAccount = account
              isPresentingPicker = false
            }) {
              AccountView(address: account.address, name: account.name)
            }
          }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
      }
      .navigationTitle(Strings.Wallet.selectAccountTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .cancellationAction) {
          Button(action: { isPresentingPicker = false }) {
            Text(Strings.CancelString)
              .foregroundColor(Color(.braveOrange))
          }
        }
        ToolbarItemGroup(placement: .primaryAction) {
          Button(action: { isPresentingAddAccount = true }) {
            Image(systemName: "plus")
              .foregroundColor(Color(.braveOrange))
          }
        }
      }
      .sheet(isPresented: $isPresentingAddAccount) {
        NavigationView {
          AddAccountView(keyringStore: keyringStore)
        }
        .navigationViewStyle(StackNavigationViewStyle())
      }
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }
}

#if DEBUG
struct AccountPicker_Previews: PreviewProvider {
  static var previews: some View {
    AccountPicker(
      keyringStore: .previewStoreWithWalletCreated,
      networkStore: .previewStore
    )
    .padding()
    .previewLayout(.sizeThatFits)
    .previewSizeCategories()
  }
}
#endif
