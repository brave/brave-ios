// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import BigNumber
import Shared

/// A store contains data for swap tokens
public class SwapTokenStore: ObservableObject {
  /// All  tokens for searching use
  @Published var allTokens: [BraveWallet.ERCToken] = []
  /// The current selected token to swap from. Default with nil value.
  @Published var selectedFromToken: BraveWallet.ERCToken? {
    didSet {
      if let token = selectedFromToken {
        fetchTokenBalance(for: token) { [weak self] balance in
          self?.selectedFromTokenBalance = balance
        }
      }
    }
  }
  /// The current selected token to swap to. Default with nil value
  @Published var selectedToToken: BraveWallet.ERCToken? {
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
  @Published var state: SwapState = .idle
  /// The sell amount in this swap
  @Published var sellAmount = "" {
    didSet {
      guard !sellAmount.isEmpty else {
        state = .idle
        return
      }
      if oldValue != sellAmount && !updatingPriceQuote {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { [weak self] _ in
          self?.fetchPriceQuote(base: .perSellAsset)
        })
      }
    }
  }
  /// The buy amount in this swap
  @Published var buyAmount = "" {
    didSet {
      guard !buyAmount.isEmpty else {
        state = .idle
        return
      }
      if oldValue != buyAmount && !updatingPriceQuote {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { [weak self] _ in
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
  
  private let keyringController: BraveWalletKeyringController
  private let tokenRegistry: BraveWalletERCTokenRegistry
  private let rpcController: BraveWalletEthJsonRpcController
  private let assetRatioController: BraveWalletAssetRatioController
  private let swapController: BraveWalletSwapController
  private let transactionController: BraveWalletEthTxController
  private var accountInfo: BraveWallet.AccountInfo?
  private var slippage = 0.005 {
    didSet {
      timer?.invalidate()
      timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { [weak self] _ in
        self?.fetchPriceQuote(base: .perSellAsset)
      })
    }
  }
  private var updatingPriceQuote = false
  private var timer: Timer?
  
  enum SwapParamsBase {
    // calculating based on sell asset amount
    case perSellAsset
    // calculating based on buy asset amount
    case perBuyAsset
  }
  
  enum SwapState {
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
    keyringController: BraveWalletKeyringController,
    tokenRegistry: BraveWalletERCTokenRegistry,
    rpcController: BraveWalletEthJsonRpcController,
    assetRatioController: BraveWalletAssetRatioController,
    swapController: BraveWalletSwapController,
    transactionController: BraveWalletEthTxController
  ) {
    self.keyringController = keyringController
    self.tokenRegistry = tokenRegistry
    self.rpcController = rpcController
    self.assetRatioController = assetRatioController
    self.swapController = swapController
    self.transactionController = transactionController
    
    self.keyringController.add(self)
    self.rpcController.add(self)
  }
  
  private func fetchTokenBalance(
    for token: BraveWallet.ERCToken,
    completion: @escaping (_ balance: BDouble?) -> Void
  ) {
    guard let account = accountInfo else {
      completion(nil)
      return
    }
    
    rpcController.balance(for: token, in: account) { balance in
      if let value = balance {
        completion(BDouble(value))
      }
    }
  }
  
  func prepareSwap() {
    switch state {
    case .error(_), .idle:
      // will never come here
      break
    case .lowAllowance(let spenderAddress):
      createERC20SwapTransaction(spenderAddress)
    case .swap:
      createETHSwapTransaction()
    }
  }
  
  private func createETHSwapTransaction() {
    guard
      let accountInfo = accountInfo,
      let swapParams = swapParameters(for: .perSellAsset)
    else { return }
    swapController.transactionPayload(swapParams) { [weak self] success, swapResponse, error in
      guard success, let self = self else {
        self?.clearAllAmount()
        return
      }
      guard let response = swapResponse else { return }
      let weiFormatter = WeiFormatter(decimalFormatStyle: .decimals(precision: 18))
      let gasPrice = "0x\(weiFormatter.weiString(from: response.gasPrice, radix: .hex, decimals: 18) ?? "0")"
      let gasLimit = "0x\(weiFormatter.weiString(from: response.estimatedGas, radix: .hex, decimals: 18) ?? "0")"
      let value = "0x\(weiFormatter.weiString(from: response.value, radix: .hex, decimals: 18) ?? "0")"
      let data: [NSNumber] = .init(hexString: response.data) ?? .init()
      let txData: BraveWallet.TxData = .init(
        nonce: "",
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        to: response.to,
        value: value,
        data: data
      )
      self.transactionController.addUnapprovedTransaction(txData, from: accountInfo.address) { success, txMetaId, error in
        // should be observed
        print("success")
      }
    }
  }
  
  func fetchPriceQuote(base: SwapParamsBase) {
    guard let swapParams = swapParameters(for: base) else { return }
    
    updatingPriceQuote = true
    swapController.priceQuote(swapParams) { [weak self] success, response, error in
      guard success else {
        self?.clearAllAmount()
        self?.updatingPriceQuote = false
        return
      }
      if let response = response {
        self?.handlePriceQuoteResponse(response, base: base)
      }
      self?.updatingPriceQuote = false
    }
  }
  
  private func swapParameters(for base: SwapParamsBase) -> BraveWallet.SwapParams? {
    guard
      let accountInfo = accountInfo,
      let sellToken = selectedFromToken,
      let buyToken = selectedToToken
    else { return nil }
    
    let weiFormatter = WeiFormatter(decimalFormatStyle: .decimals(precision: 18))
    let sellAddress = sellToken.isETH ? BraveWallet.ethSwapAddress : sellToken.contractAddress
    let buyAddress = buyToken.isETH ? BraveWallet.ethSwapAddress : buyToken.contractAddress
    let sellAmountInWei: String
    let buyAmountInWei: String
    switch base {
    case .perSellAsset:
      sellAmountInWei = weiFormatter.weiString(from: sellAmount, radix: .decimal, decimals: Int(sellToken.decimals)) ?? "0"
      buyAmountInWei = ""
    case .perBuyAsset:
      sellAmountInWei = ""
      buyAmountInWei = weiFormatter.weiString(from: buyAmount, radix: .decimal, decimals: Int(buyToken.decimals)) ?? "0"
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
  
  private func clearAllAmount() {
    sellAmount = "0"
    buyAmount = "0"
    selectedFromTokenPrice = "0"
  }
  
  /// Update price market and sell/buy amount fields based on `SwapParamsBase`
  private func handlePriceQuoteResponse(_ response: BraveWallet.SwapResponse, base: SwapParamsBase) {
    let weiFormatter = WeiFormatter(decimalFormatStyle: .decimals(precision: 18))
    switch base {
    case .perSellAsset:
      var decimal = 18
      if let fromToken = selectedFromToken {
        decimal = Int(fromToken.decimals)
      }
      let decimalString = weiFormatter.decimalString(for: response.buyAmount, decimals: decimal) ?? ""
      if let bv = BDouble(decimalString) {
        buyAmount = bv.decimalDescription
      }
    case .perBuyAsset:
      var decimal = 18
      if let toToken = selectedToToken {
        decimal = Int(toToken.decimals)
      }
      let decimalString = weiFormatter.decimalString(for: response.sellAmount, decimals: decimal) ?? ""
      if let bv = BDouble(decimalString) {
        sellAmount = bv.decimalDescription
      }
    }
    
    if let bv = BDouble(response.price) {
      // will need to invert price if price quote is based on buyAmount
      // ref from slack:
      // https://bravesoftware.slack.com/archives/C023VS4HJ6Q/p1636579425364500?thread_ts=1636570735.354500&cid=C023VS4HJ6Q
      let price = base == .perSellAsset ? bv : 1 / bv
      selectedFromTokenPrice = price.decimalDescription
    }
    
    checkBalanceShowError(swapResponse: response)
  }
  
  private func createERC20SwapTransaction(_ spenderAddress: String) {
    let weiFormatter = WeiFormatter(decimalFormatStyle: .decimals(precision: 18))
    guard
      let fromToken = selectedFromToken,
      let accountInfo = accountInfo,
      let balanceInWeiHex = weiFormatter.weiString(
        from: selectedFromTokenBalance?.decimalDescription ?? "",
        radix: .hex,
        decimals: Int(fromToken.decimals)
      )
    else { return }
    transactionController.makeErc20ApproveData(
      spenderAddress,
      amount: balanceInWeiHex
    ) { [weak self] success, data in
        guard success else { return }
        let txData = BraveWallet.TxData(
          nonce: "",
          gasPrice: "",
          gasLimit: "",
          to: fromToken.contractAddress,
          value: "0x0",
          data: data
        )
      self?.transactionController.addUnapprovedTransaction(
          txData,
          from: accountInfo.address,
          completion: { success, txMetaId, error in
            // should be observed
          }
      )
    }
  }
  
  private func checkBalanceShowError(swapResponse: BraveWallet.SwapResponse) {
    guard
      let accountInfo = accountInfo,
      let sellAmountValue = BDouble(sellAmount),
      let gasLimit = BDouble(swapResponse.estimatedGas),
      let gasPrice = BDouble(swapResponse.gasPrice, over: "1000000000000000000"),
      let fromToken = selectedFromToken,
      let fromTokenBalance = selectedFromTokenBalance
    else { return }
    
    // Check if balance is insufficient
    if sellAmountValue > fromTokenBalance {
      state = .error(Strings.Wallet.insufficientBalance)
    }
    
    // Get ETH balance for this account because gas can only be paid in ETH
    rpcController.balance(accountInfo.address) { [weak self] success, balance in
      guard let self = self else { return }
      if success {
        let fee = gasLimit * gasPrice
        let balanceFormatter = WeiFormatter(decimalFormatStyle: .balance)
        let currentBalance = BDouble(balanceFormatter.decimalString(for: balance.removingHexPrefix, radix: .hex, decimals: 18) ?? "") ?? 0
        if fromToken.isETH {
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
      }
      
      self.state = .swap
      // check for ERC20 token allowance
      if fromToken.isErc20 {
        self.checkAllowance(
          contractAddress: accountInfo.address,
          spenderAddress: swapResponse.allowanceTarget,
          amountToSend: sellAmountValue,
          fromToken: fromToken
        )
      }
    }
  }
  
  private func checkAllowance(
    contractAddress: String,
    spenderAddress: String,
    amountToSend: BDouble,
    fromToken: BraveWallet.ERCToken
  ) {
    rpcController.erc20TokenAllowance(
      contractAddress,
      ownerAddress: contractAddress,
      spenderAddress: spenderAddress
    ) { [weak self] success, allowance in
      let weiFormatter = WeiFormatter(decimalFormatStyle: .decimals(precision: 18))
      let allowanceValue = BDouble(weiFormatter.decimalString(for: allowance.removingHexPrefix, radix: .hex, decimals: Int(fromToken.decimals)) ?? "") ?? 0
      guard success, amountToSend > allowanceValue else { return } // no problem with its allowance
      self?.state = .lowAllowance(spenderAddress)
    }
  }
  
  func prepare(with accountInfo: BraveWallet.AccountInfo, completion: (() -> Void)? = nil) {
    self.accountInfo = accountInfo
    
    tokenRegistry.allTokens { [self] tokens in
      let fullList = tokens + [.eth]
      allTokens = fullList.sorted(by: { $0.symbol < $1.symbol })
      
      if let fromToken = selectedFromToken { // refresh balance
        rpcController.balance(for: fromToken, in: accountInfo) { balance in
          if let value = balance {
            selectedFromTokenBalance = BDouble(value)
          }
        }
      } else {
        selectedFromToken = allTokens.first(where: { $0.isETH })
      }
      
      rpcController.chainId { [self] chainId in
        if let toToken = selectedToToken {
          rpcController.balance(for: toToken, in: accountInfo) { balance in
            if let value = balance {
              selectedToTokenBalance = BDouble(value)
            }
          }
        } else {
          if chainId == BraveWallet.MainnetChainId {
            selectedToToken = allTokens.first(where: { $0.symbol == "BAT" })
          } else if chainId == BraveWallet.RopstenChainId {
            selectedToToken = allTokens.first(where: { $0.symbol == "DAI" })
          }
        }
      }
    }
  }
}

extension SwapTokenStore: BraveWalletKeyringControllerObserver {
  public func keyringCreated() {
  }
  
  public func keyringRestored() {
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
  
  public func selectedAccountChanged() {
    keyringController.defaultKeyringInfo { [self] keyringInfo in
      if !keyringInfo.accountInfos.isEmpty {
        keyringController.selectedAccount { accountAddress in
          let selectedAccountInfo = keyringInfo.accountInfos.first(where: { $0.address == accountAddress }) ??
            keyringInfo.accountInfos.first!
          prepare(with: selectedAccountInfo) {
            fetchPriceQuote(base: .perSellAsset)
          }
        }
      }
    }
  }
}

extension SwapTokenStore: BraveWalletEthJsonRpcControllerObserver {
  public func chainChangedEvent(_ chainId: String) {
    guard
      let accountInfo = accountInfo,
      chainId == BraveWallet.MainnetChainId || chainId == BraveWallet.RopstenChainId
    else { return }
    selectedFromToken = nil
    selectedToToken = nil
    prepare(with: accountInfo) { [weak self] in
      self?.fetchPriceQuote(base: .perSellAsset)
    }
  }
  
  public func onAddEthereumChainRequestCompleted(_ chainId: String, error: String) {
  }
  
  public func onIsEip1559Changed(_ chainId: String, isEip1559: Bool) {
  }
}
