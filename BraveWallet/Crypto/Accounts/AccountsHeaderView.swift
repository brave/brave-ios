/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import struct Shared.Strings

struct AccountsHeaderView: View {
  @ObservedObject var keyringStore: KeyringStore
  
  @State private var isPresentingBackup: Bool = false
  @State private var isPresentingAddAccount: Bool = false
  
  var body: some View {
    HStack {
      Button(action: { isPresentingBackup = true }) {
        HStack {
          Image("brave.safe")
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
        Button(action: { isPresentingAddAccount = true }) {
          Image(systemName: "plus")
        }
        .background(
          Color.clear
            .sheet(isPresented: $isPresentingAddAccount) {
              NavigationView {
                AddAccountView(keyringStore: keyringStore)
              }
              .navigationViewStyle(StackNavigationViewStyle())
            }
        )
        NavigationLink(destination: WalletSettingsView(keyringStore: keyringStore)) {
          Image("brave.gear")
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
    AccountsHeaderView(keyringStore: .previewStore)
      .previewLayout(.sizeThatFits)
      .previewColorSchemes()
  }
}
#endif
