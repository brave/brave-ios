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
  @Binding var selectedNetwork: BraveWallet.EthereumChain
  @State private var isPresentingNetworkList: Bool = false
  @Environment(\.presentationMode) @Binding private var presentationMode
  @Environment(\.buySendSwapDestination) private var buySendSwapDestination
  
  var body: some View {
    Menu {
      HStack {
        Picker(
          Strings.Wallet.selectedNetworkAccessibilityLabel,
          selection: $selectedNetwork
        ) {
          ForEach(networkStore.ethereumChains.filter({
            if let destination = buySendSwapDestination.wrappedValue {
              if destination.kind != .send {
                return !$0.isCustom
              }
            }
            return true
          })) {
            Text($0.chainName).tag($0)
          }
        }
        Divider()
        Button(action: { isPresentingNetworkList = true }) {
          Label(Strings.Wallet.addCustomNetworkDropdownButtonTitle, systemImage: "plus")
        }
      }
    } label: {
      HStack {
        Text(selectedNetwork.shortChainName)
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
      .animation(nil, value: selectedNetwork)
    }
    .accessibilityLabel(Strings.Wallet.selectedNetworkAccessibilityLabel)
    .accessibilityValue(selectedNetwork.shortChainName)
    .sheet(isPresented: $isPresentingNetworkList) {
      NavigationView {
        CustomNetworkListView(networkStore: networkStore)
          .toolbar {
            ToolbarItemGroup(placement: .cancellationAction) {
              Button(action: {
                isPresentingNetworkList = false
              }) {
                Text(Strings.cancelButtonTitle)
                  .foregroundColor(Color(.braveOrange))
              }
            }
          }
      }
    }
  }
}

#if DEBUG
struct NetworkPicker_Previews: PreviewProvider {
  static var previews: some View {
    NetworkPicker(networkStore: .previewStore, selectedNetwork: .constant(.mainnet))
      .padding()
      .previewLayout(.sizeThatFits)
      .previewColorSchemes()
  }
}
#endif
