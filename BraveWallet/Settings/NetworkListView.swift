// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import Shared

struct NetworkCell: View {
  var network: BraveWallet.EthereumChain
  var isCurrentNetwork: Bool
  
  var body: some View {
    HStack {
      Text(network.chainName)
        .foregroundColor(Color(.braveLabel))
      Spacer()
      Image(systemName: "checkmark")
        .opacity(isCurrentNetwork ? 1 : 0)
        .foregroundColor(Color(.braveOrange))
    }
    .font(.callout)
  }
}

struct NetworkListView: View {
  @ObservedObject var networkStore: NetworkStore
  @State private var isPresentingNetworkDetails: CustomNetworkDetails?
  @Environment(\.presentationMode) @Binding private var presentationMode
  @Environment(\.buySendSwapDestination) private var buySendSwapDestination
  
  private struct CustomNetworkDetails: Identifiable {
    var isEditMode: Bool
    var network: BraveWallet.EthereumChain?
    var id: String {
      "\(isEditMode)"
    }
  }
  
  var body: some View {
    List {
      ForEach(networkStore.ethereumChains.filter({ network in
        if let destination = buySendSwapDestination.wrappedValue {
          if destination.kind != .send {
            return !network.isCustom
          }
        }
        return true
      })) { network in
        if network.isCustom {
          if network.chainId != networkStore.selectedChainId {
            Button(action: {
              networkStore.updateSelectedNetwork(network)
              presentationMode.dismiss()
            }) {
              NetworkCell(
                network: network,
                isCurrentNetwork: network.chainId == networkStore.selectedChainId
              )
            }
            .contextMenu {
              Button {
                networkStore.removeCustomNetwork(network) { _ in }
              } label: {
                Label(Strings.Wallet.deleteCustomTokenOrNetwork, systemImage: "trash")
              }
              Button {
                isPresentingNetworkDetails = .init(isEditMode: true, network: network)
              } label: {
                Label(Strings.Wallet.editCustomNetwork, systemImage: "square.and.pencil")
              }
            }
          } else {
            Button(action: {
              networkStore.updateSelectedNetwork(network)
              presentationMode.dismiss()
            }) {
              NetworkCell(
                network: network,
                isCurrentNetwork: network.chainId == networkStore.selectedChainId
              )
            }
            .contextMenu {
              Button {
                isPresentingNetworkDetails = .init(isEditMode: true, network: network)
              } label: {
                Label(Strings.Wallet.editCustomNetwork, systemImage: "square.and.pencil")
              }
            }
          }
        } else {
          Button(action: {
            networkStore.updateSelectedNetwork(network)
            presentationMode.dismiss()
          }) {
            NetworkCell(
              network: network,
              isCurrentNetwork: network.chainId == networkStore.selectedChainId
            )
          }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
    }
    .listStyle(.grouped)
    .navigationTitle(Strings.Wallet.networkListTitle)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .confirmationAction) {
        Button(action: {
          isPresentingNetworkDetails = .init(isEditMode: false)
        }) {
          Label(Strings.Wallet.addCustomNetworkTitle, systemImage: "plus")
            .foregroundColor(Color(.braveOrange))
        }
      }
      ToolbarItemGroup(placement: .cancellationAction) {
        Button(action: {
          presentationMode.dismiss()
        }) {
          Text(Strings.cancelButtonTitle)
            .foregroundColor(Color(.braveOrange))
        }
      }
    }
    .sheet(item: $isPresentingNetworkDetails) { details in
      NavigationView {
        CustomNetworkDetailsView(
          networkStore: networkStore,
          network: details.network
        )
      }
      .navigationViewStyle(StackNavigationViewStyle())
    }
  }
}

#if DEBUG
struct CustomNetworksView_Previews: PreviewProvider {
    static var previews: some View {
      NetworkListView(networkStore: .previewStore)
    }
}
#endif
