// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import BigNumber
import Strings

public class TransactionConfirmationStore: ObservableObject {
  struct State {
    var value: String = ""
    var symbol: String = ""
    var fiat: String = ""
    var gasValue: String = ""
    var gasSymbol: String = ""
    var gasFiat: String = ""
    var gasAssetRatio: Double = 0.0
    var totalFiat: String = ""
    var isBalanceSufficient: Bool = true
    var isUnlimitedApprovalRequested: Bool = false
    var currentAllowance: String = ""
    var proposedAllowance: String = ""
    var originInfo: BraveWallet.OriginInfo?
  }
  @Published var state: State = .init()
  @Published var gasEstimation1559: BraveWallet.GasEstimation1559?
  /// This is a list of all unpproved transactions iterated through all the accounts for the current keyring
  @Published private(set) var transactions: [BraveWallet.TransactionInfo] = []
  /// This is an id for the unppproved transaction that is currently displayed on screen
  @Published var activeTransactionId: BraveWallet.TransactionInfo.ID = "" {
    didSet {
      if let tx = transactions.first(where: { $0.id == activeTransactionId }) {
        fetchDetails(for: tx)
      } else if let firstTx = transactions.first {
        fetchDetails(for: firstTx)
      }
    }
  }
  @Published private(set) var currencyCode: String = CurrencyCode.usd.code {
    didSet {
      currencyFormatter.currencyCode = currencyCode
      fetchDetails(for: activeTransaction)
    }
  }

  let currencyFormatter: NumberFormatter = .usdCurrencyFormatter
    .then {
      $0.minimumFractionDigits = 2
      $0.maximumFractionDigits = 6
    }
  
  var activeTransaction: BraveWallet.TransactionInfo {
    transactions.first(where: { $0.id == activeTransactionId }) ?? (transactions.first ?? .init())
  }
  
  private(set) var activeParsedTransaction: ParsedTransaction?

  private let assetRatioService: BraveWalletAssetRatioService
  private let rpcService: BraveWalletJsonRpcService
  private let txService: BraveWalletTxService
  private let blockchainRegistry: BraveWalletBlockchainRegistry
  private let walletService: BraveWalletBraveWalletService
  private let ethTxManagerProxy: BraveWalletEthTxManagerProxy
  private let keyringService: BraveWalletKeyringService
  private let solTxManagerProxy: BraveWalletSolanaTxManagerProxy
  private var selectedChain: BraveWallet.NetworkInfo = .init()

  init(
    assetRatioService: BraveWalletAssetRatioService,
    rpcService: BraveWalletJsonRpcService,
    txService: BraveWalletTxService,
    blockchainRegistry: BraveWalletBlockchainRegistry,
    walletService: BraveWalletBraveWalletService,
    ethTxManagerProxy: BraveWalletEthTxManagerProxy,
    keyringService: BraveWalletKeyringService,
    solTxManagerProxy: BraveWalletSolanaTxManagerProxy
  ) {
    self.assetRatioService = assetRatioService
    self.rpcService = rpcService
    self.txService = txService
    self.blockchainRegistry = blockchainRegistry
    self.walletService = walletService
    self.ethTxManagerProxy = ethTxManagerProxy
    self.keyringService = keyringService
    self.solTxManagerProxy = solTxManagerProxy

    self.txService.add(self)
    self.walletService.add(self)
    
    walletService.defaultBaseCurrency { [self] currencyCode in
      self.currencyCode = currencyCode
    }
  }
  
  func nextTransaction() {
    if let index = transactions.firstIndex(where: { $0.id == activeTransactionId }) {
      var nextIndex = transactions.index(after: index)
      if nextIndex == transactions.endIndex {
        nextIndex = 0
      }
      activeTransactionId = transactions[nextIndex].id
    } else {
      activeTransactionId = transactions.first!.id
    }
  }

  func rejectAllTransactions() {
    for transaction in transactions {
      reject(transaction: transaction, completion: { _ in })
    }
  }

