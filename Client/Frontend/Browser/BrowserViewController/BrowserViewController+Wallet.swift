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
    
    func showPanel() {
        guard let keyringService = BraveWallet.KeyringServiceFactory.get(privateMode: false) else { return }
        let keyringStore = KeyringStore(keyringService: keyringService)
        // TODO: Show ad-like notification prompt before calling `presentWalletPanel`
        presentWalletPanel()
    }
    
    func getOrigin() -> URL {
        guard let selectedTab = tabManager.selectedTab,
              let origin = selectedTab.url?.origin,
              let url = URL(string: origin) else {
                  assert(false, "We should have a valid origin to get to this point")
                  return NSURL() as URL // We can't make an "empty" URL like you can with NSURL
              }
        return url
    }
    
    func requestEthereumPermissions(_ completion: @escaping BraveWalletProviderResultsCallback) {
        // TODO: Figure out what order these calls happen in...
        
        /*
         1. RequestEthereumPermissions calls...
         2. GetAllowedAccounts
                - gets selected account from KeyringService
                - gets keyring info for default keyring, maps account infos to addresses
                - fetches permissions (BraveEthereumPermissionContext::GetAllowedAccounts)
                  for each address of the domain, returns allowed accounts
                - "Filters" accounts if keyring is unlocked or include_accounts_when_locked is true (w/ selected account)
                - error here is `success` or `internalError` if fail to obtain permissions
         4. ContinueRequestEthereumPermissions
                - checks success passed from GetAllowedAccounts, bails early if its an error
                - if there are no allowed accounts: responds with an empty array, success and empty error string
                - otherwise gets keyring info and passes to next function
         5. ContinueRequestEthereumPermissionsKeyringInfo
                - if no wallet is created, shows onboarding, errors with `internalError`
                - if the keyring is locked, response with an empty array, success and empty error string
         6. BraveEthereumPermissionContext::RequestPermissions (fetches ContentSetting permissions for each)
                - ???? Apparently does the same thing as GetAllowedAccounts version
                - Sets up a pending permissions request, which then is checked for in BraveWalletTabHelper::GetBubbleURL ?
         7. OnRequestEthereumPermissions
                - Just calls back with filtered account
         
         "Filter account" means possibly returning only 1 address if its the selected account instead of
         all of them
         */
        guard let walletStore = WalletStore.from(privateMode: PrivateBrowsingManager.shared.isPrivateBrowsing) else {
            completion([], .internalError, "")
            return
        }
        let permissions = WalletHostingViewController(
            walletStore: walletStore,
            presentingContext: .requestEthererumPermissions { response in
                switch response {
                case .granted(let accounts):
                    completion(accounts, .success, "")
                case .rejected:
                    completion([], .userRejectedRequest, "User rejected request")
                }
            }
        )
        present(permissions, animated: true)
    }
    
    func getAllowedAccounts(_ includeAccountsWhenLocked: Bool, completion: @escaping BraveWalletProviderResultsCallback) {
        updateURLBarWalletButton()
        guard let keyringService = BraveWallet.KeyringServiceFactory.get(privateMode: false) else { return }
        Task { @MainActor in
            let isLocked = await keyringService.isLocked()
            if !includeAccountsWhenLocked && isLocked {
                completion([], .success, "")
                return
            }
            let keyring = await keyringService.keyringInfo(BraveWallet.DefaultKeyringId)
            let selectedAccount = await keyringService.selectedAccount(.eth)
            // TODO: Pull from domain
            completion(
                filterAccounts(keyring.accountInfos.map(\.address), selectedAccount: selectedAccount),
                .success,
                ""
            )
        }
//        completion(["0x2f76C097a15792839655077346Aa4b5ef367EB90"], .success, "")
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
