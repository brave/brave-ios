// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveCore

enum PendingRequest: Equatable {
  case transactions
  case addChain(BraveWallet.AddChainRequest)
  case switchChain(BraveWallet.SwitchChainRequest)
  case addSuggestedToken(BraveWallet.AddSuggestTokenRequest)
  case signMessage([BraveWallet.SignMessageRequest])
}

extension PendingRequest: Identifiable {
  var id: String {
    switch self {
    case .transactions: return "transactions"
    case let .addChain(request): return "addChain-\(request.networkInfo.chainId)"
    case let .switchChain(chainRequest): return "switchChain-\(chainRequest.chainId)"
    case let .addSuggestedToken(tokenRequest): return "addSuggestedToken-\(tokenRequest.token.id)"
    case let .signMessage(signRequests): return "signMessage-\(signRequests.map(\.id))"
    }
  }
}

enum WebpageRequestResponse: Equatable {
  case switchChain(approved: Bool, originInfo: BraveWallet.OriginInfo)
  case addNetwork(approved: Bool, chainId: String)
  case addSuggestedToken(approved: Bool, contractAddresses: [String])
  case signMessage(approved: Bool, id: Int32)
}

public class CryptoStore: ObservableObject {
  public let networkStore: NetworkStore
  public let portfolioStore: PortfolioStore
  
  @Published var buySendSwapDestination: BuySendSwapDestination? {
    didSet {
      if buySendSwapDestination == nil {
        buyTokenStore = nil
        sendTokenStore = nil
        swapTokenStore = nil
      }
    }
  }
  @Published var isPresentingAssetSearch: Bool = false
  @Published var isPresentingPendingRequest: Bool = false {
    didSet {
      if !isPresentingPendingRequest {
        confirmationStore = nil
      }
    }
  }
  @Published private(set) var pendingRequest: PendingRequest?
  
  private let keyringService: BraveWalletKeyringService
  private let rpcService: BraveWalletJsonRpcService
  private let walletService: BraveWalletBraveWalletService
  private let assetRatioService: BraveWalletAssetRatioService
  private let swapService: BraveWalletSwapService
  let blockchainRegistry: BraveWalletBlockchainRegistry
  private let txService: BraveWalletTxService
  private let ethTxManagerProxy: BraveWalletEthTxManagerProxy
  
  public init(
    keyringService: BraveWalletKeyringService,
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService,
    assetRatioService: BraveWalletAssetRatioService,
    swapService: BraveWalletSwapService,
    blockchainRegistry: BraveWalletBlockchainRegistry,
    txService: BraveWalletTxService,
    ethTxManagerProxy: BraveWalletEthTxManagerProxy
  ) {
    self.keyringService = keyringService
    self.rpcService = rpcService
    self.walletService = walletService
    self.assetRatioService = assetRatioService
    self.swapService = swapService
    self.blockchainRegistry = blockchainRegistry
    self.txService = txService
    self.ethTxManagerProxy = ethTxManagerProxy
    
    self.networkStore = .init(rpcService: rpcService)
    self.portfolioStore = .init(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      assetRatioService: assetRatioService,
      blockchainRegistry: blockchainRegistry
    )
    
    self.keyringService.add(self)
    self.txService.add(self)
  }
  
  private var buyTokenStore: BuyTokenStore?
  func openBuyTokenStore(_ prefilledToken: BraveWallet.BlockchainToken?) -> BuyTokenStore {
    if let store = buyTokenStore {
      return store
    }
    let store = BuyTokenStore(
      blockchainRegistry: blockchainRegistry,
      rpcService: rpcService,
      prefilledToken: prefilledToken
    )
    buyTokenStore = store
    return store
  }
  
