/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Telemetry

//
// 'Unified Telemetry' is the name for Mozilla's telemetry system
//
class UnifiedTelemetry {
    private func migratePathComponentInDocumentsDirectory(_ pathComponent: String, to destinationSearchPath: FileManager.SearchPathDirectory) {
        guard let oldPath = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(pathComponent).path, FileManager.default.fileExists(atPath: oldPath) else {
            return
        }

        print("Migrating \(pathComponent) from ~/Documents to \(destinationSearchPath)")
        guard let newPath = try? FileManager.default.url(for: destinationSearchPath, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(pathComponent).path else {
            print("Unable to get destination path \(destinationSearchPath) to move \(pathComponent)")
            return
        }

        do {
            try FileManager.default.moveItem(atPath: oldPath, toPath: newPath)

            print("Migrated \(pathComponent) to \(destinationSearchPath) successfully")
        } catch let error as NSError {
            print("Unable to move \(pathComponent) to \(destinationSearchPath): \(error.localizedDescription)")
        }
    }

    init(profile: Profile) {
        migratePathComponentInDocumentsDirectory("MozTelemetry-Default-core", to: .cachesDirectory)
        migratePathComponentInDocumentsDirectory("MozTelemetry-Default-mobile-event", to: .cachesDirectory)
        migratePathComponentInDocumentsDirectory("eventArray-MozTelemetry-Default-mobile-event.json", to: .cachesDirectory)

        NotificationCenter.default.addObserver(self, selector: #selector(uploadError), name: Telemetry.notificationReportError, object: nil)

        let telemetryConfig = Telemetry.default.configuration
        telemetryConfig.appName = "Fennec"
        telemetryConfig.userDefaultsSuiteName = AppInfo.sharedContainerIdentifier
        telemetryConfig.dataDirectory = .cachesDirectory
        telemetryConfig.updateChannel = AppConstants.BuildChannel.rawValue
        let sendUsageData = profile.prefs.boolForKey(AppConstants.PrefSendUsageData) ?? true
        telemetryConfig.isCollectionEnabled = sendUsageData
        telemetryConfig.isUploadEnabled = sendUsageData

        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.blockPopups", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.saveLogins", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.showClipboardBar", withDefaultValue: false)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.settings.closePrivateTabs", withDefaultValue: false)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.ASPocketStoriesVisible", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.ASBookmarkHighlightsVisible", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.ASRecentHighlightsVisible", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.prefkey.trackingprotection.normalbrowsing", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.prefkey.trackingprotection.privatebrowsing", withDefaultValue: true)
        telemetryConfig.measureUserDefaultsSetting(forKey: "profile.prefkey.trackingprotection.strength", withDefaultValue: "basic")

        let prefs = profile.prefs
        Telemetry.default.beforeSerializePing(pingType: CorePingBuilder.PingType) { (inputDict) -> [String: Any?] in
            var outputDict = inputDict // make a mutable copy
            if let newTabChoice = prefs.stringForKey(NewTabAccessors.PrefKey) {
                outputDict["defaultNewTabExperience"] = newTabChoice as AnyObject?
            }
            if let chosenEmailClient = prefs.stringForKey(PrefsKeys.KeyMailToOption) {
                outputDict["defaultMailClient"] = chosenEmailClient as AnyObject?
            }
            return outputDict
        }

        Telemetry.default.beforeSerializePing(pingType: FocusEventPingBuilder.PingType) { (inputDict) -> [String: Any?] in
            var outputDict = inputDict

            var settings: [String: String?] = inputDict["settings"] as? [String: String?] ?? [:]

            let searchEngines = SearchEngines(prefs: profile.prefs, files: profile.files)
            settings["defaultSearchEngine"] = searchEngines.defaultEngine.engineID ?? "custom"

            if let windowBounds = UIApplication.shared.keyWindow?.bounds {
                settings["windowWidth"] = String(describing: windowBounds.width)
                settings["windowHeight"] = String(describing: windowBounds.height)
            }

            outputDict["settings"] = settings

            // App Extension telemetry requires reading events stored in prefs, then clearing them from prefs.
            if let extensionEvents = profile.prefs.arrayForKey(PrefsKeys.AppExtensionTelemetryEventArray) as? [[String: String]],
                var pingEvents = outputDict["events"] as? [[Any?]] {
                profile.prefs.removeObjectForKey(PrefsKeys.AppExtensionTelemetryEventArray)

                extensionEvents.forEach { extensionEvent in
                    let category = UnifiedTelemetry.EventCategory.appExtensionAction.rawValue
                    let newEvent = TelemetryEvent(category: category, method: extensionEvent["method"] ?? "", object: extensionEvent["object"] ?? "")
                    pingEvents.append(newEvent.toArray())
                }
                outputDict["events"] = pingEvents
            }

            return outputDict
        }

       Telemetry.default.add(pingBuilderType: CorePingBuilder.self)
        Telemetry.default.add(pingBuilderType: FocusEventPingBuilder.self)
    }

    @objc func uploadError(notification: NSNotification) {
        guard !DeviceInfo.isSimulator(), let error = notification.userInfo?["error"] as? NSError else { return }
        Sentry.shared.send(message: "Upload Error", tag: SentryTag.unifiedTelemetry, severity: .info, description: error.debugDescription)
    }
}

// Enums for Event telemetry.
extension UnifiedTelemetry {
    public enum EventCategory: String {
        case action = "action"
        case appExtensionAction = "app-extension-action"
    }

