/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import BraveCore
import struct Shared.Strings

extension BraveWallet.EthereumChain {
  var shortChainName: String {
    chainName.split(separator: " ").first?.capitalized ?? chainName
  }
}

struct NetworkPicker: View {
  @ObservedObject var networkStore: NetworkStore
  @State private var isPresentingNetworkList: Bool = false
  
  var body: some View {
    Button(action: { isPresentingNetworkList = true}) {
      HStack {
        Text(networkStore.selectedChain.shortChainName)
          .fontWeight(.bold)
        Image(systemName: "chevron.down.circle")
      }
      .foregroundColor(Color(.bravePrimary))
      .font(.caption.weight(.semibold))
      .padding(.init(top: 6, leading: 12, bottom: 6, trailing: 12))
      .background(
        Color(.secondaryButtonTint)
          .clipShape(Capsule().inset(by: 0.5).stroke())
      )
      .clipShape(Capsule())
      .contentShape(Capsule())
      .animation(nil, value: networkStore.selectedChain)
    }
    .accessibilityLabel(Strings.Wallet.selectedNetworkAccessibilityLabel)
    .accessibilityValue(networkStore.selectedChain.shortChainName)
    .sheet(isPresented: $isPresentingNetworkList) {
      NetworkListView(networkStore: networkStore)
    }
  }
}

#if DEBUG
struct NetworkPicker_Previews: PreviewProvider {
  static var previews: some View {
    NetworkPicker(networkStore: .previewStore)
      .padding()
      .previewLayout(.sizeThatFits)
      .previewColorSchemes()
  }
}
#endif
