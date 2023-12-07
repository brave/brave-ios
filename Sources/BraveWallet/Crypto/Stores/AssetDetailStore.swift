// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import SwiftUI

struct AccountAssetViewModel: Identifiable {
  var account: BraveWallet.AccountInfo
  fileprivate var decimalBalance: Double
  var balance: String
  var fiatBalance: String

  var id: String {
    account.id
  }
}

enum AssetDetailType: Identifiable {
  case blockchainToken(BraveWallet.BlockchainToken)
  case coinMarket(BraveWallet.CoinMarket)
  
  var id: String {
    switch self {
    case .blockchainToken(let token):
      return token.id
    case .coinMarket(let coinMarket):
      return coinMarket.id
    }
  }
}

class AssetDetailStore: ObservableObject, WalletObserverStore {
  @Published private(set) var isInitialState: Bool = true
  @Published private(set) var isLoadingPrice: Bool = false
  @Published private(set) var isLoadingChart: Bool = false
  @Published private(set) var price: String = "$0.0000"
  @Published private(set) var priceDelta: String = "0.00%"
  @Published private(set) var priceIsDown: Bool = false
  @Published private(set) var btcRatio: String = "0.0000 BTC"
  @Published private(set) var priceHistory: [BraveWallet.AssetTimePrice] = []
  @Published var timeframe: BraveWallet.AssetPriceTimeframe = .oneDay {
    didSet {
      if timeframe != oldValue {
        update()
      }
    }
  }
  @Published private(set) var isLoadingAccountBalances: Bool = false
  @Published private(set) var accounts: [AccountAssetViewModel] = []
  @Published private(set) var transactionSummaries: [TransactionSummary] = []
  @Published private(set) var isBuySupported: Bool = false
  @Published private(set) var isSendSupported: Bool = false
  @Published private(set) var isSwapSupported: Bool = false
  @Published private(set) var currencyCode: String = CurrencyCode.usd.code {
    didSet {
      currencyFormatter.currencyCode = currencyCode
      guard oldValue != currencyCode, // only if currency code changed
            !isInitialState // only update if we're not in initial state
      else { return }
      update()
    }
  }
  @Published private(set) var network: BraveWallet.NetworkInfo?

  let currencyFormatter: NumberFormatter = .usdCurrencyFormatter

  private(set) var assetPriceValue: Double = 0.0

  private let assetRatioService: BraveWalletAssetRatioService
  private let keyringService: BraveWalletKeyringService
  private let walletService: BraveWalletBraveWalletService
  private let rpcService: BraveWalletJsonRpcService
  private let txService: BraveWalletTxService
  private let blockchainRegistry: BraveWalletBlockchainRegistry
  private let solTxManagerProxy: BraveWalletSolanaTxManagerProxy
  private let ipfsApi: IpfsAPI
  private let swapService: BraveWalletSwapService
  private let assetManager: WalletUserAssetManagerType
  /// A list of tokens that are supported with the current selected network for all supported
  /// on-ramp providers.
  private var allBuyTokensAllOptions: [BraveWallet.OnRampProvider: [BraveWallet.BlockchainToken]] = [:]
  /// Cache for storing `BlockchainToken`s that are not in user assets or our token registry.
  /// This could occur with a dapp creating a transaction.
  private var tokenInfoCache: [BraveWallet.BlockchainToken] = []
  private var keyringServiceObserver: KeyringServiceObserver?
  private var txServiceObserver: TxServiceObserver?
  private var walletServiceObserver: WalletServiceObserver?
  let assetDetailType: AssetDetailType
  var assetDetailToken: BraveWallet.BlockchainToken {
    switch assetDetailType {
    case .blockchainToken(let token):
      return token
    case .coinMarket(let coinMarket):
      return .init().then {
        for tokens in allBuyTokensAllOptions.values {
          if let matchedToken = tokens.first(where: { token in token.symbol.caseInsensitiveCompare(coinMarket.symbol) == .orderedSame }) {
            $0.contractAddress = matchedToken.contractAddress
            $0.coin = matchedToken.coin
            $0.chainId = matchedToken.chainId
            break
          }
        }
        $0.coingeckoId = coinMarket.id
        $0.logo = coinMarket.image
        $0.symbol = coinMarket.symbol.uppercased() // ramp needs capitalized token symbol to get a valid buy url
        $0.name = coinMarket.name
      }
    }
  }
  
