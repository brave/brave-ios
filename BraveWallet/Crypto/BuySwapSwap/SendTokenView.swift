// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import struct Shared.Strings
import BraveUI

struct SendTokenView: View {
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore
  @ObservedObject var sendTokenStore: SendTokenStore
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  @State private var amountInput = ""
  @State private var quickAmount: ShortcutAmountGrid.Amount? {
    didSet {
      if let _ = quickAmount {
        // TODO: compute using `sendTokenStore.selectedSendTokenBalance` and `quickAmount` if there is one and update `amountInput`
      }
    }
  }
  @State private var sendAddress = ""
  
  @ScaledMetric var length: CGFloat = 16.0
  @ScaledMetric var recentCircleLength: CGFloat = 24.0
  @ScaledMetric var recentIconLength: CGFloat = 14.0
  
  var body: some View {
    NavigationView {
      Form {
        Section(
          header: AccountPicker(
            keyringStore: keyringStore,
            networkStore: networkStore
          )
            .listRowBackground(Color.clear)
            .resetListHeaderStyle()
            .padding(.top)
            .padding(.bottom, -16) // Get it a bit closer
        ) {
        }
        Section(
          header: WalletListHeaderView(title: Text(Strings.Wallet.sendCryptoFromTitle))
        ) {
          NavigationLink(destination: SendTokenSearchView(sendTokenStore: sendTokenStore)) {
            HStack {
              if let token = sendTokenStore.selectedSendToken {
                AssetIconView(token: token, length: 26)
              }
              Text(sendTokenStore.selectedSendToken?.symbol ?? "")
                .font(.title3.weight(.semibold))
                .foregroundColor(Color(.braveLabel))
              Spacer()
              Text(sendTokenStore.selectedSendTokenBalance ?? "")
                .font(.title3.weight(.semibold))
                .foregroundColor(Color(.braveLabel))
            }
            .padding(.vertical, 8)
          }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
        Section(
          header: WalletListHeaderView(title: Text(String.localizedStringWithFormat(Strings.Wallet.sendCryptoAmountTitle, sendTokenStore.selectedSendToken?.symbol ?? ""))),
          footer: ShortcutAmountGrid(action: { amount in
            quickAmount = amount
          })
          .listRowInsets(.zero)
          .padding(.bottom, 8)
        ) {
          TextField(String.localizedStringWithFormat(Strings.Wallet.sendCryptoAmountPlaceholder, sendTokenStore.selectedSendToken?.symbol ?? ""), text: $amountInput)
            .keyboardType(.decimalPad)
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
        Section(
          header: WalletListHeaderView(title: Text(Strings.Wallet.sendCryptoToTitle))
        ) {
          HStack(spacing: 24.0) {
            TextField(Strings.Wallet.sendCryptoAddressPlaceholder, text: $sendAddress)
            Button(action: {}) {
              Image("brave.clipboard")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: length, height: length)
                .foregroundColor(Color(.primaryButtonTint))
            }
            Button(action: {}) {
              Image("qr_code_button")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: length, height: length)
                .foregroundColor(Color(.primaryButtonTint))
            }
          }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
        /*
         * TODO: Will bring this section back when we know what to do with `recent`
         *
        Section(
          header: WalletListHeaderView(title: Text("Recent"))
        ) {
          HStack {
            ZStack {
              Circle()
                .frame(width: recentCircleLength, height: recentCircleLength)
                .foregroundColor(Color(.secondaryButtonTint))
              Image("menu-crypto")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: recentIconLength, height: recentIconLength)
                .foregroundColor(Color(.primaryButtonTint))
            }
            Text("bc1qaq...mafs4e")
              .font(.body)
              .foregroundColor(Color(.braveLabel))
          }
        }
        .listRowBackground(Color(.clear))
        */
        Section(
          header: HStack {
            Button(action: {}) {
              Text(Strings.Wallet.sendCryptoPreviewButtonTitle)
            }
              .buttonStyle(BraveFilledButtonStyle(size: .normal))
              .frame(maxWidth: .infinity)
          }
            .resetListHeaderStyle()
            .listRowBackground(Color(.clear))
        ) {
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
      }
      .navigationTitle(Strings.Wallet.send)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .cancellationAction) {
          Button(action: {
            presentationMode.dismiss()
          }) {
            Text(Strings.CancelString)
              .foregroundColor(Color(.braveOrange))
          }
        }
      }
    }
    .onAppear {
      sendTokenStore.fetchAssets()
    }
  }
}

struct SendTokenView_Previews: PreviewProvider {
    static var previews: some View {
      SendTokenView(
        keyringStore: .previewStoreWithWalletCreated,
        networkStore: .previewStore,
        sendTokenStore: .previewStore
      )
        .previewColorSchemes()
    }
}
