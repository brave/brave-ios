// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import BigNumber
import Strings
import Combine

public class TransactionConfirmationStore: ObservableObject {
  /// The value that are being sent/swapped/approved in this transaction
  @Published var value: String = ""
  /// The symbol of token that are being send/swapped/approved in this transaction
  @Published var symbol: String = ""
  /// The fiat value of `value`
  @Published var fiat: String = ""
  /// The network name that this transaction is made on
  @Published var network: BraveWallet.NetworkInfo?
  /// The gas value for this transaction
  @Published var gasValue: String = ""
  /// The symbol of the gas token for this transaction
  @Published var gasSymbol: String = ""
  /// The fiat value of `gasValue`
  @Published var gasFiat: String = ""
  /// The price for gas token
  @Published var gasAssetRatio: Double = 0.0
  /// The combine fiat value of `value` and `gasValue`
  @Published var totalFiat: String = ""
  /// If transaction fee payer account has enough gas token balance
  @Published var isBalanceSufficient: Bool = true
  /// If user requests unlimited approval for a erc20 token
  @Published var isUnlimitedApprovalRequested: Bool = false
  /// If this Solana transaction does not have an associated token account created
  @Published var isSolTokenTransferWithAssociatedTokenAccountCreation: Bool = false
  /// The current erc20 token allowance
  @Published var currentAllowance: String = ""
  /// The proposed arc20 token allowance
  @Published var proposedAllowance: String = ""
  /// The details of this transaction
  @Published var transactionDetails: String = ""
  /// The gas esitimation for this eip1559 transaction
  @Published var eip1559GasEstimation: BraveWallet.GasEstimation1559?
  /// The origin info of this transaction
  @Published var originInfo: BraveWallet.OriginInfo?
  /// This is an id for the unppproved transaction that is currently displayed on screen
  @Published var activeTransactionId: BraveWallet.TransactionInfo.ID = "" {
    didSet {
      if let tx = allTxs.first(where: { $0.id == activeTransactionId }) {
        updateTransaction(with: tx)
        activeTxStatus = tx.txStatus
      } else if let firstTx = unapprovedTxs.first {
        updateTransaction(with: firstTx)
        activeTxStatus = firstTx.txStatus
      } else {
        activeTxStatus = .error
      }
    }
  }
  @Published private(set) var currencyCode: String = CurrencyCode.usd.code {
    didSet {
      currencyFormatter.currencyCode = currencyCode
      guard currencyCode != oldValue else { return }
      updateTransaction(with: activeTransaction)
    }
  }
  @Published var activeTxStatus: BraveWallet.TransactionStatus = .unapproved {
    didSet {
      if isTxSubmitting == true, oldValue == .approved, activeTxStatus != .approved {
        isTxSubmitting = false
      }
    }
  }
  /// Indicates Tx is being submitted. This value will be set to `true` after users click `Confirm` button
  @Published var isTxSubmitting: Bool = false
  
  /// All transactions with any kind of status of all the accounts for all supported keyrings
  @Published var allTxs: [BraveWallet.TransactionInfo] = []
  /// This is a list of all unpproved transactions iterated through all the accounts for all supported keyrings
  var unapprovedTxs: [BraveWallet.TransactionInfo] {
    return allTxs.filter { $0.txStatus == .unapproved }
  }
  var isReadyToBeDismissed: Bool {
    return unapprovedTxs.isEmpty && activeTransactionId.isEmpty
  }
  /// This is a map between transaction id and its error happened during transaction submitting
  var transactionProviderErrorRegistry: [String: TransactionProviderError] = [:]

  let currencyFormatter: NumberFormatter = .usdCurrencyFormatter
    .then {
      $0.minimumFractionDigits = 2
      $0.maximumFractionDigits = 6
    }
  
  private var activeTransaction: BraveWallet.TransactionInfo {
    unapprovedTxs.first(where: { $0.id == activeTransactionId }) ?? (unapprovedTxs.first ?? .init())
  }

