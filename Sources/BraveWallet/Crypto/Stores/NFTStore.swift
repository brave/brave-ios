// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

struct NFTAssetViewModel: Identifiable, Equatable {
  var token: BraveWallet.BlockchainToken
  var network: BraveWallet.NetworkInfo
  var balance: Int
  var nftMetadata: NFTMetadata?
  
  public var id: String {
    token.id + network.chainId
  }
  
  static func == (lhs: NFTAssetViewModel, rhs: NFTAssetViewModel) -> Bool {
    lhs.id == rhs.id
  }
}

public class NFTStore: ObservableObject {
  /// The users visible NFTs
  @Published private(set) var userVisibleNFTs: [NFTAssetViewModel] = []
  /// The network filter in NFT tab
  @Published var networkFilters: [Selectable<BraveWallet.NetworkInfo>] = [] {
    didSet {
      guard !oldValue.isEmpty else { return } // initial assignment to `networkFilters`
      update()
    }
  }
  @Published var isLoadingDiscoverAssets: Bool = false
  
  public private(set) lazy var userAssetsStore: UserAssetsStore = .init(
    blockchainRegistry: self.blockchainRegistry,
    rpcService: self.rpcService,
    keyringService: self.keyringService,
    assetRatioService: self.assetRatioService,
    ipfsApi: self.ipfsApi,
    userAssetManager: self.assetManager
  )
  
  private let keyringService: BraveWalletKeyringService
  private let rpcService: BraveWalletJsonRpcService
  private let walletService: BraveWalletBraveWalletService
  private let assetRatioService: BraveWalletAssetRatioService
  private let blockchainRegistry: BraveWalletBlockchainRegistry
  private let ipfsApi: IpfsAPI
  private let assetManager: WalletUserAssetManagerType
  
  /// Cancellable for the last running `update()` Task.
  private var updateTask: Task<(), Never>?
  /// Cache of metadata for NFTs. The key is the token's `id`.
  private var metadataCache: [String: NFTMetadata] = [:]
  
  public init(
    keyringService: BraveWalletKeyringService,
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService,
    assetRatioService: BraveWalletAssetRatioService,
    blockchainRegistry: BraveWalletBlockchainRegistry,
    ipfsApi: IpfsAPI,
    userAssetManager: WalletUserAssetManagerType
  ) {
    self.keyringService = keyringService
    self.rpcService = rpcService
    self.walletService = walletService
    self.assetRatioService = assetRatioService
    self.blockchainRegistry = blockchainRegistry
    self.ipfsApi = ipfsApi
    self.assetManager = userAssetManager
    
    self.rpcService.add(self)
    self.keyringService.add(self)
    self.walletService.add(self)
    
    keyringService.isLocked { [self] isLocked in
      if !isLocked {
        update()
      }
    }
  }
  
  func update() {
    self.updateTask?.cancel()
    self.updateTask = Task { @MainActor in
      // setup network filters if not currently setup
      if self.networkFilters.isEmpty {
        self.networkFilters = await self.rpcService.allNetworksForSupportedCoins().map {
          .init(isSelected: !WalletConstants.supportedTestNetworkChainIds.contains($0.chainId), model: $0)
        }
      }
      let networks: [BraveWallet.NetworkInfo] = self.networkFilters.filter(\.isSelected).map(\.model)
      let allVisibleUserAssets = assetManager.getAllVisibleAssetsInNetworkAssets(networks: networks)
      var updatedUserVisibleNFTs: [NFTAssetViewModel] = []
      for networkAssets in allVisibleUserAssets {
        for token in networkAssets.tokens {
          if token.isErc721 || token.isNft {
            updatedUserVisibleNFTs.append(
              NFTAssetViewModel(
                token: token,
                network: networkAssets.network,
                balance: 0, // no balance shown in NFT tab
                nftMetadata: metadataCache[token.id]
              )
            )
          }
        }
      }
      self.userVisibleNFTs = updatedUserVisibleNFTs
      
      // fetch nft metadata for all NFTs
      // fetch price for every token
      let allTokens = allVisibleUserAssets.flatMap(\.tokens)
      let allNFTs = allTokens.filter { $0.isNft || $0.isErc721 }
      let allMetadata = await rpcService.fetchNFTMetadata(tokens: allNFTs, ipfsApi: ipfsApi)
      for (key, value) in allMetadata { // update cached values
        metadataCache[key] = value
      }
      
      guard !Task.isCancelled else { return }
      updatedUserVisibleNFTs.removeAll()
      for networkAssets in allVisibleUserAssets {
        for token in networkAssets.tokens {
          if token.isErc721 || token.isNft {
            updatedUserVisibleNFTs.append(
              NFTAssetViewModel(
                token: token,
                network: networkAssets.network,
                balance: 0, // no balance shown in NFT tab
                nftMetadata: metadataCache[token.id]
              )
            )
          }
        }
      }
      self.userVisibleNFTs = updatedUserVisibleNFTs
    }
  }
  
