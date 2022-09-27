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

      vpnButton(menuController)
      MenuItemFactory.button(for: .playlist(subtitle: Strings.OptionsMenu.bravePlaylistItemDescription), completion: presentPlaylistController)
      
      // Add Brave Talk and News options only in normal browsing
      if !PrivateBrowsingManager.shared.isPrivateBrowsing {
        // Show Brave News if it is first launch and after first launch If the new is enabled
        if Preferences.General.isFirstLaunch.value || (!Preferences.General.isFirstLaunch.value && Preferences.BraveNews.isEnabled.value) {
          MenuItemFactory.button(for: .news, completion: navigateToBraveNews)
        }
        MenuItemFactory.button(for: .talk, completion: finishEditingAndSubmit)
      }
      
      MenuItemFactory.button(for: .wallet(subtitle: Strings.OptionsMenu.braveWalletItemDescription), completion: presentWallet)
    }
    .fixedSize(horizontal: false, vertical: true)
    .padding(.top, 10)
    .padding(.bottom, 5)
  }

  func destinationMenuSection(_ menuController: MenuViewController, isShownOnWebPage: Bool) -> some View {
    VStack(spacing: 0) {
      MenuItemFactory.button(for: .bookmarks) { [weak self] in
        self?.presentBookmarks(menuController)
      }
      MenuItemFactory.button(for: .history) { [weak self] in
        self?.presentHistory(menuController)
      }
      MenuItemFactory.button(for: .downloads, completion: openBraveDownloadsFolder)

      if isShownOnWebPage {
        MenuItemFactory.button(for: .wallet(), completion: presentWallet)
        MenuItemFactory.button(for: .playlist(), completion: presentPlaylistController)
      }
      MenuItemFactory.button(for: .settings) { [weak self] in
        self?.presentSettings(menuController)
      }
    }
  }
  
  private func vpnButton(_ menuController: MenuViewController) -> VPNMenuButton {
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
  }

  private func presentWallet() {
    guard let walletStore = self.walletStore ?? newWalletStore() else { return }
    let vc = WalletHostingViewController(walletStore: walletStore, faviconRenderer: FavIconImageRenderer())
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
  
  private func navigateToBraveNews() {
    guard let newTabPageController = self.tabManager.selectedTab?.newTabPageViewController else {
      return
    }
    self.popToBVC()
    newTabPageController.scrollToBraveNews()
  }
  
  private func finishEditingAndSubmit() {
    guard let url = URL(string: "https://talk.brave.com/") else { return }

    self.popToBVC()
    self.finishEditingAndSubmit(url, visitType: .typed)
  }
  
  private func presentBookmarks(_ menuController: MenuViewController) {
    let vc = BookmarksViewController(
      folder: bookmarkManager.lastVisitedFolder(),
      bookmarkManager: bookmarkManager,
      isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing)
    vc.toolbarUrlActionsDelegate = self
    menuController.presentInnerMenu(vc)
  }
  
  private func presentHistory(_ menuController: MenuViewController) {
    let vc = HistoryViewController(
      isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing,
      historyAPI: braveCore.historyAPI,
      tabManager: tabManager)
    vc.toolbarUrlActionsDelegate = self
    menuController.pushInnerMenu(vc)
  }
  
  private func openBraveDownloadsFolder() {
    FileManager.default.openBraveDownloadsFolder { success in
      if !success {
        self.displayOpenDownloadsError()
      }
    }
  }
  
  private func presentSettings(_ menuController: MenuViewController) {
    let isPrivateMode = PrivateBrowsingManager.shared.isPrivateBrowsing
    let keyringService = BraveWallet.KeyringServiceFactory.get(privateMode: isPrivateMode)
    let walletService = BraveWallet.ServiceFactory.get(privateMode: isPrivateMode)
    let rpcService = BraveWallet.JsonRpcServiceFactory.get(privateMode: isPrivateMode)
    
    var keyringStore: KeyringStore?
    if let keyringService = keyringService,
       let walletService = walletService,
       let rpcService = rpcService {
      keyringStore = KeyringStore(
        keyringService: keyringService,
        walletService: walletService,
        rpcService: rpcService
      )
    }
    
    let cryptoStore = CryptoStore.from(privateMode: isPrivateMode)

    let vc = SettingsViewController(
      profile: self.profile,
      tabManager: self.tabManager,
      feedDataSource: self.feedDataSource,
      rewards: self.rewards,
      legacyWallet: self.legacyWallet,
      windowProtection: self.windowProtection,
      braveCore: self.braveCore,
      keyringStore: keyringStore,
      cryptoStore: cryptoStore
    )
    vc.settingsDelegate = self
    menuController.pushInnerMenu(vc)
  }

  struct PageActionsMenuSection: View {
    var browserViewController: BrowserViewController
    var tabURL: URL
    var activities: [UIActivity]

    @State private var playlistItemAdded: Bool = false

    private var playlistActivity: (enabled: Bool, item: PlaylistInfo?)? {
      browserViewController.addToPlayListActivityItem ?? browserViewController.openInPlaylistActivityItem
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
          }
          MenuItemButton(icon: UIImage(named: "nav-share", in: .current, compatibleWith: nil)!.template, title: Strings.shareWithMenuItem) {
            browserViewController.dismiss(animated: true)
            browserViewController.tabToolbarDidPressShare()
          }
          NightModeMenuButton(dismiss: {
            browserViewController.dismiss(animated: true)
          })
          MenuItemButton(icon: UIImage(named: "menu-add-bookmark", in: .current, compatibleWith: nil)!.template, title: Strings.addToMenuItem) {
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
