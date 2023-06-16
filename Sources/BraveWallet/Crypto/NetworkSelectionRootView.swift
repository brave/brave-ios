/* Copyright 2022 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import BraveCore
import SwiftUI

struct NetworkPresentation: Equatable, Hashable, Identifiable {
  let network: BraveWallet.NetworkInfo
  let subNetworks: [BraveWallet.NetworkInfo]
  let isPrimaryNetwork: Bool
  
  var id: String {
    network.id
  }
  
  init(
    network: BraveWallet.NetworkInfo,
    subNetworks: [BraveWallet.NetworkInfo],
    isPrimaryNetwork: Bool
  ) {
    self.network = network
    self.subNetworks = subNetworks
    self.isPrimaryNetwork = isPrimaryNetwork
  }
}

struct NetworkSelectionRootView: View {
  
  var navigationTitle: String
  var selectedNetworks: [BraveWallet.NetworkInfo]
  var primaryNetworks: [NetworkPresentation]
  var secondaryNetworks: [NetworkPresentation]
  var selectNetwork: (BraveWallet.NetworkInfo) -> Void
  @State private var detailNetwork: NetworkPresentation?
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  var body: some View {
    List {
      Section {
        ForEach(primaryNetworks) { presentation in
          Button(action: { selectNetwork(presentation.network) }) {
            NetworkRowView(
              presentation: presentation,
              selectedNetworks: selectedNetworks,
              detailTappedHandler: {
                detailNetwork = presentation
              }
            )
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
      }
      Section(content: {
        ForEach(secondaryNetworks) { presentation in
          Button(action: { selectNetwork(presentation.network) }) {
            NetworkRowView(
              presentation: presentation,
              selectedNetworks: selectedNetworks
            )
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
      }, header: {
        WalletListHeaderView(title: Text(Strings.Wallet.networkSelectionSecondaryNetworks))
      })
    }
    .listStyle(.insetGrouped)
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .navigationTitle(navigationTitle)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .cancellationAction) {
        Button(action: { presentationMode.dismiss() }) {
          Text(Strings.cancelButtonTitle)
            .foregroundColor(Color(.braveBlurpleTint))
        }
      }
    }
    .background(
      NavigationLink(
        isActive: Binding(
          get: { detailNetwork != nil },
          set: { if !$0 { detailNetwork = nil } }
        ),
        destination: {
          if let detailNetwork = detailNetwork {
            NetworkSelectionDetailView(
              networks: detailNetwork.subNetworks,
              selectedNetworks: selectedNetworks,
              navigationTitle: navigationTitle,
              selectedNetworkHandler: { network in
                selectNetwork(network)
              }
            )
          }
        },
        label: { EmptyView() }
      )
    )
  }
}

private struct NetworkRowView: View {

  var presentation: NetworkPresentation
  var selectedNetworks: [BraveWallet.NetworkInfo]
  var detailTappedHandler: (() -> Void)?

  @ScaledMetric private var length: CGFloat = 30
  
  init(
    presentation: NetworkPresentation,
    selectedNetworks: [BraveWallet.NetworkInfo],
    detailTappedHandler: (() -> Void)? = nil
  ) {
    self.presentation = presentation
    self.selectedNetworks = selectedNetworks
    self.detailTappedHandler = detailTappedHandler
  }
  
  private var isSelected: Bool {
    if selectedNetworks.contains(where: { $0.chainId == presentation.network.chainId }) {
      return true
    } else if !presentation.subNetworks.isEmpty {
      return isSubNetworkSelected
    }
    return false
  }
  
  private var isSubNetworkSelected: Bool {
    for subNetwork in presentation.subNetworks where selectedNetworks.contains(where: { subNetwork.chainId == $0.chainId }) {
      return true
    }
    return false
  }

  private var checkmark: some View {
    Image(braveSystemName: "leo.check.normal")
      .resizable()
      .aspectRatio(contentMode: .fit)
      .opacity(isSelected ? 1 : 0)
      .foregroundColor(Color(.braveBlurpleTint))
      .frame(width: 14, height: 14)
  }
  
  private var showShortChainName: Bool {
    presentation.isPrimaryNetwork && !presentation.subNetworks.isEmpty
  }
  
  private var networkName: String {
    return showShortChainName ? presentation.network.shortChainName : presentation.network.chainName
  }

  var body: some View {
    HStack {
      HStack {
        checkmark
        NetworkIcon(network: presentation.network)
        VStack(alignment: .leading, spacing: 0) {
          Text(networkName)
            .font(.body)
          if isSubNetworkSelected {
            let selectedSubNetworkNames = selectedNetworks
              .filter { selectedNetwork in
                presentation.subNetworks.contains(where: { $0.chainId == selectedNetwork.chainId })
              }
              .map(\.chainName)
              .joined(separator: ", ")
            Text(selectedSubNetworkNames)
              .foregroundColor(Color(.secondaryBraveLabel))
              .font(.footnote)
          }
        }
        .frame(minHeight: length) // maintain height for All Networks row w/o icon
        Spacer()
      }
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(isSelected ? [.isSelected] : [])
      if !presentation.subNetworks.isEmpty {
        Button(action: { detailTappedHandler?() }) {
          Image(systemName: "chevron.right.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(Color(.braveBlurpleTint))
            .contentShape(Rectangle())
            .frame(width: 15, height: 15)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
          Text(String.localizedStringWithFormat(
            Strings.Wallet.networkSelectionTestnetAccessibilityLabel,
            networkName)
          )
        )
      }
    }
    .foregroundColor(Color(.braveLabel))
    .padding(.vertical, 4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}

#if DEBUG
struct NetworkRowView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      NetworkRowView(
        presentation: .init(
          network: .mockSolana,
          subNetworks: [.mockSolana, .mockSolanaTestnet],
          isPrimaryNetwork: true
        ),
        selectedNetworks: [.mockSolana]
      )
      NetworkRowView(
        presentation: .init(
          network: .mockMainnet,
          subNetworks: [.mockMainnet, .mockGoerli, .mockSepolia],
          isPrimaryNetwork: true
        ),
        selectedNetworks: [.mockMainnet]
      )
      NetworkRowView(
        presentation: .init(
          network: .mockPolygon,
          subNetworks: [],
          isPrimaryNetwork: false
        ),
        selectedNetworks: [.mockMainnet]
      )
    }
    .previewLayout(.sizeThatFits)
  }
}
#endif

// MARK: Detail View

private struct NetworkSelectionDetailView: View {
  
  var networks: [BraveWallet.NetworkInfo]
  var selectedNetworks: [BraveWallet.NetworkInfo]
  let navigationTitle: String
  var selectedNetworkHandler: (BraveWallet.NetworkInfo) -> Void
  
  var body: some View {
    List {
      ForEach(networks) { network in
        Button(action: { selectedNetworkHandler(network) }) {
          NetworkSelectionDetailRow(
            isSelected: isSelected(network),
            network: network
          )
          .contentShape(Rectangle())
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
      }
    }
    .listStyle(.insetGrouped)
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .navigationTitle(networks.first?.shortChainName ?? navigationTitle)
    .navigationBarTitleDisplayMode(.inline)
  }
  
  private func isSelected(_ network: BraveWallet.NetworkInfo) -> Bool {
    return selectedNetworks.contains(where: { $0.chainId == network.chainId && $0.coin == network.coin })
  }
}

#if DEBUG
struct NetworkSelectionDetailView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      NetworkSelectionDetailView(
        networks: [.mockMainnet, .mockGoerli, .mockSepolia],
        selectedNetworks: [.mockMainnet],
        navigationTitle: Strings.Wallet.networkFilterTitle,
        selectedNetworkHandler: { _ in }
      )
    }
  }
}
#endif

private struct NetworkSelectionDetailRow: View {
  
  var isSelected: Bool
  var network: BraveWallet.NetworkInfo
  
  @ScaledMetric private var length: CGFloat = 30
  
  var body: some View {
    HStack {
      NetworkIcon(network: network)
      Text(network.chainName)
      Spacer()
      if isSelected {
        Image(braveSystemName: "leo.check.normal")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .foregroundColor(Color(.braveBlurpleTint))
          .frame(width: 14, height: 14)
      }
    }
    .foregroundColor(Color(.braveLabel))
    .listRowBackground(Color(.secondaryBraveGroupedBackground))
    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    .accessibilityElement(children: .combine)
  }
}

#if DEBUG
struct NetworkSelectionDetailRow_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      NetworkSelectionDetailRow(
        isSelected: true,
        network: .mockMainnet
      )
      NetworkSelectionDetailRow(
        isSelected: false,
        network: .mockGoerli
      )
    }
    .previewLayout(.sizeThatFits)
  }
}
#endif
