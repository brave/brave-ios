// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
import BraveCore
import SwiftUI

class WalletPanelStore: ObservableObject {

  @Published var assets: [AssetViewModel] = []

  @Published private(set) var currencyCode: String = CurrencyCode.usd.code {
    didSet {
      currencyFormatter.currencyCode = currencyCode
      guard oldValue != currencyCode else { return }
      update()
    }
  }

  let currencyFormatter: NumberFormatter = .usdCurrencyFormatter

  private let keyringService: BraveWalletKeyringService
  private let walletService: BraveWalletBraveWalletService
  private let rpcService: BraveWalletJsonRpcService
  private let assetRatioService: BraveWalletAssetRatioService

  init(
    keyringService: BraveWalletKeyringService,
    walletService: BraveWalletBraveWalletService,
    rpcService: BraveWalletJsonRpcService,
    assetRatioService: BraveWalletAssetRatioService
  ) {
    self.keyringService = keyringService
    self.walletService = walletService
    self.rpcService = rpcService
    self.assetRatioService = assetRatioService
  }

  func setup() {
    self.keyringService.add(self)
    self.walletService.add(self)
    self.rpcService.add(self)

    walletService.defaultBaseCurrency { [self] currencyCode in
      self.currencyCode = currencyCode
    }

    update()
  }

  private var updateTask: Task<Void, Never>?
  private func update() {
    updateTask?.cancel()
    updateTask = Task { @MainActor in
      let coin = await walletService.selectedCoin()
      let network = await rpcService.network(coin)
      let keyring = await keyringService.keyringInfo(coin.keyringId)
      let accountAddress = await keyringService.selectedAccount(coin)
      let userVisibleTokens: [BraveWallet.BlockchainToken] = await walletService.userAssets(network.chainId, coin: network.coin)
      guard !Task.isCancelled else { return }
      guard let accountAddress = accountAddress,
            let account = keyring.accountInfos.first(where: { $0.address.caseInsensitiveCompare(accountAddress) == .orderedSame }) else {
        return
      }
      self.assets = await fetchAssets(
        account: account,
        network: network,
        userVisibleTokens: userVisibleTokens
      )
    }
  }

  @MainActor private func fetchAssets(
    account: BraveWallet.AccountInfo,
    network: BraveWallet.NetworkInfo,
    userVisibleTokens: [BraveWallet.BlockchainToken]
  ) async -> [AssetViewModel] {
    var updatedAssets = userVisibleTokens.map {
      AssetViewModel(token: $0, decimalBalance: 0, price: "", history: [])
    }
    // fetch price for each asset
    let priceResult = await assetRatioService.priceWithIndividualRetry(
      userVisibleTokens.map { $0.assetRatioId.lowercased() },
      toAssets: [currencyFormatter.currencyCode],
      timeframe: .oneDay
    )
    for price in priceResult.assetPrices {
      if let index = updatedAssets.firstIndex(where: {
        $0.token.assetRatioId.caseInsensitiveCompare(price.fromAsset) == .orderedSame
      }) {
        updatedAssets[index].price = price.price
      }
    }
    // fetch balance for each asset
    typealias TokenBalance = (token: BraveWallet.BlockchainToken, balance: Double?)
    let tokenBalances = await withTaskGroup(of: [TokenBalance].self) { @MainActor group -> [TokenBalance] in
      for token in userVisibleTokens {
        group.addTask { @MainActor in
          let balance = await self.rpcService.balance(for: token, in: account)
          return [TokenBalance(token, balance)]
        }
      }
      return await group.reduce([TokenBalance](), { $0 + $1 })
    }
    // update assets with balance
    for tokenBalance in tokenBalances {
      if let value = tokenBalance.balance, let index = updatedAssets.firstIndex(where: {
        $0.token.symbol.caseInsensitiveCompare(tokenBalance.token.symbol) == .orderedSame
      }) {
        updatedAssets[index].decimalBalance = value
      }
    }
    return updatedAssets
  }
}

extension WalletPanelStore: BraveWalletKeyringServiceObserver {
  func keyringCreated(_ keyringId: String) {
  }

  func keyringRestored(_ keyringId: String) {
  }

  func keyringReset() {
  }

  func locked() {
  }

  func unlocked() {
  }

  func backedUp() {
  }

  func accountsChanged() {
  }

  func autoLockMinutesChanged() {
  }

  func selectedAccountChanged(_ coin: BraveWallet.CoinType) {
    update()
  }
}

extension WalletPanelStore: BraveWalletBraveWalletServiceObserver {
  func onDefaultEthereumWalletChanged(_ wallet: BraveWallet.DefaultWallet) {
  }
  
  func onDefaultSolanaWalletChanged(_ wallet: BraveWallet.DefaultWallet) {
  }
  
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
}

extension WalletPanelStore: BraveWalletJsonRpcServiceObserver {
  func chainChangedEvent(_ chainId: String, coin: BraveWallet.CoinType) {
    update()
  }

  func onAddEthereumChainRequestCompleted(_ chainId: String, error: String) {
  }

  func onIsEip1559Changed(_ chainId: String, isEip1559: Bool) {
  }
}
