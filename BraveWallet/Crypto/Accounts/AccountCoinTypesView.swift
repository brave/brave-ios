/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import BraveCore
import Strings

struct AccountCoinTypesView: View {
  var action: (BraveWallet.CoinType) -> Void
  var coinTypes: [BraveWallet.CoinType] = WalletConstants.supportedCoinTypes
  
  init(action: @escaping (BraveWallet.CoinType) -> Void) {
    self.action = action
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      ForEach(coinTypes, id: \.self) { type in
        Button(action: { self.action(type) }) {
          VStack(alignment: .leading, spacing: 3) {
            Text(type.localizedTitle)
              .foregroundColor(Color(.bravePrimary))
              .font(.headline)
              .multilineTextAlignment(.leading)
            Text(type.localizedDescription)
              .foregroundColor(Color(.braveLabel))
              .font(.footnote)
              .multilineTextAlignment(.leading)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding([.leading, .trailing], 20)
        }
        if type != coinTypes.last {
          Divider()
            .padding(.leading, 20)
        }
      }
    }
    .padding(.vertical, 20)
    .background(Color(.braveBackground))
  }
}

#if DEBUG
struct AccountCoinTypesView_Previews: PreviewProvider {
  static var previews: some View {
    AccountCoinTypesView(action: { _ in })
      .previewLayout(.sizeThatFits)
      .previewSizeCategories([.large, .accessibilityLarge])
  }
}
#endif
