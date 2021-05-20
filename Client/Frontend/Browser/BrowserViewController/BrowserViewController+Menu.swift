// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import BraveUI
import Shared
import Data

private let log = Logger.browserLogger

extension BrowserViewController {
    func featuresMenuSection(_ menuController: MenuViewController) -> some View {
        VStack(spacing: 0) {
            VPNMenuButton(vpnProductInfo: self.vpnProductInfo) { vc in
                (self.presentedViewController as? MenuViewController)?
                    .pushViewController(vc, animated: true)
            }
        }
    }
    
    func destinationMenuSection(_ menuController: MenuViewController) -> some View {
        VStack(spacing: 0) {
            MenuItemButton(icon: #imageLiteral(resourceName: "menu_bookmarks").template, title: Strings.bookmarksMenuItem) { [unowned menuController] in
                let vc = BookmarksViewController(folder: Bookmarkv2.lastVisitedFolder(), isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing)
                vc.toolbarUrlActionsDelegate = self
                menuController.presentInnerMenu(vc)
            }
            MenuItemButton(icon: #imageLiteral(resourceName: "menu-history").template, title: Strings.historyMenuItem) { [unowned menuController] in
                let vc = HistoryViewController(isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing)
                vc.toolbarUrlActionsDelegate = self
                menuController.pushViewController(vc, animated: true)
            }
            MenuItemButton(icon: #imageLiteral(resourceName: "menu-downloads").template, title: Strings.downloadsMenuItem) { [unowned menuController] in
                let vc = DownloadsPanel(profile: self.profile)
                menuController.pushViewController(vc, animated: true)
            }
            MenuItemButton(icon: #imageLiteral(resourceName: "playlist_menu").template, title: Strings.playlistMenuItem) {
                let playlistController = (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController ?? PlaylistViewController()
                playlistController.modalPresentationStyle = .fullScreen
                self.dismiss(animated: true) {
                    self.present(playlistController, animated: true)
                }
            }
            MenuItemButton(icon: #imageLiteral(resourceName: "menu-settings").template, title: Strings.settingsMenuItem) { [unowned menuController] in
                let vc = SettingsViewController(profile: self.profile, tabManager: self.tabManager, feedDataSource: self.feedDataSource, rewards: self.rewards, legacyWallet: self.legacyWallet)
                vc.settingsDelegate = self
                menuController.pushViewController(vc, animated: true)
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
                                    browserViewController.openPlaylist()
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
                            browserViewController.dismiss(animated: true) {
                                activity.perform()
                            }
                        }
                    }
                }
            }
        }
    }
    
    struct MenuTabDetailsView: View {
        @SwiftUI.Environment(\.colorScheme) var colorScheme: ColorScheme
        var tab: Tab?
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
