/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import UIKit
import Preferences

enum TabBarVisibility: Int, CaseIterable {
  case never
  case always
  case landscapeOnly
}

extension Preferences {
  public enum AutoCloseTabsOption: Int, CaseIterable {
    case manually
    case oneDay, oneWeek, oneMonth

    /// Return time interval when to remove old tabs, or nil if no tabs should be removed.
    public var timeInterval: TimeInterval? {
      let isPublic = AppConstants.buildChannel.isPublic
      switch self {
      case .manually: return nil
      case .oneDay: return isPublic ? 1.days : 5.minutes
      case .oneWeek: return isPublic ? 7.days : 10.minutes
      case .oneMonth: return isPublic ? 30.days : 1.hours
      }
    }
  }
}

// MARK: - User Preferences
extension Preferences {
  final public class General {
    /// Whether this is the first time user has ever launched Brave after intalling. *Should never be set to `true` manually!*
    public static let isFirstLaunch = Option<Bool>(key: "general.first-launch", default: true)
    /// Whether or not to save logins in Brave
    static let saveLogins = Option<Bool>(key: "general.save-logins", default: true)
    /// Whether or not to block popups from websites automaticaly
    static let blockPopups = Option<Bool>(key: "general.block-popups", default: true)
    /// Controls how the tab bar should be shown (or not shown)
    static let tabBarVisibility = Option<Int>(key: "general.tab-bar-visiblity", default: TabBarVisibility.always.rawValue)
    /// After what time unused tabs should be auto-removed at app launch.
    static let autocloseTabs = Option<Int>(
      key: "general.autoclose-tabs",
      default: AutoCloseTabsOption.manually.rawValue)
    /// Defines the user's normal browsing theme
    /// `system`, follows the current OS display mode
    public static let themeNormalMode = Option<String>(key: "general.normal-mode-theme", default: DefaultTheme.system.rawValue)
    /// Specifies If Night Mode is enabled
    public static let nightModeEnabled = Option<Bool>(key: "general.night-mode-enabled", default: false)
    /// Specifies whether the bookmark button is present on toolbar
    static let showBookmarkToolbarShortcut = Option<Bool>(key: "general.show-bookmark-toolbar-shortcut", default: UIDevice.isIpad)
    /// Sets Desktop UA for iPad by default (iOS 13+ & iPad only).
    /// Do not read it directly, prefer to use `UserAgent.shouldUseDesktopMode` instead.
    static let alwaysRequestDesktopSite = Option<Bool>(key: "general.always-request-desktop-site", default: UIDevice.isIpad)
    /// Controls whether or not media should continue playing in the background
    static let mediaAutoBackgrounding = Option<Bool>(key: "general.media-auto-backgrounding", default: false)
    /// Controls whether or not to show the last visited bookmarks folder
    static let showLastVisitedBookmarksFolder = Option<Bool>(key: "general.bookmarks-show-last-visited-bookmarks-folder", default: true)

    /// The preference for determining whether or not to show the adblock onboarding popup
    static let onboardingAdblockPopoverShown = Option<Bool>(key: "general.basic-onboarding-adblock-popover-shown", default: false)

    /// Whether or not link preview upon long press action should be shown.
    static let enableLinkPreview = Option<Bool>(key: "general.night-mode", default: true)

    /// Whether a default browser callout was dismissed.
    /// It should apply to all kinds of callouts: banner on NTP, at-launch modal etc.
    static let defaultBrowserCalloutDismissed =
      Option<Bool>(key: "general.default-browser-callout-dismissed", default: false)

    /// Whether or not the app (in regular browsing mode) will follow universal links
    static let followUniversalLinks = Option<Bool>(key: "general.follow-universal-links", default: true)

    /// Whether or not the pull-to-refresh control is added to web views
    static let enablePullToRefresh = Option<Bool>(key: "general.enable-pull-to-refresh", default: true)
    
    /// Global Page Zoom-Level
    static var defaultPageZoomLevel = Option<Double>(key: "general.default-page-zoom-level", default: 1.0)
    
    static let isUsingBottomBar = Option<Bool>(key: "general.bottom-bar", default: false)
  }

