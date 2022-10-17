// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveWallet
import struct Shared.InternalURL
import BraveCore
import SwiftUI
import BraveUI
import Data
import BraveShared
import os.log

extension WalletStore {
  /// Creates a WalletStore based on whether or not the user is in Private Mode
  static func from(privateMode: Bool) -> WalletStore? {
    guard
      let keyringService = BraveWallet.KeyringServiceFactory.get(privateMode: privateMode),
      let rpcService = BraveWallet.JsonRpcServiceFactory.get(privateMode: privateMode),
      let assetRatioService = BraveWallet.AssetRatioServiceFactory.get(privateMode: privateMode),
      let walletService = BraveWallet.ServiceFactory.get(privateMode: privateMode),
      let swapService = BraveWallet.SwapServiceFactory.get(privateMode: privateMode),
      let txService = BraveWallet.TxServiceFactory.get(privateMode: privateMode),
      let ethTxManagerProxy = BraveWallet.EthTxManagerProxyFactory.get(privateMode: privateMode),
      let solTxManagerProxy = BraveWallet.SolanaTxManagerProxyFactory.get(privateMode: privateMode)
    else {
      Logger.module.error("Failed to load wallet. One or more services were unavailable")
      return nil
    }
    return WalletStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      assetRatioService: assetRatioService,
      swapService: swapService,
      blockchainRegistry: BraveWalletAPI.blockchainRegistry,
      txService: txService,
      ethTxManagerProxy: ethTxManagerProxy,
      solTxManagerProxy: solTxManagerProxy
    )
  }
}

extension CryptoStore {
  /// Creates a CryptoStore based on whether or not the user is in Private Mode
  static func from(privateMode: Bool) -> CryptoStore? {
    guard
      let keyringService = BraveWallet.KeyringServiceFactory.get(privateMode: privateMode),
      let rpcService = BraveWallet.JsonRpcServiceFactory.get(privateMode: privateMode),
      let assetRatioService = BraveWallet.AssetRatioServiceFactory.get(privateMode: privateMode),
      let walletService = BraveWallet.ServiceFactory.get(privateMode: privateMode),
      let swapService = BraveWallet.SwapServiceFactory.get(privateMode: privateMode),
      let txService = BraveWallet.TxServiceFactory.get(privateMode: privateMode),
      let ethTxManagerProxy = BraveWallet.EthTxManagerProxyFactory.get(privateMode: privateMode),
      let solTxManagerProxy = BraveWallet.SolanaTxManagerProxyFactory.get(privateMode: privateMode)
    else {
      Logger.module.error("Failed to load wallet. One or more services were unavailable")
      return nil
    }
    return CryptoStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      assetRatioService: assetRatioService,
      swapService: swapService,
      blockchainRegistry: BraveWalletAPI.blockchainRegistry,
      txService: txService,
      ethTxManagerProxy: ethTxManagerProxy,
      solTxManagerProxy: solTxManagerProxy
    )
  }
}

extension BrowserViewController {
  /// Initializes a new WalletStore for displaying the wallet, setting up an observer to notify
  /// when the pending request is updated so we can update the wallet url bar button.
  func newWalletStore() -> WalletStore? {
    let privateMode = PrivateBrowsingManager.shared.isPrivateBrowsing
    guard let walletStore = WalletStore.from(privateMode: privateMode)
    else {
      Logger.module.error("Failed to load wallet. One or more services were unavailable")
      return nil
    }
    self.walletStore = walletStore
    self.onPendingRequestUpdatedCancellable = walletStore.onPendingRequestUpdated
      .sink { [weak self] _ in
        self?.updateURLBarWalletButton()
      }
    return walletStore
  }
  
  func presentWalletPanel(from origin: URLOrigin, with tabDappStore: TabDappStore) {
    guard let walletStore = self.walletStore ?? newWalletStore() else { return }
    let controller = WalletPanelHostingController(
      walletStore: walletStore,
      tabDappStore: tabDappStore,
      origin: origin,
      faviconRenderer: FavIconImageRenderer()
    )
    controller.delegate = self
    let popover = PopoverController(contentController: controller)
    popover.present(from: topToolbar.locationView.walletButton, on: self, completion: nil)
    toolbarVisibilityViewModel.toolbarState = .expanded
  }
}

extension WalletPanelHostingController: PopoverContentComponent {}