  var isObserving: Bool {
    keyringServiceObserver != nil && txServiceObserver != nil && walletServiceObserver != nil
  }

  init(
    assetRatioService: BraveWalletAssetRatioService,
    keyringService: BraveWalletKeyringService,
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService,
    txService: BraveWalletTxService,
    blockchainRegistry: BraveWalletBlockchainRegistry,
    solTxManagerProxy: BraveWalletSolanaTxManagerProxy,
    ipfsApi: IpfsAPI,
    swapService: BraveWalletSwapService,
    userAssetManager: WalletUserAssetManagerType,
    assetDetailType: AssetDetailType
  ) {
    self.assetRatioService = assetRatioService
    self.keyringService = keyringService
    self.rpcService = rpcService
    self.walletService = walletService
    self.txService = txService
    self.blockchainRegistry = blockchainRegistry
    self.solTxManagerProxy = solTxManagerProxy
    self.ipfsApi = ipfsApi
    self.swapService = swapService
    self.assetManager = userAssetManager
    self.assetDetailType = assetDetailType

    self.setupObservers()
    
    walletService.defaultBaseCurrency { [self] currencyCode in
      self.currencyCode = currencyCode
    }
  }
  
  func tearDown() {
    keyringServiceObserver = nil
    txServiceObserver = nil
    walletServiceObserver = nil
    transactionDetailsStore?.tearDown()
  }
  
  func setupObservers() {
    guard !isObserving else { return }
    self.keyringServiceObserver = KeyringServiceObserver(
      keyringService: keyringService,
      _accountsChanged: { [weak self] in
        self?.update()
      }
    )
    self.txServiceObserver = TxServiceObserver(
      txService: txService,
      _onTransactionStatusChanged: { [weak self] _ in
        self?.update()
      }
    )
    self.walletServiceObserver = WalletServiceObserver(
      walletService: walletService,
      _onDefaultBaseCurrencyChanged: { [weak self] currency in
        self?.currencyCode = currency
      }
    )
  }

  private let percentFormatter = NumberFormatter().then {
    $0.numberStyle = .percent
    $0.maximumFractionDigits = 2
  }
  
