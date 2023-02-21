// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import BigNumber
import Strings
import Combine

/// A store contains data for swap tokens
public class SwapTokenStore: ObservableObject {
  /// All  tokens for searching use
  @Published var allTokens: [BraveWallet.BlockchainToken] = []
  /// The current selected token to swap from. Default with nil value.
  @Published var selectedFromToken: BraveWallet.BlockchainToken? {
    didSet {
      if let token = selectedFromToken {
        fetchTokenBalance(for: token) { [weak self] balance in
          self?.selectedFromTokenBalance = balance
        }
      }
    }
  }
  /// The current selected token to swap to. Default with nil value
  @Published var selectedToToken: BraveWallet.BlockchainToken? {
    didSet {
      if let token = selectedToToken {
        fetchTokenBalance(for: token) { [weak self] balance in
          self?.selectedToTokenBalance = balance
        }
      }
    }
  }
  /// The current selected token balance to swap from. Default with nil value.
  @Published var selectedFromTokenBalance: BDouble?
  /// The current selected token balance to swap to. Default with nil value.
  @Published var selectedToTokenBalance: BDouble?
  /// The current market price for selected token to swap from.
  @Published var selectedFromTokenPrice = "0"
  /// The state of swap screen
  @Published var state: SwapState = .idle {
    didSet {
      if case .error = state {
        isMakingTx = false
      }
    }
  }
  /// The sell amount in this swap
  @Published var sellAmount = "" {
    didSet {
      guard !sellAmount.isEmpty, BDouble(sellAmount.normalizedDecimals) != nil else {
        state = .idle
        return
      }
      if oldValue != sellAmount && !updatingPriceQuote && !isMakingTx {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
          withTimeInterval: 0.25, repeats: false,
          block: { [weak self] _ in
            self?.fetchPriceQuote(base: .perSellAsset)
          })
      }
    }
  }
  /// The buy amount in this swap
  @Published var buyAmount = "" {
    didSet {
      guard !buyAmount.isEmpty, BDouble(buyAmount.normalizedDecimals) != nil else {
        state = .idle
        return
      }
      if oldValue != buyAmount && !updatingPriceQuote && !isMakingTx {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
          withTimeInterval: 0.25, repeats: false,
          block: { [weak self] _ in
            self?.fetchPriceQuote(base: .perBuyAsset)
          })
      }
    }
  }
  /// The latest slippage option that user selected
  @Published var slippageOption = SlippageGrid.Option.halfPercent {
    didSet {
      slippage = slippageOption.value
    }
  }
  /// The custom user input slippage percentage value which will override `slippageOption` if it is not nil
  @Published var overrideSlippage: Int? {
    didSet {
      if let overrideSlippage = overrideSlippage {
        slippage = Double(overrideSlippage) / 100.0
      } else {
        slippage = slippageOption.value
      }
    }
  }
  /// A boolean indicates if this store is making an unapproved tx
  @Published var isMakingTx = false

  private let keyringService: BraveWalletKeyringService
  private let blockchainRegistry: BraveWalletBlockchainRegistry
  private let rpcService: BraveWalletJsonRpcService
  private let swapService: BraveWalletSwapService
  private let txService: BraveWalletTxService
  private let walletService: BraveWalletBraveWalletService
  private let ethTxManagerProxy: BraveWalletEthTxManagerProxy
  private var accountInfo: BraveWallet.AccountInfo?
  private var slippage = 0.005 {
    didSet {
      timer?.invalidate()
      timer = Timer.scheduledTimer(
        withTimeInterval: 0.25, repeats: false,
        block: { [weak self] _ in
          self?.fetchPriceQuote(base: .perSellAsset)
        })
    }
  }
  private var updatingPriceQuote = false
  private var timer: Timer?
  private let batSymbol = "BAT"
  private let daiSymbol = "DAI"
  private var prefilledToken: BraveWallet.BlockchainToken?

  enum SwapParamsBase {
    // calculating based on sell asset amount
    case perSellAsset
    // calculating based on buy asset amount
    case perBuyAsset
  }

  enum SwapState: Equatable {
    // when there is an error occurs. associated with an error message
    case error(String)
    // when erc20 token's allowance is less then sell amount. associated with a spender address
    // the future of this state would get erc20 token apporve data then create
    // an unapproved transaction
    case lowAllowance(String)
    // when able to swap
    case swap
    // has not passed validation
    case idle
  }

  public init(
    keyringService: BraveWalletKeyringService,
    blockchainRegistry: BraveWalletBlockchainRegistry,
    rpcService: BraveWalletJsonRpcService,
    swapService: BraveWalletSwapService,
    txService: BraveWalletTxService,
    walletService: BraveWalletBraveWalletService,
    ethTxManagerProxy: BraveWalletEthTxManagerProxy,
    prefilledToken: BraveWallet.BlockchainToken?
  ) {
    self.keyringService = keyringService
    self.blockchainRegistry = blockchainRegistry
    self.rpcService = rpcService
    self.swapService = swapService
    self.txService = txService
    self.walletService = walletService
    self.ethTxManagerProxy = ethTxManagerProxy
    self.prefilledToken = prefilledToken

    self.keyringService.add(self)
    self.rpcService.add(self)
  }

  private func fetchTokenBalance(
    for token: BraveWallet.BlockchainToken,
    completion: @escaping (_ balance: BDouble?) -> Void
  ) {
    guard let account = accountInfo else {
      completion(nil)
      return
    }
    
    rpcService.network(token.coin) { [weak self] network in
      self?.rpcService.balance(
        for: token,
        in: account.address,
        network: network,
        decimalFormatStyle: .decimals(precision: Int(token.decimals))
      ) { balance in
        completion(balance)
      }
    }
  }

  private func swapParameters(
    for base: SwapParamsBase,
    in network: BraveWallet.NetworkInfo
  ) -> BraveWallet.SwapParams? {
    guard
      let accountInfo = accountInfo,
      let sellToken = selectedFromToken,
      let buyToken = selectedToToken
    else { return nil }

    let weiFormatter = WeiFormatter(decimalFormatStyle: .decimals(precision: 18))
    let sellAddress = sellToken.contractAddress(in: network)
    let buyAddress = buyToken.contractAddress(in: network)
    let sellAmountInWei: String
    let buyAmountInWei: String
    switch base {
    case .perSellAsset:
      // make sure the base value should not be zero, otherwise, it will always return insufficient liquidity error.
      // following desktop to make a idle state
      if let sellAmountValue = BDouble(sellAmount.normalizedDecimals), sellAmountValue == 0 {
        return nil
      }
      sellAmountInWei = weiFormatter.weiString(from: sellAmount.normalizedDecimals, radix: .decimal, decimals: Int(sellToken.decimals)) ?? "0"
      buyAmountInWei = ""
    case .perBuyAsset:
      // same as sell amount. make sure base value should not be zero
      if let buyAmountValue = BDouble(buyAmount.normalizedDecimals), buyAmountValue == 0 {
        return nil
      }
      sellAmountInWei = ""
      buyAmountInWei = weiFormatter.weiString(from: buyAmount.normalizedDecimals, radix: .decimal, decimals: Int(buyToken.decimals)) ?? "0"
    }
    let swapParams = BraveWallet.SwapParams(
      takerAddress: accountInfo.address,
      sellAmount: sellAmountInWei,
      buyAmount: buyAmountInWei,
      buyToken: buyAddress,
      sellToken: sellAddress,
      slippagePercentage: slippage,
      gasPrice: ""
    )

    return swapParams
  }
  
  @MainActor private func createEthSwapTransaction() async -> Bool {
    self.isMakingTx = true
    defer { self.isMakingTx = false }
    let coin = await walletService.selectedCoin()
    let network = await rpcService.network(coin)
    guard
      let accountInfo = self.accountInfo,
      let swapParams = self.swapParameters(for: .perSellAsset, in: network)
    else {
      self.state = .error(Strings.Wallet.unknownError)
      self.clearAllAmount()
      return false
    }
    let (swapResponse, _, _) = await swapService.transactionPayload(swapParams)
    guard let swapResponse = swapResponse else {
      self.state = .error(Strings.Wallet.unknownError)
      self.clearAllAmount()
      return false
    }
    let weiFormatter = WeiFormatter(decimalFormatStyle: .decimals(precision: 18))
    let gasPrice = "0x\(weiFormatter.weiString(from: swapResponse.gasPrice, radix: .hex, decimals: 0) ?? "0")"  // already in wei
    let gasLimit = "0x\(weiFormatter.weiString(from: swapResponse.estimatedGas, radix: .hex, decimals: 0) ?? "0")"  // already in wei
    let value = "0x\(weiFormatter.weiString(from: swapResponse.value, radix: .hex, decimals: 0) ?? "0")"  // already in wei
    let data: [NSNumber] = .init(hexString: swapResponse.data) ?? .init()
    
    if network.isEip1559 {
      let baseData: BraveWallet.TxData = .init(
        nonce: "",
        gasPrice: "",  // no gas price in eip1559
        gasLimit: gasLimit,
        to: swapResponse.to,
        value: value,
        data: data,
        signOnly: false,
        signedTransaction: nil
      )
      let success = await self.makeEIP1559Tx(chainId: network.chainId, baseData: baseData, from: accountInfo)
      if !success {
        self.state = .error(Strings.Wallet.unknownError)
        self.clearAllAmount()
      }
      return success
    } else {
      let baseData: BraveWallet.TxData = .init(
        nonce: "",
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        to: swapResponse.to,
        value: value,
        data: data,
        signOnly: false,
        signedTransaction: nil
      )
      let txDataUnion = BraveWallet.TxDataUnion(ethTxData: baseData)
      let (success, _, _) = await txService.addUnapprovedTransaction(txDataUnion, from: accountInfo.address, origin: nil, groupId: nil)
      if !success {
        self.state = .error(Strings.Wallet.unknownError)
        self.clearAllAmount()
      }
      return success
    }
  }

  private func clearAllAmount() {
    sellAmount = "0"
    buyAmount = "0"
    selectedFromTokenPrice = "0"
  }

  /// Update price market and sell/buy amount fields based on `SwapParamsBase`
  @MainActor private func handlePriceQuoteResponse(_ response: BraveWallet.SwapResponse, base: SwapParamsBase) async {
    let weiFormatter = WeiFormatter(decimalFormatStyle: .decimals(precision: 18))
    switch base {
    case .perSellAsset:
      var decimal = 18
      if let buyToken = selectedToToken {
        decimal = Int(buyToken.decimals)
      }
      let decimalString = weiFormatter.decimalString(for: response.buyAmount, decimals: decimal) ?? ""
      if let bv = BDouble(decimalString) {
        buyAmount = bv.decimalDescription
      }
    case .perBuyAsset:
      var decimal = 18
      if let sellToken = selectedFromToken {
        decimal = Int(sellToken.decimals)
      }
      let decimalString = weiFormatter.decimalString(for: response.sellAmount, decimals: decimal) ?? ""
      if let bv = BDouble(decimalString) {
        sellAmount = bv.decimalDescription
      }
    }

    if let bv = BDouble(response.price) {
      switch base {
      case .perSellAsset:
        selectedFromTokenPrice = bv.decimalDescription
      case .perBuyAsset:
        // will need to invert price if price quote is based on buyAmount
        if bv != 0 {
          selectedFromTokenPrice = (1 / bv).decimalDescription
        }
      }
    }

    await checkBalanceShowError(swapResponse: response)
  }

  @MainActor private func createERC20ApprovalTransaction(
      _ spenderAddress: String
  ) async -> Bool {
    guard
      let fromToken = selectedFromToken,
      let accountInfo = accountInfo
    else {
      return false
    }
    
    // IMPORTANT SECURITY NOTICE
    //
    // The token allowance suggested by Swap is always unlimited,
    // i.e., max(uint256). While unlimited approvals are not safe from a
    // security standpoint, and this puts the entire token balance at risk
    // if 0x contracts are ever exploited, we still opted for this to give
    // users a frictionless UX and save on gas fees.
    //
    // The transaction confirmation screen for ERC20 approve() shows a loud
    // security notice, and still allows users to edit the default approval
    // amount.
    let allowance = WalletConstants.MAX_UINT256
    self.isMakingTx = true
    defer { self.isMakingTx = false }
    let coin = await walletService.selectedCoin()
    let network = await rpcService.network(coin)
    let (success, data) = await ethTxManagerProxy.makeErc20ApproveData(spenderAddress, amount: allowance)
    guard success else {
      return false
    }
    let baseData = BraveWallet.TxData(
      nonce: "",
      gasPrice: "",
      gasLimit: "",
      to: fromToken.contractAddress(in: network),
      value: "0x0",
      data: data,
      signOnly: false,
      signedTransaction: nil
    )
    if network.isEip1559 {
      let success = await self.makeEIP1559Tx(chainId: network.chainId, baseData: baseData, from: accountInfo)
      if !success {
        self.state = .error(Strings.Wallet.unknownError)
        self.clearAllAmount()
      }
      return success
    } else {
      let txDataUnion = BraveWallet.TxDataUnion(ethTxData: baseData)
      let (success, _, _) = await txService.addUnapprovedTransaction(txDataUnion, from: accountInfo.address, origin: nil, groupId: nil)
      if !success {
        self.state = .error(Strings.Wallet.unknownError)
        self.clearAllAmount()
      }
      return success
    }
  }
  
  @MainActor private func makeEIP1559Tx(
    chainId: String,
    baseData: BraveWallet.TxData,
    from account: BraveWallet.AccountInfo
  ) async -> Bool {
    var maxPriorityFeePerGas = ""
    var maxFeePerGas = ""
    let gasEstimation = await ethTxManagerProxy.gasEstimation1559()
    if let gasEstimation = gasEstimation {
      // Bump fast priority fee and max fee by 1 GWei if same as average fees.
      if gasEstimation.fastMaxPriorityFeePerGas == gasEstimation.avgMaxPriorityFeePerGas {
        maxPriorityFeePerGas = "0x\(self.bumpFeeByOneGWei(with: gasEstimation.fastMaxPriorityFeePerGas) ?? "0")"
        maxFeePerGas = "0x\(self.bumpFeeByOneGWei(with: gasEstimation.fastMaxFeePerGas) ?? "0")"
      } else {
        // Always suggest fast gas fees as default
        maxPriorityFeePerGas = gasEstimation.fastMaxPriorityFeePerGas
        maxFeePerGas = gasEstimation.fastMaxFeePerGas
      }
    }
    let eip1559Data = BraveWallet.TxData1559(baseData: baseData, chainId: chainId, maxPriorityFeePerGas: maxPriorityFeePerGas, maxFeePerGas: maxFeePerGas, gasEstimation: gasEstimation)
    let txDataUnion = BraveWallet.TxDataUnion(ethTxData1559: eip1559Data)
    let (success, _, _) = await txService.addUnapprovedTransaction(txDataUnion, from: account.address, origin: nil, groupId: nil)
    if !success {
      self.state = .error(Strings.Wallet.unknownError)
      self.clearAllAmount()
    }
    return success
  }

  private func bumpFeeByOneGWei(with value: String) -> String? {
    guard let bv = BDouble(value, radix: 16) else { return nil }
    let bumpedValue = bv + (BDouble(10) ** 9)
    return bumpedValue.rounded().asString(radix: 16)
  }

  @MainActor private func checkBalanceShowError(swapResponse: BraveWallet.SwapResponse) async {
    guard
      let accountInfo = accountInfo,
      let sellAmountValue = BDouble(sellAmount.normalizedDecimals),
      let gasLimit = BDouble(swapResponse.estimatedGas),
      let gasPrice = BDouble(swapResponse.gasPrice, over: "1000000000000000000"),
      let fromToken = selectedFromToken,
      let fromTokenBalance = selectedFromTokenBalance
    else { return }

    // Check if balance is insufficient
    guard sellAmountValue <= fromTokenBalance else {
      state = .error(Strings.Wallet.insufficientBalance)
      return
    }

    // Get ETH balance for this account because gas can only be paid in ETH
    let coin = await walletService.selectedCoin()
    let network = await rpcService.network(coin)
    let (balance, status, _) = await rpcService.balance(accountInfo.address, coin: network.coin, chainId: network.chainId)
    if status == BraveWallet.ProviderError.success {
      let fee = gasLimit * gasPrice
      let balanceFormatter = WeiFormatter(decimalFormatStyle: .balance)
      let currentBalance = BDouble(balanceFormatter.decimalString(for: balance.removingHexPrefix, radix: .hex, decimals: 18) ?? "") ?? 0
      if fromToken.symbol == network.symbol {
        if currentBalance < fee + sellAmountValue {
          self.state = .error(Strings.Wallet.insufficientFundsForGas)
          return
        }
      } else {
        if currentBalance < fee {
          self.state = .error(Strings.Wallet.insufficientFundsForGas)
          return
        }
      }
      self.state = .swap
      // check for ERC20 token allowance
      if fromToken.isErc20 {
        await self.checkAllowance(
          network: network,
          ownerAddress: accountInfo.address,
          spenderAddress: swapResponse.allowanceTarget,
          amountToSend: sellAmountValue,
          fromToken: fromToken
        )
      }
    } else {
      self.state = .error(Strings.Wallet.unknownError)
      self.clearAllAmount()
    }
  }

  @MainActor private func checkAllowance(
    network: BraveWallet.NetworkInfo,
    ownerAddress: String,
    spenderAddress: String,
    amountToSend: BDouble,
    fromToken: BraveWallet.BlockchainToken
  ) async {
    let (allowance, status, _) = await rpcService.erc20TokenAllowance(
      fromToken.contractAddress(in: network),
      ownerAddress: ownerAddress,
      spenderAddress: spenderAddress)
    let weiFormatter = WeiFormatter(decimalFormatStyle: .decimals(precision: Int(fromToken.decimals)))
    let allowanceValue = BDouble(weiFormatter.decimalString(for: allowance.removingHexPrefix, radix: .hex, decimals: Int(fromToken.decimals)) ?? "") ?? 0
    guard status == .success, amountToSend > allowanceValue else { return }  // no problem with its allowance
    self.state = .lowAllowance(spenderAddress)
  }

  // MARK: Public

  func swapSelectedTokens() {
    guard let oldFromToken = selectedFromToken,
      let oldToToken = selectedToToken
    else { return }

    selectedFromToken = oldToToken
    selectedToToken = oldFromToken

    if !sellAmount.isEmpty {
      fetchPriceQuote(base: .perSellAsset)
    }
  }

  @MainActor func createSwapTransaction() async -> Bool {
    switch state {
    case .error, .idle:
      // will never come here
      return false
    case let .lowAllowance(spenderAddress):
      return await createERC20ApprovalTransaction(spenderAddress)
    case .swap:
      return await createEthSwapTransaction()
    }
  }

  func fetchPriceQuote(base: SwapParamsBase) {
    Task { @MainActor in
      let coin = await walletService.selectedCoin()
      let network = await rpcService.network(coin)
      guard let swapParams = self.swapParameters(for: base, in: network) else {
        self.state = .idle
        return
      }
      switch coin {
      case .eth:
        await fetchEthPriceQuote(base: base, swapParams: swapParams, network: network)
      default:
        break
      }
    }
  }
  
  @MainActor private func fetchEthPriceQuote(
    base: SwapParamsBase,
    swapParams: BraveWallet.SwapParams,
    network: BraveWallet.NetworkInfo
  ) async {
    self.updatingPriceQuote = true
    defer { self.updatingPriceQuote = false }
    let (swapResponse, swapErrorResponse, _) = await swapService.priceQuote(swapParams)
    if let swapResponse = swapResponse {
      await self.handlePriceQuoteResponse(swapResponse, base: base)
    } else if let swapErrorResponse = swapErrorResponse {
      // check balance first because error can cause by insufficient balance
      if let sellTokenBalance = self.selectedFromTokenBalance,
         let sellAmountValue = BDouble(self.sellAmount.normalizedDecimals),
         sellTokenBalance < sellAmountValue {
        self.state = .error(Strings.Wallet.insufficientBalance)
        return
      }
      // check if priceQuote fails due to insufficient liquidity
      if swapErrorResponse.isInsufficientLiquidity {
        self.state = .error(Strings.Wallet.insufficientLiquidity)
        return
      }
      self.state = .error(Strings.Wallet.unknownError)
      self.clearAllAmount()
    }
  }

  func prepare(with accountInfo: BraveWallet.AccountInfo, completion: (() -> Void)? = nil) {
    self.accountInfo = accountInfo

    func updateSelectedTokens(in network: BraveWallet.NetworkInfo) {
      if let fromToken = selectedFromToken {  // refresh balance
        fetchTokenBalance(for: fromToken) { [weak self] balance in
          self?.selectedFromTokenBalance = balance ?? 0
        }
      } else {
        selectedFromToken = allTokens.first(where: { $0.symbol == network.symbol })
      }

      if let toToken = selectedToToken {
        fetchTokenBalance(for: toToken) { [weak self] balance in
          self?.selectedToTokenBalance = balance ?? 0
        }
      } else {
        if network.chainId == BraveWallet.MainnetChainId {
          if let fromToken = selectedFromToken, fromToken.symbol.uppercased() == batSymbol.uppercased() {
            selectedToToken = allTokens.first(where: { $0.symbol.uppercased() != batSymbol.uppercased() })
          } else {
            selectedToToken = allTokens.first(where: { $0.symbol.uppercased() == batSymbol.uppercased() })
          }
        } else {
          if let fromToken = selectedFromToken {
            selectedToToken = allTokens.first(where: { $0.symbol.uppercased() != fromToken.symbol.uppercased() })
          } else {
            selectedToToken = allTokens.first
          }
        }
        completion?()
      }
    }

    // All tokens from token registry
    walletService.selectedCoin { [weak self] coinType in
      guard let self = self else { return }
      self.rpcService.network(coinType) { network in
        // Closure run after validating the prefilledToken (if applicable)
        let continueClosure: (BraveWallet.NetworkInfo) -> Void = { [weak self] network in
          guard let self = self else { return }
          self.blockchainRegistry.allTokens(network.chainId, coin: network.coin) { tokens in
            // Native token on the current selected network
            let nativeAsset = network.nativeToken
            // Custom tokens added by users
            self.walletService.userAssets(network.chainId, coin: network.coin) { userAssets in
              let customTokens = userAssets.filter { asset in
                !tokens.contains(where: { $0.contractAddress(in: network).caseInsensitiveCompare(asset.contractAddress) == .orderedSame })
              }
              let sortedCustomTokens = customTokens.sorted {
                if $0.contractAddress(in: network).caseInsensitiveCompare(nativeAsset.contractAddress) == .orderedSame {
                  return true
                } else {
                  return $0.symbol < $1.symbol
                }
              }
              self.allTokens = sortedCustomTokens + tokens.sorted(by: { $0.symbol < $1.symbol })
              // Seems like user assets always include the selected network's native asset
              // But let's make sure all token list includes the native asset
              if !self.allTokens.contains(where: { $0.symbol.lowercased() == nativeAsset.symbol.lowercased() }) {
                self.allTokens.insert(nativeAsset, at: 0)
              }
              updateSelectedTokens(in: network)
            }
          }
        }
        
        // validate the `prefilledToken`
        if let prefilledToken = self.prefilledToken {
          if prefilledToken.coin == network.coin && prefilledToken.chainId == network.chainId {
            self.selectedFromToken = prefilledToken
            continueClosure(network)
          } else {
            self.rpcService.allNetworks(prefilledToken.coin) { allNetworksForTokenCoin in
              guard let networkForToken = allNetworksForTokenCoin.first(where: { $0.chainId == prefilledToken.chainId }) else {
                // don't set prefilled token if it belongs to a network we don't know
                continueClosure(network)
                return
              }
              self.rpcService.setNetwork(networkForToken.chainId, coin: networkForToken.coin) { success in
                if success {
                  self.selectedFromToken = prefilledToken
                  continueClosure(networkForToken) // network changed
                } else {
                  continueClosure(network)
                }
              }
            }
          }
          self.prefilledToken = nil
        } else { // `prefilledToken` is nil
          continueClosure(network)
        }
      }
    }
  }
  
  func suggestedAmountTapped(_ amount: ShortcutAmountGrid.Amount) {
    var decimalPoint = 6
    var rounded = true
    if amount == .all {
      decimalPoint = Int(selectedFromToken?.decimals ?? 18)
      rounded = false
    }
    sellAmount = ((selectedFromTokenBalance ?? 0) * amount.rawValue)
      .decimalExpansion(precisionAfterDecimalPoint: decimalPoint, rounded: rounded)
  }

  #if DEBUG
  func setUpTest(sellAmount: String = "0.01") {
    accountInfo = .init()
    selectedFromToken = .previewToken
    selectedToToken = .previewDaiToken
    self.sellAmount = sellAmount
    selectedFromTokenBalance = 0.02
  }
  
  func setUpTestForRounding() {
    accountInfo = .init()
    selectedFromToken = .previewToken
  }
  #endif
}

