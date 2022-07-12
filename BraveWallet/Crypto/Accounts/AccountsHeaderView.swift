/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import Strings
import DesignSystem

struct AccountsHeaderView: View {
  @ObservedObject var keyringStore: KeyringStore
  var settingsStore: SettingsStore
  var networkStore: NetworkStore

  @State private var isPresentingBackup: Bool = false
  
  @Binding var isPresentingCoinTypes: Bool

  var body: some View {
    HStack {
      Button(action: { isPresentingBackup = true }) {
        HStack {
          Image(braveSystemName: "brave.safe")
            .foregroundColor(Color(.braveLabel))
          Text(Strings.Wallet.accountBackup)
            .font(.subheadline.weight(.medium))
            .foregroundColor(Color(.braveBlurpleTint))
        }
      }
      .background(
        Color.clear
          .sheet(isPresented: $isPresentingBackup) {
            NavigationView {
              BackupRecoveryPhraseView(keyringStore: keyringStore)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environment(\.modalPresentationMode, $isPresentingBackup)
          }
      )
      Spacer()
      HStack(spacing: 16) {
        Button(action: {
          isPresentingCoinTypes = true
        }) {
          Label(Strings.Wallet.addAccountTitle, systemImage: "plus")
            .labelStyle(.iconOnly)
        }
        NavigationLink(
          destination: WalletSettingsView(
            settingsStore: settingsStore,
            networkStore: networkStore,
            keyringStore: keyringStore)
        ) {
          Label(Strings.Wallet.settings, braveSystemImage: "brave.gear")
            .labelStyle(.iconOnly)
        }
      }
      .foregroundColor(Color(.braveLabel))
    }
    .padding(.top)
  }
}

#if DEBUG
struct AccountsHeaderView_Previews: PreviewProvider {
  static var previews: some View {
    AccountsHeaderView(
      keyringStore: .previewStore,
      settingsStore: .previewStore,
      networkStore: .previewStore,
      isPresentingCoinTypes: .constant(false)
    )
    .previewLayout(.sizeThatFits)
    .previewColorSchemes()
  }
}
#endif
