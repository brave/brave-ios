// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveShared
import BraveUI
import Shared
import BraveCore
import Storage
import Data
import SwiftUI

// MARK: - TopToolbarDelegate

extension BrowserViewController: TopToolbarDelegate {
    
    func showTabTray() {
        if tabManager.tabsForCurrentMode.isEmpty {
            return
        }
        updateFindInPageVisibility(visible: false)
        
        if tabManager.selectedTab == nil {
            tabManager.selectTab(tabManager.tabsForCurrentMode.first)
        }
        if let tab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(tab)
        }
        
        isTabTrayActive = true
        
        let tabTrayController = TabTrayController(tabManager: tabManager).then {
            $0.delegate = self
        }
        let container = SettingsNavigationController(rootViewController: tabTrayController)
        if !UIAccessibility.isReduceMotionEnabled {
            container.transitioningDelegate = tabTrayController
            container.modalPresentationStyle = .fullScreen
        }
        present(container, animated: true)
    }
    
    func topToolbarDidPressReload(_ topToolbar: TopToolbarView) {
        tabManager.selectedTab?.reload()
    }
    
    func topToolbarDidPressStop(_ topToolbar: TopToolbarView) {
        tabManager.selectedTab?.stop()
    }
    
    func topToolbarDidLongPressReloadButton(_ topToolbar: TopToolbarView, from button: UIButton) {
        guard let tab = tabManager.selectedTab, let url = tab.url, !url.isLocal, !url.isReaderModeURL else { return }
       
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel, handler: nil))
        
        let toggleActionTitle = tab.isDesktopSite == true ?
            Strings.appMenuViewMobileSiteTitleString : Strings.appMenuViewDesktopSiteTitleString
        alert.addAction(UIAlertAction(title: toggleActionTitle, style: .default, handler: { _ in
            tab.switchUserAgent()
        }))
        
        UIImpactFeedbackGenerator(style: .heavy).bzzt()
        if UIDevice.current.userInterfaceIdiom == .pad {
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = self.view.convert(button.frame, from: button.superview)
            alert.popoverPresentationController?.permittedArrowDirections = [.up]
        }
        present(alert, animated: true)
    }

    func topToolbarDidPressTabs(_ topToolbar: TopToolbarView) {
        showTabTray()
    }

    func topToolbarDidPressReaderMode(_ topToolbar: TopToolbarView) {
        if let tab = tabManager.selectedTab {
            if let readerMode = tab.getContentScript(name: "ReaderMode") as? ReaderMode {
                switch readerMode.state {
                case .available:
                    enableReaderMode()
                case .active:
                    disableReaderMode()
                case .unavailable:
                    break
                }
            }
        }
    }

    func topToolbarDidLongPressReaderMode(_ topToolbar: TopToolbarView) -> Bool {
        // Maybe we want to add something here down the road
        return false
    }
    
    func topToolbarDidPressPlaylistButton(_ urlBar: TopToolbarView) {
        let state = urlBar.locationView.playlistButton.buttonState
        switch state {
        case .addToPlaylist:
            showPlaylistPopover(tab: tabManager.selectedTab, state: .addToPlaylist)
        case .addedToPlaylist:
            showPlaylistPopover(tab: tabManager.selectedTab, state: .addedToPlaylist)
        case .none:
            break
        }
    }

    func topToolbarDisplayTextForURL(_ topToolbar: URL?) -> (String?, Bool) {
        // use the initial value for the URL so we can do proper pattern matching with search URLs
        var searchURL = self.tabManager.selectedTab?.currentInitialURL
        if let url = searchURL, InternalURL.isValid(url: url) {
            searchURL = url
        }
        if let query = profile.searchEngines.queryForSearchURL(searchURL as URL?) {
            return (query, true)
        } else {
            return (topToolbar?.absoluteString, false)
        }
    }

    func topToolbarDidLongPressLocation(_ topToolbar: TopToolbarView) {
        // The actions are carried to menu actions for Top ToolBar Location View
    }

    func topToolbarDidPressScrollToTop(_ topToolbar: TopToolbarView) {
        if let selectedTab = tabManager.selectedTab, favoritesController == nil {
            // Only scroll to top if we are not showing the home view controller
            selectedTab.webView?.scrollView.setContentOffset(CGPoint.zero, animated: true)
        }
    }

    func topToolbar(_ topToolbar: TopToolbarView, didEnterText text: String) {
        if text.isEmpty {
            hideSearchController()
        } else {
            showSearchController()
            searchController?.searchQuery = text
            searchLoader?.query = text.lowercased()
        }
    }

    func topToolbar(_ topToolbar: TopToolbarView, didSubmitText text: String) {
        // TopToolBar Submit Text is Typed URL Visit Type
        // This visit type will be used while adding History
        // And it will determine either to sync the data or not
        processAddressBar(text: text, visitType: .typed)
    }

    func processAddressBar(text: String, visitType: VisitType) {
        if let fixupURL = URIFixup.getURL(text) {
            // The user entered a URL, so use it.
            finishEditingAndSubmit(fixupURL, visitType: visitType)
            
            return
        }

        // We couldn't build a URL, so pass it on to the search engine.
        submitSearchText(text)
        
        if !PrivateBrowsingManager.shared.isPrivateBrowsing {
            RecentSearch.addItem(type: .text, text: text, websiteUrl: nil)
        }
    }

    func submitSearchText(_ text: String) {
        let engine = profile.searchEngines.defaultEngine()

        if let searchURL = engine.searchURLForQuery(text) {
            // We couldn't find a matching search keyword, so do a search query.
            finishEditingAndSubmit(searchURL, visitType: .typed)
        } else {
            // We still don't have a valid URL, so something is broken. Give up.
            print("Error handling URL entry: \"\(text)\".")
            assertionFailure("Couldn't generate search URL: \(text)")
        }
    }

    func topToolbarDidEnterOverlayMode(_ topToolbar: TopToolbarView) {
        if .blankPage == NewTabAccessors.getNewTabPage() {
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        } else {
            if let toast = clipboardBarDisplayHandler?.clipboardToast {
                toast.removeFromSuperview()
            }
            displayFavoritesController()
        }
    }

    func topToolbarDidLeaveOverlayMode(_ topToolbar: TopToolbarView) {
        hideSearchController()
        hideFavoritesController()
        updateInContentHomePanel(tabManager.selectedTab?.url as URL?)
        
        // Show NTP Onboarding when user selects cancel after retention onboard
        showNTPOnboarding()
    }

    func topToolbarDidBeginDragInteraction(_ topToolbar: TopToolbarView) {
        dismissVisibleMenus()
    }
    
    func topToolbarDidTapBraveShieldsButton(_ topToolbar: TopToolbarView) {
        presentBraveShieldsViewController()
    }
    
    func presentBraveShieldsViewController() {
        guard let selectedTab = tabManager.selectedTab, var url = selectedTab.url else { return }
        if let internalUrl = InternalURL(url), internalUrl.isErrorPage, let originalURL = internalUrl.originalURLFromErrorPage {
            url = originalURL
        }
        
        if url.isLocalUtility || InternalURL(url)?.isAboutURL == true || InternalURL(url)?.isAboutHomeURL == true {
            return
        }
        
        let shields = ShieldsViewController(tab: selectedTab)
        shields.shieldsSettingsChanged = { [unowned self] _ in
            // Update the shields status immediately
            self.topToolbar.refreshShieldsStatus()
            
            // Reload this tab. This will also trigger an update of the brave icon in `TabLocationView` if
            // the setting changed is the global `.AllOff` shield
            self.tabManager.selectedTab?.reload()
            
            // In 1.6 we "reload" the whole web view state, dumping caches, etc. (reload():BraveWebView.swift:495)
            // BRAVE TODO: Port over proper tab reloading with Shields
        }
        shields.showGlobalShieldsSettings = { [unowned self] vc in
            vc.dismiss(animated: true) {
                let shieldsAndPrivacy = BraveShieldsAndPrivacySettingsController(
                    profile: self.profile,
                    tabManager: self.tabManager,
                    feedDataSource: self.feedDataSource,
                    historyAPI: self.historyAPI
                )
                let container = SettingsNavigationController(rootViewController: shieldsAndPrivacy)
                container.isModalInPresentation = true
                container.modalPresentationStyle =
                    UIDevice.current.userInterfaceIdiom == .phone ? .pageSheet : .formSheet
                shieldsAndPrivacy.navigationItem.rightBarButtonItem = .init(
                    barButtonSystemItem: .done,
                    target: container,
                    action: #selector(SettingsNavigationController.done)
                )
                self.present(container, animated: true)
            }
        }
        let container = PopoverNavigationController(rootViewController: shields)
        let popover = PopoverController(contentController: container, contentSizeBehavior: .preferredContentSize)
        popover.present(from: topToolbar.locationView.shieldsButton, on: self)
    }
    
    // TODO: This logic should be fully abstracted away and share logic from current MenuViewController
    // See: https://github.com/brave/brave-ios/issues/1452
    func topToolbarDidTapBookmarkButton(_ topToolbar: TopToolbarView) {
        navigationHelper.openBookmarks()
    }
    
    func topToolbarDidTapBraveRewardsButton(_ topToolbar: TopToolbarView) {
        showBraveRewardsPanel()
    }
    
    func topToolbarDidLongPressBraveRewardsButton(_ topToolbar: TopToolbarView) {
        showRewardsDebugSettings()
    }
    
    func topToolbarDidTapMenuButton(_ topToolbar: TopToolbarView) {
        tabToolbarDidPressMenu(topToolbar)
    }

    func topToolbarDidPressQrCodeButton(_ urlBar: TopToolbarView) {
        scanQRCode()
    }
    
    private func hideSearchController() {
        if let searchController = searchController {
            searchController.willMove(toParent: nil)
            searchController.view.removeFromSuperview()
            searchController.removeFromParent()
            self.searchController = nil
            searchLoader = nil
        }
    }
    
    private func showSearchController() {
        if searchController != nil { return }

        let tabType = TabType.of(tabManager.selectedTab)
        searchController = SearchViewController(forTabType: tabType)
        
        guard let searchController = searchController else { return }

        searchController.searchEngines = profile.searchEngines
        searchController.searchDelegate = self
        searchController.profile = self.profile

        searchLoader = SearchLoader(historyAPI: historyAPI, bookmarkManager: bookmarkManager)
        searchLoader?.addListener(searchController)
        searchLoader?.autocompleteSuggestionHandler = { [weak self] completion in
            self?.topToolbar.setAutocompleteSuggestion(completion)
        }

        addChild(searchController)
        view.addSubview(searchController.view)
        searchController.view.snp.makeConstraints { make in
            make.top.equalTo(self.topToolbar.snp.bottom)
            make.left.right.bottom.equalTo(self.view)
            return
        }
        
        searchController.didMove(toParent: self)
    }
    
    private func displayFavoritesController() {
        if favoritesController == nil {
            let tabType = TabType.of(tabManager.selectedTab)
            let favoritesController = FavoritesViewController(tabType: tabType, action: { [weak self] bookmark, action in
                self?.handleFavoriteAction(favorite: bookmark, action: action)
            }, recentSearchAction: { [weak self] recentSearch, shouldSubmitSearch in
                guard let self = self else { return }
                
                let submitSearch = { [weak self] (text: String) in
                    if let fixupURL = URIFixup.getURL(text) {
                        self?.finishEditingAndSubmit(fixupURL, visitType: .unknown)
                        return
                    }
                    
                    self?.submitSearchText(text)
                }
                
                if let recentSearch = recentSearch,
                   let searchType = RecentSearchType(rawValue: recentSearch.searchType) {
                    if shouldSubmitSearch {
                        recentSearch.update(dateAdded: Date())
                    }
                    
                    switch searchType {
                    case .text:
                        if let text = recentSearch.text {
                            self.topToolbar.setLocation(text, search: false)
                            self.topToolbar(self.topToolbar, didEnterText: text)
                            
                            if shouldSubmitSearch {
                                submitSearch(text)
                            }
                        }
                    case .qrCode:
                        if let text = recentSearch.text {
                            self.topToolbar.setLocation(text, search: false)
                            self.topToolbar(self.topToolbar, didEnterText: text)
                            
                            if shouldSubmitSearch {
                                submitSearch(text)
                            }
                        } else if let websiteUrl = recentSearch.websiteUrl {
                            self.topToolbar.setLocation(websiteUrl, search: false)
                            self.topToolbar(self.topToolbar, didEnterText: websiteUrl)
                            
                            if shouldSubmitSearch {
                                submitSearch(websiteUrl)
                            }
                        }
                    case .website:
                        if let websiteUrl = recentSearch.websiteUrl {
                            self.topToolbar.setLocation(websiteUrl, search: false)
                            self.topToolbar(self.topToolbar, didEnterText: websiteUrl)
                            
                            if shouldSubmitSearch {
                                submitSearch(websiteUrl)
                            }
                        }
                    }
                } else if UIPasteboard.general.hasStrings || UIPasteboard.general.hasURLs,
                          let searchQuery = UIPasteboard.general.string ?? UIPasteboard.general.url?.absoluteString {
                    
                    self.topToolbar.setLocation(searchQuery, search: false)
                    self.topToolbar(self.topToolbar, didEnterText: searchQuery)
                    
                    if shouldSubmitSearch {
                        submitSearch(searchQuery)
                    }
                }
            })
            self.favoritesController = favoritesController
            
            addChild(favoritesController)
            view.addSubview(favoritesController.view)
            favoritesController.didMove(toParent: self)
            
            favoritesController.view.snp.makeConstraints {
                $0.top.leading.trailing.equalTo(pageOverlayLayoutGuide)
                $0.bottom.equalTo(view)
            }
        }
        guard let favoritesController = favoritesController else { return }
        favoritesController.view.alpha = 0.0
        let animator = UIViewPropertyAnimator(duration: 0.2, dampingRatio: 1.0) {
            favoritesController.view.alpha = 1
        }
        animator.addCompletion { _ in
            self.webViewContainer.accessibilityElementsHidden = true
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
        animator.startAnimation()
    }
    
    private func hideFavoritesController() {
        guard let controller = favoritesController else { return }
        self.favoritesController = nil
        UIView.animate(withDuration: 0.1, delay: 0, options: [.beginFromCurrentState], animations: {
            controller.view.alpha = 0.0
        }, completion: { _ in
            controller.willMove(toParent: nil)
            controller.view.removeFromSuperview()
            controller.removeFromParent()
            self.webViewContainer.accessibilityElementsHidden = false
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        })
    }
    
    func openAddBookmark() {
        guard let selectedTab = tabManager.selectedTab,
              let selectedUrl = selectedTab.url,
              !(selectedUrl.isLocal || selectedUrl.isReaderModeURL) else {
            return
        }

        let bookmarkUrl = selectedUrl.decodeReaderModeURL ?? selectedUrl
        
        let mode = BookmarkEditMode.addBookmark(title: selectedTab.displayTitle, url: bookmarkUrl.absoluteString)
        
        let addBookMarkController = AddEditBookmarkTableViewController(bookmarkManager: bookmarkManager, mode: mode)
        presentSettingsNavigation(with: addBookMarkController, cancelEnabled: true)
    }
    
    func presentSettingsNavigation(with controller: UIViewController, cancelEnabled: Bool = false) {
        let navigationController = SettingsNavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .formSheet
        
        let cancelBarbutton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: navigationController,
            action: #selector(SettingsNavigationController.done))
        
        let doneBarbutton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: navigationController,
            action: #selector(SettingsNavigationController.done))
        
        navigationController.navigationBar.topItem?.leftBarButtonItem = cancelEnabled ? cancelBarbutton : nil
        
        navigationController.navigationBar.topItem?.rightBarButtonItem = doneBarbutton
        
        present(navigationController, animated: true)
    }
}

