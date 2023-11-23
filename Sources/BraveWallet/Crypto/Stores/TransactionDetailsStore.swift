// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore

class TransactionDetailsStore: ObservableObject, WalletObserverStore {
  
  let transaction: BraveWallet.TransactionInfo
  @Published private(set) var parsedTransaction: ParsedTransaction?
  @Published private(set) var network: BraveWallet.NetworkInfo?
  
  @Published private(set) var currencyCode: String = CurrencyCode.usd.code {
    didSet {
      currencyFormatter.currencyCode = currencyCode
      guard currencyCode != oldValue else { return }
      update()
    }
  }
  let currencyFormatter: NumberFormatter = .usdCurrencyFormatter
    .then {
      $0.minimumFractionDigits = 2
      $0.maximumFractionDigits = 6
    }
  
  private let keyringService: BraveWalletKeyringService
  private let walletService: BraveWalletBraveWalletService
  private let rpcService: BraveWalletJsonRpcService
  private let assetRatioService: BraveWalletAssetRatioService
  private let blockchainRegistry: BraveWalletBlockchainRegistry
  private let solanaTxManagerProxy: BraveWalletSolanaTxManagerProxy
  private let ipfsApi: IpfsAPI
  private let assetManager: WalletUserAssetManagerType
  /// Cache for storing `BlockchainToken`s that are not in user assets or our token registry.
  /// This could occur with a dapp creating a transaction.
  private var tokenInfoCache: [String: BraveWallet.BlockchainToken] = [:]
  private var nftMetadataCache: [String: NFTMetadata] = [:]
  
  var isObserving: Bool = false
  
  init(
    transaction: BraveWallet.TransactionInfo,
    parsedTransaction: ParsedTransaction?,
    keyringService: BraveWalletKeyringService,
    walletService: BraveWalletBraveWalletService,
    rpcService: BraveWalletJsonRpcService,
    assetRatioService: BraveWalletAssetRatioService,
    blockchainRegistry: BraveWalletBlockchainRegistry,
    solanaTxManagerProxy: BraveWalletSolanaTxManagerProxy,
    ipfsApi: IpfsAPI,
    userAssetManager: WalletUserAssetManagerType
  ) {
    self.transaction = transaction
    self.parsedTransaction = parsedTransaction
    self.keyringService = keyringService
    self.walletService = walletService
    self.rpcService = rpcService
    self.assetRatioService = assetRatioService
    self.blockchainRegistry = blockchainRegistry
    self.solanaTxManagerProxy = solanaTxManagerProxy
    self.ipfsApi = ipfsApi
    self.assetManager = userAssetManager
    
    walletService.defaultBaseCurrency { [self] currencyCode in
      self.currencyCode = currencyCode
    }
  }
  
  func update() {
    Task { @MainActor in
      let coin = transaction.coin
      let networksForCoin = await rpcService.allNetworks(coin)
      guard let network = networksForCoin.first(where: { $0.chainId == transaction.chainId }) else {
        // Transactions should be removed if their network is removed
        // https://github.com/brave/brave-browser/issues/30234
        assertionFailure("The NetworkInfo for the transaction's chainId (\(transaction.chainId)) is unavailable")
        return
      }
      self.network = network
      var allTokens: [BraveWallet.BlockchainToken] = await blockchainRegistry.allTokens(network.chainId, coin: network.coin) + tokenInfoCache.map(\.value)
      let userAssets: [BraveWallet.BlockchainToken] = assetManager.getAllUserAssetsInNetworkAssets(networks: [network], includingUserDeleted: true).flatMap { $0.tokens }
      let unknownTokenContractAddresses = transaction.tokenContractAddresses
        .filter { contractAddress in
          !userAssets.contains(where: { $0.contractAddress(in: network).caseInsensitiveCompare(contractAddress) == .orderedSame })
          && !allTokens.contains(where: { $0.contractAddress(in: network).caseInsensitiveCompare(contractAddress) == .orderedSame })
          && !tokenInfoCache.keys.contains(where: { $0.caseInsensitiveCompare(contractAddress) == .orderedSame })
        }
      if !unknownTokenContractAddresses.isEmpty {
        let unknownTokens = await assetRatioService.fetchTokens(for: unknownTokenContractAddresses)
        for unknownToken in unknownTokens {
          tokenInfoCache[unknownToken.contractAddress] = unknownToken
        }
        allTokens.append(contentsOf: unknownTokens)
      }
      
      let priceResult = await assetRatioService.priceWithIndividualRetry(
        userAssets.map { $0.assetRatioId.lowercased() },
        toAssets: [currencyFormatter.currencyCode],
        timeframe: .oneDay
      )
      let assetRatios = priceResult.assetPrices.reduce(into: [String: Double]()) {
        $0[$1.fromAsset] = Double($1.price)
      }
      var solEstimatedTxFee: UInt64?
      if transaction.coin == .sol {
        (solEstimatedTxFee, _, _) = await solanaTxManagerProxy.estimatedTxFee(network.chainId, txMetaId: transaction.id)
      }
      let allAccounts = await keyringService.allAccounts().accounts
      guard let parsedTransaction = transaction.parsedTransaction(
        network: network,
        accountInfos: allAccounts,
        userAssets: userAssets,
        allTokens: allTokens,
        assetRatios: assetRatios,
        nftMetadata: nftMetadataCache,
        solEstimatedTxFee: solEstimatedTxFee,
        currencyFormatter: currencyFormatter
      ) else {
        return
      }
      self.parsedTransaction = parsedTransaction

      // Fetch NFTMetadata if needed.
      let nftToken: BraveWallet.BlockchainToken?
      switch parsedTransaction.details {
      case .erc721Transfer(let details):
        if details.nftMetadata == nil {
          nftToken = details.fromToken
        } else {
          nftToken = nil
        }
      case .solSplTokenTransfer(let details):
        if let fromToken = details.fromToken,
           fromToken.isNft,
           details.fromTokenMetadata == nil {
          nftToken = fromToken
        } else {
          nftToken = nil
        }
      default:
        nftToken = nil
      }
      guard let nftToken else { return }
      self.nftMetadataCache[nftToken.id] = await rpcService.fetchNFTMetadata(for: nftToken, ipfsApi: ipfsApi)
      guard let parsedTransaction = transaction.parsedTransaction(
        network: network,
        accountInfos: allAccounts,
        userAssets: userAssets,
        allTokens: allTokens,
        assetRatios: assetRatios,
        nftMetadata: nftMetadataCache,
        solEstimatedTxFee: solEstimatedTxFee,
        currencyFormatter: currencyFormatter
      ) else {
        return
      }
      self.parsedTransaction = parsedTransaction
    }
  }
  
  @MainActor private func fetchTokenInfo(for contractAddress: String) async -> BraveWallet.BlockchainToken? {
    if let cachedToken = tokenInfoCache[contractAddress] {
      return cachedToken
    }
    let tokenInfo = await assetRatioService.tokenInfo(contractAddress)
    guard let tokenInfo = tokenInfo else { return nil }
    self.tokenInfoCache[contractAddress] = tokenInfo
    return tokenInfo
  }
}
