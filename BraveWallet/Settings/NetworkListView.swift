// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore

struct NetworkCell: View {
  var network: BraveWallet.EthereumChain
  var isCurrentNetwork: Bool
  
  var body: some View {
    HStack {
      Text(network.chainName)
        .font(.callout)
      Spacer()
      Image(systemName: "checkmark")
        .opacity(isCurrentNetwork ? 1 : 0)
        .font(.callout)
        .foregroundColor(Color(.braveOrange))
    }
  }
}

struct NetworkListView: View {
  @ObservedObject var networkStore: NetworkStore
  @State private var isPresentingNetworkDetails: CustomNetworkDetails?
  
  private struct CustomNetworkDetails: Identifiable {
    var isEditMode: Bool
    var network: BraveWallet.EthereumChain?
    var id: String {
      "\(isEditMode)"
    }
  }
  
  var body: some View {
    List {
      ForEach(networkStore.ethereumChains) { network in
        if network.isCustom {
          Button(action: {
            networkStore.updateSelectedNetwork(network)
          }) {
            NetworkCell(
              network: network,
              isCurrentNetwork: network.chainId == networkStore.selectedChainId
            )
          }
          .osAvailabilityModifiers { content in
            if #available(iOS 15.0, *) {
              content
                .swipeActions(edge: .trailing) {
                  Button(role: .destructive) {
                    networkStore.removeCustomNetwork(network)
                  } label: {
                    Label("Delete custom network", systemImage: "trash")
                  }
                }
                .swipeActions(edge: .trailing) {
                  Button(role: .cancel) {
                    isPresentingNetworkDetails = .init(isEditMode: true, network: network)
                  } label: {
                    Label("Edit custom network", systemImage: "square.and.pencil")
                  }
                  .tint(Color(.braveBlurpleTint))
                }
            } else {
              content
                .contextMenu {
                  Button {
                    networkStore.removeCustomNetwork(network)
                  } label: {
                    Label("Delete custom network", systemImage: "trash")
                  }
                  Button {
                    isPresentingNetworkDetails = .init(isEditMode: true, network: network)
                  } label: {
                    Label("Edit custom network", systemImage: "square.and.pencil")
                  }
                }
            }
          }
        } else {
          Button(action: {
            networkStore.updateSelectedNetwork(network)
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
    .listStyle(PlainListStyle())
    .padding(.top, 23.0)
    .navigationBarTitle("Select Network")
    .toolbar {
      ToolbarItemGroup(placement: .confirmationAction) {
        Button(action: {
          isPresentingNetworkDetails = .init(isEditMode: false)
        }) {
          Text("Add")
            .foregroundColor(Color(.braveOrange))
        }
      }
    }
    .sheet(item: $isPresentingNetworkDetails) { details in
      NavigationView {
        CustomNetworkDetailsView(
          networkStore: networkStore,
          isEditMode: details.isEditMode,
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
