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
  var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore
  @Binding var selectedNetwork: BraveWallet.NetworkInfo
  @State private var isPresentingAddNetwork: Bool = false
  @State private var isPresentingAddAccount: Bool = false
  @Environment(\.presentationMode) @Binding private var presentationMode
  @Environment(\.buySendSwapDestination) @Binding private var buySendSwapDestination
  
  init(
    style: Style = .`default`,
    keyringStore: KeyringStore,
    networkStore: NetworkStore,
    selectedNetwork: Binding<BraveWallet.NetworkInfo>
  ) {
    self.style = style
    self.keyringStore = keyringStore
    self.networkStore = networkStore
    self._selectedNetwork = selectedNetwork
  }
  
  private var availableChains: [BraveWallet.NetworkInfo] {
    networkStore.allChains.filter { chain in
      if !Preferences.Wallet.showTestNetworks.value {
        var testNetworkChainIdsToRemove = WalletConstants.supportedTestNetworkChainIds
        // Don't remove selected network (possible if selected then disabled showing test networks)
        testNetworkChainIdsToRemove.removeAll(where: { $0 == selectedNetwork.chainId })
        if testNetworkChainIdsToRemove.contains(chain.chainId) {
          return false
        }
      }
      if let destination = buySendSwapDestination {
        if destination.kind != .send {
          return !chain.isCustom
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
    .alert(
      isPresented: Binding(
        get: { networkStore.currentNetworkNeedsAccount },
        set: { isPresenting in
          // alert dismissed, return to previous chain if account not created
          networkStore.returnToPreviousChainIfAccountNotCreated()
        }
      )
    ) {
      Alert(
        title: Text(String.localizedStringWithFormat(Strings.Wallet.createAccountAlertTitle, selectedNetwork.shortChainName)),
        message: Text(Strings.Wallet.createAccountAlertMessage),
        primaryButton: .default(Text(Strings.yes), action: {
          // show create account for `networkStore.selectedChain.coin`
          self.isPresentingAddAccount = true
        }),
        secondaryButton: .cancel(Text(Strings.no))
      )
    }
    .sheet(
      isPresented: Binding(
        get: { isPresentingAddAccount },
        set: { isPresenting in
          if !isPresenting {
            // add account dismissed, return to previous chain if account not created
            networkStore.returnToPreviousChainIfAccountNotCreated()
          }
          self.isPresentingAddAccount = false
        }
      )
    ) {
      NavigationView {
        AddAccountView(keyringStore: keyringStore) // TODO: pass `networkStore.selectedNetwork.coin` to account creation
      }
    }
  }
}

#if DEBUG
struct NetworkPicker_Previews: PreviewProvider {
  static var previews: some View {
    NetworkPicker(
      keyringStore: .previewStoreWithWalletCreated,
      networkStore: .previewStore,
      selectedNetwork: .constant(.mockMainnet)
    )
      .padding()
      .previewLayout(.sizeThatFits)
      .previewColorSchemes()
  }
}
#endif