  func fetchDetails(for transaction: BraveWallet.TransactionInfo) {
    Task { @MainActor in
      let keyring = await keyringService.keyringInfo(transaction.coin.keyringId)
      let network = await rpcService.network(transaction.coin)
      let allTokens = await blockchainRegistry.allTokens(network.chainId, coin: transaction.coin)
      let userVisibleTokens = await walletService.userAssets(network.chainId, coin: transaction.coin)
      let priceResult = await assetRatioService.priceWithIndividualRetry(
        userVisibleTokens.map { $0.symbol.lowercased() },
        toAssets: [currencyFormatter.currencyCode],
        timeframe: .oneDay
      )
      let assetRatios = priceResult.assetPrices.reduce(into: [String: Double]()) {
        $0[$1.fromAsset] = Double($1.price)
      }
      
      var gasTokenBalance: Double?
      if let account = keyring.accountInfos.first(where: { $0.address == transaction.fromAddress }) {
        gasTokenBalance = await rpcService.balance(for: network.nativeToken, in: account)
      }
      
      var solEstimatedTxFee: UInt64?
      if transaction.coin == .sol {
        (solEstimatedTxFee, _, _) = await solTxManagerProxy.estimatedTxFee(transaction.id)
      }
      
      guard let parsedTransaction = transaction.parsedTransaction(
        network: network,
        accountInfos: keyring.accountInfos,
        visibleTokens: userVisibleTokens,
        allTokens: allTokens,
        assetRatios: assetRatios,
        solEstimatedTxFee: solEstimatedTxFee,
        currencyFormatter: currencyFormatter
      ) else {
        return
      }
      activeParsedTransaction = parsedTransaction
      
      state = .init() // Reset state
      state.originInfo = transaction.originInfo
      
      switch parsedTransaction.details {
      case let .ethSend(details),
        let .erc20Transfer(details),
        let .solSystemTransfer(details),
        let .solSplTokenTransfer(details):
        state.symbol = details.fromToken.symbol
        state.value = details.fromAmount
        state.fiat = details.fromFiat ?? ""
        
        if let gasFee = details.gasFee {
          state.gasValue = gasFee.fee
          state.gasFiat = gasFee.fiat
          state.gasSymbol = parsedTransaction.networkSymbol
          state.gasAssetRatio = assetRatios[parsedTransaction.networkSymbol.lowercased(), default: 0]
          
          if let gasBalance = gasTokenBalance,
             let gasValue = BDouble(gasFee.fee),
             BDouble(gasBalance) > gasValue {
            state.isBalanceSufficient = true
          } else {
            state.isBalanceSufficient = false
          }
        }
        
        state.totalFiat = totalFiat(value: state.value, tokenSymbol: state.symbol, gasValue: state.gasValue, gasSymbol: state.gasSymbol, assetRatios: assetRatios, currencyFormatter: currencyFormatter)
        
      case let .ethErc20Approve(details):
        state.value = details.approvalAmount
        state.symbol = details.token.symbol
        state.proposedAllowance = details.approvalValue
        state.isUnlimitedApprovalRequested = details.isUnlimited
        if let gasFee = details.gasFee {
          state.gasValue = gasFee.fee
          state.gasFiat = gasFee.fiat
          state.gasSymbol = parsedTransaction.networkSymbol
          state.gasAssetRatio = assetRatios[parsedTransaction.networkSymbol.lowercased(), default: 0]
          
          if let gasBalance = gasTokenBalance,
             let gasValue = BDouble(gasFee.fee),
             BDouble(gasBalance) > gasValue {
            state.isBalanceSufficient = true
          } else {
            state.isBalanceSufficient = false
          }
        }
        
        state.totalFiat = state.gasFiat
        
        // Update `State.currentAllowance`
        let formatter = WeiFormatter(decimalFormatStyle: .balance)
        let contractAddress = transaction.txDataUnion.ethTxData1559?.baseData.to ?? ""
        if let token = allTokens.first(where: {
          $0.contractAddress(in: selectedChain).caseInsensitiveCompare(contractAddress) == .orderedSame
        }) {
          rpcService.erc20TokenAllowance(
            token.contractAddress(in: selectedChain),
            ownerAddress: transaction.fromAddress,
            spenderAddress: transaction.txArgs[safe: 0] ?? "") { allowance, status, _ in
              self.state.currentAllowance = formatter.decimalString(for: allowance.removingHexPrefix, radix: .hex, decimals: Int(token.decimals)) ?? ""
            }
        }
      case let .ethSwap(details):
        state.symbol = details.fromToken?.symbol ?? ""
        state.value = details.fromAmount
        if let gasFee = details.gasFee {
          state.gasValue = gasFee.fee
          state.gasFiat = gasFee.fiat
          state.gasSymbol = parsedTransaction.networkSymbol
          state.gasAssetRatio = assetRatios[parsedTransaction.networkSymbol.lowercased(), default: 0]
          
          if let gasBalance = gasTokenBalance,
             let gasValue = BDouble(gasFee.fee),
             BDouble(gasBalance) > gasValue {
            state.isBalanceSufficient = true
          } else {
            state.isBalanceSufficient = false
          }
          
          state.totalFiat = totalFiat(value: state.value, tokenSymbol: state.symbol, gasValue: state.gasValue, gasSymbol: state.gasSymbol, assetRatios: assetRatios, currencyFormatter: currencyFormatter)
        }
      case let .erc721Transfer(details):
        state.symbol = details.fromToken?.symbol ?? ""
        state.value = details.fromAmount
      }
    }
  }
  
