// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import SwiftUI

public struct AssetViewModel: Identifiable, Equatable {
  var token: BraveWallet.BlockchainToken
  var network: BraveWallet.NetworkInfo
  var decimalBalance: Double
  var price: String
  var history: [BraveWallet.AssetTimePrice]

  public var id: String {
    token.id + network.chainId
  }
}

struct NFTAssetViewModel: Identifiable, Equatable {
  var token: BraveWallet.BlockchainToken
  var network: BraveWallet.NetworkInfo
  var balance: Int
  var imageUrl: URL?

  public var id: String {
    token.id + network.chainId
  }
}

struct BalanceTimePrice: DataPoint, Equatable {
  var date: Date
  var price: Double
  var formattedPrice: String

  var value: CGFloat {
    price
  }
}

public enum NetworkFilter: Equatable {
  case allNetworks
  case network(BraveWallet.NetworkInfo)
  
  var title: String {
    switch self {
    case .allNetworks:
      return Strings.Wallet.allNetworksTitle
    case let .network(network):
      return network.chainName
    }
  }
}

/// A store containing data around the users assets
public class PortfolioStore: ObservableObject {
  /// The dollar amount of your portfolio
  @Published private(set) var balance: String = "$0.00"
  /// The users visible fungible tokens. NFTs are separated into `userVisibleNFTs`.
  @Published private(set) var userVisibleAssets: [AssetViewModel] = []
  /// The users visible NFTs
  @Published private(set) var userVisibleNFTs: [NFTAssetViewModel] = []
  /// The timeframe of the portfolio
  @Published var timeframe: BraveWallet.AssetPriceTimeframe = .oneDay {
    didSet {
      if timeframe != oldValue {
        update()
      }
    }
  }
  /// A set of balances of your portfolio's visible assets based on `timeframe`
  @Published private(set) var historicalBalances: [BalanceTimePrice] = []
  /// Whether or not balances are still currently loading
  @Published private(set) var isLoadingBalances: Bool = false
  /// The current default base currency code
  @Published private(set) var currencyCode: String = CurrencyCode.usd.code {
    didSet {
      currencyFormatter.currencyCode = currencyCode
      guard oldValue != currencyCode else { return }
      update()
    }
  }
  
  @Published var networkFilter: NetworkFilter = .allNetworks {
    didSet {
      update()
    }
  }

  public private(set) lazy var userAssetsStore: UserAssetsStore = .init(
    walletService: self.walletService,
    blockchainRegistry: self.blockchainRegistry,
    rpcService: self.rpcService,
    keyringService: self.keyringService,
    assetRatioService: self.assetRatioService
  )
  
  let currencyFormatter: NumberFormatter = .usdCurrencyFormatter
  
  /// Cancellable for the last running `update()` Task.
  private var updateTask: Task<(), Never>?
  /// Cache of total balances. The key is the token's `assetBalanceId`.
  private var totalBalancesCache: [String: Double] = [:]
  /// Cache of prices for each token. The key is the token's `assetRatioId`.
  private var pricesCache: [String: String] = [:]
  /// Cache of priceHistories. The key is the token's `assetRatioId`.
  private var priceHistoriesCache: [String: [BraveWallet.AssetTimePrice]] = [:]

  private let keyringService: BraveWalletKeyringService
  private let rpcService: BraveWalletJsonRpcService
  private let walletService: BraveWalletBraveWalletService
  private let assetRatioService: BraveWalletAssetRatioService
  private let blockchainRegistry: BraveWalletBlockchainRegistry

  public init(
    keyringService: BraveWalletKeyringService,
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService,
    assetRatioService: BraveWalletAssetRatioService,
    blockchainRegistry: BraveWalletBlockchainRegistry
  ) {
    self.keyringService = keyringService
    self.rpcService = rpcService
    self.walletService = walletService
    self.assetRatioService = assetRatioService
    self.blockchainRegistry = blockchainRegistry

    self.rpcService.add(self)
    self.keyringService.add(self)
    self.walletService.add(self)

    keyringService.isLocked { [self] isLocked in
      if !isLocked {
        update()
      }
    }
    walletService.defaultBaseCurrency { [self] currencyCode in
      self.currencyCode = currencyCode
    }
  }
  