extension BrowserViewController: BraveWalletDelegate {
  public func openWalletURL(_ destinationURL: URL) {
    if presentedViewController != nil {
      // dismiss to show the new tab
      self.dismiss(animated: true)
    }
    if let url = tabManager.selectedTab?.url, InternalURL.isValid(url: url) {
      select(url: destinationURL, visitType: .link)
    } else {
      _ = tabManager.addTabAndSelect(
        URLRequest(url: destinationURL),
        isPrivate: PrivateBrowsingManager.shared.isPrivateBrowsing
      )
    }
  }
  
  public func walletPanel(_ panel: WalletPanelHostingController, presentWalletWithContext: PresentingContext, walletStore: WalletStore) {
    let walletHostingController = WalletHostingViewController(
      walletStore: walletStore,
      presentingContext: presentWalletWithContext,
      faviconRenderer: FavIconImageRenderer()
    )
    walletHostingController.delegate = self
    
    switch presentWalletWithContext {
    case .default, .settings:
      // Dismiss Wallet Panel first, then present Wallet
      self.dismiss(animated: true) { [weak self] in
        self?.present(walletHostingController, animated: true)
      }
    default:
      panel.present(walletHostingController, animated: true)
    }
  }
}

extension Tab: BraveWalletProviderDelegate {
  func showPanel() {
    guard let origin = url?.origin else {
      Logger.module.error("Failing to show Wallet panel due to unavailable tab url origin")
      return
    }
    tabDelegate?.showWalletNotification(self, origin: origin)
  }

  func getOrigin() -> URLOrigin {
    guard let origin = url?.origin else {
      assert(false, "We should have a valid origin to get to this point")
      return .init()
    }
    return origin
  }

  public func requestPermissions(_ coinType: BraveWallet.CoinType, accounts: [String], completion: @escaping RequestPermissionsCallback) {
    Task { @MainActor in
      let permissionRequestManager = WalletProviderPermissionRequestsManager.shared
      let origin = getOrigin()
      
      if permissionRequestManager.hasPendingRequest(for: origin, coinType: coinType) {
        completion(.requestInProgress, nil)
        return
      }
      
      let isPrivate = PrivateBrowsingManager.shared.isPrivateBrowsing
      
      // Check if eth permissions already exist for this origin and if they don't, ensure the user allows
      // ethereum/solana provider access
      let walletPermissions = origin.url.map { Domain.walletPermissions(forUrl: $0, coin: coinType) ?? [] } ?? []
      if walletPermissions.isEmpty, !Preferences.Wallet.allowEthProviderAccess.value {
        completion(.internal, nil)
        return
      }
      
      guard WalletStore.from(privateMode: isPrivate) != nil else {
        completion(.internal, nil)
        return
      }
      let (success, accounts) = await allowedAccounts(coinType, accounts: accounts)
      if !success {
        completion(.internal, [])
        return
      }
      if success && !accounts.isEmpty {
        completion(.none, accounts)
        return
      }
      
      // add permission request to the queue
      _ = permissionRequestManager.beginRequest(for: origin, coinType: coinType, providerHandler: completion, completion: { response in
        switch response {
        case .granted(let accounts):
          completion(.none, accounts)
        case .rejected:
          completion(.none, [])
        }
        self.tabDelegate?.updateURLBarWalletButton()
      })

      self.tabDelegate?.showWalletNotification(self, origin: origin)
    }
  }

  @MainActor func allowedAccountsForCurrentCoin() async -> (Bool, [String]) {
    guard let keyringService = BraveWallet.KeyringServiceFactory.get(privateMode: false),
          let walletService = BraveWallet.ServiceFactory.get(privateMode: false) else {
      return (false, [])
    }
    let coin = await walletService.selectedCoin()
    let accounts = await keyringService.keyringInfo(coin.keyringId).accountInfos.map(\.address)
    return await allowedAccounts(coin, accounts: accounts)
  }
  
