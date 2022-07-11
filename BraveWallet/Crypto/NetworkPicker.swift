/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import BraveCore
import BraveShared
import Strings

extension BraveWallet.NetworkInfo {
  var shortChainName: String {
    chainName.split(separator: " ").first?.capitalized ?? chainName
  }
}

struct NetworkPicker: View {
  
  struct Style: Equatable {
    let textColor: UIColor
    let borderColor: UIColor
    
    static let `default` = Style(
      textColor: .bravePrimary,
      borderColor: .secondaryButtonTint
    )
  }
  
  let style: Style
  @ObservedObject var networkStore: NetworkStore
  @Binding var selectedNetwork: BraveWallet.NetworkInfo
  @State private var isPresentingAddNetwork: Bool = false
  @Environment(\.presentationMode) @Binding private var presentationMode
  @Environment(\.buySendSwapDestination) @Binding private var buySendSwapDestination
  
  init(
    style: Style = .`default`,
    networkStore: NetworkStore,
    selectedNetwork: Binding<BraveWallet.NetworkInfo>
  ) {
    self.style = style
    self.networkStore = networkStore
    self._selectedNetwork = selectedNetwork
  }
  
  private var availableChains: [BraveWallet.NetworkInfo] {
    networkStore.ethereumChains.filter {
      if !Preferences.Wallet.showTestNetworks.value,
          WalletConstants.supportedTestNetworkChainIds.contains($0.chainId) {
        return false
      }
      if let destination = buySendSwapDestination {
        if destination.kind != .send {
          return !$0.isCustom
        }
      }
      return true
    }
  }
  
  var body: some View {
    Menu {
      Picker(
        Strings.Wallet.selectedNetworkAccessibilityLabel,
        selection: $selectedNetwork
      ) {
        ForEach(availableChains) {
          Text($0.chainName).tag($0)
        }
      }
      Divider()
      Button(action: { isPresentingAddNetwork = true }) {
        Label(Strings.Wallet.addCustomNetworkDropdownButtonTitle, systemImage: "plus")
      }
    } label: {
      HStack {
        Text(selectedNetwork.shortChainName)
          .fontWeight(.bold)
        Image(systemName: "chevron.down.circle")
      }
      .foregroundColor(Color(style.textColor))
      .font(.caption.weight(.semibold))
      .padding(.init(top: 6, leading: 12, bottom: 6, trailing: 12))
      .background(
        Color(style.borderColor)
          .clipShape(Capsule().inset(by: 0.5).stroke())
      )
      .clipShape(Capsule())
      .contentShape(Capsule())
      .animation(nil, value: selectedNetwork)
    }
    .accessibilityLabel(Strings.Wallet.selectedNetworkAccessibilityLabel)
    .accessibilityValue(selectedNetwork.shortChainName)
    .sheet(isPresented: $isPresentingAddNetwork) {
      NavigationView {
        CustomNetworkDetailsView(networkStore: networkStore, model: .init())
      }
    }
  }
}

#if DEBUG
struct NetworkPicker_Previews: PreviewProvider {
  static var previews: some View {
    NetworkPicker(networkStore: .previewStore, selectedNetwork: .constant(.mockMainnet))
      .padding()
      .previewLayout(.sizeThatFits)
      .previewColorSchemes()
  }
}
#endif
