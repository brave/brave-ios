/* Copyright 2022 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import BraveCore
import SwiftUI
import Preferences

struct NetworkSelectionRootView: View {
  
  var navigationTitle: String
  var selectedNetworks: [BraveWallet.NetworkInfo]
  var allNetworks: [BraveWallet.NetworkInfo]
  var showsCancelButton: Bool
  var showsSelectAllButton: Bool
  var selectNetwork: (BraveWallet.NetworkInfo) -> Void
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  init(
    navigationTitle: String,
    selectedNetworks: [BraveWallet.NetworkInfo],
    allNetworks: [BraveWallet.NetworkInfo],
    showsCancelButton: Bool = true,
    showsSelectAllButton: Bool = false,
    selectNetwork: @escaping (BraveWallet.NetworkInfo) -> Void
  ) {
    self.navigationTitle = navigationTitle
    self.selectedNetworks = selectedNetworks
    self.allNetworks = allNetworks
    self.showsCancelButton = showsCancelButton
    self.showsSelectAllButton = showsSelectAllButton
    self.selectNetwork = selectNetwork
  }
  
  /// If all primary networks are selected
  private var allPrimarySelected: Bool {
    allNetworks.primaryNetworks.allSatisfy({ primaryNetwork in
      selectedNetworks.contains(where: { $0.chainId == primaryNetwork.chainId })
    })
  }
  
  /// If all secondary networks are selected
  private var allSecondarySelected: Bool {
    allNetworks.secondaryNetworks.allSatisfy({ secondaryNetwork in
      selectedNetworks.contains(where: { $0.chainId == secondaryNetwork.chainId })
    })
  }
  
  /// If all test networks are selected
  private var allTestnetSelected: Bool {
    allNetworks.testNetworks.allSatisfy({ testNetwork in
      selectedNetworks.contains(where: { $0.chainId == testNetwork.chainId })
    })
  }
  
  private func selectAllButtonTitle(_ allSelected: Bool) -> String {
    if allSelected {
      return Strings.Wallet.deselectAllButtonTitle
    }
    return Strings.Wallet.selectAllButtonTitle
  }
  
  @ViewBuilder private func headerView(
    title: String,
    allSelected: Bool,
    selectAllAction: @escaping () -> Void
  ) -> some View {
    HStack {
      Text(title)
        .font(.body.weight(.semibold))
        .foregroundColor(Color(uiColor: WalletV2Design.textPrimary))
      Spacer()
      if showsSelectAllButton {
        Button(action: selectAllAction) {
          Text(selectAllButtonTitle(allSelected))
            .font(.callout.weight(.semibold))
            .foregroundColor(Color(uiColor: WalletV2Design.textInteractive))
        }
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
  }
  
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        headerView(
          title: Strings.Wallet.networkSelectionPrimaryNetworks,
          allSelected: allPrimarySelected,
          selectAllAction: {
            if allPrimarySelected { // deselect all
              allNetworks.primaryNetworks.forEach(selectNetwork)
            } else { // select all
              let unselectedNetworks = allNetworks.primaryNetworks
                .filter { primaryNetwork in
                  !selectedNetworks.contains(
                    where: { $0.chainId == primaryNetwork.chainId && $0.coin == primaryNetwork.coin }
                  )
                }
              unselectedNetworks.forEach(selectNetwork)
            }
          }
        )
        ForEach(allNetworks.primaryNetworks) { network in
          Button(action: { selectNetwork(network) }) {
            NetworkRowView(
              network: network,
              selectedNetworks: selectedNetworks
            )
          }
        }
        
        DividerLine()
          .padding(.top, 12)
        
        headerView(
          title: Strings.Wallet.networkSelectionSecondaryNetworks,
          allSelected: allSecondarySelected,
          selectAllAction: {
            if allSecondarySelected { // deselect all
              allNetworks.secondaryNetworks.forEach(selectNetwork)
            } else { // select all
              let unselectedNetworks = allNetworks.secondaryNetworks
                .filter { secondaryNetwork in
                  !selectedNetworks.contains(
                    where: { $0.chainId == secondaryNetwork.chainId && $0.coin == secondaryNetwork.coin }
                  )
                }
              unselectedNetworks.forEach(selectNetwork)
            }
          }
        )
        ForEach(allNetworks.secondaryNetworks) { network in
          Button(action: { selectNetwork(network) }) {
            NetworkRowView(
              network: network,
              selectedNetworks: selectedNetworks
            )
          }
        }
        
        if Preferences.Wallet.showTestNetworks.value && !allNetworks.testNetworks.isEmpty {
          DividerLine()
            .padding(.top, 12)
          
          headerView(
            title: Strings.Wallet.networkSelectionTestNetworks,
            allSelected: allTestnetSelected,
            selectAllAction: {
              if allTestnetSelected { // deselect all
                allNetworks.testNetworks.forEach(selectNetwork)
              } else { // select all
                let unselectedNetworks = allNetworks.testNetworks
                  .filter { testNetwork in
                    !selectedNetworks.contains(
                      where: { $0.chainId == testNetwork.chainId && $0.coin == testNetwork.coin }
                    )
                  }
                unselectedNetworks.forEach(selectNetwork)
              }
            }
          )
          ForEach(allNetworks.testNetworks) { network in
            Button(action: { selectNetwork(network) }) {
              NetworkRowView(
                network: network,
                selectedNetworks: selectedNetworks
              )
            }
          }
        }
      }
    }
    .listBackgroundColor(Color(uiColor: WalletV2Design.containerBackground))
    .navigationTitle(navigationTitle)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .cancellationAction) {
        if showsCancelButton {
          Button(action: { presentationMode.dismiss() }) {
            Text(Strings.cancelButtonTitle)
              .foregroundColor(Color(.braveBlurpleTint))
          }
        }
      }
    }
  }
}

#if DEBUG
struct NetworkSelectionRootView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      NetworkSelectionRootView(
        navigationTitle: "Select Networks",
        selectedNetworks: [.mockMainnet, .mockSolana, .mockPolygon],
        allNetworks: [
          .mockMainnet, .mockSolana,
          .mockPolygon, .mockCelo,
          .mockGoerli, .mockSolanaTestnet
        ],
        selectNetwork: { _ in
          
        }
      )
    }
  }
}
#endif

private struct NetworkRowView: View {

  var network: BraveWallet.NetworkInfo
  var selectedNetworks: [BraveWallet.NetworkInfo]

  @ScaledMetric private var length: CGFloat = 30
  
  init(
    network: BraveWallet.NetworkInfo,
    selectedNetworks: [BraveWallet.NetworkInfo]
  ) {
    self.network = network
    self.selectedNetworks = selectedNetworks
  }
  
  private var isSelected: Bool {
    selectedNetworks.contains(where: { $0.chainId == network.chainId })
  }

  private var checkmark: some View {
    Image(braveSystemName: "leo.check.normal")
      .resizable()
      .aspectRatio(contentMode: .fit)
      .hidden(isHidden: !isSelected)
      .foregroundColor(Color(.braveBlurpleTint))
      .frame(width: 14, height: 14)
  }

  var body: some View {
    HStack {
      NetworkIcon(network: network)
      VStack(alignment: .leading, spacing: 0) {
        Text(network.chainName)
          .font(.body)
      }
      .frame(minHeight: length) // maintain height for All Networks row w/o icon
      Spacer()
      checkmark
    }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    .foregroundColor(Color(.braveLabel))
    .padding(.horizontal)
    .padding(.vertical, 12)
    .contentShape(Rectangle())
  }
}

#if DEBUG
struct NetworkRowView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      NetworkRowView(
        network: .mockSolana,
        selectedNetworks: [.mockSolana]
      )
      NetworkRowView(
        network: .mockMainnet,
        selectedNetworks: [.mockMainnet]
      )
      NetworkRowView(
        network: .mockPolygon,
        selectedNetworks: [.mockMainnet]
      )
    }
    .previewLayout(.sizeThatFits)
  }
}
#endif