extension BrowserViewController: ToolbarDelegate {
    func tabToolbarDidPressSearch(_ tabToolbar: ToolbarProtocol, button: UIButton) {
        topToolbar.tabLocationViewDidTapLocation(topToolbar.locationView)
    }
    
    func tabToolbarDidPressBack(_ tabToolbar: ToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goBack()
    }

    func tabToolbarDidLongPressBack(_ tabToolbar: ToolbarProtocol, button: UIButton) {
        UIImpactFeedbackGenerator(style: .heavy).bzzt()
        showBackForwardList()
    }
    
    func tabToolbarDidPressForward(_ tabToolbar: ToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goForward()
    }
    
    func tabToolbarDidPressShare() {
        navigationHelper.openShareSheet()
    }
    
    func tabToolbarDidPressMenu(_ tabToolbar: ToolbarProtocol) {
        let selectedTabURL: URL? = {
            guard let url = tabManager.selectedTab?.url else { return nil }
            
            if (InternalURL.isValid(url: url) || url.isLocal) && !url.isReaderModeURL { return nil }
            
            return url
        }()
        var activities: [UIActivity] = []
        if let url = selectedTabURL, let tab = tabManager.selectedTab {
            activities = shareActivities(for: url, tab: tab, sourceView: view, sourceRect: self.view.convert(self.topToolbar.menuButton.frame, from: self.topToolbar.menuButton.superview), arrowDirection: .up)
        }
        let initialHeight: CGFloat = selectedTabURL != nil ? 470 : 500
        let menuController = MenuViewController(initialHeight: initialHeight, content: { menuController in
            let isShownOnWebPage = selectedTabURL != nil
            VStack(spacing: 6) {
                if isShownOnWebPage {
                    featuresMenuSection(menuController)
                } else {
                    privacyFeaturesMenuSection(menuController)
                }
                Divider()
                destinationMenuSection(menuController, isShownOnWebPage: isShownOnWebPage)
                if let tabURL = selectedTabURL {
                    Divider()
                    PageActionsMenuSection(browserViewController: self, tabURL: tabURL, activities: activities)
                }
            }
            .navigationBarHidden(true)
        })
        presentPanModal(menuController, sourceView: tabToolbar.menuButton, sourceRect: tabToolbar.menuButton.bounds)
        if menuController.modalPresentationStyle == .popover {
            menuController.popoverPresentationController?.popoverLayoutMargins = .init(equalInset: 4)
            menuController.popoverPresentationController?.permittedArrowDirections = [.up]
        }
    }
    
