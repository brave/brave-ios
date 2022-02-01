// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import BraveUI
import BraveShared
import Shared
import Data
import BraveWallet
import BraveCore

private let log = Logger.browserLogger

extension BrowserViewController {
    func featuresMenuSection(_ menuController: MenuViewController) -> some View {
        VStack(spacing: 0) {
            VPNMenuButton(
                vpnProductInfo: self.vpnProductInfo,
                displayVPNDestination: { [unowned self] vc in
                    (self.presentedViewController as? MenuViewController)?
                        .pushInnerMenu(vc)
                },
                enableInstalledVPN: { [unowned menuController] in
                    /// Donate Enable VPN Activity for suggestions
                    let enableVPNActivity = ActivityShortcutManager.shared.createShortcutActivity(type: .enableBraveVPN)
                    menuController.userActivity = enableVPNActivity
                    enableVPNActivity.becomeCurrent()
                })
        }
    }
    
    func privacyFeaturesMenuSection(_ menuController: MenuViewController) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.OptionsMenu.menuSectionTitle.capitalized)
                .font(.callout.weight(.semibold))
                .foregroundColor(Color(.braveLabel))
                .padding(.horizontal, 14)
                .padding(.bottom, 5)
                        
            VPNMenuButton(
                vpnProductInfo: self.vpnProductInfo,
                description: Strings.OptionsMenu.braveVPNItemDescription,
                displayVPNDestination: { [unowned self] vc in
                    (self.presentedViewController as? MenuViewController)?
                        .pushInnerMenu(vc)
                },
                enableInstalledVPN: { [unowned menuController] in
                    /// Donate Enable VPN Activity for suggestions
                    let enableVPNActivity = ActivityShortcutManager.shared.createShortcutActivity(type: .enableBraveVPN)
                    menuController.userActivity = enableVPNActivity
                    enableVPNActivity.becomeCurrent()
                }
            )
            
            MenuItemButton(
                icon: #imageLiteral(resourceName: "playlist_menu").template,
                title: Strings.OptionsMenu.bravePlaylistItemTitle,
                subtitle: Strings.OptionsMenu.bravePlaylistItemDescription) { [weak self] in
                guard let self = self else { return }

                self.presentPlaylistController()
            }
            
            // Add Brave Talk and News options only in normal browsing
            if !PrivateBrowsingManager.shared.isPrivateBrowsing {
                // Show Brave News if it is first launch and after first launch If the new is enabled
                if Preferences.General.isFirstLaunch.value || (!Preferences.General.isFirstLaunch.value && Preferences.BraveNews.isEnabled.value) {
                    MenuItemButton(
                        icon: #imageLiteral(resourceName: "menu_brave_news").template,
                        title: Strings.OptionsMenu.braveNewsItemTitle,
                        subtitle: Strings.OptionsMenu.braveNewsItemDescription) { [weak self] in
                        guard let self = self, let newTabPageController = self.tabManager.selectedTab?.newTabPageViewController  else {
                            return
                        }

                        self.popToBVC()
                        newTabPageController.scrollToBraveNews()
                    }
                }
                
                MenuItemButton(
                    icon: #imageLiteral(resourceName: "menu-brave-talk").template,
                    title: Strings.OptionsMenu.braveTalkItemTitle,
                    subtitle: Strings.OptionsMenu.braveTalkItemDescription) { [weak self] in
                    guard let self = self, let url = URL(string: "https://talk.brave.com/") else { return }
                    
                    self.popToBVC()
                    self.finishEditingAndSubmit(url, visitType: .typed)
                }
            }
            
            MenuItemButton(
                icon: #imageLiteral(resourceName: "menu-crypto").template,
                title: "\(Strings.Wallet.wallet) (\(Strings.Wallet.betaLabel))",
                subtitle: Strings.OptionsMenu.braveWalletItemDescription
            ) { [unowned self] in
                self.presentWallet()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
    
    func destinationMenuSection(_ menuController: MenuViewController, isShownOnWebPage: Bool) -> some View {
        VStack(spacing: 0) {
            MenuItemButton(icon: #imageLiteral(resourceName: "menu_bookmarks").template, title: Strings.bookmarksMenuItem) { [unowned self, unowned menuController] in
                let vc = BookmarksViewController(
                    folder: bookmarkManager.lastVisitedFolder(),
                    bookmarkManager: bookmarkManager,
                    isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing)
                vc.toolbarUrlActionsDelegate = self
                menuController.presentInnerMenu(vc)
            }

            MenuItemButton(icon: #imageLiteral(resourceName: "menu-history").template, title: Strings.historyMenuItem) { [unowned self, unowned menuController] in
                let vc = HistoryViewController(isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing, historyAPI: historyAPI)
                vc.toolbarUrlActionsDelegate = self
                menuController.pushInnerMenu(vc)
            }
            MenuItemButton(icon: #imageLiteral(resourceName: "menu-downloads").template, title: Strings.downloadsMenuItem) { [unowned self] in
                FileManager.default.openBraveDownloadsFolder { success in
                    if !success {
                        self.displayOpenDownloadsError()
                    }
                }
            }
            if isShownOnWebPage {
                MenuItemButton(
                    icon: #imageLiteral(resourceName: "menu-crypto").template,
                    title: "\(Strings.Wallet.wallet) (\(Strings.Wallet.betaLabel))"
                ) { [unowned self] in
                    self.presentWallet()
                }
                MenuItemButton(icon: #imageLiteral(resourceName: "playlist_menu").template, title: Strings.playlistMenuItem) { [weak self] in
                    guard let self = self else { return }
                    self.presentPlaylistController()
                }
            }
            MenuItemButton(icon: #imageLiteral(resourceName: "menu-settings").template, title: Strings.settingsMenuItem) { [unowned self, unowned menuController] in
                var keyringStore: KeyringStore?
                if let walletService = BraveWallet.ServiceFactory.get(privateMode: PrivateBrowsingManager.shared.isPrivateBrowsing),
                   let keyringService = BraveWallet.KeyringServiceFactory.get(privateMode: PrivateBrowsingManager.shared.isPrivateBrowsing) {
                        keyringStore = KeyringStore(keyringService: keyringService,
                                                    walletService: walletService)
                }
                
                let vc = SettingsViewController(profile: self.profile,
                                                tabManager: self.tabManager,
                                                feedDataSource: self.feedDataSource,
                                                rewards: self.rewards,
                                                legacyWallet: self.legacyWallet,
                                                windowProtection: self.windowProtection,
                                                historyAPI: self.historyAPI,
                                                syncAPI: self.syncAPI,
                                                walletKeyringStore: keyringStore)
                vc.settingsDelegate = self
                menuController.pushInnerMenu(vc)
            }
        }
    }
    
    private func presentWallet() {
        let privateMode = PrivateBrowsingManager.shared.isPrivateBrowsing
        guard
            let keyringService = BraveWallet.KeyringServiceFactory.get(privateMode: privateMode),
            let rpcService = BraveWallet.JsonRpcServiceFactory.get(privateMode: privateMode),
            let assetRatioService = BraveWallet.AssetRatioServiceFactory.get(privateMode: privateMode),
            let walletService = BraveWallet.ServiceFactory.get(privateMode: privateMode),
            let swapService = BraveWallet.SwapServiceFactory.get(privateMode: privateMode),
            let txService = BraveWallet.EthTxServiceFactory.get(privateMode: privateMode)
        else {
            log.error("Failed to load wallet. One or more services were unavailable")
            return
        }
        
        let walletStore = WalletStore(
            keyringService: keyringService,
            rpcService: rpcService,
            walletService: walletService,
            assetRatioService: assetRatioService,
            swapService: swapService,
            blockchainRegistry: BraveCoreMain.blockchainRegistry,
            txService: txService
        )
        
        let vc = WalletHostingViewController(walletStore: walletStore)
        vc.delegate = self
        self.dismiss(animated: true) {
            self.present(vc, animated: true)
        }
    }
    
    private func presentPlaylistController() {
        // Present existing playlist controller
        if let playlistController = PlaylistCarplayManager.shared.playlistController {
            dismiss(animated: true) {
                self.present(playlistController, animated: true)
            }
        } else {
            // Retrieve the item and offset-time from the current tab's webview.
            let tab = self.tabManager.selectedTab
            PlaylistCarplayManager.shared.getPlaylistController(tab: tab) { [weak self] playlistController in
                guard let self = self else { return }
                
                playlistController.modalPresentationStyle = .fullScreen
                
                self.dismiss(animated: true) {
                    self.present(playlistController, animated: true)
                }
            }
        }
    }
    
    struct PageActionsMenuSection: View {
        var browserViewController: BrowserViewController
        var tabURL: URL
        var activities: [UIActivity]
        
        @State private var playlistItemAdded: Bool = false
        
        private var playlistActivity: (enabled: Bool, item: PlaylistInfo?)? {
            browserViewController.addToPlayListActivityItem ??
                browserViewController.openInPlaylistActivityItem
        }
        
        private var isPlaylistItemAdded: Bool {
            browserViewController.openInPlaylistActivityItem != nil
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                MenuTabDetailsView(tab: browserViewController.tabManager.selectedTab, url: tabURL)
                VStack(spacing: 0) {
                    if let activity = playlistActivity, activity.enabled, let item = activity.item {
                        PlaylistMenuButton(isAdded: isPlaylistItemAdded) {
                            if !isPlaylistItemAdded {
                                // Add to playlist
                                browserViewController.addToPlaylist(item: item) { didAddItem in
                                    log.debug("Playlist Item Added")
                                    if didAddItem {
                                        playlistItemAdded = true
                                    }
                                }
                            } else {
                                browserViewController.dismiss(animated: true) {
                                    let tab = browserViewController.tabManager.selectedTab
                                    
                                    if let webView = tab?.webView {
                                        PlaylistHelper.getCurrentTime(webView: webView, nodeTag: item.tagId) { [weak browserViewController] currentTime in
                                            browserViewController?.openPlaylist(tab: tab, item: item, playbackOffset: currentTime)
                                        }
                                    } else {
                                        browserViewController.openPlaylist(tab: nil, item: item, playbackOffset: 0.0)
                                    }
                                }
                            }
                        }
                        .animation(.default, value: playlistItemAdded)
                    }
                    MenuItemButton(icon: #imageLiteral(resourceName: "nav-share").template, title: Strings.shareWithMenuItem) {
                        browserViewController.dismiss(animated: true)
                        browserViewController.tabToolbarDidPressShare()
                    }
                    MenuItemButton(icon: #imageLiteral(resourceName: "menu-add-bookmark").template, title: Strings.addToMenuItem) {
                        browserViewController.dismiss(animated: true) {
                            browserViewController.openAddBookmark()
                        }
                    }
                    ForEach(activities, id: \.activityTitle) { activity in
                        MenuItemButton(icon: activity.activityImage?.template ?? UIImage(), title: activity.activityTitle ?? "") {
                            browserViewController.dismiss(animated: true)
                            activity.perform()
                        }
                    }
                }
            }
        }
    }
    
    struct MenuTabDetailsView: View {
        @SwiftUI.Environment(\.colorScheme) var colorScheme: ColorScheme
        weak var tab: Tab?
        var url: URL

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                if let tab = tab {
                    Text(verbatim: tab.displayTitle)
                        .font(.callout)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(Color(.braveLabel))
                }
                Text(verbatim: url.baseDomain ?? url.host ?? url.absoluteDisplayString)
                    .font(.footnote)
                    .lineLimit(1)
                    .foregroundColor(Color(.secondaryBraveLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
    }
}