  func update() {
    self.updateTask?.cancel()
    self.updateTask = Task { @MainActor in
      self.isLoadingBalances = true
      let networks: [BraveWallet.NetworkInfo]
      switch networkFilter {
      case .allNetworks:
        networks = await self.rpcService.allNetworksForSupportedCoins()
          .filter { !WalletConstants.supportedTestNetworkChainIds.contains($0.chainId) }
      case let .network(network):
        networks = [network]
      }
      struct AssetsForNetwork: Equatable {
        let network: BraveWallet.NetworkInfo
        let tokens: [BraveWallet.BlockchainToken]
        let sortOrder: Int
      }
      let allVisibleUserAssets = await withTaskGroup(
        of: [AssetsForNetwork].self,
        body: { @MainActor group -> [AssetsForNetwork] in
          for (index, network) in networks.enumerated() {
            group.addTask {
              let userAssets = await self.walletService.userAssets(network.chainId, coin: network.coin).filter(\.visible)
              return [AssetsForNetwork(network: network, tokens: userAssets, sortOrder: index)]
            }
          }
          return await group.reduce([AssetsForNetwork](), { $0 + $1 })
            .sorted(by: { $0.sortOrder < $1.sortOrder }) // maintain sort order of networks
        }
      )
      let visibleUserAssetsForNetwork = allVisibleUserAssets.map {
        AssetsForNetwork(
          network: $0.network,
          tokens: $0.tokens.filter { !$0.isErc721 && !$0.isNft },
          sortOrder: $0.sortOrder
        )
      }
      let visibleNFTUserAssetsForNetwork = allVisibleUserAssets.map {
        AssetsForNetwork(
          network: $0.network,
          tokens: $0.tokens.filter { $0.isErc721 || $0.isNft },
          sortOrder: $0.sortOrder
        )
      }
      // update userVisibleAssets on display immediately with empty values. Issue #5567
      userVisibleAssets = visibleUserAssetsForNetwork.flatMap { assetsForNetwork in
        assetsForNetwork.tokens.map { token in
          AssetViewModel(
            token: token,
            network: assetsForNetwork.network,
            decimalBalance: totalBalancesCache[token.assetBalanceId] ?? 0,
            price: pricesCache[token.assetRatioId.lowercased()] ?? "",
            history: priceHistoriesCache[token.assetRatioId.lowercased()] ?? []
          )
        }
      }
      userVisibleNFTs = visibleNFTUserAssetsForNetwork.flatMap { assetsForNetwork in
        assetsForNetwork.tokens.map { token in
          NFTAssetViewModel(
            token: token,
            network: assetsForNetwork.network,
            balance: Int(totalBalancesCache[token.assetBalanceId] ?? 0)
          )
        }
      }
      let keyrings = await self.keyringService.keyrings(for: WalletConstants.supportedCoinTypes)
      guard !Task.isCancelled else { return }
      // fetch balance for every token
      for userVisibleAsset in self.userVisibleAssets {
        let accountsToFetchBalance = keyrings.first(where: { $0.coin == userVisibleAsset.token.coin })?.accountInfos ?? []
        let totalBalance = await fetchTotalBalance(
          token: userVisibleAsset.token,
          network: userVisibleAsset.network,
          accounts: accountsToFetchBalance
        )
        totalBalancesCache[userVisibleAsset.token.assetBalanceId] = totalBalance
      }
      guard !Task.isCancelled else { return }
      for userVisibleNFT in self.userVisibleNFTs {
        let accountsToFetchBalance = keyrings.first(where: { $0.coin == userVisibleNFT.token.coin })?.accountInfos ?? []
        // fetch balance
        let totalBalance = await fetchTotalBalance(
          token: userVisibleNFT.token,
          network: userVisibleNFT.network,
          accounts: accountsToFetchBalance
        )
        totalBalancesCache[userVisibleNFT.token.assetBalanceId] = totalBalance
      }

      // fetch price for every token
      let allTokens = allVisibleUserAssets.flatMap(\.tokens)
      let allAssetRatioIds = allTokens.map(\.assetRatioId)
      let prices: [String: String] = await fetchPrices(for: allAssetRatioIds)
      for (key, value) in prices { // update cached values
        self.pricesCache[key] = value
      }

      // fetch price history for every non-zero balance token
      let nonZeroBalanceAssetRatioIds: [String] = allTokens
        .filter { (totalBalancesCache[$0.assetBalanceId] ?? 0) > 0 }
        .map { $0.assetRatioId }
      let priceHistories: [String: [BraveWallet.AssetTimePrice]] = await fetchPriceHistory(for: nonZeroBalanceAssetRatioIds)
      for (key, value) in priceHistories { // update cached values
        self.priceHistoriesCache[key] = value
      }
      
      guard !Task.isCancelled else { return }
      // build our userVisibleAssets
      userVisibleAssets = visibleUserAssetsForNetwork.flatMap { assetsForNetwork in
        assetsForNetwork.tokens.map { token in
          AssetViewModel(
            token: token,
            network: assetsForNetwork.network,
            decimalBalance: totalBalancesCache[token.assetBalanceId] ?? 0,
            price: pricesCache[token.assetRatioId.lowercased()] ?? "",
            history: priceHistoriesCache[token.assetRatioId.lowercased()] ?? []
          )
        }
      }
      userVisibleNFTs = visibleNFTUserAssetsForNetwork.flatMap { assetsForNetwork in
        assetsForNetwork.tokens.map { token in
          NFTAssetViewModel(
            token: token,
            network: assetsForNetwork.network,
            balance: Int(totalBalancesCache[token.assetBalanceId] ?? 0)
          )
        }
      }
      
      // Compute balance based on current prices
      let currentBalance = userVisibleAssets
        .compactMap {
          if let price = Double($0.price) {
            return $0.decimalBalance * price
          }
          return nil
        }
        .reduce(0.0, +)
      balance = currencyFormatter.string(from: NSNumber(value: currentBalance)) ?? "–"
      // Compute historical balances based on historical prices and current balances
      let assets = userVisibleAssets.filter { !$0.history.isEmpty }  // [[AssetTimePrice]]
      let minCount = assets.map(\.history.count).min() ?? 0  // Shortest array count
      historicalBalances = (0..<minCount).map { index in
        let value = assets.reduce(0.0, {
          $0 + ((Double($1.history[index].price) ?? 0.0) * $1.decimalBalance)
        })
        return .init(
          date: assets.map { $0.history[index].date }.max() ?? .init(),
          price: value,
          formattedPrice: currencyFormatter.string(from: NSNumber(value: value)) ?? "0.00"
        )
      }
      isLoadingBalances = false
    }
  }
  