  @MainActor func allowedAccounts(_ type: BraveWallet.CoinType, accounts: [String]) async -> (Bool, [String]) {
    func filterAccounts(
      _ accounts: [String],
      selectedAccount: String?
    ) -> [String] {
      if let selectedAccount = selectedAccount, accounts.contains(selectedAccount) {
        return [selectedAccount]
      }
      return accounts
    }
    // This method is called immediately upon creation of the wallet provider, which happens at tab
    // configuration, which means it may not be selected or ready yet.
    guard let keyringService = BraveWallet.KeyringServiceFactory.get(privateMode: false),
          let originURL = url?.origin.url else {
      return (false, [])
    }
    let isLocked = await keyringService.isLocked()
    if isLocked {
      return (false, [])
    }
    let selectedAccount = await keyringService.selectedAccount(type)
    let permissions = Domain.walletPermissions(forUrl: originURL, coin: type)
    return (
      true,
      filterAccounts(permissions ?? [], selectedAccount: selectedAccount)
    )
  }
  
  func isAccountAllowed(_ type: BraveWallet.CoinType, account: String) async -> Bool {
    return await allowedAccounts(type, accounts: [account]).1.contains(account)
  }
  
  func walletInteractionDetected() {
    // No usage for iOS
  }
  
  func showWalletOnboarding() {
    showPanel()
  }
  
  func isTabVisible() -> Bool {
    tabDelegate?.isTabVisible(self) ?? false
  }
  
  func isPermissionDenied(_ type: BraveWallet.CoinType) -> Bool {
    switch type {
    case .eth, .sol:
      return false
    case .fil:
      return true
    @unknown default:
      return true
    }
  }
  
  func showAccountCreation(_ type: BraveWallet.CoinType) {
  }
  
  func isSolanaAccountConnected(_ account: String) -> Bool {
    tabDappStore.solConnectedAddresses.contains(account)
  }
  
  func addSolanaConnectedAccount(_ account: String) {
    tabDappStore.solConnectedAddresses.insert(account)
  }
  
  func removeSolanaConnectedAccount(_ account: String) {
    tabDappStore.solConnectedAddresses.remove(account)
  }
  
  func clearSolanaConnectedAccounts() {
    tabDappStore.solConnectedAddresses = .init()
  }
}

extension Tab: BraveWalletEventsListener {
  func emitEthereumEvent(_ event: Web3ProviderEvent) {
    guard Preferences.Wallet.defaultEthWallet.value == Preferences.Wallet.WalletType.brave.rawValue else {
      return
    }
    var arguments: [Any] = [event.name]
    if let eventArgs = event.arguments {
      arguments.append(eventArgs)
    }
    webView?.evaluateSafeJavaScript(
      functionName: "window.ethereum.emit",
      args: arguments,
      contentWorld: EthereumProviderScriptHandler.scriptSandbox,
      completion: nil
    )
  }
  
  func chainChangedEvent(_ chainId: String) {
    Task { @MainActor in
      /// Temporary fix for #5404
      /// Ethereum properties have been updated correctly, however, dapp is not updated unless there is a reload
      /// We keep the same as Metamask, that, we will reload tab on chain changes.
      emitEthereumEvent(.ethereumChainChanged(chainId: chainId))
      updateEthereumProperties()
      reload()
    }
  }
  
  func accountsChangedEvent(_ accounts: [String]) {
    /// Temporary fix for #5402.
    /// If we emit from one account directly to another we're not seeing dapp sites
    /// update our selected account. If we emit an undefined/empty string before
    /// emitting the new account, we're seeing correct account change behaviour
    emitEthereumEvent(.ethereumAccountsChanged(accounts: []))
    emitEthereumEvent(.ethereumAccountsChanged(accounts: accounts))
    updateEthereumProperties()
  }
  