  public func update() {
    Task { @MainActor in
      self.isLoadingPrice = true
      self.isLoadingChart = true
      
      switch assetDetailType {
      case .blockchainToken(let token):
        // not come from Market tab
        let allNetworks = await rpcService.allNetworks(token.coin)
        let selectedNetwork = await rpcService.network(token.coin, origin: nil)
        let network = allNetworks.first(where: { $0.chainId == token.chainId }) ?? selectedNetwork
        self.network = network
        self.isBuySupported = await self.isBuyButtonSupported(in: network, for: token.symbol)
        self.isSendSupported = true
        self.isSwapSupported = await swapService.isSwapSupported(token.chainId)
        
        // fetch accounts
        let allAccountsForTokenCoin = await keyringService.allAccounts().accounts.filter { $0.coin == token.coin }
        var updatedAccounts = allAccountsForTokenCoin.map {
          AccountAssetViewModel(account: $0, decimalBalance: 0.0, balance: "", fiatBalance: "")
        }
        
        if !token.isErc721 && !token.isNft {
          // fetch prices for the asset
          let (prices, btcRatio, priceHistory) = await fetchPriceInfo(for: token.assetRatioId)
          self.btcRatio = btcRatio
          self.priceHistory = priceHistory
          self.isLoadingPrice = false
          self.isInitialState = false
          self.isLoadingChart = false
          
          if let assetPrice = prices.first(where: { $0.toAsset.caseInsensitiveCompare(self.currencyFormatter.currencyCode) == .orderedSame }),
             let value = Double(assetPrice.price) {
            self.assetPriceValue = value
            self.price = self.currencyFormatter.string(from: NSNumber(value: value)) ?? ""
            if let deltaValue = Double(assetPrice.assetTimeframeChange) {
              self.priceIsDown = deltaValue < 0
              self.priceDelta = self.percentFormatter.string(from: NSNumber(value: deltaValue / 100.0)) ?? ""
            }
            for index in 0..<updatedAccounts.count {
              updatedAccounts[index].fiatBalance = self.currencyFormatter.string(from: NSNumber(value: updatedAccounts[index].decimalBalance * self.assetPriceValue)) ?? ""
            }
          }
        }
        
        self.accounts = await fetchAccountBalances(updatedAccounts, network: network)
        let assetRatios = [token.assetRatioId.lowercased(): assetPriceValue]
        self.transactionSummaries = await fetchTransactionSummarys(
          accounts: allAccountsForTokenCoin,
          network: network,
          assetRatios: assetRatios
        )
      case .coinMarket(let coinMarket):
        // comes from Market tab
        self.price = self.currencyFormatter.string(from: NSNumber(value: coinMarket.currentPrice)) ?? ""
        self.priceDelta = self.percentFormatter.string(from: NSNumber(value: coinMarket.priceChangePercentage24h / 100.0)) ?? ""
        self.priceIsDown = coinMarket.priceChangePercentage24h < 0
        
        let (_, btcRatio, priceHistory) = await self.fetchPriceInfo(for: coinMarket.id)
        self.btcRatio = btcRatio
        self.priceHistory = priceHistory
        self.isLoadingPrice = false
        self.isInitialState = false
        self.isLoadingChart = false
        
        let selectedCoin = await keyringService.allAccounts().selectedAccount?.coin ?? .eth
        // selected network used because we don't have `chainId` on CoinMarket
        let selectedNetwork = await self.rpcService.network(selectedCoin, origin: nil)
        self.isBuySupported = await self.isBuyButtonSupported(in: selectedNetwork, for: coinMarket.symbol)

        // below is all not supported from Market tab
        self.isSendSupported = false
        self.isSwapSupported = false
        self.accounts = []
        self.transactionSummaries = []
      }
    }
  }
  
