// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import Preferences

struct NFTAssetViewModel: Identifiable, Equatable {
  var token: BraveWallet.BlockchainToken
  var network: BraveWallet.NetworkInfo
  /// Balance for the NFT for each account address. The key is the account address.
  var balanceForAccounts: [String: Int]
  var nftMetadata: NFTMetadata?
  
  public var id: String {
    token.id + network.chainId
  }
  
  static func == (lhs: NFTAssetViewModel, rhs: NFTAssetViewModel) -> Bool {
    lhs.id == rhs.id
  }
}

public class NFTStore: ObservableObject {
  /// The NFTs grouped by enum `NFTDisplayType` displayed in `NFTView`
  var displayNFTs: [NFTAssetViewModel] {
    switch displayType {
    case .visible:
      return userVisibleNFTs
    case .invisible:
      return userInvisibleNFTs
    case .spam:
      return userSpamNFTs
    }
  }
  /// All User Accounts
  var allAccounts: [BraveWallet.AccountInfo] = []
  /// All available networks
  var allNetworks: [BraveWallet.NetworkInfo] = []
  var filters: Filters {
    let nonSelectedAccountAddresses = Preferences.Wallet.nonSelectedAccountsFilter.value
    let nonSelectedNetworkChainIds = Preferences.Wallet.nonSelectedNetworksFilter.value
    return Filters(
      accounts: allAccounts.map { account in
          .init(
            isSelected: !nonSelectedAccountAddresses.contains(where: { $0 == account.address }),
            model: account
          )
      },
      networks: allNetworks.map { network in
          .init(
            isSelected: !nonSelectedNetworkChainIds.contains(where: { $0 == network.chainId }),
            model: network
          )
      }
    )
  }
  /// Flag indicating when we are saving filters. Since we are observing multiple `Preference.Option`s,
  /// we should avoid calling `update()` in `preferencesDidChange()` unless another view changed.
  private var isSavingFilters: Bool = false
  @Published var isLoadingDiscoverAssets: Bool = false
  
  public private(set) lazy var userAssetsStore: UserAssetsStore = .init(
    blockchainRegistry: self.blockchainRegistry,
    rpcService: self.rpcService,
    keyringService: self.keyringService,
    assetRatioService: self.assetRatioService,
    ipfsApi: self.ipfsApi,
    userAssetManager: self.assetManager
  )
  
  enum NFTDisplayType: Int, CaseIterable, Identifiable {
    case visible
    case invisible
    case spam
    
    var id: Int {
      rawValue
    }
    
    var dropdownTitle: String {
      switch self {
      case .visible:
        return Strings.Wallet.nftsTitle
      case .invisible:
        return Strings.Wallet.nftHidden
      case .spam:
        return Strings.Wallet.nftSpam
      }
    }
    
    var emptyTitle: String {
      switch self {
      case .visible:
        return Strings.Wallet.nftPageEmptyTitle
      case .invisible:
        return Strings.Wallet.nftInvisiblePageEmptyTitle
      case .spam:
        return Strings.Wallet.nftSpamPageEmptyTitle
      }
    }
    
    var emptyDescription: String? {
      switch self {
      case .visible:
        return Strings.Wallet.nftPageEmptyDescription
      case .invisible, .spam:
        return nil
      }
    }
  }

  @Published var displayType: NFTDisplayType = .visible
  @Published private(set) var userVisibleNFTs: [NFTAssetViewModel] = []
  @Published private(set) var userInvisibleNFTs: [NFTAssetViewModel] = []
  @Published private(set) var userSpamNFTs: [NFTAssetViewModel] = []
  
