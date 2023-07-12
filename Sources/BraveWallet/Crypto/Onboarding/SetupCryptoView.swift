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
  
  @Environment(\.colorScheme) private var colorScheme: ColorScheme

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        VStack(spacing: 14) {
          Text(Strings.Wallet.setupCryptoTitle)
            .foregroundColor(.primary)
            .font(.largeTitle)
          Text(Strings.Wallet.setupCryptoSubtitle)
            .foregroundColor(.secondary)
            .font(.subheadline)
        }
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
        VStack(spacing: 24) {
          NavigationLink(destination: CreateWalletContainerView(keyringStore: keyringStore)) {
            HStack(alignment: .top, spacing: 16) {
              Image("wallet-add", bundle: .module)
                .frame(width: 32, height: 32)
                .background(Color(.braveDisabled).opacity(0.5))
                .clipShape(Circle())
              VStack(alignment: .leading, spacing: 12) {
                Text(Strings.Wallet.setupCryptoCreateNewTitle)
                  .font(.title3.weight(.medium))
                  .foregroundColor(.primary)
                Text(Strings.Wallet.setupCryptoCreateNewSubTitle)
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }
              .multilineTextAlignment(.leading)
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
                .frame(width: 32, height: 32)
                .background(Color(.braveDisabled).opacity(0.5))
                .clipShape(Circle())
              VStack(alignment: .leading, spacing: 12) {
                Group {
                  Text(Strings.Wallet.setupCryptoRestoreTitle)
                    .font(.title3.weight(.medium))
                    .foregroundColor(.primary)
                  Text(Strings.Wallet.setupCryptoRestoreSubTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.leading)
                HStack(spacing: 14) {
                  Group {
                    Image(braveSystemName: "leo.social.brave-favicon-fullheight")
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
        .resizable()
        .aspectRatio(contentMode: .fill)
    )
    .edgesIgnoringSafeArea(.all)
    .accessibilityEmbedInScrollView()
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
