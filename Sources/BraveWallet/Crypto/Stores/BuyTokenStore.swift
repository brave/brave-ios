// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import OrderedCollections

/// A store contains data for buying tokens
public class BuyTokenStore: ObservableObject {
  /// The current selected token to buy. Default with nil value.
  @Published var selectedBuyToken: BraveWallet.BlockchainToken?
  /// The supported currencies for purchasing
  @Published var supportedCurrencies: [BraveWallet.OnRampCurrency] = []
  /// A boolean indicates if the current selected network supports `Buy`
  @Published var isSelectedNetworkSupported: Bool = false
  /// The amount user wishes to purchase
  @Published var buyAmount: String = ""
  /// The currency user wishes to purchase with
  @Published var selectedCurrency: BraveWallet.OnRampCurrency = .init()
  
  /// A map of list of available tokens to a certain on ramp provider
  var buyTokens: [BraveWallet.OnRampProvider: [BraveWallet.BlockchainToken]] = [.ramp: [], .wyre: [], .sardine: []]
  /// A list of all available tokens for all providers
  var allTokens: [BraveWallet.BlockchainToken] = []
  /// A list of on ramp providers for `selectedBuyToken`
  var supportedBuyOptionsByToken: [BraveWallet.OnRampProvider] {
    var providers = [BraveWallet.OnRampProvider]()
    for provider in buyTokens.keys {
      if let token = selectedBuyToken,
         let tokens = buyTokens[provider],
         tokens.includes(token) {
        providers.append(provider)
      }
    }
    return providers.sorted {
      $0.name < $1.name
    }
  }

  private let blockchainRegistry: BraveWalletBlockchainRegistry
  private let rpcService: BraveWalletJsonRpcService
  private let walletService: BraveWalletBraveWalletService
  private let assetRatioService: BraveWalletAssetRatioService
  private var selectedNetwork: BraveWallet.NetworkInfo = .init()
  private(set) var orderedSupportedBuyOptions: OrderedSet<BraveWallet.OnRampProvider> = []
  
  /// A map between chain id and gas token's symbol
  static let gasTokens: [String: [String]] = [
    BraveWallet.MainnetChainId: ["eth"],
    BraveWallet.OptimismMainnetChainId: ["eth"],
    BraveWallet.AuroraMainnetChainId: ["eth"],
    BraveWallet.PolygonMainnetChainId: ["matic"],
    BraveWallet.FantomMainnetChainId: ["ftm"],
    BraveWallet.CeloMainnetChainId: ["celo"],
    BraveWallet.BinanceSmartChainMainnetChainId: ["bnb"],
    BraveWallet.SolanaMainnet: ["sol"],
    BraveWallet.FilecoinMainnet: ["fil"],
    BraveWallet.AvalancheMainnetChainId: ["avax", "avaxc"]
  ]

  public init(
    blockchainRegistry: BraveWalletBlockchainRegistry,
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService,
    assetRatioService: BraveWalletAssetRatioService,
    prefilledToken: BraveWallet.BlockchainToken?
  ) {
    self.blockchainRegistry = blockchainRegistry
    self.rpcService = rpcService
    self.walletService = walletService
    self.assetRatioService = assetRatioService
    self.selectedBuyToken = prefilledToken
    
    self.rpcService.add(self)
    
    Task { @MainActor in
      await updateInfo()
    }
  }

  func fetchBuyUrl(
    provider: BraveWallet.OnRampProvider,
    account: BraveWallet.AccountInfo
  ) async -> String? {
    guard let token = selectedBuyToken else { return nil }
    
    let symbol: String
    switch provider {
    case .ramp:
      symbol = token.rampNetworkSymbol
    case .wyre:
      symbol = token.wyreSymbol
    case .sardine:
      symbol = token.symbol
    @unknown default:
      symbol = token.symbol
    }
    
    let (url, error) = await assetRatioService.buyUrlV1(
      provider,
      chainId: selectedNetwork.chainId,
      address: account.address,
      symbol: symbol,
      amount: buyAmount,
      currencyCode: selectedCurrency.currencyCode
    )

    guard error == nil else { return nil }
    
    // some adjustment
    if provider == .wyre {
      if selectedNetwork.chainId.caseInsensitiveCompare(BraveWallet.AvalancheMainnetChainId) == .orderedSame {
        return url.replacingOccurrences(of: "dest=ethereum", with: "dest=avalanche")
      } else if selectedNetwork.chainId.caseInsensitiveCompare(BraveWallet.PolygonMainnetChainId) == .orderedSame {
        return url.replacingOccurrences(of: "dest=ethereum", with: "dest=matic")
      }
    }
    
    return url
  }

  @MainActor
  private func fetchBuyTokens(network: BraveWallet.NetworkInfo) async {
    allTokens = []
    for provider in buyTokens.keys {
      let tokens = await blockchainRegistry.buyTokens(provider, chainId: network.chainId)
      let sortedTokenList = tokens.sorted(by: {
        if $0.isGasToken, !$1.isGasToken {
          return true
        } else if !$0.isGasToken, $1.isGasToken {
          return false
        } else if $0.isBatToken, !$1.isBatToken {
          return true
        } else if !$0.isBatToken, $1.isBatToken {
          return false
        } else {
          return $0.symbol < $1.symbol
        }
      })
      buyTokens[provider] = sortedTokenList
    }
    
    for provider in orderedSupportedBuyOptions {
      if let tokens = buyTokens[provider] {
        for token in tokens where !allTokens.includes(token) {
          allTokens.append(token)
        }
      }
    }
    
    if selectedBuyToken == nil || selectedBuyToken?.chainId != network.chainId {
      selectedBuyToken = allTokens.first
    }
  }
  