    func tabToolbarDidPressAddTab(_ tabToolbar: ToolbarProtocol, button: UIButton) {
        self.openBlankNewTab(attemptLocationFieldFocus: true, isPrivate: PrivateBrowsingManager.shared.isPrivateBrowsing)
    }
    
    func tabToolbarDidLongPressForward(_ tabToolbar: ToolbarProtocol, button: UIButton) {
        UIImpactFeedbackGenerator(style: .heavy).bzzt()
        showBackForwardList()
    }
    
    func tabToolbarDidPressTabs(_ tabToolbar: ToolbarProtocol, button: UIButton) {
        showTabTray()
    }
    
    func showBackForwardList() {
        if let backForwardList = tabManager.selectedTab?.webView?.backForwardList {
            let backForwardViewController = BackForwardListViewController(profile: profile, backForwardList: backForwardList)
            backForwardViewController.tabManager = tabManager
            backForwardViewController.bvc = self
            backForwardViewController.modalPresentationStyle = .overCurrentContext
            backForwardViewController.backForwardTransitionDelegate = BackForwardListAnimator()
            self.present(backForwardViewController, animated: true, completion: nil)
        }
    }
    
    func tabToolbarDidSwipeToChangeTabs(_ tabToolbar: ToolbarProtocol, direction: UISwipeGestureRecognizer.Direction) {
        let tabs = tabManager.tabsForCurrentMode
        guard let selectedTab = tabManager.selectedTab, let index = tabs.firstIndex(where: { $0 === selectedTab }) else { return }
        let newTabIndex = index + (direction == .left ? -1 : 1)
        if newTabIndex >= 0 && newTabIndex < tabs.count {
            tabManager.selectTab(tabs[newTabIndex])
        }
    }
}

