/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftUI
import BraveCore
import Strings

struct AssetSearchView: View {
  var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore
  var cryptoStore: CryptoStore
  var userAssetsStore: UserAssetsStore
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  @State private var allAssets: [AssetViewModel] = []
  @State private var allNFTMetadata: [String: NFTMetadata] = [:]
  @State private var query = ""
  @State private var networkFilters: [Selectable<BraveWallet.NetworkInfo>] = []
  @State private var isPresentingNetworkFilter = false
  
  public init(
    keyringStore: KeyringStore,
    cryptoStore: CryptoStore,
    userAssetsStore: UserAssetsStore
  ) {
    self.keyringStore = keyringStore
    self.networkStore = cryptoStore.networkStore
    self.cryptoStore = cryptoStore
    self.userAssetsStore = userAssetsStore
  }

  private var filteredTokens: [AssetViewModel] {
    let filterByNetwork = !networkFilters.allSatisfy(\.isSelected)
    let filterByQuery = !query.isEmpty
    if !filterByNetwork && !filterByQuery {
      return allAssets
    }
    let selectedNetworks = networkFilters.filter(\.isSelected)
    let normalizedQuery = query.lowercased()
    return allAssets.filter { asset in
      if filterByNetwork,
         !selectedNetworks.contains(where: { asset.network.chainId == $0.model.chainId }) {
        return false
      }
      if filterByQuery {
        return asset.token.symbol.lowercased().contains(normalizedQuery) || asset.token.name.lowercased().contains(normalizedQuery)
      }
      return true
    }
  }
  
  private var networkFilterButton: some View {
    Button(action: {
      self.isPresentingNetworkFilter = true
    }) {
      Image(braveSystemName: "leo.tune")
        .font(.footnote.weight(.medium))
        .foregroundColor(Color(.braveBlurpleTint))
        .clipShape(Rectangle())
    }
    .sheet(isPresented: $isPresentingNetworkFilter) {
      NavigationView {
        NetworkFilterView(
          networks: networkFilters,
          networkStore: cryptoStore.networkStore,
          saveAction: { networkFilters in
            self.networkFilters = networkFilters
          }
        )
      }
      .onDisappear {
        cryptoStore.networkStore.closeNetworkSelectionStore()
      }
    }
  }
  
  var body: some View {
    NavigationView {
      List {
        Section(
          header: WalletListHeaderView(
            title: Text(Strings.Wallet.assetsTitle)
          )
        ) {
          Group {
            if filteredTokens.isEmpty {
              Text(Strings.Wallet.assetSearchEmpty)
                .font(.footnote)
                .foregroundColor(Color(.secondaryBraveLabel))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            } else {
              ForEach(filteredTokens) { assetViewModel in
                
                NavigationLink(
                  destination: {
                    if assetViewModel.token.isErc721 {
                      NFTDetailView(
                        nftDetailStore: cryptoStore.nftDetailStore(for: assetViewModel.token, nftMetadata: allNFTMetadata[assetViewModel.token.id]),
                        buySendSwapDestination: .constant(nil)
                      ) { metadata in
                        allNFTMetadata[assetViewModel.token.id] = metadata
                      }
                      .onDisappear {
                        cryptoStore.closeNFTDetailStore(for: assetViewModel.token)
                      }
                    } else {
                      AssetDetailView(
                        assetDetailStore: cryptoStore.assetDetailStore(for: .blockchainToken(assetViewModel.token)),
                        keyringStore: keyringStore,
                        networkStore: cryptoStore.networkStore
                      )
                      .onDisappear {
                        cryptoStore.closeAssetDetailStore(for: .blockchainToken(assetViewModel.token))
                      }
                    }
                  }
                ) {
                  SearchAssetView(
                    title: title(for: assetViewModel.token),
                    symbol: assetViewModel.token.symbol,
                    networkName: assetViewModel.network.chainName
                  ) {
                    if assetViewModel.token.isErc721 || assetViewModel.token.isNft {
                      NFTIconView(
                        token: assetViewModel.token,
                        network: assetViewModel.network,
                        url: allNFTMetadata[assetViewModel.token.id]?.imageURL,
                        shouldShowNetworkIcon: true
                      )
                    } else {
                      AssetIconView(
                        token: assetViewModel.token,
                        network: assetViewModel.network,
                        shouldShowNetworkIcon: true
                      )
                    }
                  }
                }
              }
            }
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
      }
      .listStyle(.insetGrouped)
      .listBackgroundColor(Color(UIColor.braveGroupedBackground))
      .navigationTitle(Strings.Wallet.searchTitle.capitalized)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .cancellationAction) {
          Button(action: {
            presentationMode.dismiss()
          }) {
            Text(Strings.cancelButtonTitle)
              .foregroundColor(Color(.braveBlurpleTint))
          }
        }
        ToolbarItemGroup(placement: .bottomBar) {
          networkFilterButton
          Spacer()
        }
      }
      .animation(nil, value: query)
      .searchable(
        text: $query,
        placement: .navigationBarDrawer(displayMode: .always)
      )
    }
    .navigationViewStyle(StackNavigationViewStyle())
    .onAppear {
      Task { @MainActor in
        self.allAssets = await userAssetsStore.allAssets()
        self.allNFTMetadata = await userAssetsStore.allNFTMetadata()
        self.networkFilters = networkStore.allChains.map {
          .init(isSelected: true, model: $0)
        }
      }
    }
  }
  
  private func title(for token: BraveWallet.BlockchainToken) -> String {
    if (token.isErc721 || token.isNft), !token.tokenId.isEmpty {
      return token.nftTokenTitle
    } else {
      return token.name
    }
  }
}

struct SearchAssetView<ImageView: View>: View {
  var image: () -> ImageView
  var title: String
  var symbol: String
  let networkName: String
  
  init(
    title: String,
    symbol: String,
    networkName: String,
    @ViewBuilder image: @escaping () -> ImageView
  ) {
    self.title = title
    self.symbol = symbol
    self.networkName = networkName
    self.image = image
  }

  var body: some View {
    HStack {
      image()
      VStack(alignment: .leading) {
        Text(title)
          .font(.footnote)
          .fontWeight(.semibold)
          .foregroundColor(Color(.bravePrimary))
        Text(String.localizedStringWithFormat(Strings.Wallet.userAssetSymbolNetworkDesc, symbol, networkName))
          .font(.caption)
          .foregroundColor(Color(.braveLabel))
      }
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 6)
    .accessibilityElement()
    .accessibilityLabel("\(title), \(symbol), \(networkName)")
  }
}