  @MainActor
  private func updateInfo() async {
    // check device language to determine if we support `Sardine`
    if Locale.preferredLanguages.first?.caseInsensitiveCompare("en-us") == .orderedSame {
      orderedSupportedBuyOptions = [.ramp, .wyre, .sardine]
    } else {
      orderedSupportedBuyOptions = [.ramp, .wyre]
    }
    
    let coin = await walletService.selectedCoin()
    selectedNetwork = await rpcService.network(coin)
    await fetchBuyTokens(network: selectedNetwork)
  
    // exclude all buy options that its available buy tokens list does not include the
    // `selectedBuyToken`
    orderedSupportedBuyOptions = OrderedSet(orderedSupportedBuyOptions
      .filter { [weak self] provider in
      guard let self = self,
            let tokens = self.buyTokens[provider],
            let selectedBuyToken = self.selectedBuyToken
      else { return false }
      return tokens.includes(selectedBuyToken)
    })
    
    // check if current selected network supports buy
    if WalletConstants.supportedTestNetworkChainIds.contains(selectedNetwork.chainId) {
      isSelectedNetworkSupported = false
    } else {
      isSelectedNetworkSupported = allTokens.contains(where: { token in
        return token.chainId.caseInsensitiveCompare(selectedNetwork.chainId) == .orderedSame
      })
    }
    
    // fetch all available currencies for on ramp providers
    supportedCurrencies = await blockchainRegistry.onRampCurrencies()
    if let firstCurrency = supportedCurrencies.first {
      selectedCurrency = firstCurrency
    }
  }
}

extension BuyTokenStore: BraveWalletJsonRpcServiceObserver {
  public func chainChangedEvent(_ chainId: String, coin: BraveWallet.CoinType) {
    Task { @MainActor in
      await updateInfo()
    }
  }
  
  public func onAddEthereumChainRequestCompleted(_ chainId: String, error: String) {
  }
  
  public func onIsEip1559Changed(_ chainId: String, isEip1559: Bool) {
  }
}

private extension BraveWallet.BlockchainToken {
  var isGasToken: Bool {
    guard let gasTokensByChain = BuyTokenStore.gasTokens[chainId] else { return false }
    return gasTokensByChain.contains { $0.caseInsensitiveCompare(symbol) == .orderedSame }
  }
  
  var isBatToken: Bool {
    // BAT/wormhole BAT/Avalanche C-Chain BAT
    return symbol.caseInsensitiveCompare("bat") == .orderedSame || symbol.caseInsensitiveCompare("wbat") == .orderedSame || symbol.caseInsensitiveCompare("bat.e") == .orderedSame
  }
  
  // a special symbol to fetch correct ramp.network buy url
  var rampNetworkSymbol: String {
    if symbol.caseInsensitiveCompare("bat") == .orderedSame && chainId.caseInsensitiveCompare(BraveWallet.MainnetChainId) == .orderedSame {
      // BAT is the only token on Ethereum Mainnet with a prefix on Ramp.Network
      return "ETH_BAT"
    } else if chainId.caseInsensitiveCompare(BraveWallet.AvalancheMainnetChainId) == .orderedSame && contractAddress.isEmpty {
      // AVAX native token has no prefix
      return symbol
    } else {
      let rampNetworkPrefix: String
      switch chainId.lowercased() {
      case BraveWallet.MainnetChainId.lowercased(),
        BraveWallet.CeloMainnetChainId.lowercased():
        rampNetworkPrefix = ""
      case BraveWallet.AvalancheMainnetChainId.lowercased():
        rampNetworkPrefix = "AVAXC"
      case BraveWallet.BinanceSmartChainMainnetChainId.lowercased():
        rampNetworkPrefix = "BSC"
      case BraveWallet.PolygonMainnetChainId.lowercased():
        rampNetworkPrefix = "MATIC"
      case BraveWallet.SolanaMainnet.lowercased():
        rampNetworkPrefix = "SOLANA"
      case BraveWallet.OptimismMainnetChainId.lowercased():
        rampNetworkPrefix = "OPTIMISM"
      case BraveWallet.FilecoinMainnet.lowercased():
        rampNetworkPrefix = "FILECOIN"
      default:
        rampNetworkPrefix = ""
      }
      
      return rampNetworkPrefix.isEmpty ? symbol : "\(rampNetworkPrefix)_\(symbol.uppercased())"
    }
  }
  
  // a special symbol to fetch correct wyre buy url
  var wyreSymbol: String {
    if contractAddress.isEmpty || chainId.caseInsensitiveCompare(BraveWallet.MainnetChainId) == .orderedSame {
      return symbol
    } else {
      let wyrePrefix: String
      switch chainId.lowercased() {
      case BraveWallet.PolygonMainnetChainId.lowercased():
        wyrePrefix = "M"
      case BraveWallet.AvalancheMainnetChainId.lowercased():
        wyrePrefix = "AVAXC"
      case BraveWallet.MainnetChainId.lowercased():
        wyrePrefix = ""
      default:
        wyrePrefix = ""
      }
      return wyrePrefix.isEmpty ? symbol : "\(wyrePrefix)\(symbol.uppercased())"
    }
  }
}