  private(set) var activeParsedTransaction: ParsedTransaction = .init()
  private var activeTransactionDetails: String {
    if activeParsedTransaction.transaction.coin == .sol {
      return String.localizedStringWithFormat(Strings.Wallet.inputDataPlaceholderSolana, activeParsedTransaction.transaction.txType.rawValue)
    } else {
      if activeParsedTransaction.transaction.txArgs.isEmpty {
        let data = activeParsedTransaction.transaction.ethTxData
          .map { byte in
            String(format: "%02X", byte.uint8Value)
          }
          .joined()
        if data.isEmpty {
          return Strings.Wallet.inputDataPlaceholder
        }
        return "0x\(data)"
      } else {
        return zip(activeParsedTransaction.transaction.txParams, activeParsedTransaction.transaction.txArgs)
          .map { (param, arg) in
            "\(param): \(arg)"
          }
          .joined(separator: "\n\n")
      }
    }
  }
  
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
    if let index = unapprovedTxs.firstIndex(where: { $0.id == activeTransactionId }) {
      var nextIndex = unapprovedTxs.index(after: index)
      if nextIndex == unapprovedTxs.endIndex {
        nextIndex = 0
      }
      activeTransactionId = unapprovedTxs[nextIndex].id
    } else {
      activeTransactionId = unapprovedTxs.first!.id
    }
  }

  func rejectAllTransactions(completion: @escaping (Bool) -> Void) {
    let dispatchGroup = DispatchGroup()
    var allRejectsSucceeded = true
    for transaction in unapprovedTxs {
      dispatchGroup.enter()
      reject(transaction: transaction, completion: { success in
        defer { dispatchGroup.leave() }
        if !success {
          allRejectsSucceeded = false
        }
      })
    }
    dispatchGroup.notify(queue: .main) {
      completion(allRejectsSucceeded)
    }
  }
  
  @MainActor func prepare() async {
    allTxs = await fetchAllTransactions()
    if !unapprovedTxs.contains(where: { $0.id == activeTransactionId }) {
      self.activeTransactionId = unapprovedTxs.first?.id ?? ""
    }
    let coinsForTransactions: Set<BraveWallet.CoinType> = .init(unapprovedTxs.map(\.coin))
    for coin in coinsForTransactions {
      let network = await rpcService.network(coin, origin: nil)
      let userVisibleTokens = await walletService.userAssets(network.chainId, coin: coin)
      await fetchAssetRatios(for: userVisibleTokens)
    }
    await fetchUnknownTokens(for: unapprovedTxs)
    await fetchSolEstimatedTxFees(for: unapprovedTxs)
  }
  
  func updateTransaction(
    with transaction: BraveWallet.TransactionInfo,
    shouldFetchCurrentAllowance: Bool = true,
    shouldFetchGasTokenBalance: Bool = true
  ) {
    Task { @MainActor in
      clearTrasactionInfoBeforeUpdate()
      
      let coin = transaction.coin
      let keyring = await keyringService.keyringInfo(coin.keyringId)
      let network = await rpcService.network(coin, origin: nil)
      let allTokens = await blockchainRegistry.allTokens(network.chainId, coin: coin) + tokenInfoCache.map(\.value)
      let userVisibleTokens = await walletService.userAssets(network.chainId, coin: coin)
      let solEstimatedTxFee: UInt64? = solEstimatedTxFeeCache[transaction.id]
      
      if transaction.isEIP1559Transaction {
        eip1559GasEstimation = transaction.txDataUnion.ethTxData1559?.gasEstimation
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
      
      await fetchActiveTransactionDetails(
        keyring: keyring,
        network: network,
        allTokens: allTokens,
        shouldFetchCurrentAllowance: shouldFetchCurrentAllowance,
        shouldFetchGasTokenBalance: shouldFetchGasTokenBalance
      )
    }
  }
  
  func activeTxDetailsStore() -> TransactionDetailsStore {
    let tx = allTxs.first { $0.id == activeTransactionId } ?? activeParsedTransaction.transaction
    return TransactionDetailsStore(
      transaction: tx,
      keyringService: keyringService,
      walletService: walletService,
      rpcService: rpcService,
      assetRatioService: assetRatioService,
      blockchainRegistry: blockchainRegistry,
      solanaTxManagerProxy: solTxManagerProxy
    )
  }
  
  private func clearTrasactionInfoBeforeUpdate() {
    // clear fields that could have dynamic async changes
    fiat = ""
    gasFiat = ""
    gasAssetRatio = 0.0
    totalFiat = ""
    currentAllowance = ""
    isBalanceSufficient = true
    isSolTokenTransferWithAssociatedTokenAccountCreation = false
    isUnlimitedApprovalRequested = false
  }
  
  private var assetRatios: [String: Double] = [:]
  private var currentAllowanceCache: [String: String] = [:]
  private var gasTokenBalanceCache: [String: Double] = [:]
  /// Cache for storing `BlockchainToken`s that are not in user assets or our token registry.
  /// This could occur with a dapp creating a transaction.
  private var tokenInfoCache: [String: BraveWallet.BlockchainToken] = [:]
  /// Cache for storing the estimated transaction fee for each Solana transaction. The key is the transaction id.
  private var solEstimatedTxFeeCache: [String: UInt64] = [:]
  
  @MainActor private func fetchAssetRatios(for userVisibleTokens: [BraveWallet.BlockchainToken]) async {
    let priceResult = await assetRatioService.priceWithIndividualRetry(
      userVisibleTokens.map { $0.assetRatioId.lowercased() },
      toAssets: [currencyFormatter.currencyCode],
      timeframe: .oneDay
    )
    let newAssetRatios = priceResult.assetPrices.reduce(into: [String: Double]()) {
      $0[$1.fromAsset] = Double($1.price)
    }
    assetRatios.merge(with: newAssetRatios)
    updateTransaction(with: activeTransaction, shouldFetchCurrentAllowance: false, shouldFetchGasTokenBalance: false)
  }
  
  @MainActor func fetchCurrentAllowance(
    for parsedTransaction: ParsedTransaction,
    allTokens: [BraveWallet.BlockchainToken]
  ) async {
    guard case let .ethErc20Approve(details) = parsedTransaction.details else {
      return
    }
    
    let formatter = WeiFormatter(decimalFormatStyle: .balance)
    let (allowance, _, _) = await rpcService.erc20TokenAllowance(
      details.token?.contractAddress(in: selectedChain) ?? "",
      ownerAddress: parsedTransaction.fromAddress,
      spenderAddress: details.spenderAddress,
      chainId: parsedTransaction.transaction.chainId
    )
    let allowanceString = formatter.decimalString(for: allowance.removingHexPrefix, radix: .hex, decimals: Int(details.token?.decimals ?? selectedChain.decimals)) ?? ""
    currentAllowanceCache[parsedTransaction.transaction.id] = allowanceString
    updateTransaction(with: activeTransaction, shouldFetchCurrentAllowance: false, shouldFetchGasTokenBalance: false)
  }
  
  @MainActor func fetchGasTokenBalance(
    token: BraveWallet.BlockchainToken,
    account: BraveWallet.AccountInfo,
    network: BraveWallet.NetworkInfo
  ) async {
    if let gasTokenBalance = await rpcService.balance(for: token, in: account, network: network) {
      gasTokenBalanceCache["\(token.symbol)\(account.address)"] = gasTokenBalance
      updateTransaction(with: activeTransaction, shouldFetchCurrentAllowance: false, shouldFetchGasTokenBalance: false)
    }
  }
  
  @MainActor private func fetchUnknownTokens(
    for transactions: [BraveWallet.TransactionInfo]
  ) async {
    let coin = await walletService.selectedCoin()
    let network = await rpcService.network(coin, origin: nil)
    let userVisibleTokens = await walletService.userAssets(network.chainId, coin: network.coin)
    let allTokens = await blockchainRegistry.allTokens(network.chainId, coin: network.coin)
    let unknownTokenContractAddresses = transactions.flatMap(\.tokenContractAddresses)
      .filter { contractAddress in
        !userVisibleTokens.contains(where: { $0.contractAddress(in: network).caseInsensitiveCompare(contractAddress) == .orderedSame })
        && !allTokens.contains(where: { $0.contractAddress(in: network).caseInsensitiveCompare(contractAddress) == .orderedSame })
        && !tokenInfoCache.keys.contains(where: { $0.caseInsensitiveCompare(contractAddress) == .orderedSame })
      }
    guard !unknownTokenContractAddresses.isEmpty else { return }
    let unknownTokens = await assetRatioService.fetchTokens(for: unknownTokenContractAddresses)
    for unknownToken in unknownTokens {
      tokenInfoCache[unknownToken.contractAddress] = unknownToken
    }
    updateTransaction(with: activeTransaction, shouldFetchCurrentAllowance: false, shouldFetchGasTokenBalance: false)
  }
  
  @MainActor private func fetchSolEstimatedTxFees(
    for transactions: [BraveWallet.TransactionInfo]
  ) async {
    for transaction in transactions where transaction.coin == .sol {
      let (solEstimatedTxFee, _, _) = await solTxManagerProxy.estimatedTxFee(transaction.chainId, txMetaId: transaction.id)
      self.solEstimatedTxFeeCache[transaction.id] = solEstimatedTxFee
    }
    updateTransaction(with: activeTransaction, shouldFetchCurrentAllowance: false, shouldFetchGasTokenBalance: false)
  }
  
  @MainActor func fetchActiveTransactionDetails(
    keyring: BraveWallet.KeyringInfo,
    network: BraveWallet.NetworkInfo,
    allTokens: [BraveWallet.BlockchainToken],
    shouldFetchCurrentAllowance: Bool,
    shouldFetchGasTokenBalance: Bool
  ) async {
    originInfo = activeParsedTransaction.transaction.originInfo
    transactionDetails = activeTransactionDetails
    self.network = network
    
    switch activeParsedTransaction.details {
    case let .ethSend(details),
      let .erc20Transfer(details),
      let .solSystemTransfer(details),
      let .solSplTokenTransfer(details):
      symbol = details.fromToken?.symbol ?? ""
      value = details.fromAmount
      fiat = details.fromFiat ?? ""
      
      isSolTokenTransferWithAssociatedTokenAccountCreation = activeParsedTransaction.transaction.txType == .solanaSplTokenTransferWithAssociatedTokenAccountCreation
      
      if let gasFee = details.gasFee {
        gasValue = gasFee.fee
        gasFiat = gasFee.fiat
        gasSymbol = activeParsedTransaction.networkSymbol
        gasAssetRatio = assetRatios[activeParsedTransaction.networkSymbol.lowercased(), default: 0]
        
        if let gasBalance = gasTokenBalanceCache["\(network.nativeToken.symbol)\(activeParsedTransaction.fromAddress)"] {
          if let gasValue = BDouble(gasFee.fee),
             BDouble(gasBalance) > gasValue {
            isBalanceSufficient = true
          } else {
            isBalanceSufficient = false
          }
        } else if shouldFetchGasTokenBalance {
          if let account = keyring.accountInfos.first(where: { $0.address == activeParsedTransaction.fromAddress }) {
            await fetchGasTokenBalance(token: network.nativeToken, account: account, network: network)
          }
        }
      }
      if let fromToken = details.fromToken {
        totalFiat = totalFiat(value: value, tokenAssetRatioId: fromToken.assetRatioId, gasValue: gasValue, gasSymbol: gasSymbol, assetRatios: assetRatios, currencyFormatter: currencyFormatter)
      }
      
    case let .ethErc20Approve(details):
      value = details.approvalAmount
      symbol = details.token?.symbol ?? ""
      proposedAllowance = details.approvalValue
      isUnlimitedApprovalRequested = details.isUnlimited
      
      if let gasFee = details.gasFee {
        gasValue = gasFee.fee
        gasFiat = gasFee.fiat
        gasSymbol = activeParsedTransaction.networkSymbol
        gasAssetRatio = assetRatios[activeParsedTransaction.networkSymbol.lowercased(), default: 0]
        
        if let gasBalance = gasTokenBalanceCache["\(network.nativeToken.symbol)\(activeParsedTransaction.fromAddress)"] {
          if let gasValue = BDouble(gasFee.fee),
             BDouble(gasBalance) > gasValue {
            isBalanceSufficient = true
          } else {
            isBalanceSufficient = false
          }
        } else if shouldFetchGasTokenBalance {
          if let account = keyring.accountInfos.first(where: { $0.address == activeParsedTransaction.fromAddress }) {
            await fetchGasTokenBalance(token: network.nativeToken, account: account, network: network)
          }
        }
      }
      
      totalFiat = gasFiat
      
      if let cachedAllowance = self.currentAllowanceCache[activeParsedTransaction.transaction.id] {
        currentAllowance = cachedAllowance
      } else if shouldFetchCurrentAllowance {
        // async fetch current allowance to not delay updating transaction details (will re-parse after fetching current allowance)
        await fetchCurrentAllowance(for: activeParsedTransaction, allTokens: allTokens)
      }
    case let .ethSwap(details):
      symbol = details.fromToken?.symbol ?? ""
      value = details.fromAmount
      fiat = details.fromFiat ?? ""
      
      if let gasFee = details.gasFee {
        gasValue = gasFee.fee
        gasFiat = gasFee.fiat
        gasSymbol = activeParsedTransaction.networkSymbol
        gasAssetRatio = assetRatios[activeParsedTransaction.networkSymbol.lowercased(), default: 0]
        
        if let gasBalance = gasTokenBalanceCache["\(network.nativeToken.symbol)\(activeParsedTransaction.fromAddress)"] {
          if let gasValue = BDouble(gasFee.fee),
             BDouble(gasBalance) > gasValue {
            isBalanceSufficient = true
          } else {
            isBalanceSufficient = false
          }
        } else if shouldFetchGasTokenBalance {
          if let account = keyring.accountInfos.first(where: { $0.address == activeParsedTransaction.fromAddress }) {
            await fetchGasTokenBalance(token: network.nativeToken, account: account, network: network)
          }
        }
        
        totalFiat = totalFiat(value: value, tokenAssetRatioId: details.fromToken?.assetRatioId ?? "", gasValue: gasValue, gasSymbol: gasSymbol, assetRatios: assetRatios, currencyFormatter: currencyFormatter)
      }
    case let .erc721Transfer(details):
      symbol = details.fromToken?.symbol ?? ""
      value = details.fromAmount
      
      if let gasFee = details.gasFee {
        gasValue = gasFee.fee
        gasFiat = gasFee.fiat
        gasSymbol = activeParsedTransaction.networkSymbol
        gasAssetRatio = assetRatios[activeParsedTransaction.networkSymbol.lowercased(), default: 0]
        
        if let gasBalance = gasTokenBalanceCache["\(network.nativeToken.symbol)\(activeParsedTransaction.fromAddress)"] {
          if let gasValue = BDouble(gasFee.fee),
             BDouble(gasBalance) > gasValue {
            isBalanceSufficient = true
          } else {
            isBalanceSufficient = false
          }
        } else if shouldFetchGasTokenBalance {
          if let account = keyring.accountInfos.first(where: { $0.address == activeParsedTransaction.fromAddress }) {
            await fetchGasTokenBalance(token: network.nativeToken, account: account, network: network)
          }
        }
        
        totalFiat = totalFiat(value: value, tokenAssetRatioId: details.fromToken?.assetRatioId ?? "", gasValue: gasValue, gasSymbol: gasSymbol, assetRatios: assetRatios, currencyFormatter: currencyFormatter)
      }
    case let .solDappTransaction(details), let .solSwapTransaction(details):
      symbol = details.symbol ?? ""
      value = details.fromAmount
      transactionDetails = details.instructions
        .map(\.toString)
        .joined(separator: "\n\n====\n\n") // separator between each instruction
      
      if let gasFee = details.gasFee {
        gasValue = gasFee.fee
        gasFiat = gasFee.fiat
        gasSymbol = activeParsedTransaction.networkSymbol
        gasAssetRatio = assetRatios[activeParsedTransaction.networkSymbol.lowercased(), default: 0]
        
        if let gasBalance = gasTokenBalanceCache["\(network.nativeToken.symbol)\(activeParsedTransaction.fromAddress)"] {
          if let gasValue = BDouble(gasFee.fee),
             BDouble(gasBalance) > gasValue {
            isBalanceSufficient = true
          } else {
            isBalanceSufficient = false
          }
        } else if shouldFetchGasTokenBalance {
          if let account = keyring.accountInfos.first(where: { $0.address == activeParsedTransaction.fromAddress }) {
            await fetchGasTokenBalance(token: network.nativeToken, account: account, network: network)
          }
        }
      }
    case .other:
      break
    }
  }
  
  private func totalFiat(
    value: String,
    tokenAssetRatioId: String,
    gasValue: String,
    gasSymbol: String,
    assetRatios: [String: Double],
    currencyFormatter: NumberFormatter
  ) -> String {
    let ratio = assetRatios[tokenAssetRatioId.lowercased(), default: 0]
    let gasRatio = assetRatios[gasSymbol.lowercased(), default: 0]
    let amount = (Double(value) ?? 0.0) * ratio
    let gasAmount = (Double(gasValue) ?? 0.0) * gasRatio
    let totalFiat = currencyFormatter.string(from: NSNumber(value: amount + gasAmount)) ?? "$0.00"
    return totalFiat
  }
  
  @MainActor private func fetchAllTransactions() async -> [BraveWallet.TransactionInfo] {
    let allKeyrings = await keyringService.keyrings(for: WalletConstants.supportedCoinTypes)
    return await txService.allTransactions(for: allKeyrings)
  }

  func confirm(transaction: BraveWallet.TransactionInfo, completion: @escaping (_ error: String?) -> Void) {
    txService.approveTransaction(
      transaction.coin,
      chainId: transaction.chainId,
      txMetaId: transaction.id
    ) { [weak self] success, error, message in
      // As desktop, we only care about eth provider error or solana
      // provider error (plus we haven't start supporting filecoin)
      if error.tag == .providerError {
        self?.transactionProviderErrorRegistry[transaction.id] = TransactionProviderError(code: error.providerError.rawValue, message: message)
      } else if error.tag == .solanaProviderError {
        self?.transactionProviderErrorRegistry[transaction.id] = TransactionProviderError(code: error.solanaProviderError.rawValue, message: message)
      }
      completion(success ? nil : message)
    }
  }

  func reject(transaction: BraveWallet.TransactionInfo, completion: @escaping (Bool) -> Void) {
    txService.rejectTransaction(
      transaction.coin,
      chainId: transaction.chainId,
      txMetaId: transaction.id
    ) { success in
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
      transaction.chainId,
      txMetaId: transaction.id,
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
    transaction.chainId,
    txMetaId: transaction.id,
      gasPrice: gasPrice,
      gasLimit: gasLimit
    ) { success in
      completion?(success)
    }
  }
  
  func editNonce(
    for transaction: BraveWallet.TransactionInfo,
    nonce: String,
    completion: @escaping ((Bool) -> Void)
  ) {
    ethTxManagerProxy.setNonceForUnapprovedTransaction(
      transaction.chainId,
      txMetaId: transaction.id,
      nonce: nonce
    ) { success in
      // not going to refresh unapproved transactions since the tx observer will be
      // notified `onTransactionStatusChanged` and `onUnapprovedTxUpdated`
      // `transactions` list will be refreshed there.
      completion(success)
    }
  }
  
  func editAllowance(
    transaction: BraveWallet.TransactionInfo,
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
      self.ethTxManagerProxy.setDataForUnapprovedTransaction(
        transaction.chainId,
        txMetaId: transaction.id,
        data: []
      ) { success in
        // not going to refresh unapproved transactions since the tx observer will be
        // notified `onTransactionStatusChanged` and `onUnapprovedTxUpdated`
        // `transactions` list will be refreshed there.
        completion(success)
      }
    }
  }
  
  func updateActiveTxIdAfterSignedClosed() {
    let indexOfChangedTx = unapprovedTxs.firstIndex(where: { $0.id == activeTransactionId }) ?? 0
    let newIndex = indexOfChangedTx > 0 ? indexOfChangedTx - 1 : 0
    activeTransactionId = unapprovedTxs[safe: newIndex]?.id ?? unapprovedTxs.first?.id ?? ""
  }
}