  func updateNFTMetadataCache(for token: BraveWallet.BlockchainToken, metadata: NFTMetadata) {
    metadataCache[token.id] = metadata
    if let index = userVisibleNFTs.firstIndex(where: { $0.token.id == token.id }), let viewModel = userVisibleNFTs[safe: index] {
      userVisibleNFTs[index] = NFTAssetViewModel(token: viewModel.token, network: viewModel.network, balance: viewModel.balance, nftMetadata: metadata)
    }
  }
  
  @MainActor func isNFTDiscoveryEnabled() async -> Bool {
    await walletService.nftDiscoveryEnabled()
  }
  
  func enableNFTDiscovery() {
    walletService.setNftDiscoveryEnabled(true)
  }
  
  func updateVisibility(_ token: BraveWallet.BlockchainToken, visible: Bool) {
    assetManager.updateUserAsset(for: token, visible: visible) { [weak self] in
      self?.update()
    }
  }
}

extension NFTStore: BraveWalletJsonRpcServiceObserver {
  public func onIsEip1559Changed(_ chainId: String, isEip1559: Bool) {
  }
  
  public func onAddEthereumChainRequestCompleted(_ chainId: String, error: String) {
  }
  
  public func chainChangedEvent(_ chainId: String, coin: BraveWallet.CoinType, origin: URLOrigin?) {
    update()
  }
}

extension NFTStore: BraveWalletKeyringServiceObserver {
  public func keyringReset() {
  }
  
  public func accountsChanged() {
    update()
  }
  public func backedUp() {
  }
  public func keyringCreated(_ keyringId: BraveWallet.KeyringId) {
  }
  public func keyringRestored(_ keyringId: BraveWallet.KeyringId) {
  }
  public func locked() {
  }
  public func unlocked() {
    DispatchQueue.main.async { [self] in
      update()
    }
  }
  public func autoLockMinutesChanged() {
  }
//  public func selectedAccountChanged(_ coinType: BraveWallet.CoinType) {
//    DispatchQueue.main.async { [self] in
//      update()
//    }
//  }
  public func selectedWalletAccountChanged(_ account: BraveWallet.AccountInfo) {
  }
  
  public func selectedDappAccountChanged(_ coin: BraveWallet.CoinType, account: BraveWallet.AccountInfo?) {
  }
  
  public func accountsAdded(_ addedAccounts: [BraveWallet.AccountInfo]) {
  }
}

extension NFTStore: BraveWalletBraveWalletServiceObserver {
  public func onActiveOriginChanged(_ originInfo: BraveWallet.OriginInfo) {
  }
  
  public func onDefaultEthereumWalletChanged(_ wallet: BraveWallet.DefaultWallet) {
  }
  
  public func onDefaultSolanaWalletChanged(_ wallet: BraveWallet.DefaultWallet) {
  }
  
  public func onDefaultBaseCurrencyChanged(_ currency: String) {
  }
  
  public func onDefaultBaseCryptocurrencyChanged(_ cryptocurrency: String) {
  }
  
  public func onNetworkListChanged() {
    Task { @MainActor in
      // A network was added or removed, update our network filters for the change.
      self.networkFilters = await self.rpcService.allNetworksForSupportedCoins().map { network in
        let defaultValue = !WalletConstants.supportedTestNetworkChainIds.contains(network.chainId)
        let existingSelectionValue = self.networkFilters.first(where: { $0.model.chainId == network.chainId})?.isSelected
        return .init(isSelected: existingSelectionValue ?? defaultValue, model: network)
      }
    }
  }
  
  public func onDiscoverAssetsStarted() {
    isLoadingDiscoverAssets = true
  }
  
  public func onDiscoverAssetsCompleted(_ discoveredAssets: [BraveWallet.BlockchainToken]) {
    isLoadingDiscoverAssets = false
    // assets update will be called via `CryptoStore`
  }
  
  public func onResetWallet() {
  }
}
