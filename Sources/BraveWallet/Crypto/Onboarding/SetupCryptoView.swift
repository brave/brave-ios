/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftUI
import Introspect
import DesignSystem
import Strings

struct SetupCryptoView: View {
  @ObservedObject var keyringStore: KeyringStore

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        HStack {
          Image("wallet-brave-logo", bundle: .module)
          Divider()
            .frame(height: 14)
          Text("Wallet")
            .font(.title3.weight(.medium))
            .foregroundColor(.primary)
        }
        VStack(spacing: 14) {
          Text(Strings.Wallet.setupCryptoTitle)
            .foregroundColor(.primary)
            .font(.largeTitle)
          Text(Strings.Wallet.setupCryptoSubtitle)
            .foregroundColor(.secondary)
            .font(.headline)
        }
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
        VStack(spacing: 24) {
          NavigationLink(destination: CreateWalletContainerView(keyringStore: keyringStore)) {
            HStack(alignment: .top, spacing: 16) {
              Image("wallet-add", bundle: .module)
                .frame(width: 24, height: 24)
                .background(Color(.braveDisabled).opacity(0.5))
                .clipShape(Circle())
              VStack(alignment: .leading, spacing: 12) {
                Text("Need a new wallet?")
                  .font(.title3.weight(.medium))
                  .foregroundColor(.primary)
                Text("Get started with Brave Wallet within minutes")
                  .font(.headline)
                  .foregroundColor(.secondary)
              }
              Spacer()
            }
            .padding(28)
            .background(Color.white)
            .cornerRadius(16)
            .frame(maxWidth: .infinity)
          }
          NavigationLink(destination: RestoreWalletContainerView(keyringStore: keyringStore)) {
            HStack(alignment: .top, spacing: 16) {
              Image("wallet-import", bundle: .module)
                .frame(width: 24, height: 24)
                .background(Color(.braveDisabled).opacity(0.5))
                .clipShape(Circle())
              VStack(alignment: .leading, spacing: 12) {
                Text("Already have a wallet?")
                  .font(.title3.weight(.medium))
                  .foregroundColor(.primary)
                Text("Import your existing wallet")
                  .font(.headline)
                  .foregroundColor(.secondary)
                HStack(spacing: 14) {
                  Group {
                    Image(braveSystemName: "leo.social.brave-favicon")
                      .renderingMode(.template)
                      .foregroundColor(Color(.braveOrange))
                    Image("wallet-phantom", bundle: .module)
                    Image("wallet-metamask", bundle: .module)
                    Image("wallet-coinbase", bundle: .module)
                  }
                  .frame(width: 20, height: 20)
                }
              }
              Spacer()
            }
            .padding(28)
            .background(Color.white)
            .cornerRadius(16)
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(24)
    }
    .padding(.top, 80)
    .background(
      Image("wallet-background", bundle: .module)
    )
    .edgesIgnoringSafeArea(.all)
    .accessibilityEmbedInScrollView()
    .navigationTitle(Strings.Wallet.cryptoTitle)
    .navigationBarTitleDisplayMode(.inline)
    .introspectViewController { vc in
      vc.navigationItem.backButtonTitle = Strings.Wallet.setupCryptoButtonBackButtonTitle
      vc.navigationItem.backButtonDisplayMode = .minimal
    }
  }
}

#if DEBUG
struct SetupCryptoView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      SetupCryptoView(keyringStore: .previewStore)
    }
    .previewLayout(.sizeThatFits)
    .previewColorSchemes()
  }
}
#endif