extension SwapTokenStore: BraveWalletKeyringServiceObserver {
  public func keyringReset() {
  }

  public func keyringCreated(_ keyringId: String) {
  }

  public func keyringRestored(_ keyringId: String) {
  }

  public func locked() {
  }

  public func unlocked() {
  }

  public func backedUp() {
  }

  public func accountsChanged() {
  }

  public func autoLockMinutesChanged() {
  }

  public func selectedAccountChanged(_ coinType: BraveWallet.CoinType) {
    Task { @MainActor in
      let network = await rpcService.network(coinType)
      let isSwapSupported = await swapService.isiOSSwapSupported(chainId: network.chainId, coin: coinType)
      guard isSwapSupported else { return }
      
      let keyringInfo = await keyringService.keyringInfo(coinType.keyringId)
      if !keyringInfo.accountInfos.isEmpty {
        let accountAddress = await keyringService.selectedAccount(coinType)
        let selectedAccountInfo = keyringInfo.accountInfos.first(where: { $0.address == accountAddress }) ?? keyringInfo.accountInfos.first!
        prepare(with: selectedAccountInfo) { [self] in
          fetchPriceQuote(base: .perSellAsset)
        }
      }
    }
  }
  
  public func accountsAdded(_ coin: BraveWallet.CoinType, addresses: [String]) {
  }
}

extension SwapTokenStore: BraveWalletJsonRpcServiceObserver {
  public func chainChangedEvent(_ chainId: String, coin: BraveWallet.CoinType) {
    Task { @MainActor in
      let isSwapSupported = await swapService.isiOSSwapSupported(chainId: chainId, coin: coin)
      guard isSwapSupported, let accountInfo = accountInfo else { return }
      selectedFromToken = nil
      selectedToToken = nil
      prepare(with: accountInfo) { [self] in
        fetchPriceQuote(base: .perSellAsset)
      }
    }
  }

  public func onAddEthereumChainRequestCompleted(_ chainId: String, error: String) {
  }

  public func onIsEip1559Changed(_ chainId: String, isEip1559: Bool) {
  }
}
