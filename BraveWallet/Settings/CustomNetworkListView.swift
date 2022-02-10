// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import Shared

struct CustomNetworkListView: View {
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
      Section {
        Group {
          if networkStore.ethereumChains.filter({ $0.isCustom }).isEmpty {
            Text("No networks added")
              .font(.footnote.weight(.medium))
              .frame(maxWidth: .infinity)
              .multilineTextAlignment(.center)
              .foregroundColor(Color(.secondaryBraveLabel))
          } else {
            ForEach(networkStore.ethereumChains.filter({ $0.isCustom })) { network in
              Text(network.chainName)
                .foregroundColor(Color(.braveLabel))
                .font(.callout)
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
            }
          }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
      }
    }
    .listStyle(.grouped)
    .navigationTitle(Strings.Wallet.addCustomNetworkTitle)
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
struct CustomNetworkListView_Previews: PreviewProvider {
    static var previews: some View {
      CustomNetworkListView(networkStore: .previewStore)
    }
}
#endif