struct TransactionProviderError {
  let code: Int
  let message: String
}

extension TransactionConfirmationStore: BraveWalletTxServiceObserver {
  public func onNewUnapprovedTx(_ txInfo: BraveWallet.TransactionInfo) {
    // won't have any new unapproved tx being added if you on tx confirmation panel
  }
  public func onTransactionStatusChanged(_ txInfo: BraveWallet.TransactionInfo) {
    Task { @MainActor in
      // once we come here. it means user either rejects or confirms a transaction
      
      // first update `allTxs` with the new updated txInfo(txStatus)
      if let index = allTxs.firstIndex(where: { $0.id == txInfo.id }) {
        allTxs[index] = txInfo
      }
      
      // only update the `activeTransactionId` if the current active transaction status
      // becomes `.rejected`/`.dropped`
      if activeTransactionId == txInfo.id, txInfo.txStatus == .rejected || txInfo.txStatus == .dropped {
        let indexOfChangedTx = unapprovedTxs.firstIndex(where: { $0.id == txInfo.id }) ?? 0
        let newIndex = indexOfChangedTx > 0 ? indexOfChangedTx - 1 : 0
        activeTransactionId = unapprovedTxs[safe: newIndex]?.id ?? unapprovedTxs.first?.id ?? ""
      } else {
        if activeTransactionId == txInfo.id {
          activeTxStatus = txInfo.txStatus
        }
      }
    }
  }
  public func onUnapprovedTxUpdated(_ txInfo: BraveWallet.TransactionInfo) {
    Task { @MainActor in
      // refresh the unapproved transaction list, as well as tx details UI
      // first update `allTxs` with the new updated txInfo(txStatus)
      if let index = allTxs.firstIndex(where: { $0.id == txInfo.id }) {
        allTxs[index] = txInfo
      }
      
      // update details UI if the current active tx is updated
      if activeTransactionId == txInfo.id {
        updateTransaction(with: txInfo)
        activeTxStatus = txInfo.txStatus
      }
      
      // if somehow the current active transaction no longer exists
      // set the first `.unapproved` tx as the new `activeTransactionId`
      if !unapprovedTxs.contains(where: { $0.id == activeTransactionId }) {
        activeTransactionId = unapprovedTxs.first?.id ?? ""
      }
    }
  }

  public func onTxServiceReset() {
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
  
  public func onDefaultEthereumWalletChanged(_ wallet: BraveWallet.DefaultWallet) {
  }
  
  public func onDefaultSolanaWalletChanged(_ wallet: BraveWallet.DefaultWallet) {
  }
  
  public func onDiscoverAssetsCompleted(_ discoveredAssets: [BraveWallet.BlockchainToken]) {
  }
  
  public func onResetWallet() {
  }
}