  @MainActor private func isBuyButtonSupported(in network: BraveWallet.NetworkInfo, for symbol: String) async -> Bool {
    let buyOptions: [BraveWallet.OnRampProvider] = Array(BraveWallet.OnRampProvider.allSupportedOnRampProviders)
    self.allBuyTokensAllOptions = await blockchainRegistry.allBuyTokens(in: network, for: buyOptions)
    let buyTokens = allBuyTokensAllOptions.flatMap { $0.value }
    return buyTokens.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) != nil
  }
  
  // Return given token's asset prices, btc ratio and price history
  @MainActor private func fetchPriceInfo(for tokenId: String) async -> ([BraveWallet.AssetPrice], String, [BraveWallet.AssetTimePrice]) {
    // fetch prices for the asset
    var assetPrices: [BraveWallet.AssetPrice] = []
    var btcRatio = "0.0000 BTC"
    let (_, prices) = await assetRatioService.price([tokenId], toAssets: [currencyFormatter.currencyCode, "btc"], timeframe: timeframe)
    assetPrices = prices
    if tokenId.caseInsensitiveCompare("bitcoin") == .orderedSame {
      btcRatio = "1 BTC"
    } else if let assetPrice = prices.first(where: { $0.toAsset == "btc" }) {
      btcRatio = "\(assetPrice.price) BTC"
    }
    // fetch price history for the asset
    let (_, priceHistory) = await assetRatioService.priceHistory(tokenId, vsAsset: currencyFormatter.currencyCode, timeframe: timeframe)
    
    return (assetPrices, btcRatio, priceHistory)
  }
  
  @MainActor private func fetchAccountBalances(
    _ accountAssetViewModels: [AccountAssetViewModel],
    network: BraveWallet.NetworkInfo
  ) async -> [AccountAssetViewModel] {
    guard case let .blockchainToken(token) = assetDetailType
    else { return [] }

    var accountAssetViewModels = accountAssetViewModels
    isLoadingAccountBalances = true
    typealias AccountBalance = (account: BraveWallet.AccountInfo, balance: Double?)
    let tokenBalances = await withTaskGroup(of: [AccountBalance].self) { @MainActor group -> [AccountBalance] in
      for accountAssetViewModel in accountAssetViewModels {
        group.addTask { @MainActor in
          let balance = await self.rpcService.balance(for: token, in: accountAssetViewModel.account, network: network)
          return [AccountBalance(accountAssetViewModel.account, balance)]
        }
      }
      return await group.reduce([AccountBalance](), { $0 + $1 })
    }
    for tokenBalance in tokenBalances {
      if let index = accountAssetViewModels.firstIndex(where: { $0.account.address == tokenBalance.account.address }) {
        accountAssetViewModels[index].decimalBalance = tokenBalance.balance ?? 0.0
        if token.isErc721 || token.isNft {
          accountAssetViewModels[index].balance = (tokenBalance.balance ?? 0) > 0 ? "1" : "0"
        } else {
          accountAssetViewModels[index].balance = String(format: "%.4f", tokenBalance.balance ?? 0.0)
          accountAssetViewModels[index].fiatBalance = self.currencyFormatter.string(from: NSNumber(value: accountAssetViewModels[index].decimalBalance * assetPriceValue)) ?? ""
        }
      }
    }
    self.isLoadingAccountBalances = false
    return accountAssetViewModels
  }
  
  @MainActor private func fetchTransactionSummarys(
    accounts: [BraveWallet.AccountInfo],
    network: BraveWallet.NetworkInfo,
    assetRatios: [String: Double]
  ) async -> [TransactionSummary] {
    guard case let .blockchainToken(token) = assetDetailType
    else { return [] }
    let userAssets = assetManager.getAllUserAssetsInNetworkAssets(networks: [network], includingUserDeleted: true).flatMap { $0.tokens }
    let allTokens = await blockchainRegistry.allTokens(network.chainId, coin: network.coin)
    let allTransactions = await withTaskGroup(of: [BraveWallet.TransactionInfo].self) { @MainActor group -> [BraveWallet.TransactionInfo] in
      for account in accounts {
        group.addTask { @MainActor in
          await self.txService.allTransactionInfo(
            network.coin,
            chainId: network.chainId,
            from: account.accountId
          )
        }
      }
      return await group.reduce([BraveWallet.TransactionInfo](), { partialResult, prior in
        return partialResult + prior
      })
    }
    var solEstimatedTxFees: [String: UInt64] = [:]
    switch token.coin {
    case .eth:
      let ethTransactions = allTransactions.filter { $0.coin == .eth }
      if !ethTransactions.isEmpty { // we can only fetch unknown Ethereum tokens
        let unknownTokenInfo = ethTransactions.unknownTokenContractAddressChainIdPairs(
          knownTokens: userAssets + allTokens + tokenInfoCache
        )
        updateUnknownTokens(for: unknownTokenInfo)
      }
    case .sol:
      solEstimatedTxFees = await solTxManagerProxy.estimatedTxFees(for: allTransactions)
    default:
      break
    }
    return allTransactions
      .filter { tx in
        switch tx.txType {
        case .erc20Approve, .erc20Transfer:
          guard let tokenContractAddress = tx.txDataUnion.ethTxData1559?.baseData.to else {
            return false
          }
          return tokenContractAddress.caseInsensitiveCompare(token.contractAddress) == .orderedSame
        case .ethSend, .ethSwap, .other:
          return network.symbol.caseInsensitiveCompare(token.symbol) == .orderedSame
        case .erc721TransferFrom, .erc721SafeTransferFrom:
          guard let tokenContractAddress = tx.txDataUnion.ethTxData1559?.baseData.to else { return false }
          return tokenContractAddress.caseInsensitiveCompare(token.contractAddress) == .orderedSame
        case .solanaSystemTransfer:
          return network.symbol.caseInsensitiveCompare(token.symbol) == .orderedSame
        case .solanaSplTokenTransfer, .solanaSplTokenTransferWithAssociatedTokenAccountCreation:
          guard let tokenContractAddress = tx.txDataUnion.solanaTxData?.splTokenMintAddress else {
            return false
          }
          return tokenContractAddress.caseInsensitiveCompare(token.contractAddress) == .orderedSame
        case .erc1155SafeTransferFrom, .solanaDappSignTransaction, .solanaDappSignAndSendTransaction, .solanaSwap:
          return false
        case .ethFilForwarderTransfer:
          return false
        @unknown default:
          return false
        }
      }
      .sorted(by: { $0.createdTime > $1.createdTime })
      .map { transaction in
        TransactionParser.transactionSummary(
          from: transaction,
          network: network,
          accountInfos: accounts,
          userAssets: userAssets,
          allTokens: allTokens + tokenInfoCache,
          assetRatios: assetRatios,
          nftMetadata: [:],
          solEstimatedTxFee: solEstimatedTxFees[transaction.id],
          currencyFormatter: self.currencyFormatter
        )
      }
  }
  
  private var transactionDetailsStore: TransactionDetailsStore?
  func transactionDetailsStore(for transaction: BraveWallet.TransactionInfo) -> TransactionDetailsStore {
    let transactionDetailsStore = TransactionDetailsStore(
      transaction: transaction,
      parsedTransaction: nil,
      keyringService: keyringService,
      walletService: walletService,
      rpcService: rpcService,
      assetRatioService: assetRatioService,
      blockchainRegistry: blockchainRegistry,
      txService: txService,
      solanaTxManagerProxy: solTxManagerProxy,
      ipfsApi: ipfsApi,
      userAssetManager: assetManager
    )
    self.transactionDetailsStore = transactionDetailsStore
    return transactionDetailsStore
  }
  
  func closeTransactionDetailsStore() {
    self.transactionDetailsStore?.tearDown()
    self.transactionDetailsStore = nil
  }
  
  /// Should be called after dismissing create account. Returns true if an account was created
  @MainActor func handleDismissAddAccount() async -> Bool {
    if await keyringService.isAccountAvailable(for: assetDetailToken.coin, chainId: assetDetailToken.chainId) {
      self.update()
      return true
    } else {
      return false
    }
  }
  
  private func updateUnknownTokens(
    for contractAddressesChainIdPairs: [ContractAddressChainIdPair]
  ) {
    guard !contractAddressesChainIdPairs.isEmpty else { return }
    Task { @MainActor in
      // Gather known information about the transaction(s) tokens
      let unknownTokens: [BraveWallet.BlockchainToken] = await rpcService.fetchEthTokens(
        for: contractAddressesChainIdPairs
      )
      guard !unknownTokens.isEmpty else { return }
      tokenInfoCache.append(contentsOf: unknownTokens)
      update()
    }
  }
}