    public enum EventMethod: String {
        case add = "add"
        case background = "background"
        case cancel = "cancel"
        case change = "change"
        case delete = "delete"
        case drag = "drag"
        case drop = "drop"
        case foreground = "foreground"
        case open = "open"
        case press = "press"
        case scan = "scan"
        case share = "share"
        case tap = "tap"
        case view = "view"
        case applicationOpenUrl = "application-open-url"
    }

    public enum EventObject: String {
        case app = "app"
        case bookmark = "bookmark"
        case bookmarksPanel = "bookmarks-panel"
        case download = "download"
        case downloadLinkButton = "download-link-button"
        case downloadNowButton = "download-now-button"
        case downloadsPanel = "downloads-panel"
        case keyCommand = "key-command"
        case locationBar = "location-bar"
        case qrCodeText = "qr-code-text"
        case qrCodeURL = "qr-code-url"
        case readerModeCloseButton = "reader-mode-close-button"
        case readerModeOpenButton = "reader-mode-open-button"
        case readingListItem = "reading-list-item"
        case setting = "setting"
        case tab = "tab"
        case trackingProtectionStatistics = "tracking-protection-statistics"
        case trackingProtectionWhitelist = "tracking-protection-whitelist"
        case url = "url"
        case searchText = "searchText"
    }

    public enum EventValue: String {
        case activityStream = "activity-stream"
        case appMenu = "app-menu"
        case awesomebarResults = "awesomebar-results"
        case bookmarksPanel = "bookmarks-panel"
        case browser = "browser"
        case downloadCompleteToast = "download-complete-toast"
        case downloadsPanel = "downloads-panel"
        case homePanel = "home-panel"
        case homePanelTabButton = "home-panel-tab-button"
        case markAsRead = "mark-as-read"
        case markAsUnread = "mark-as-unread"
        case pageActionMenu = "page-action-menu"
        case readerModeToolbar = "reader-mode-toolbar"
        case readingListPanel = "reading-list-panel"
        case shareExtension = "share-extension"
        case shareMenu = "share-menu"
        case tabTray = "tab-tray"
        case topTabs = "top-tabs"
    }

    public static func recordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: EventValue, extras: [String: Any?]? = nil) {
        Telemetry.default.recordEvent(category: category.rawValue, method: method.rawValue, object: object.rawValue, value: value.rawValue, extras: extras)
    }

    public static func recordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: String? = nil, extras: [String: Any?]? = nil) {
        Telemetry.default.recordEvent(category: category.rawValue, method: method.rawValue, object: object.rawValue, value: value, extras: extras)
    }
}
