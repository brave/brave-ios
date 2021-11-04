// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import Shared

private struct TokenView: View {
  var token: BraveWallet.ERCToken
  
  var body: some View {
    HStack(spacing: 8) {
      AssetIconView(token: token)
      VStack(alignment: .leading) {
        Text(token.name)
          .fontWeight(.semibold)
          .foregroundColor(Color(.bravePrimary))
        Text(token.symbol.uppercased())
          .foregroundColor(Color(.secondaryBraveLabel))
      }
      .font(.footnote)
    }
    .padding(.vertical, 8)
  }
}

struct SwapTokenSearchView: View {
  @ObservedObject var swapTokenStore: SwapTokenStore

  @Environment(\.presentationMode) @Binding private var presentationMode
  
  enum SwapSearchType {
    case fromToken
    case toToken
  }
  
  var searchType: SwapSearchType
  
  var body: some View {
    let excludedToken = searchType == .fromToken ? swapTokenStore.selectedToToken : swapTokenStore.selectedFromToken
    TokenList(tokens: swapTokenStore.allTokens.filter { $0.symbol != excludedToken?.symbol }) { token in
      Button(action: {
        if searchType == .fromToken {
          swapTokenStore.selectedFromToken = token
        } else {
          swapTokenStore.selectedToToken = token
        }
        presentationMode.dismiss()
      }) {
        TokenView(token: token)
      }
    }
    .navigationTitle(Strings.Wallet.searchTitle)
  }
}

#if DEBUG
struct SwapTokenSearchView_Previews: PreviewProvider {
  static var previews: some View {
    SwapTokenSearchView(swapTokenStore: .previewStore,
                        searchType: .fromToken
    )
  }
}
#endif