  private func totalFiat(
    value: String,
    tokenSymbol: String,
    gasValue: String,
    gasSymbol: String,
    assetRatios: [String: Double],
    currencyFormatter: NumberFormatter
  ) -> String {
    let ratio = assetRatios[tokenSymbol.lowercased(), default: 0]
    let gasRatio = assetRatios[gasSymbol.lowercased(), default: 0]
    let amount = (Double(value) ?? 0.0) * ratio
    let gasAmount = (Double(gasValue) ?? 0.0) * gasRatio
    let totalFiat = currencyFormatter.string(from: NSNumber(value: amount + gasAmount)) ?? "$0.00"
    return totalFiat
  }

  @MainActor private func fetchTransactions() async -> [BraveWallet.TransactionInfo] {
    var allKeyrings: [BraveWallet.KeyringInfo] = []
    allKeyrings = await withTaskGroup(
      of: BraveWallet.KeyringInfo.self,
      returning: [BraveWallet.KeyringInfo].self,
      body: { group in
        for coin in WalletConstants.supportedCoinTypes {
          group.addTask {
            await self.keyringService.keyringInfo(coin.keyringId)
          }
        }
        var allKeyrings: [BraveWallet.KeyringInfo] = []
        for await keyring in group {
          allKeyrings.append(keyring)
        }
        return allKeyrings
      }
    )
    
    var pendingTransactions: [BraveWallet.TransactionInfo] = []
    pendingTransactions = await withTaskGroup(
      of: [BraveWallet.TransactionInfo].self,
      body: { group in
        for keyring in allKeyrings {
          for info in keyring.accountInfos {
            group.addTask {
              await self.txService.allTransactionInfo(info.coin, from: info.address)
            }
          }
        }
        var allPendingTx: [BraveWallet.TransactionInfo] = []
        for await transactions in group {
          allPendingTx.append(contentsOf: transactions.filter { $0.txStatus == .unapproved })
        }
        return allPendingTx
      }
    )
    
    return pendingTransactions
  }

  func confirm(transaction: BraveWallet.TransactionInfo, completion: @escaping (_ error: String?) -> Void) {
    txService.approveTransaction(transaction.coin, txMetaId: transaction.id) { success, error, message in
      completion(success ? nil : message)
    }
  }

