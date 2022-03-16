// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveWallet
import struct Shared.InternalURL
import struct Shared.Logger
import BraveCore
import SwiftUI
import BraveUI
import Data

private let log = Logger.browserLogger

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
            let ethTxManagerProxy = BraveWallet.EthTxManagerProxyFactory.get(privateMode: privateMode)
        else {
            log.error("Failed to load wallet. One or more services were unavailable")
            return nil
        }
        return WalletStore(
            keyringService: keyringService,
            rpcService: rpcService,
            walletService: walletService,
            assetRatioService: assetRatioService,
            swapService: swapService,
            blockchainRegistry: BraveCoreMain.blockchainRegistry,
            txService: txService,
            ethTxManagerProxy: ethTxManagerProxy
        )
    }
}

extension BrowserViewController {
    func presentWalletPanel() {
        let privateMode = PrivateBrowsingManager.shared.isPrivateBrowsing
        guard let keyringService = BraveWallet.KeyringServiceFactory.get(privateMode: privateMode),
              let rpcService = BraveWallet.JsonRpcServiceFactory.get(privateMode: privateMode) else {
                  return
              }
        let controller = WalletPanelHostingController(
            rootView: WalletPanelView(
                keyringStore: KeyringStore(keyringService: keyringService),
                networkStore: NetworkStore(rpcService: rpcService)
            )
        )
        let popover = PopoverController(contentController: controller, contentSizeBehavior: .autoLayout)
        popover.present(from: topToolbar.locationView.walletButton, on: self, completion: nil)
    }
}

extension BrowserViewController: BraveWalletDelegate {
    func openWalletURL(_ destinationURL: URL) {
        if let url = tabManager.selectedTab?.url, InternalURL.isValid(url: url) {
            select(url: destinationURL, visitType: .link)
        } else {
            _ = tabManager.addTabAndSelect(
                URLRequest(url: destinationURL),
                isPrivate: PrivateBrowsingManager.shared.isPrivateBrowsing
            )
        }
    }
}

private class WalletPanelHostingController: UIHostingController<WalletPanelView> & PopoverContentComponent {
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // For some reason these 2 calls are required in order for the `UIHostingController` to layout
        // correctly. Without this it for some reason becomes taller than what it needs to be despite its
        // `sizeThatFits(_:)` calls returning the correct value once the parent does layout.
        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()
    }
}

extension BrowserViewController: BraveWalletProviderDelegate {
    private func filterAccounts(
        _ accounts: [String],
        selectedAccount: String?
    ) -> [String] {
        if let selectedAccount = selectedAccount, accounts.contains(selectedAccount) {
            return [selectedAccount]
        }
        return accounts
    }
    
    private var selectedTabOrigin: URL? {
        guard let tab = tabManager.selectedTab, let origin = tab.url?.origin else { return nil }
        return URL(string: origin)
    }
    
    func showPanel() {
        // TODO: Show ad-like notification prompt before calling `presentWalletPanel`
        presentWalletPanel()
    }
    
    func getOrigin() -> URL {
        guard let origin = selectedTabOrigin else {
            assert(false, "We should have a valid origin to get to this point")
            return NSURL() as URL // We can't make an "empty" URL like you can with NSURL
        }
        return origin
    }
    
    func requestEthereumPermissions(_ completion: @escaping BraveWalletProviderResultsCallback) {
        Task { @MainActor in
            let isPrivate = PrivateBrowsingManager.shared.isPrivateBrowsing
            guard let walletStore = WalletStore.from(privateMode: isPrivate) else {
                completion([], .internalError, "")
                return
            }
            let (accounts, status, message) = await allowedAccounts(false)
            if status != .success {
                completion([], status, message)
                return
            }
            if status == .success && !accounts.isEmpty {
                completion(accounts, .success, "")
                return
            }
            
            let permissions = WalletHostingViewController(
                walletStore: walletStore,
                presentingContext: .requestEthererumPermissions { [weak self] response in
                    guard let self = self else { return }
                    switch response {
                    case .granted(let accounts):
                        Domain.setEthereumPermissions(forUrl: self.getOrigin(), accounts: accounts, grant: true)
                        completion(accounts, .success, "")
                    case .rejected:
                        completion([], .userRejectedRequest, "User rejected request")
                    }
                },
                onUnlock: {
                    Task { @MainActor in
                        // If the user unlocks their wallet and we already have permissions setup they do not
                        // go through the regular flow
                        let (accounts, status, _) = await self.allowedAccounts(false)
                        if status == .success, !accounts.isEmpty {
                            completion(accounts, .success, "")
                            self.dismiss(animated: true)
                            return
                        }
                    }
                }
            )
            present(permissions, animated: true)
        }
    }
    
    func allowedAccounts(_ includeAccountsWhenLocked: Bool) async -> ([String], BraveWallet.ProviderError, String) {
        // This method is called immediately upon creation of the wallet provider, which happens at tab
        // configuration, which means it may not be selected or ready yet.
        guard let keyringService = BraveWallet.KeyringServiceFactory.get(privateMode: false),
              selectedTabOrigin != nil else {
            return ([], .internalError, "Internal error")
        }
        updateURLBarWalletButton()
        let origin = getOrigin()
        let isLocked = await keyringService.isLocked()
        if !includeAccountsWhenLocked && isLocked {
            return ([], .success, "")
        }
        let selectedAccount = await keyringService.selectedAccount(.eth)
        let permissions = Domain.ethereumPermissions(forUrl: origin)
        return (
            filterAccounts(permissions ?? [], selectedAccount: selectedAccount),
            .success,
            ""
        )
    }
    
    func updateURLBarWalletButton() {
        topToolbar.locationView.walletButton.buttonState =
            tabManager.selectedTab?.isWalletIconVisible == true ? .active : .inactive
    }
}

extension Tab {
    func updateEthereumProperties() {
        Task { @MainActor in
            guard let webView = webView, let provider = walletProvider else {
                return
            }
            let chainId = await provider.chainId()
            webView.evaluateSafeJavaScript(
                functionName: "window.ethereum.chainId = \"\(chainId)\"",
                contentWorld: .page,
                asFunction: false,
                completion: nil
            )
            if let networkVersion = Int(chainId.removingHexPrefix, radix: 16) {
                webView.evaluateSafeJavaScript(
                    functionName: "window.ethereum.networkVersion = \(networkVersion)",
                    contentWorld: .page,
                    asFunction: false,
                    completion: nil
                )
            }
//            let (accounts, _, _) = await provider.allowedAccounts(false)
//            if let account = accounts.first {
//                webView.evaluateSafeJavaScript(
//                    functionName: "window.ethereum.selectedAccount = \"\(account)\"",
//                    contentWorld: .page,
//                    asFunction: false,
//                    completion: nil
//                )
//            }
        }
    }
}
