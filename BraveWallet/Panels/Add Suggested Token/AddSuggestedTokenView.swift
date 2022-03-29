// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import struct Shared.Strings
import BraveCore
import BraveUI

struct AddSuggestedTokenView: View {
  var token: BraveWallet.BlockchainToken
  var networkStore: NetworkStore
  
  var onApprove: () -> Void
  var onCancel: () -> Void
  
  @Environment(\.sizeCategory) private var sizeCategory
  @Environment(\.openWalletURLAction) private var openWalletURL
  
  var body: some View {
    ScrollView(.vertical) {
      VStack(spacing: 44) {
        Text(Strings.Wallet.addSuggestedTokenSubtitle)
          .foregroundColor(Color(.braveLabel))
          .font(.subheadline)
        VStack {
          AssetIconView(token: token, length: 64)
          Text(token.symbol)
            .font(.headline)
            .foregroundColor(Color(.bravePrimary))
          Button(action: {
            if let baseURL = self.networkStore.selectedChain.blockExplorerUrls.first.map(URL.init(string:)),
               let url = baseURL?.appendingPathComponent("token/\(token.contractAddress)") {
              openWalletURL?(url)
            }
          }) {
            HStack {
              Text(token.contractAddress.truncatedAddress)
              Image(systemName: "arrow.up.forward.square")
            }
            .font(.subheadline)
            .foregroundColor(Color(.braveBlurpleTint))
          }
        }
        actionButtonContainer
      }
      .frame(maxWidth: .infinity)
      .padding(.top, 64)
      .padding([.leading, .trailing, .bottom])
    }
    .background(Color(.braveGroupedBackground).ignoresSafeArea())
    .navigationTitle(Strings.Wallet.addSuggestedTokenTitle)
    .navigationBarTitleDisplayMode(.inline)
  }
  
  @ViewBuilder private var actionButtonContainer: some View {
    if sizeCategory.isAccessibilityCategory {
      VStack {
        actionButtons
      }
    } else {
      HStack {
        actionButtons
      }
    }
  }

  @ViewBuilder private var actionButtons: some View {
    Button(action: onCancel) {
      HStack {
        Image(systemName: "xmark")
        Text(Strings.cancelButtonTitle)
      }
    }
    .buttonStyle(BraveOutlineButtonStyle(size: .large))
    Button(action: onApprove) {
      HStack {
        Image("brave.checkmark.circle.fill")
        Text(Strings.Wallet.add)
          .multilineTextAlignment(.center)
      }
    }
    .buttonStyle(BraveFilledButtonStyle(size: .large))
  }
}

#if DEBUG
struct AddSuggestedTokenView_Previews: PreviewProvider {
  static var previews: some View {
    AddSuggestedTokenView(
      token: .previewToken,
      networkStore: .previewStore,
      onApprove: {},
      onCancel: {}
    )
  }
}
#endif