extension BrowserViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [unowned self] _ in
            var actionMenuChildren: [UIAction] = []
            
            let pasteGoAction = UIAction(
                title: Strings.pasteAndGoTitle,
                image: UIImage(systemName: "doc.on.clipboard.fill"),
                handler: UIAction.deferredActionHandler { _ in
                if let pasteboardContents = UIPasteboard.general.string {
                    self.topToolbar(self.topToolbar, didSubmitText: pasteboardContents)
                }
            })
            
            let pasteAction = UIAction(
                title: Strings.pasteTitle,
                image: UIImage(systemName: "doc.on.clipboard"),
                handler: UIAction.deferredActionHandler { _ in
                if let pasteboardContents = UIPasteboard.general.string {
                    // Enter overlay mode and make the search controller appear.
                    self.topToolbar.enterOverlayMode(pasteboardContents, pasted: true, search: true)
                }
            })
            
            let copyAction = UIAction(
                title: Strings.copyAddressTitle,
                image: UIImage(systemName: "doc.on.doc"),
                handler: UIAction.deferredActionHandler { _ in
                if let url = self.topToolbar.currentURL {
                    UIPasteboard.general.url = url as URL
                }
            })
            
            if UIPasteboard.general.hasStrings || UIPasteboard.general.hasURLs {
                actionMenuChildren = [pasteGoAction, pasteAction, copyAction]
            } else {
                actionMenuChildren = [copyAction]
            }
            
            return UIMenu(title: "", identifier: nil, children: actionMenuChildren)
        }
    }
}