  func reject(transaction: BraveWallet.TransactionInfo, completion: @escaping (Bool) -> Void) {
    txService.rejectTransaction(transaction.coin, txMetaId: transaction.id) { success in
      completion(success)
    }
  }

  func updateGasFeeAndLimits(
    for transaction: BraveWallet.TransactionInfo,
    maxPriorityFeePerGas: String,
    maxFeePerGas: String,
    gasLimit: String,
    completion: ((Bool) -> Void)? = nil
  ) {
    assert(
      transaction.isEIP1559Transaction,
      "Use updateGasFeeAndLimits(for:gasPrice:gasLimit:) for standard transactions")
    ethTxManagerProxy.setGasFeeAndLimitForUnapprovedTransaction(
      transaction.id,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      maxFeePerGas: maxFeePerGas,
      gasLimit: gasLimit
    ) { success in
      completion?(success)
    }
  }

  func updateGasFeeAndLimits(
    for transaction: BraveWallet.TransactionInfo,
    gasPrice: String,
    gasLimit: String,
    completion: ((Bool) -> Void)? = nil
  ) {
    assert(
      !transaction.isEIP1559Transaction,
      "Use updateGasFeeAndLimits(for:maxPriorityFeePerGas:maxFeePerGas:gasLimit:) for EIP-1559 transactions")
    ethTxManagerProxy.setGasPriceAndLimitForUnapprovedTransaction(
      transaction.id,
      gasPrice: gasPrice,
      gasLimit: gasLimit
    ) { success in
      completion?(success)
    }
  }

  @MainActor func prepare() async {
    transactions = await fetchTransactions()
    if let firstTx = transactions.first {
      activeTransactionId = firstTx.id
      gasEstimation1559 = await ethTxManagerProxy.gasEstimation1559()
    }
  }

  func editNonce(
    for transaction: BraveWallet.TransactionInfo,
    nonce: String,
    completion: @escaping ((Bool) -> Void)
  ) {
    ethTxManagerProxy.setNonceForUnapprovedTransaction(transaction.id, nonce: nonce) { success in
      // not going to refresh unapproved transactions since the tx observer will be
      // notified `onTransactionStatusChanged` and `onUnapprovedTxUpdated`
      // `transactions` list will be refreshed there.
      completion(success)
    }
  }
  
  func editAllowance(
    txMetaId: String,
    spenderAddress: String,
    amount: String,
    completion: @escaping (Bool) -> Void
  ) {
    ethTxManagerProxy.makeErc20ApproveData(spenderAddress, amount: amount) { [weak self] success, data in
      guard let self = self else { return }
      if !success {
        completion(false)
        return
      }
      self.ethTxManagerProxy.setDataForUnapprovedTransaction(txMetaId, data: data) { success in
        // not going to refresh unapproved transactions since the tx observer will be
        // notified `onTransactionStatusChanged` and `onUnapprovedTxUpdated`
        // `transactions` list will be refreshed there.
        completion(success)
      }
    }
  }
}

extension TransactionConfirmationStore: BraveWalletTxServiceObserver {
  public func onNewUnapprovedTx(_ txInfo: BraveWallet.TransactionInfo) {
    // won't have any new unapproved tx being added if you on tx confirmation panel
  }
  public func onTransactionStatusChanged(_ txInfo: BraveWallet.TransactionInfo) {
    Task { @MainActor in
      await refreshTransactions(txInfo)
    }
  }
  public func onUnapprovedTxUpdated(_ txInfo: BraveWallet.TransactionInfo) {
    Task { @MainActor in
      // refresh the unapproved transaction list, as well as tx details UI
      await refreshTransactions(txInfo)
    }
  }

  @MainActor private func refreshTransactions(_ txInfo: BraveWallet.TransactionInfo) async {
    transactions = await fetchTransactions()
    if activeTransactionId == txInfo.id {
      fetchDetails(for: txInfo)
    }
  }
}

extension TransactionConfirmationStore: BraveWalletBraveWalletServiceObserver {
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
