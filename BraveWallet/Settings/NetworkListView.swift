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
      Spacer()
      Image(systemName: "checkmark")
        .opacity(isCurrentNetwork ? 1 : 0)
        .foregroundColor(Color(.braveOrange))
    }
    .font(.callout)
  }
}

// Modifier workaround for FB9812596 to avoid crashing on iOS 14 on Release builds
@available(iOS 15.0, *)
private struct SwipeActionsViewModifier_FB9812596_NetworkList: ViewModifier {
  enum ActionType {
    case delete
    case edit
  }
  var type: ActionType
  var label: String
  var action: () -> Void
  
  func body(content: Content) -> some View {
    content
      .swipeActions(edge: .trailing) {
        Button(role: type == .delete ? .destructive : .cancel, action: action) {
          Label(label, systemImage: type == .delete ? "trash" : "square.and.pencil")
        }
        .tint(type == .edit ? Color(.braveBlurpleTint) : nil)
      }
  }
}

struct NetworkListView: View {
  @ObservedObject var networkStore: NetworkStore
  @State private var isPresentingNetworkDetails: CustomNetworkDetails?
  @Environment(\.presentationMode) @Binding private var presentationMode
  
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
            presentationMode.dismiss()
          }) {
            NetworkCell(
              network: network,
              isCurrentNetwork: network.chainId == networkStore.selectedChainId
            )
          }
          .osAvailabilityModifiers { content in
            if #available(iOS 15.0, *) {
              if network.chainId != networkStore.selectedChainId {
                content
                  .modifier(SwipeActionsViewModifier_FB9812596_NetworkList(
                    type: .delete,
                    label: Strings.Wallet.deleteCustomTokenOrNetwork,
                    action: {
                      networkStore.removeCustomNetwork(network) { _ in }
                    })
                  )
                  .modifier(SwipeActionsViewModifier_FB9812596_NetworkList(
                    type: .edit,
                    label: Strings.Wallet.editCustomNetwork,
                    action: {
                      isPresentingNetworkDetails = .init(isEditMode: true, network: network)
                    })
                  )
              } else {
                content
                  .modifier(SwipeActionsViewModifier_FB9812596_NetworkList(
                    type: .edit,
                    label: Strings.Wallet.editCustomNetwork,
                    action: {
                      isPresentingNetworkDetails = .init(isEditMode: true, network: network)
                    })
                  )
              }
            } else {
              if network.chainId != networkStore.selectedChainId {
                content
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
                content
                  .contextMenu {
                    Button {
                      isPresentingNetworkDetails = .init(isEditMode: true, network: network)
                    } label: {
                      Label(Strings.Wallet.editCustomNetwork, systemImage: "square.and.pencil")
                    }
                  }
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
    .listStyle(PlainListStyle())
    .padding(.top, 23.0)
    .navigationTitle(Strings.Wallet.networkListTitle)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .confirmationAction) {
        Button(action: {
          isPresentingNetworkDetails = .init(isEditMode: false)
        }) {
          Text(Strings.Wallet.add)
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