  @MainActor private func fetchTotalBalance(
    token: BraveWallet.BlockchainToken,
    network: BraveWallet.NetworkInfo,
    accounts: [BraveWallet.AccountInfo]
  ) async -> Double {
    let balancesForAsset = await withTaskGroup(of: [Double].self, body: { group in
      for account in accounts {
        group.addTask {
          let balance = await self.rpcService.balance(
            for: token,
            in: account,
            network: network
          )
          return [balance ?? 0]
        }
      }
      return await group.reduce([Double](), { $0 + $1 })
    })
    return balancesForAsset.reduce(0, +)
  }
  
  /// Fetches the prices for a given list of `assetRatioId`, giving a dictionary with the price for each symbol
  @MainActor func fetchPrices(
    for priceIds: [String]
  ) async -> [String: String] {
    let priceResult = await assetRatioService.priceWithIndividualRetry(
      priceIds.map { $0.lowercased() },
      toAssets: [currencyFormatter.currencyCode],
      timeframe: timeframe
    )
    let prices = Dictionary(uniqueKeysWithValues: priceResult.assetPrices.map { ($0.fromAsset, $0.price) })
    return prices
  }
  
  /// Fetches the price history for the given `assetRatioId`, giving a dictionary with the price history for each symbol
  @MainActor func fetchPriceHistory(
    for priceIds: [String]
  ) async -> [String: [BraveWallet.AssetTimePrice]] {
    let uniquePriceIds = Set(priceIds)
    let priceHistories = await withTaskGroup(of: [String: [BraveWallet.AssetTimePrice]].self) { @MainActor group -> [String: [BraveWallet.AssetTimePrice]] in
      for priceId in uniquePriceIds {
        let priceId = priceId.lowercased()
        group.addTask { @MainActor in
          let (success, history) = await self.assetRatioService.priceHistory(
            priceId,
            vsAsset: self.currencyFormatter.currencyCode,
            timeframe: self.timeframe
          )
          if success {
            return [priceId: history.sorted(by: { $0.date < $1.date })]
          } else {
            return [:]
          }
        }
      }
      return await group.reduce(into: [String: [BraveWallet.AssetTimePrice]](), { partialResult, new in
        for key in new.keys {
          partialResult[key] = new[key]
        }
      })
    }
    return priceHistories
  }
}

extension PortfolioStore: BraveWalletJsonRpcServiceObserver {
  public func onIsEip1559Changed(_ chainId: String, isEip1559: Bool) {
  }

  public func onAddEthereumChainRequestCompleted(_ chainId: String, error: String) {
  }

  public func chainChangedEvent(_ chainId: String, coin: BraveWallet.CoinType) {
    update()
  }
}

extension PortfolioStore: BraveWalletKeyringServiceObserver {
  public func keyringReset() {
  }

  public func accountsChanged() {
    update()
  }
  public func backedUp() {
  }
  public func keyringCreated(_ keyringId: String) {
  }
  public func keyringRestored(_ keyringId: String) {
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
  public func selectedAccountChanged(_ coinType: BraveWallet.CoinType) {
    DispatchQueue.main.async { [self] in
      update()
    }
  }
}

extension PortfolioStore: BraveWalletBraveWalletServiceObserver {
  public func onActiveOriginChanged(_ originInfo: BraveWallet.OriginInfo) {
  }

  public func onDefaultWalletChanged(_ wallet: BraveWallet.DefaultWallet) {
  }

  public func onDefaultBaseCurrencyChanged(_ currency: String) {
    currencyCode = currency
  }

  public func onDefaultBaseCryptocurrencyChanged(_ cryptocurrency: String) {
  }

  public func onNetworkListChanged() {
  }
  
  public func onDefaultEthereumWalletChanged(_ wallet: BraveWallet.DefaultWallet) {
  }
  
  public func onDefaultSolanaWalletChanged(_ wallet: BraveWallet.DefaultWallet) {
  }
}
