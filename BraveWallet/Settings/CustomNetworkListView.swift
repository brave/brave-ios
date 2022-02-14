// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import Shared

// Modifier workaround for FB9812596 to avoid crashing on iOS 14 on Release builds
@available(iOS 15.0, *)
private struct SwipeActionsViewModifier_FB9812596: ViewModifier {
  var action: () -> Void
  
  func body(content: Content) -> some View {
    content
      .swipeActions(edge: .trailing) {
        Button(role: .destructive, action: action) {
          Label(Strings.Wallet.delete, systemImage: "trash")
        }
      }
  }
}

struct CustomNetworkListView: View {
  @ObservedObject var networkStore: NetworkStore
  @State private var isPresentingNetworkDetails: CustomNetworkDetails?
  @Environment(\.presentationMode) @Binding private var presentationMode
  @Environment(\.sizeCategory) private var sizeCategory
  
  private struct CustomNetworkDetails: Identifiable {
    var isEditMode: Bool
    var network: BraveWallet.EthereumChain?
    var id: String {
      "\(isEditMode)"
    }
  }
  
  var body: some View {
    Group {
      if networkStore.ethereumChains.filter({ $0.isCustom }).isEmpty {
        ZStack {
          Color(.braveGroupedBackground)
            .ignoresSafeArea()
          Text(Strings.Wallet.noNetworks)
            .font(.headline.weight(.medium))
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .foregroundColor(Color(.secondaryBraveLabel))
        }
      } else {
        List {
          Section {
            ForEach(networkStore.ethereumChains.filter({ $0.isCustom })) { network in
              Button(action: {
                isPresentingNetworkDetails = .init(isEditMode: true, network: network)
              }) {
                VStack(alignment: .leading, spacing: 5) {
                  Text(network.chainName)
                    .foregroundColor(Color(.braveLabel))
                    .font(.callout)
                  Group {
                    if sizeCategory.isAccessibilityCategory {
                      VStack(alignment: .leading) {
                        Text(network.id)
                        Text(network.rpcUrls.first ?? "")
                      }
                    } else {
                      HStack {
                        Text(network.id)
                        Text(network.rpcUrls.first ?? "")
                      }
                    }
                  }
                  .foregroundColor(Color(.secondaryBraveLabel))
                  .font(.footnote)
                }
              }
              .osAvailabilityModifiers { content in
                if #available(iOS 15.0, *) {
                  content
                    .modifier(SwipeActionsViewModifier_FB9812596 {
                      networkStore.removeCustomNetwork(network) { _ in }
                    })
                } else {
                  content
                    .contextMenu {
                      Button {
                        networkStore.removeCustomNetwork(network) { _ in }
                      } label: {
                        Label(Strings.Wallet.delete, systemImage: "trash")
                      }
                    }
                }
              }
            }
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
        .padding(.top, 23.0)
        .listStyle(.plain)
        .background(Color(.braveGroupedBackground).edgesIgnoringSafeArea(.bottom))
      }
    }
    .navigationTitle(Strings.Wallet.customNetworksTitle)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .confirmationAction) {
        Button(action: {
          isPresentingNetworkDetails = .init(isEditMode: false)
        }) {
          Label(Strings.Wallet.addCustomNetworkBarItemTitle, systemImage: "plus")
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
      NavigationView {
        CustomNetworkListView(networkStore: .previewStore)
      }
    }
}
#endif