  private var simpleHashSpamNFTs: [NetworkAssets] = []
  
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
    Preferences.Wallet.showTestNetworks.observe(from: self)
    Preferences.Wallet.isHidingUnownedNFTsFilter.observe(from: self)
    Preferences.Wallet.isShowingNFTNetworkLogoFilter.observe(from: self)
    Preferences.Wallet.nonSelectedNetworksFilter.observe(from: self)
  }
  
  /// Cache of NFT balances for each account tokenBalances: [token.contractAddress]
  private var nftBalancesCache: [String: [String: Int]] = [:]
  
  func update() {
    self.updateTask?.cancel()
    self.updateTask = Task { @MainActor in
      self.allAccounts = await keyringService.allAccounts().accounts
        .filter { account in
          WalletConstants.supportedCoinTypes().contains(account.coin)
        }
      self.allNetworks = await rpcService.allNetworksForSupportedCoins()
      let filters = self.filters
      let selectedAccounts = filters.accounts.filter(\.isSelected).map(\.model)
      let selectedNetworks = filters.networks.filter(\.isSelected).map(\.model)
      
      // user visible assets
      let userVisibleAssets = assetManager.getAllUserAssetsInNetworkAssets(networks: selectedNetworks, visible: true)
      
      // user invisible assets
      let userInvisibleAssets = assetManager.getAllUserAssetsInNetworkAssets(networks: selectedNetworks, visible: false)
      
      // all spam NFTs marked by user
      let allUserMarkedSpamNFTs = assetManager.getAllUserNFTs(networks: selectedNetworks, spamStatus: true)
      
      // all spam NFTs marked by SimpleHash
      let simpleHashSpamNFTs = await walletService.simpleHashSpamNFTs(for: selectedAccounts, on: selectedNetworks)
      
      // filter out any spam NFTs from `simpleHashSpamNFTs` that are marked
      // not-spam by user
      var updatedSimpleHashSpamNFTs: [NetworkAssets] = []
      for simpleHashSpamNFTsOnNetwork in simpleHashSpamNFTs {
        let userMarkedNotSpamTokensOnNetwork = assetManager.getAllUserNFTs(networks: [simpleHashSpamNFTsOnNetwork.network], spamStatus: false).flatMap(\.tokens)
        let filteredSimpleHashSpamTokens = simpleHashSpamNFTsOnNetwork.tokens.filter { simpleHashSpamToken in
          !userMarkedNotSpamTokensOnNetwork.contains { token in
            token.id == simpleHashSpamToken.id
          }
        }
        updatedSimpleHashSpamNFTs.append(NetworkAssets(network: simpleHashSpamNFTsOnNetwork.network, tokens: filteredSimpleHashSpamTokens, sortOrder: simpleHashSpamNFTsOnNetwork.sortOrder))
      }
      // union user marked spam NFTs with spam NFTs from SimpleHash
      var computedSpamNFTs: [NetworkAssets] = []
      for (index, network) in selectedNetworks.enumerated() {
        let userMarkedSpamNFTsOnNetwork: [BraveWallet.BlockchainToken] = allUserMarkedSpamNFTs.first { $0.network.chainId == network.chainId }?.tokens ?? []
        let simpleHashSpamNFTsOnNetwork = updatedSimpleHashSpamNFTs.first { $0.network.chainId == network.chainId }?.tokens ?? []
        var spamNFTUnion: [BraveWallet.BlockchainToken] = simpleHashSpamNFTsOnNetwork
        for userSpam in userMarkedSpamNFTsOnNetwork where !simpleHashSpamNFTsOnNetwork.contains(where: { simpleHashSpam in
          simpleHashSpam.id == userSpam.id
        }) {
          spamNFTUnion.append(userSpam)
        }
        computedSpamNFTs.append(NetworkAssets(network: network, tokens: spamNFTUnion, sortOrder: index))
      }
      
      updateUserAssetViewModels(
        userVisibleAssets: userVisibleAssets,
        userInvisibleAssets: userInvisibleAssets,
        spamNFTs: computedSpamNFTs,
        filter: filters,
        selectedAccounts: selectedAccounts
      )
      
      var allTokens: [BraveWallet.BlockchainToken] = []
      for networkAssets in [userVisibleAssets, userInvisibleAssets, computedSpamNFTs] {
        allTokens.append(contentsOf: networkAssets.flatMap(\.tokens))
      }
      let allNFTs = allTokens.filter { $0.isNft || $0.isErc721 }
      // if we're not hiding unowned or grouping by account, balance isn't needed
      if filters.isHidingUnownedNFTs {
        // fetch balance for all NFTs
        let allAccounts = filters.accounts.map(\.model)
        nftBalancesCache = await withTaskGroup(
          of: [String: [String: Int]].self,
          body: { @MainActor [nftBalancesCache, rpcService] group in
            for nft in allNFTs { // for each NFT
              guard let networkForNFT = allNetworks.first(where: { $0.chainId == nft.chainId }) else {
                continue
              }
              group.addTask { @MainActor in
                let updatedBalances = await withTaskGroup(
                  of: [String: Int].self,
                  body: { @MainActor group in
                    for account in allAccounts where account.coin == nft.coin {
                      group.addTask { @MainActor in
                        let balanceForToken = await rpcService.balance(
                          for: nft,
                          in: account,
                          network: networkForNFT
                        )
                        return [account.address: Int(balanceForToken ?? 0)]
                      }
                    }
                    return await group.reduce(into: [String: Int](), { partialResult, new in
                      partialResult.merge(with: new)
                    })
                  })
                var tokenBalances = nftBalancesCache[nft.id] ?? [:]
                tokenBalances.merge(with: updatedBalances)
                return [nft.id: tokenBalances]
              }
            }
            return await group.reduce(into: [String: [String: Int]](), { partialResult, new in
              partialResult.merge(with: new)
            })
          })
      }
      guard !Task.isCancelled else { return }
      updateUserAssetViewModels(
        userVisibleAssets: userVisibleAssets,
        userInvisibleAssets: userInvisibleAssets,
        spamNFTs: computedSpamNFTs,
        filter: filters,
        selectedAccounts: selectedAccounts
      )
      
      // fetch nft metadata for all NFTs
      let allMetadata = await rpcService.fetchNFTMetadata(tokens: allNFTs, ipfsApi: ipfsApi)
      for (key, value) in allMetadata { // update cached values
        metadataCache[key] = value
      }
      guard !Task.isCancelled else { return }
      updateUserAssetViewModels(
        userVisibleAssets: userVisibleAssets,
        userInvisibleAssets: userInvisibleAssets,
        spamNFTs: computedSpamNFTs,
        filter: filters,
        selectedAccounts: selectedAccounts
      )
    }
  }
  
  func updateNFTMetadataCache(for token: BraveWallet.BlockchainToken, metadata: NFTMetadata) {
    metadataCache[token.id] = metadata
    var targetList: [NFTAssetViewModel]?
    switch displayType {
    case .visible:
      targetList = userVisibleNFTs
    case .invisible:
      targetList = userInvisibleNFTs
    case .spam:
      targetList = userSpamNFTs
    }
    if let index = targetList?.firstIndex(where: { $0.token.id == token.id }),
       var updatedViewModel = targetList?[safe: index] {
      updatedViewModel.nftMetadata = metadata
      switch displayType {
      case .visible:
        userVisibleNFTs[index] = updatedViewModel
      case .invisible:
        userInvisibleNFTs[index] = updatedViewModel
      case .spam:
        userSpamNFTs[index] = updatedViewModel
      }
    }
  }
  
  private func buildAssetViewModels(
    allUserAssets: [NetworkAssets]
  ) -> [NFTAssetViewModel] {
    allUserAssets.flatMap { networkAssets in
      networkAssets.tokens.compactMap { token in
        guard token.isErc721 || token.isNft else { return nil }
        return NFTAssetViewModel(
          token: token,
          network: networkAssets.network,
          balanceForAccounts: nftBalancesCache[token.id] ?? [:],
          nftMetadata: metadataCache[token.id]
        )
      }
    }
  }
  
  private func updateUserAssetViewModels(
    userVisibleAssets: [NetworkAssets],
    userInvisibleAssets: [NetworkAssets],
    spamNFTs: [NetworkAssets],
    filter: Filters,
    selectedAccounts: [BraveWallet.AccountInfo]
  ) {
    userVisibleNFTs = buildAssetViewModels(allUserAssets: userVisibleAssets)
      .optionallyFilterUnownedNFTs(
        isHidingUnownedNFTs: filters.isHidingUnownedNFTs,
        selectedAccounts: selectedAccounts
      )
    userInvisibleNFTs = buildAssetViewModels(allUserAssets: userInvisibleAssets)
      .optionallyFilterUnownedNFTs(
        isHidingUnownedNFTs: filters.isHidingUnownedNFTs,
        selectedAccounts: selectedAccounts
      )
    userSpamNFTs = buildAssetViewModels(allUserAssets: spamNFTs)
      .optionallyFilterUnownedNFTs(
        isHidingUnownedNFTs: filters.isHidingUnownedNFTs,
        selectedAccounts: selectedAccounts
      )
  }
  
  @MainActor func isNFTDiscoveryEnabled() async -> Bool {
    await walletService.nftDiscoveryEnabled()
  }
  
  func enableNFTDiscovery() {
    walletService.setNftDiscoveryEnabled(true)
  }
  
  func updateNFTStatus(_ token: BraveWallet.BlockchainToken, visible: Bool, spamStatus: Bool) {
    assetManager.updateUserAsset(for: token, visible: visible, spamStatus: spamStatus) { [weak self] in
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
    // A network was added or removed, `update()` will update `allNetworks`.
    update()
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

extension NFTStore: PreferencesObserver {
  func saveFilters(_ filters: Filters) {
    isSavingFilters = true
    filters.save()
    isSavingFilters = false
    update()
  }
  public func preferencesDidChange(for key: String) {
    guard !isSavingFilters else { return }
    update()
  }
}

private extension Array where Element == NFTAssetViewModel {
  /// Optionally filters out NFTs not belonging to the given `selectedAccounts`.
  func optionallyFilterUnownedNFTs(
    isHidingUnownedNFTs: Bool,
    selectedAccounts: [BraveWallet.AccountInfo]
  ) -> [Element] {
    optionallyFilter(
      shouldFilter: isHidingUnownedNFTs,
      isIncluded: { nftAsset in
        let balancesForSelectedAccounts = nftAsset.balanceForAccounts.filter { balance in
          selectedAccounts.contains(where: { account in
            account.address == balance.key
          })
        }
        return balancesForSelectedAccounts.contains(where: { $0.value > 0 })
      })
  }
}