  final public class Search {
    /// Whether or not to show suggestions while the user types
    static let showSuggestions = Option<Bool>(key: "search.show-suggestions", default: false)
    /// If the user should see the show suggetsions opt-in
    static let shouldShowSuggestionsOptIn = Option<Bool>(key: "search.show-suggestions-opt-in", default: true)
    /// A list of disabled search engines
    static let disabledEngines = Option<[String]?>(key: "search.disabled-engines", default: nil)
    /// A list of ordered search engines or nil if they have not been set up yet
    static let orderedEngines = Option<[String]?>(key: "search.ordered-engines", default: nil)
    /// The default selected search engine in regular mode
    public static let defaultEngineName = Option<String?>(key: "search.default.name", default: nil)
    /// The default selected search engine in private mode
    static let defaultPrivateEngineName = Option<String?>(key: "search.defaultprivate.name", default: nil)
    /// Whether or not to show recent searches
    static let shouldShowRecentSearches = Option<Bool>(key: "search.should-show-recent-searches", default: false)
    /// Whether or not to show recent searches opt-in
    static let shouldShowRecentSearchesOptIn = Option<Bool>(key: "search.should-show-recent-searches.opt-in", default: true)
    /// How many times Brave Search websites has asked the user to check whether Brave Search can be set as a default
    static let braveSearchDefaultBrowserPromptCount =
      Option<Int>(key: "search.brave-search-default-website-prompt", default: 0)
    /// Determines Yahoo Search Engine is migration is done
    public static let yahooEngineMigrationCompleted = Option<Bool>(key: "search-yahoo-engine-migration-completed", default: false)
  }
  
  final public class BraveSearch {
    /// The app launch date after brave search promotion
    public static let braveSearchPromotionLaunchDate = Option<Date?>(key: "brave-search.promo-launch-date", default: nil)
    /// Whether or not  user interacted with brave search promotion
    /// User tapping on maybe later on promotion onboarding does NOT count as dismissed.
    /// Next session after clicking 'maybe later' dismiss will be shown to user
    public static let braveSearchPromotionCompletionState = Option<Int>(
      key: "brave-search.promo-completion-state",
      default: BraveSearchPromotionState.undetermined.rawValue)
  }
  
  final public class Privacy {
    static let lockWithPasscode = Option<Bool>(key: "privacy.lock-with-passcode", default: false)
    /// Forces all private tabs
    public static let privateBrowsingOnly = Option<Bool>(key: "privacy.private-only", default: false)
    /// Blocks all cookies and access to local storage
    static let blockAllCookies = Option<Bool>(key: "privacy.block-all-cookies", default: false)
    /// The toggles states for clear private data screen
    static let clearPrivateDataToggles = Option<[Bool]>(key: "privacy.clear-data-toggles", default: [])
  }
  final public class NewTabPage {
    /// Whether bookmark image are enabled / shown
    static let backgroundImages = Option<Bool>(key: "newtabpage.background-images", default: true)
    /// Whether sponsored images are included into the background image rotation
    static let backgroundSponsoredImages = Option<Bool>(key: "newtabpage.background-sponsored-images", default: true)

    /// At least one notification must show before we lock showing subsequent notifications.
    static let atleastOneNTPNotificationWasShowed = Option<Bool>(
      key: "newtabpage.one-notificaiton-showed",
      default: false)

    /// Whether the callout to use branded image was shown.
    static let brandedImageShowed = Option<Bool>(
      key: "newtabpage.branded-image-callout-showed",
      default: false)

    /// When true, a notification on new tab page will be shown that an ad grant can be claimed(if rewards and grant are available).
    /// This value is reseted on each app launch,
    /// The goal is to show the claim grant notification only once per app session if still available.
    static let attemptToShowClaimRewardsNotification =
      Option<Bool>(key: "newtabpage.show-grant-notification", default: true)

    /// Whether preloaded favorites have been initialized. Uses custom favorites in case of super referral or default ones instead.
    static let preloadedFavoritiesInitialized =
      Option<Bool>(key: "newtabpage.favorites-initialized", default: false)

    /// When super referrer fails to download and user hasn't changed their default favorites we might want to try to replace them
    /// with the ones provided super referrer once available.This should be done only once.
    static let initialFavoritesHaveBeenReplaced =
      Option<Bool>(key: "newtabpage.initial-favorites-replaced", default: false)

    /// Custom theme used in app. Nil if default theme is used.
    static let selectedCustomTheme =
      Option<String?>(key: "newtabpage.selected-custom-theme", default: nil)

    /// List of currently installed themes on the device.
    static let installedCustomThemes =
      Option<[String]>(key: "newtabpage.installed-custom-themes", default: [])

    /// Tells the app whether we should try to fetch super referrer assets again in case of network error.
    public static let superReferrerThemeRetryDeadline =
      Option<Date?>(key: "newtabpage.superreferrer-retry-deadline", default: nil)
    
    /// Tells the app whether we should show Privacy Hub in new tab page view controller
    public static let showNewTabPrivacyHub =
      Option<Bool>(key: "newtabpage.show-newtab-privacyhub", default: true)
    
    /// Tells the app whether we should show Favourites in new tab page view controller
    public static let showNewTabFavourites =
      Option<Bool>(key: "newtabpage.show-newtab-favourites", default: true)
  }