  private var sendTokenStore: SendTokenStore?
  func openSendTokenStore(_ prefilledToken: BraveWallet.BlockchainToken?) -> SendTokenStore {
    if let store = sendTokenStore {
      return store
    }
    let store = SendTokenStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      txService: txService,
      blockchainRegistry: blockchainRegistry,
      ethTxManagerProxy: ethTxManagerProxy,
      prefilledToken: prefilledToken
    )
    sendTokenStore = store
    return store
  }
  
  private var swapTokenStore: SwapTokenStore?
  func openSwapTokenStore(_ prefilledToken: BraveWallet.BlockchainToken?) -> SwapTokenStore {
    if let store = swapTokenStore {
      return store
    }
    let store = SwapTokenStore(
      keyringService: keyringService,
      blockchainRegistry: blockchainRegistry,
      rpcService: rpcService,
      assetRatioService: assetRatioService,
      swapService: swapService,
      txService: txService,
      walletService: walletService,
      ethTxManagerProxy: ethTxManagerProxy,
      prefilledToken: prefilledToken
    )
    swapTokenStore = store
    return store
  }
  
  private var assetDetailStore: AssetDetailStore?
  func assetDetailStore(for token: BraveWallet.BlockchainToken) -> AssetDetailStore {
    if let store = assetDetailStore, store.token.id == token.id {
      return store
    }
    let store = AssetDetailStore(
      assetRatioService: assetRatioService,
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      txService: txService,
      blockchainRegistry: blockchainRegistry,
      token: token
    )
    assetDetailStore = store
    return store
  }
  
  func closeAssetDetailStore(for token: BraveWallet.BlockchainToken) {
    if let store = assetDetailStore, store.token.id == token.id {
      assetDetailStore = nil
    }
  }
  
  private var accountActivityStore: AccountActivityStore?
  func accountActivityStore(for account: BraveWallet.AccountInfo) -> AccountActivityStore {
    if let store = accountActivityStore, store.account.address == account.address {
      return store
    }
    let store = AccountActivityStore(
      account: account,
      walletService: walletService,
      rpcService: rpcService,
      assetRatioService: assetRatioService,
      txService: txService,
      blockchainRegistry: blockchainRegistry
    )
    accountActivityStore = store
    return store
  }
  
  func closeAccountActivityStore(for account: BraveWallet.AccountInfo) {
    if let store = accountActivityStore, store.account.address == account.address {
      accountActivityStore = nil
    }
  }
  
  private var confirmationStore: TransactionConfirmationStore?
  func openConfirmationStore() -> TransactionConfirmationStore {
    if let store = confirmationStore {
      return store
    }
    let store = TransactionConfirmationStore(
      assetRatioService: assetRatioService,
      rpcService: rpcService,
      txService: txService,
      blockchainRegistry: blockchainRegistry,
      walletService: walletService,
      ethTxManagerProxy: ethTxManagerProxy,
      keyringService: keyringService
    )
    confirmationStore = store
    return store
  }
  
  private(set) lazy var settingsStore = SettingsStore(
    keyringService: keyringService,
    walletService: walletService,
    txService: txService
  )
  
  func prepare() {
    Task { @MainActor in
      let pendingTransactions = await fetchPendingTransactions()
      if !pendingTransactions.isEmpty {
        if self.buySendSwapDestination != nil {
          // Dismiss any buy send swap open to show the unapproved transactions
          self.buySendSwapDestination = nil
        }
        self.pendingRequest = .transactions
        self.isPresentingPendingRequest = true
      } else { // no pending transactions, check for webpage requests
        let pendingWebpageRequest = await fetchPendingWebpageRequest()
        self.pendingRequest = pendingWebpageRequest
        self.isPresentingPendingRequest = pendingWebpageRequest != nil
      }
    }
  }

  @MainActor
  func fetchPendingTransactions() async -> [BraveWallet.TransactionInfo] {
    let keyring = await keyringService.keyringInfo(BraveWallet.DefaultKeyringId)
    var pendingTransactions: [BraveWallet.TransactionInfo] = []
    for info in keyring.accountInfos {
      let allTransactionInfo = await txService.allTransactionInfo(.eth, from: info.address)
      pendingTransactions.append(contentsOf: allTransactionInfo.filter { $0.txStatus == .unapproved })
    }
    return pendingTransactions
  }

  @MainActor
  func fetchPendingWebpageRequest() async -> PendingRequest? {
    // TODO: Add check for eth permissions… get first eth request
    if let chainRequest = await rpcService.pendingAddChainRequests().first {
      return .addChain(chainRequest)
    } else if case let signMessageRequests = await walletService.pendingSignMessageRequests(), !signMessageRequests.isEmpty {
      return .signMessage(signMessageRequests)
    } else if let switchRequest = await rpcService.pendingSwitchChainRequests().first {
      return .switchChain(switchRequest)
    } else if let addTokenRequest = await walletService.pendingAddSuggestTokenRequests().first {
      return .addSuggestedToken(addTokenRequest)
    } else {
      return nil
    }
  }

  func handleWebpageRequestResponse(_ response: WebpageRequestResponse) {
    switch response {
    case let .switchChain(approved, originInfo):
      rpcService.notifySwitchChainRequestProcessed(approved, origin: originInfo.origin)
    case let .addNetwork(approved, chainId):
      rpcService.addEthereumChainRequestCompleted(chainId, approved: approved)
    case let .addSuggestedToken(approved, contractAddresses):
      walletService.notifyAddSuggestTokenRequestsProcessed(approved, contractAddresses: contractAddresses)
    case let .signMessage(approved, id):
      walletService.notifySignMessageRequestProcessed(approved, id: id)
    }
    pendingRequest = nil
    prepare()
  }
}

extension CryptoStore: BraveWalletTxServiceObserver {
  public func onNewUnapprovedTx(_ txInfo: BraveWallet.TransactionInfo) {
    prepare()
  }
  public func onUnapprovedTxUpdated(_ txInfo: BraveWallet.TransactionInfo) {
    prepare()
  }
  public func onTransactionStatusChanged(_ txInfo: BraveWallet.TransactionInfo) {
    prepare()
  }
}

extension CryptoStore: BraveWalletKeyringServiceObserver {
  public func keyringReset() {
  }
  public func keyringCreated(_ keyringId: String) {
  }
  public func keyringRestored(_ keyringId: String) {
  }
  public func locked() {
    isPresentingPendingRequest = false
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
  }
}
