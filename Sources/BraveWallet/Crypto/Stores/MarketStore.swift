// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BraveCore

struct CoinViewModel: Identifiable {
  var id: String
  var name: String
  var symbol: String
  var rank: Int
  var price: String
  var priceChangePercentage24h: String
}

public class MarketStore: ObservableObject {
  /// Avalaible coins in market
  @Published var coins: [BraveWallet.CoinMarket] = []
  /// Currency code for prices
  @Published private(set) var currencyCode: String = CurrencyCode.usd.code {
    didSet {
      priceFormatter.currencyCode = currencyCode
      guard oldValue != currencyCode else { return }
      update()
    }
  }
  /// Indicates `MarketStore` is loading coins in markets
  @Published var isLoading: Bool = false
  
  private let assetRatioService: BraveWalletAssetRatioService
  private let blockchainRegistry: BraveWalletBlockchainRegistry
  private let rpcService: BraveWalletJsonRpcService
  private let walletService: BraveWalletBraveWalletService
  private let assetsRequestLimit = 250
  var allCoingeckoTokens: [BraveWallet.BlockchainToken] = []
  let priceFormatter: NumberFormatter = .usdCurrencyFormatter
  let priceChangeFormatter = NumberFormatter().then {
    $0.numberStyle = .percent
    $0.minimumFractionDigits = 2
    $0.roundingMode = .up
  }
  
  init(
    assetRatioService: BraveWalletAssetRatioService,
    blockchainRegistry: BraveWalletBlockchainRegistry,
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService
  ) {
    self.assetRatioService = assetRatioService
    self.blockchainRegistry = blockchainRegistry
    self.rpcService = rpcService
    self.walletService = walletService
  }
  
  private var updateTask: Task<Void, Never>?
  func update() {
    isLoading = true
    updateTask?.cancel()
    updateTask = Task { @MainActor in
      // update market coins
      guard !Task.isCancelled else { return }
      let (success, assets) = await assetRatioService.coinMarkets(priceFormatter.currencyCode, limit: UInt8(assetsRequestLimit))
      if success {
        self.coins = assets
      }
      // update currency code
      guard !Task.isCancelled else { return }
      self.currencyCode = await walletService.defaultBaseCurrency()
      // update all supported coingecko tokens
      guard !Task.isCancelled else { return }
      self.allCoingeckoTokens = await fetchCoingeckoTokens()
      
      self.isLoading = false
    }
  }
  
  // Returns all coingecko tokens from the BlockchainRegistry and User's assets
  @MainActor func fetchCoingeckoTokens() async -> [BraveWallet.BlockchainToken] {
    let allNetworks = await rpcService.allNetworksForSupportedCoins()
    let allUserAssets = await walletService.allUserAssets(in: allNetworks)
    // Filter `allTokens` to remove any tokens existing in `allUserAssets`. This is possible for ERC721 tokens in the registry without a `tokenId`, which requires the user to add as a custom token
    let allUserTokens = allUserAssets.flatMap(\.tokens).filter { !$0.coingeckoId.isEmpty }
    let allBlockchainTokens = await blockchainRegistry.allTokens(in: allNetworks)
      .flatMap(\.tokens)
      .filter { token in
        !allUserTokens.contains(where: { $0.id == token.id && !$0.coingeckoId.isEmpty }) 
      }
    
    return allUserTokens + allBlockchainTokens
  }
}
