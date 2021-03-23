// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Shared
import Intents
import CoreSpotlight
import MobileCoreServices

/// Shortcut Activity Types and detailed information to create and perform actions
enum ActivityType: String {
    case newTab = "NewTab"
    case newPrivateTab = "NewPrivateTab"

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
        }
    }
    
    /// The content description for designated activity  type
    var description: String {
        switch self {
            case .newTab, .newPrivateTab:
                return "Start Searching the web securely with Brave."
        }
    }
    
    /// The phrase suggested to the user when they create a shortcut for the activity
    var suggestedPhrase: String {
        switch self {
            case .newTab:
                return "Open New Tab"
            case .newPrivateTab:
                return "Open New Private Tab"
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
        activity.suggestedInvocationPhrase =  "Open New Private Tab"
        activity.contentAttributeSet = attributes

        return activity
    }

    // MARK: Activity Action Methods

    public func performShortcutActivity(type: ActivityType, using browserViewController: BrowserViewController) {
        switch type {
            case .newTab:
                browserViewController.openBlankNewTab(attemptLocationFieldFocus: true, isPrivate: false)
            case .newPrivateTab:
                browserViewController.openBlankNewTab(attemptLocationFieldFocus: true, isPrivate: true)
        }
    }
}