  func updateEthereumProperties() {
    guard let keyringService = BraveWallet.KeyringServiceFactory.get(privateMode: false),
          let walletService = BraveWallet.ServiceFactory.get(privateMode: false),
          Preferences.Wallet.defaultEthWallet.value == Preferences.Wallet.WalletType.brave.rawValue else {
      return
    }
    Task { @MainActor in
      /// Turn an optional value into a string (or quoted string in case of the value being a string) or
      /// return `undefined`
      func valueOrUndefined<T>(_ value: T?) -> String {
        switch value {
        case .some(let string as String):
          return "\"\(string)\""
        case .some(let value):
          return "\(value)"
        case .none:
          return "undefined"
        }
      }
      guard let webView = webView, let provider = walletEthProvider else {
        return
      }
      let chainId = await provider.chainId()
      webView.evaluateSafeJavaScript(
        functionName: "window.ethereum.chainId = \"\(chainId)\"",
        contentWorld: EthereumProviderScriptHandler.scriptSandbox,
        asFunction: false,
        completion: nil
      )
      let networkVersion = valueOrUndefined(Int(chainId.removingHexPrefix, radix: 16))
      webView.evaluateSafeJavaScript(
        functionName: "window.ethereum.networkVersion = \(networkVersion)",
        contentWorld: EthereumProviderScriptHandler.scriptSandbox,
        asFunction: false,
        completion: nil
      )
      let coin = await walletService.selectedCoin()
      let accounts = await keyringService.keyringInfo(coin.keyringId).accountInfos.map(\.address)
      let selectedAccount = valueOrUndefined(await allowedAccounts(coin, accounts: accounts).1.first)
      webView.evaluateSafeJavaScript(
        functionName: "window.ethereum.selectedAddress = \(selectedAccount)",
        contentWorld: EthereumProviderScriptHandler.scriptSandbox,
        asFunction: false,
        completion: nil
      )
    }
  }
}

extension Tab: BraveWalletSolanaEventsListener {
  func accountChangedEvent(_ account: String?) {
    emitSolanaEvent(.solanaAccountChanged(account: account ?? ""))
    updateSolanaProperties()
  }

  func emitSolanaEvent(_ event: Web3ProviderEvent) {
    guard Preferences.Wallet.defaultSolWallet.value == Preferences.Wallet.WalletType.brave.rawValue,
          let webView = webView else {
      return
    }
    Task { @MainActor in
      var arguments: [Any] = [event.name]
      if let eventArgs = event.arguments {
        arguments.append(eventArgs)
      }
      await webView.evaluateSafeJavaScript(
        functionName: "window.solana.emit", // TODO: `window.braveSolana` ?
        args: arguments,
        contentWorld: .page
      )
    }
  }

  func updateSolanaProperties() {
    guard Preferences.Wallet.defaultSolWallet.value == Preferences.Wallet.WalletType.brave.rawValue else {
      return
    }
    Task { @MainActor in
      guard let webView = webView,
            let provider = walletSolProvider else {
        return
      }
      let isConnected = await provider.isConnected()
      await webView.evaluateSafeJavaScript(
        functionName: "window.solana.isConnected = \(isConnected)",
        contentWorld: .page,
        asFunction: false
      )
      // TODO: publicKey
    }
  }
}

extension BraveWallet.CoinType {
  var keyringId: String {
    switch self {
    case .eth:
      return BraveWallet.DefaultKeyringId
    case .sol:
      return BraveWallet.SolanaKeyringId
    case .fil:
      return BraveWallet.FilecoinKeyringId
    @unknown default:
      return ""
    }
  }
}

extension Tab: BraveWalletKeyringServiceObserver {
  func keyringCreated(_ keyringId: String) {
  }
  
  func keyringRestored(_ keyringId: String) {
  }
  
  func keyringReset() {
    reload()
    tabDelegate?.updateURLBarWalletButton()
  }
  
  func locked() {
  }
  
  func unlocked() {
    guard let origin = url?.origin else { return }
    Task { @MainActor in
      // check domain already has some permitted accounts for this Tab's URLOrigin
      let permissionRequestManager = WalletProviderPermissionRequestsManager.shared
      if permissionRequestManager.hasPendingRequest(for: origin, coinType: .eth) {
        let pendingRequests = permissionRequestManager.pendingRequests(for: origin, coinType: .eth)
        let (success, accounts) = await allowedAccountsForCurrentCoin()
        if success, !accounts.isEmpty {
          for request in pendingRequests {
            // cancel the requests if `allowedAccounts` is not empty for this domain
            permissionRequestManager.cancelRequest(request)
            // let wallet provider know we have allowed accounts for this domain
            request.providerHandler?(.none, accounts)
          }
        }
      }
    }
  }
  
  func backedUp() {
  }
  
  func accountsChanged() {
  }
  
  func autoLockMinutesChanged() {
  }
  
  func selectedAccountChanged(_ coin: BraveWallet.CoinType) {
  }
}

extension FavIconImageRenderer: WalletFaviconRenderer {
  func loadIcon(siteURL: URL, persistent: Bool, completion: ((UIImage?) -> Void)?) {
    loadIcon(siteURL: siteURL, kind: .largeIcon, persistent: persistent, completion: completion)
  }
}