extension AssetDetailStore: BraveWalletKeyringServiceObserver {
  func walletReset() {
  }

  func accountsChanged() {
    update()
  }

  func walletCreated() {
  }

  func walletRestored() {
  }

  func locked() {
  }

  func unlocked() {
  }

  func backedUp() {
  }

  func autoLockMinutesChanged() {
  }

  func selectedWalletAccountChanged(_ account: BraveWallet.AccountInfo) {
  }
  
  func selectedDappAccountChanged(_ coin: BraveWallet.CoinType, account: BraveWallet.AccountInfo?) {
  }
  
  func accountsAdded(_ addedAccounts: [BraveWallet.AccountInfo]) {
  }
}

extension AssetDetailStore: BraveWalletTxServiceObserver {
  func onNewUnapprovedTx(_ txInfo: BraveWallet.TransactionInfo) {
  }
  func onUnapprovedTxUpdated(_ txInfo: BraveWallet.TransactionInfo) {
  }
  func onTransactionStatusChanged(_ txInfo: BraveWallet.TransactionInfo) {
    update()
  }
  func onTxServiceReset() {
  }
}

extension AssetDetailStore: BraveWalletBraveWalletServiceObserver {
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
  
  func onDefaultEthereumWalletChanged(_ wallet: BraveWallet.DefaultWallet) {
  }
  
  func onDefaultSolanaWalletChanged(_ wallet: BraveWallet.DefaultWallet) {
  }
  
  func onDiscoverAssetsStarted() {
  }
  
  func onDiscoverAssetsCompleted(_ discoveredAssets: [BraveWallet.BlockchainToken]) {
  }

  func onResetWallet() {
  }
}