  final public class Debug {
    /// When general blocklists were last time updated on the device.
    static let lastGeneralAdblockUpdate = Option<Date?>(key: "last-general-adblock-update", default: nil)
    /// When regional blocklists were last time updated on the device.
    static let lastRegionalAdblockUpdate = Option<Date?>(key: "last-regional-adblock-update", default: nil)
    /// When cosmetic filters CSS was last time updated on the device.
    static let lastCosmeticFiltersCSSUpdate = Option<Date?>(key: "last-cosmetic-filters-css-update", default: nil)
    /// When cosmetic filters Scriptlets were last time updated on the device.
    static let lastCosmeticFiltersScripletsUpdate = Option<Date?>(key: "last-cosmetic-filters-scriptlets-update", default: nil)
  }

  final public class Playlist {
    /// The Option to show video list left or right side
    static let listViewSide = Option<String>(key: "playlist.listViewSide", default: PlayListSide.left.rawValue)
    /// The count of how many times  Add to Playlist URL-Bar onboarding has been shown
    static let addToPlaylistURLBarOnboardingCount = Option<Int>(key: "playlist.addToPlaylistURLBarOnboardingCount", default: 0)
    /// The last played item url
    static let lastPlayedItemUrl = Option<String?>(key: "playlist.last.played.item.url", default: nil)
    /// The last played item time
    static let lastPlayedItemTime = Option<Double>(key: "playlist.last.played.item.time", default: 0.0)
    /// Whether to play the video when controller loaded
    static let firstLoadAutoPlay = Option<Bool>(key: "playlist.firstLoadAutoPlay", default: false)
    /// The Option to download video yes / no / only wi-fi
    static let autoDownloadVideo = Option<String>(key: "playlist.autoDownload", default: PlayListDownloadType.on.rawValue)
    /// The Option to disable playlist MediaSource web-compatibility
    static let webMediaSourceCompatibility = Option<Bool>(key: "playlist.webMediaSourceCompatibility", default: UIDevice.isIpad)
    /// The option to start the playback where user left-off
    static let playbackLeftOff = Option<Bool>(key: "playlist.playbackLeftOff", default: true)
    /// The option to disable long-press-to-add-to-playlist gesture.
    static let enableLongPressAddToPlaylist =
      Option<Bool>(key: "playlist.longPressAddToPlaylist", default: true)
    /// The option to enable or disable the 3-dot menu badge for playlist
    static let enablePlaylistMenuBadge =
      Option<Bool>(key: "playlist.enablePlaylistMenuBadge", default: true)
    /// The option to enable or disable the URL-Bar button for playlist
    static let enablePlaylistURLBarButton =
      Option<Bool>(key: "playlist.enablePlaylistURLBarButton", default: true)
    /// The option to enable or disable the continue where left-off playback in CarPlay
    static let enableCarPlayRestartPlayback =
      Option<Bool>(key: "playlist.enableCarPlayRestartPlayback", default: false)
    /// The last time all playlist folders were synced
    static let lastPlaylistFoldersSyncTime =
      Option<Date?>(key: "playlist.lastPlaylistFoldersSyncTime", default: nil)
    /// Sync shared folders automatically preference
    static let syncSharedFoldersAutomatically =
      Option<Bool>(key: "playlist.syncSharedFoldersAutomatically", default: false)
  }
    
  final public class PrivacyReports {
    /// Used to track whether to prompt user to enable app notifications.
    static let shouldShowNotificationPermissionCallout =
    Option<Bool>(key: "privacy-hub.show-notification-permission-callout", default: true)
    /// When disabled, no tracker data will be recorded for the Privacy Reports.
    static let captureShieldsData = Option<Bool>(key: "privacy-hub.capture-shields-data", default: true)
    /// When disabled, no Brave VPN alerts will be recorded for the Privacy Reports.
    static let captureVPNAlerts = Option<Bool>(key: "privacy-hub.capture-vpn-alerts", default: true)
    /// Tracker when to consolidate tracker and vpn data. By default the first consolidation happens 7 days after Privacy Reports build is installed.
    static let nextConsolidationDate =
    Option<Date?>(key: "privacy-hub.next-consolidation-date", default: nil)
    /// Determines whether to show a Privacy Reports onboarding popup on the NTP.
    public static let ntpOnboardingCompleted =
    Option<Bool>(key: "privacy-hub.onboarding-completed", default: true)
  }
  
  final public class WebsiteRedirects {
    static let reddit = Option<Bool>(key: "website-redirect.reddit", default: false)
    static let npr = Option<Bool>(key: "website-redirect.npr", default: false)
  }
}
