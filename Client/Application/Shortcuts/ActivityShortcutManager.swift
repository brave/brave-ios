// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Shared
import Data
import Intents
import CoreSpotlight
import MobileCoreServices

private let log = Logger.browserLogger

/// Shortcut Activity Types and detailed information to create and perform actions
enum ActivityType: String {
    case newTab = "NewTab"
    case newPrivateTab = "NewPrivateTab"
    case clearBrowsingHistory = "ClearBrowsingHistory"
    case enableBraveVPN = "EnableBraveVPN"
    case openBraveToday = "OpenBraveToday"
    case openPlayList = "OpenPlayList"

    var identifier: String {
        return " \(Bundle.main.bundleIdentifier ?? "") + .\(self.rawValue)"
    }
    
    /// The activity title for designated  type
    var title: String {
        switch self {
            case .newTab:
                return "Open a New Browser Tab"
            case .newPrivateTab:
                return "Open a New Private Browser Tab"
            case .clearBrowsingHistory:
                return "Clear Brave Browsing History"
            case .enableBraveVPN:
                return "Open Brave Browser and Enable VPN"
            case .openBraveToday:
                return "Open Brave Today"
            case .openPlayList:
                return "Open Playlist"
        }
    }
    
    /// The content description for designated activity  type
    var description: String {
        switch self {
            case .newTab, .newPrivateTab:
                return "Start Searching the Web Securely with Brave"
            case .clearBrowsingHistory:
                return "Open Browser in a New Tab and Delete All Private Browser History Data"
            case .enableBraveVPN:
                return "Open Browser in a New Tab and Enable VPN"
            case .openBraveToday:
                return "Open Brave Today and Check Today's Top Stories"
            case .openPlayList:
                return "Start Playing your Videos in Playlist"
        }
    }
    
    /// The phrase suggested to the user when they create a shortcut for the activity
    var suggestedPhrase: String {
        switch self {
            case .newTab:
                return "Open New Tab"
            case .newPrivateTab:
                return "Open New Private Tab"
            case .clearBrowsingHistory:
                return "Clear Browser History"
            case .enableBraveVPN:
                return "Enable VPN"
            case .openBraveToday:
                return "Open Brave Today"
            case .openPlayList:
                return "Open Playlist"
        }
    }
}

/// Singleton Manager handles creation and action for Activities
class ActivityShortcutManager: NSObject {

    // MARK: Lifecycle
    
    static var shared = ActivityShortcutManager()
    
    // MARK: Activity Creation Methods
    
    public func createShortcutActivity(type: ActivityType) -> NSUserActivity {
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        attributes.contentDescription = type.description
        
        let activity = NSUserActivity(activityType: type.identifier)
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(type.identifier)
        
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        
        activity.title = type.title
        activity.suggestedInvocationPhrase = type.suggestedPhrase
        activity.contentAttributeSet = attributes

        return activity
    }

    // MARK: Activity Action Methods

    public func performShortcutActivity(type: ActivityType, using bvc: BrowserViewController) {
        switch type {
            case .newTab:
                bvc.openBlankNewTab(attemptLocationFieldFocus: true, isPrivate: false)
            case .newPrivateTab:
                bvc.openBlankNewTab(attemptLocationFieldFocus: true, isPrivate: true)
            case .clearBrowsingHistory:
                History.deleteAll {
                    bvc.tabManager.clearTabHistory() {
                        bvc.openBlankNewTab(attemptLocationFieldFocus: true, isPrivate: false)
                    }
                }
            case .enableBraveVPN:
                bvc.openBlankNewTab(attemptLocationFieldFocus: true, isPrivate: false)

                switch BraveVPN.vpnState {
                    case .notPurchased, .purchased, .expired:
                        guard let vc = BraveVPN.vpnState.enableVPNDestinationVC else { return }
                    
                        let nav = SettingsNavigationController(rootViewController: vc)
                        nav.isModalInPresentation = false
                        nav.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .phone ? .pageSheet : .formSheet
                        nav.navigationBar.topItem?.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: nav, action: #selector(nav.done))
                        
                        // All menu views should be opened in portrait on iPhones.
                        UIDevice.current.forcePortraitIfIphone(for: UIApplication.shared)

                        bvc.present(nav, animated: true)
                    case .installed(let connected):
                        if !connected {
                            BraveVPN.reconnect()
                        }
                }
            case .openBraveToday:
                bvc.openBlankNewTab(attemptLocationFieldFocus: true, isPrivate: false)

                guard let newTabPageController = bvc.tabManager.selectedTab?.newTabPageViewController else { return }
                newTabPageController.scrollToBraveToday()
            case .openPlayList:
                print("Open Playlist")
        }
    }
    
    // MARK: Intent Creation Methods
    
    private func createOpenWebsiteIntent(with urlString: String) -> OpenWebsiteIntent {
        let intent = OpenWebsiteIntent()
        intent.websiteURL = urlString
        intent.suggestedInvocationPhrase = "Open Website"
        
        return intent
    }
    
    // MARK: Intent Donation Methods
    
    public func donateOpenWebsiteIntent(for urlString: String) {
        let intent = createOpenWebsiteIntent(with: urlString)

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { (error) in
            guard let error = error else {
                return
            }
            
            log.error("Failed to donate shorcut open website, error: \(error)")
        }
    }
}
