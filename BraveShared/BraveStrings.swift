/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/*
 * Shared module is to be as unmodified as possible by Brave.
 *
 * This file is more of a catch-all for adding strings that would traditionally be added into the Shared framework's
 *      `Strings.swift` file.
 *
 * This allows easy merging at a later point, or even the ability to abstract to a separate framework.
 */

// TODO: Identify the commented out re-declarations and see what one we would like to use

import Shared

// swiftlint:disable line_length

extension Strings {
  /// "BAT" or "BAT Points" depending on the region
  public static var BAT: String {
    return Preferences.Rewards.isUsingBAP.value == true ? "BAP" : "BAT"
  }
}

// MARK: - Common Strings
extension Strings {
  public static let cancelButtonTitle = NSLocalizedString("CancelButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Cancel", comment: "")
  public static let webContentAccessibilityLabel = NSLocalizedString("WebContentAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Web content", comment: "Accessibility label for the main web content view")
  public static let shareLinkActionTitle = NSLocalizedString("ShareLinkActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Share Link", comment: "Context menu item for sharing a link URL")
  public static let showTabs = NSLocalizedString("ShowTabs", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Show Tabs", comment: "Accessibility Label for the tabs button in the browser toolbar")
  public static let copyLinkActionTitle = NSLocalizedString("CopyLinkActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Copy Link", comment: "Context menu item for copying a link URL to the clipboard")
  public static let openNewPrivateTabButtonTitle = NSLocalizedString("OpenNewPrivateTabButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Open in New Private Tab", comment: "Context menu option for opening a link in a new private tab")
  public static let deleteLoginButtonTitle = NSLocalizedString("DeleteLoginButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Delete", comment: "Label for the button used to delete the current login.")
  public static let saveButtonTitle = NSLocalizedString("SaveButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Save", comment: "Label for the button used to save data")
  public static let share = NSLocalizedString("CommonShare", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Share", comment: "Text to select sharing something (example: image, video, URL)")
  public static let download = NSLocalizedString("CommonDownload", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Download", comment: "Text to choose for downloading a file (example: saving an image to phone)")
  public static let showLinkPreviewsActionTitle = NSLocalizedString("ShowLinkPreviewsActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Show Link Previews", comment: "Context menu item for showing link previews")
  public static let hideLinkPreviewsActionTitle = NSLocalizedString("HideLinkPreviewsActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Hide Link Previews", comment: "Context menu item for hiding link previews")
  public static let learnMore = NSLocalizedString(
    "learnMore", tableName: "BraveShared",
    bundle: .braveShared, value: "Learn More", comment: "")
  public static let termsOfService = NSLocalizedString(
    "TermsOfService", tableName: "BraveShared",
    bundle: .braveShared, value: "Terms of Service", comment: "")
  public static let title = NSLocalizedString(
    "Title", tableName: "BraveShared",
    bundle: .braveShared, value: "Title", comment: "")
  public static let monthAbbreviation =
    NSLocalizedString(
      "monthAbbreviation", tableName: "BraveShared",
      bundle: .braveShared, value: "mo.", comment: "Abbreviation for 'Month', use full word' Month' if this word can't be shortened in your language")
  public static let yearAbbreviation =
    NSLocalizedString(
      "yearAbbreviation", tableName: "BraveShared",
      bundle: .braveShared, value: "yr.", comment: "Abbreviation for 'Year', use full word' Yeara' if this word can't be shortened in your language")
}

// MARK:-  UIAlertControllerExtensions.swift
extension Strings {
  public static let sendCrashReportAlertTitle = NSLocalizedString("SendCrashReportAlertTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Oops! Brave crashed", comment: "Title for prompt displayed to user after the app crashes")
  public static let sendCrashReportAlertMessage = NSLocalizedString("SendCrashReportAlertMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Send a crash report so Brave can fix the problem?", comment: "Message displayed in the crash dialog above the buttons used to select when sending reports")
  public static let sendReportButtonTitle = NSLocalizedString("SendReportButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Send Report", comment: "Used as a button label for crash dialog prompt")
  public static let alwaysSendButtonTitle = NSLocalizedString("AlwaysSendButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Always Send", comment: "Used as a button label for crash dialog prompt")
  public static let dontSendButtonTitle = NSLocalizedString("DontSendButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Don’t Send", comment: "Used as a button label for crash dialog prompt")
  public static let restoreTabOnCrashAlertTitle = NSLocalizedString("RestoreTabOnCrashAlertTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Well, this is embarrassing.", comment: "Restore Tabs Prompt Title")
  public static let restoreTabOnCrashAlertMessage = NSLocalizedString("RestoreTabOnCrashAlertMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Looks like Brave crashed previously. Would you like to restore your tabs?", comment: "Restore Tabs Prompt Description")
  public static let restoreTabNegativeButtonTitle = NSLocalizedString("RestoreTabNegativeButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "No", comment: "Restore Tabs Negative Action")
  public static let restoreTabAffirmativeButtonTitle = NSLocalizedString("RestoreTabAffirmativeButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Okay", comment: "Restore Tabs Affirmative Action")
  public static let clearPrivateDataAlertCancelButtonTitle = NSLocalizedString("ClearPrivateDataAlertCancelButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Cancel", comment: "The cancel button when confirming clear private data.")
  public static let clearPrivateDataAlertOkButtonTitle = NSLocalizedString("ClearPrivateDataAlertOkButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "OK", comment: "The button that clears private data.")
  public static let clearSyncedHistoryAlertMessage = NSLocalizedString("ClearSyncedHistoryAlertMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "This action will clear all of your private data, including history from your synced devices.", comment: "Description of the confirmation dialog shown when a user tries to clear history that's synced to another device.")
  public static let clearSyncedHistoryAlertCancelButtoTitle = NSLocalizedString("ClearSyncedHistoryAlertCancelButtoTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Cancel", comment: "The cancel button when confirming clear history.")
  public static let clearSyncedHistoryAlertOkButtoTitle = NSLocalizedString("ClearSyncedHistoryAlertOkButtoTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "OK", comment: "The confirmation button that clears history even when Sync is connected.")
  public static let deleteLoginAlertTitle = NSLocalizedString("DeleteLoginAlertTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Are you sure?", comment: "Prompt title when deleting logins")
  public static let deleteLoginAlertLocalMessage = NSLocalizedString("DeleteLoginAlertLocalMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Logins will be permanently removed.", comment: "Prompt message warning the user that deleting non-synced logins will permanently remove them")
  public static let deleteLoginAlertSyncedDevicesMessage = NSLocalizedString("DeleteLoginAlertSyncedDevicesMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Logins will be removed from all connected devices.", comment: "Prompt message warning the user that deleted logins will remove logins from all connected devices")
  public static let deleteLoginAlertCancelActionTitle = NSLocalizedString("DeleteLoginAlertCancelActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Cancel", comment: "Prompt option for cancelling out of deletion")
  public static let genericErrorTitle = NSLocalizedString(
    "genericErrorTitle", tableName: "BraveShared",
    bundle: .braveShared, value: "Error", comment: "")
  public static let genericErrorBody = NSLocalizedString(
    "genericErrorBody", tableName: "BraveShared",
    bundle: .braveShared, value: "Oops! Something went wrong. Please try again.", comment: "")
}

// MARK:-  SearchViewController.swift
extension Strings {
  public static let searchSettingsButtonTitle = NSLocalizedString("SearchSettingsButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Search Settings", comment: "Label for search settings button.")
  public static let searchEngineFormatText = NSLocalizedString("SearchEngineFormatText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "%@ search", comment: "Label for search engine buttons. The argument corresponds to the name of the search engine.")
  public static let searchSuggestionFromFormatText = NSLocalizedString("SearchSuggestionFromFormatText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Search suggestions from %@", comment: "Accessibility label for image of default search engine displayed left to the actual search suggestions from the engine. The parameter substituted for \"%@\" is the name of the search engine. E.g.: Search suggestions from Google")
  public static let searchesForSuggestionButtonAccessibilityText = NSLocalizedString("SearchesForSuggestionButtonAccessibilityText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Searches for the suggestion", comment: "Accessibility hint describing the action performed when a search suggestion is clicked")
  public static let searchSuggestionSectionTitleFormat = NSLocalizedString("SearchSuggestionSectionTitleFormat", tableName: "BraveShared", bundle: Bundle.braveShared, value: "%@ Search", comment: "Section Title when showing search suggestions. The parameter substituted for \"%@\" is the name of the search engine. E.g.: Google Search")
  public static let turnOnSearchSuggestions = NSLocalizedString("Turn on search suggestions?", bundle: Bundle.braveShared, comment: "Prompt shown before enabling provider search queries")
  public static let searchSuggestionSectionTitleNoSearchFormat = NSLocalizedString("SearchSuggestionSectionTitleNoSearchFormat", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Search", comment: "Section Title when showing search suggestions and the engine does not contain the word 'Search'.")
  public static let noSearchResultsfound = NSLocalizedString("noSearchResultsfound", tableName: "BraveShared", bundle: .braveShared, value: "No search results found.", comment: "The information title displayed when there is no search reault found")
  public static let searchBookmarksTitle = NSLocalizedString("searchBookmarksTitle", tableName: "BraveShared", bundle: .braveShared, value: "Search Bookmarks", comment: "The placeholder text for bookmark search")
}

// MARK:-  Authenticator.swift
extension Strings {
  public static let authPromptAlertCancelButtonTitle = NSLocalizedString("AuthPromptAlertCancelButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Cancel", comment: "Label for Cancel button")
  public static let authPromptAlertLogInButtonTitle = NSLocalizedString("AuthPromptAlertLogInButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Log in", comment: "Authentication prompt log in button")
  public static let authPromptAlertTitle = NSLocalizedString("AuthPromptAlertTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Authentication required", comment: "Authentication prompt title")
  public static let authPromptAlertFormatRealmMessageText = NSLocalizedString("AuthPromptAlertFormatRealmMessageText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "A username and password are being requested by %@. The site says: %@", comment: "Authentication prompt message with a realm. First parameter is the hostname. Second is the realm string")
  public static let authPromptAlertMessageText = NSLocalizedString("AuthPromptAlertMessageText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "A username and password are being requested by %@.", comment: "Authentication prompt message with no realm. Parameter is the hostname of the site")
  public static let authPromptAlertUsernamePlaceholderText = NSLocalizedString("AuthPromptAlertUsernamePlaceholderText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Username", comment: "Username textbox in Authentication prompt")
  public static let authPromptAlertPasswordPlaceholderText = NSLocalizedString("AuthPromptAlertPasswordPlaceholderText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Password", comment: "Password textbox in Authentication prompt")
}

// MARK:-  BrowserViewController.swift
extension Strings {
  public static let openNewTabButtonTitle = NSLocalizedString("OpenNewTabButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Open in New Tab", comment: "Context menu item for opening a link in a new tab")

  public static let openImageInNewTabActionTitle = NSLocalizedString("OpenImageInNewTab", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Open Image In New Tab", comment: "Context menu for opening image in new tab")
  public static let saveImageActionTitle = NSLocalizedString("SaveImageActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Save Image", comment: "Context menu item for saving an image")
  public static let accessPhotoDeniedAlertTitle = NSLocalizedString("AccessPhotoDeniedAlertTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Brave would like to access your Photos", comment: "See http://mzl.la/1G7uHo7")
  public static let accessPhotoDeniedAlertMessage = NSLocalizedString("AccessPhotoDeniedAlertMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "This allows you to save the image to your Camera Roll.", comment: "See http://mzl.la/1G7uHo7")
  public static let openPhoneSettingsActionTitle = NSLocalizedString("OpenPhoneSettingsActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Open Settings", comment: "See http://mzl.la/1G7uHo7")
  public static let copyImageActionTitle = NSLocalizedString("CopyImageActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Copy Image", comment: "Context menu item for copying an image to the clipboard")
  public static let closeAllTabsTitle = NSLocalizedString("CloseAllTabsTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Close All %i Tabs", comment: "")
  public static let closeAllTabsPrompt =
    NSLocalizedString(
      "closeAllTabsPrompt",
      tableName: "BraveShared",
      bundle: .braveShared,
      value: "Are you sure you want to close all open tabs?",
      comment: "We ask users this prompt before attempting to close multiple tabs via context menu")
  public static let savedTabsFolderTitle = NSLocalizedString("SavedTabsFolderTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Saved Tabs", comment: "The title for the folder created when all bookmarks are being ")
  public static let bookmarkAllTabsTitle = NSLocalizedString("BookmarkAllTabsTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Bookmark All Tabs", comment: "Action item title of long press for Adding Bookmark for All Tabs in Tab List")
  public static let suppressAlertsActionTitle = NSLocalizedString("SuppressAlertsActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Suppress Alerts", comment: "Title of alert that seeks permission from user to suppress future JS alerts")
  public static let suppressAlertsActionMessage = NSLocalizedString("SuppressAlertsActionMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Prevent this page from creating additional alerts", comment: "Message body of alert that seeks permission from user to suppress future JS alerts")
  public static let openDownloadsFolderErrorDescription =
    NSLocalizedString(
      "OpenDownloadsFolderErrorDescription",
      tableName: "BraveShared",
      bundle: Bundle.braveShared,
      value: "An unknown error occurred while opening the Downloads folder in the Files app.",
      comment: "Error description when there is an error while navigating to Files App")
}

// MARK:-  DefaultBrowserIntroCalloutViewController.swift
extension Strings {
  public struct DefaultBrowserCallout {
    public static let introPrimaryText =
      NSLocalizedString(
        "defaultBrowserCallout.introPrimaryText",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Open all links with Brave to protect your privacy",
        comment: "Primary text on default browser popup screen")
    public static let introSecondaryText =
      NSLocalizedString(
        "defaultBrowserCallout.introSecondaryText",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Brave Shields block trackers & ads, saves data, and saves you time on every site you visit",
        comment: "Secondary text on default browser popup.")
    public static let introTertiaryText =
      NSLocalizedString(
        "defaultBrowserCallout.introTertiaryText",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Open Settings, tap Default Browser App, and select Brave.",
        comment: "Tertiary text on default browser popup screen")
    public static let introOpenSettingsButtonText =
      NSLocalizedString(
        "defaultBrowserCallout.introOpenSettingsButtonText",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Open Settings",
        comment: "Button text to open app settings")
    public static let introSkipButtonText =
      NSLocalizedString(
        "defaultBrowserCallout.introCancelButtonText",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Not now",
        comment: "Button text to close the default browser popup.")
    public static let notificationTitle =
      NSLocalizedString(
        "defaultBrowserCallout.notificationTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Brave Web Browser",
        comment: "Notification title to promote setting Brave app as default browser")

    public static let notificationBody =
      NSLocalizedString(
        "defaultBrowserCallout.notificationBody",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Optimized for iOS %@. Make Brave your default browser today.",
        comment: "Notification body to promote setting Brave app as default browser")
  }
}

// MARK:  Callouts

extension Strings {
  public struct Callout {
    public static let defaultBrowserCalloutTitle =
      NSLocalizedString(
        "callout.defaultBrowserTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Make Brave your default browser",
        comment: "Title for Default Browser Full Screen Callout")
    public static let defaultBrowserCalloutDescription =
      NSLocalizedString(
        "callout.defaultBrowserCalloutDescription",
        tableName: "BraveShared", bundle: .braveShared,
        value: "With Brave as default, every link you click opens with Brave's privacy protections.",
        comment: "Subtitle - Description for Default Browser Full Screen Callout")
    public static let defaultBrowserCalloutPrimaryButtonTitle =
      NSLocalizedString(
        "callout.defaultBrowserCalloutPrimaryButtonTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Set as default",
        comment: "Title for main button in Default Browser Full Screen Callout")
    public static let defaultBrowserCalloutSecondaryButtonTitle =
      NSLocalizedString(
        "callout.defaultBrowserCalloutSecondaryButtonTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Skip this",
        comment: "Title for secondary button in Default Browser Full Screen Callout")
    public static let defaultBrowserCalloutSecondaryButtonDescription =
      NSLocalizedString(
        "callout.defaultBrowserCalloutSecondaryButtonDescription",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Already default?",
        comment: "Description for secondary button in Default Browser Full Screen Callout")
    public static let privacyEverywhereCalloutTitle =
      NSLocalizedString(
        "callout.privacyEverywhereCalloutTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Privacy. Everywhere.",
        comment: "Title for Privacy Everywhere Full Screen Callout")
    public static let privacyEverywhereCalloutDescription =
      NSLocalizedString(
        "callout.privacyEverywhereCalloutDescription",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Get Brave privacy on your computer or tablet, and sync bookmarks & extensions between devices.",
        comment: "Subtitle - Description for Privacy Everywhere Full Screen Callout")
    public static let privacyEverywhereCalloutPrimaryButtonTitle =
      NSLocalizedString(
        "callout.privacyEverywhereCalloutPrimaryButtonTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Sync now",
        comment: "Title for button in Default Browser Full Screen Callout")
    public static let playlistOnboardingViewTitle =
      NSLocalizedString(
        "callout.playlistOnboardingViewTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Add video to Playlist…",
        comment: "Title for Playlist Onboarding View")
    public static let playlistOnboardingViewDescription =
      NSLocalizedString(
        "callout.playlistOnboardingViewDescription",
        tableName: "BraveShared", bundle: .braveShared,
        value: "…play anywhere, anytime. In the background, picture-in-picture, or even offline. And, of course, ad-free.",
        comment: "Description for Playlist Onboarding View")
    public static let playlistOnboardingViewButtonTitle =
      NSLocalizedString(
        "callout.playlistOnboardingViewButtonTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Watch the video",
        comment: "Button title for Playlist Onboarding View")
  }
}

// MARK:  Onboarding

extension Strings {
  public struct Onboarding {
    public static let welcomeScreenTitle =
      NSLocalizedString(
        "onboarding.welcomeScreenTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Welcome to Brave!",
        comment: "Title for Welcome Screen in Onboarding")
    public static let privacyScreenTitle =
      NSLocalizedString(
        "onboarding.privacyScreenTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Privacy made easy",
        comment: "Title for Privacy Screen in Onboarding")
    public static let privacyScreenDescription =
      NSLocalizedString(
        "onboarding.privacyScreenDescription",
        tableName: "BraveShared", bundle: .braveShared,
        value: "You're just a step away from the best privacy online. Ready?",
        comment: "Description for Privacy Screen in Onboarding")
    public static let privacyScreenButtonTitle =
      NSLocalizedString(
        "onboarding.privacyScreenButtonTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Let's go",
        comment: "Button Title for Privacy Screen in Onboarding")
    public static let readyScreenTitle =
      NSLocalizedString(
        "onboarding.readyScreenTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "You're ready to browse!",
        comment: "Title for Ready Screen in Onboarding")
    public static let readyScreenDescription =
      NSLocalizedString(
        "onboarding.readyScreenDescription",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Select a popular site below or enter your own...",
        comment: "Description for Ready Screen in Onboarding")
    public static let readyScreenAdditionalDescription =
      NSLocalizedString(
        "onboarding.readyScreenAdditionalDescription",
        tableName: "BraveShared", bundle: .braveShared,
        value: "...and watch those trackers & ads disappear.",
        comment: "Additional Description for Ready Screen in Onboarding")
    public static let ntpOnboardingPopOverTrackerDescription =
      NSLocalizedString(
        "onboarding.ntpOnboardingPopOverTrackerDescription",
        tableName: "BraveShared", bundle: .braveShared,
        value: "By blocking trackers & ads, websites use less data and load way faster.",
        comment: "Description for the NTP pop-over that describes the tracking information on NTP")
    public static let ntpOnboardingPopoverDoneTitle =
      NSLocalizedString(
        "onboarding.ntpOnboardingPopoverDoneTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "All set!",
        comment: "Title for the NTP pop-over that describes the onboarding is done")
    public static let ntpOnboardingPopoverDoneDescription =
      NSLocalizedString(
        "onboarding.ntpOnboardingPopoverDoneDescription",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Check the menu for settings and more great privacy features!",
        comment: "DEscription for the NTP pop-over that describes the onboarding is done")
    public static let searchViewEnterWebsiteRowTitle =
      NSLocalizedString(
        "onboarding.searchViewEnterWebsiteRowTitle",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Enter a website",
        comment: "The title of the row asking user to enter a website url")
    public static let blockedAdsOnboardingPopoverSingleTrackerDescription =
      NSLocalizedString(
        "onboarding.blockedAdsOnboardingPopoverSingleTrackerDescription",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Brave blocked %@ and %d other tracker on: %@.",
        comment: "The description of the popover showing trackers that were blocked. %@ and %d are placeholders for a tracker name and count.")
    public static let blockedAdsOnboardingPopoverMultipleTrackerDescription =
      NSLocalizedString(
        "onboarding.blockedAdsOnboardingPopoverMultipleTrackerDescription",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Brave blocked %@ and %d other trackers on: %@.",
        comment: "The description of the popover showing trackers that were blocked. %@ and %d are placeholders for a tracker name and count.")
    public static let blockedAdsOnboardingPopoverDescriptionTwo =
      NSLocalizedString(
        "onboarding.blockedAdsOnboardingPopoverDescriptionTwo",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Brave blocked %@ on: %@.",
        comment: "The alternate description of the popover showing trackers that were blocked. %@ and %d are placeholders for a tracker name and count.")
    public static let blockedAdsOnboardingPopoverDescriptionThree =
      NSLocalizedString(
        "onboarding.blockedAdsOnboardingPopoverDescriptionThree",
        tableName: "BraveShared", bundle: .braveShared,
        value: "Tap the Shield from any site to see all the stuff we blocked.",
        comment: "The description of the popover showing trackers that were blocked.")
  }
}

// MARK:-  ErrorPageHelper.swift
extension Strings {
  public static let errorPageReloadButtonTitle = NSLocalizedString("ErrorPageReloadButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Reload", comment: "Shown in error pages on a button that will try to load the page again")
  public static let errorPageOpenInSafariButtonTitle = NSLocalizedString("ErrorPageOpenInSafariButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Open in Safari", comment: "Shown in error pages for files that can't be shown and need to be downloaded.")
  public static let errorPageCantBeReachedTry =
    NSLocalizedString(
      "errorPageCantBeReachedTry",
      tableName: "BraveShared",
      bundle: Bundle.braveShared,
      value: "Try re-typing the URL, or opening a search engine and searching for the new URL.",
      comment: "Shown in error pages to suggest a fix to the user.")
}

// MARK:-  FindInPageBar.swift
extension Strings {
  public static let findInPagePreviousResultButtonAccessibilityLabel = NSLocalizedString("FindInPagePreviousResultButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Previous in-page result", comment: "Accessibility label for previous result button in Find in Page Toolbar.")
  public static let findInPageNextResultButtonAccessibilityLabel = NSLocalizedString("FindInPageNextResultButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Next in-page result", comment: "Accessibility label for next result button in Find in Page Toolbar.")
  public static let findInPageDoneButtonAccessibilityLabel = NSLocalizedString("FindInPageDoneButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Done", comment: "Done button in Find in Page Toolbar.")
  public static let findInPageFormat = NSLocalizedString("FindInPageFormat", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Find \"%@\"", comment: "Find %@ text in page.")
}

// MARK:-  ReaderModeBarView.swift
extension Strings {
  public static let readerModeDisplaySettingsButtonTitle = NSLocalizedString("ReaderModeDisplaySettingsButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Display Settings", comment: "Name for display settings button in reader mode. Display in the meaning of presentation, not monitor.")
}

// MARK:-  TabLocationView.swift
extension Strings {
  public static let tabToolbarStopButtonAccessibilityLabel = NSLocalizedString("TabToolbarStopButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Stop", comment: "Accessibility Label for the tab toolbar Stop button")
  public static let tabToolbarPlaylistButtonAccessibilityLabel = NSLocalizedString("TabToolbarPlaylistButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Playlist", comment: "Accessibility Label for the tab toolbar Playlist button")
  public static let tabToolbarReloadButtonAccessibilityLabel = NSLocalizedString("TabToolbarReloadButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Reload", comment: "Accessibility Label for the tab toolbar Reload button")
  public static let tabToolbarSearchAddressPlaceholderText = NSLocalizedString("TabToolbarSearchAddressPlaceholderText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Search or enter address", comment: "The text shown in the URL bar on about:home")
  public static let tabToolbarLockImageAccessibilityLabel = NSLocalizedString("TabToolbarLockImageAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure")
  public static let tabToolbarReaderViewButtonAccessibilityLabel = NSLocalizedString("TabToolbarReaderViewButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Reader View", comment: "Accessibility label for the Reader View button")
  public static let tabToolbarReaderViewButtonTitle = NSLocalizedString("TabToolbarReaderViewButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Add to Reading List", comment: "Accessibility label for action adding current page to reading list.")
  public static let searchSuggestionsSectionHeader = NSLocalizedString("SearchSuggestionsSectionHeader", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Search Suggestions", comment: "Section header for search suggestions option")
  public static let findOnPageSectionHeader = NSLocalizedString("FindOnPageSectionHeader", tableName: "BraveShared", bundle: Bundle.braveShared, value: "On This Page", comment: "Section header for find in page option")
  public static let searchHistorySectionHeader = NSLocalizedString("SearchHistorySectionHeader", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Open Tabs & Bookmarks & History", comment: "Section header for history and bookmarks and open tabs option")
  public static let searchSuggestionOpenTabActionTitle = NSLocalizedString("searchSuggestionOpenTabActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Switch to this tab", comment: "Action title for Switching to an existing tab for the suggestion item shown on the table list")
  
}

// MARK:-  TabPeekViewController.swift
extension Strings {
  public static let previewActionAddToBookmarksActionTitle = NSLocalizedString("PreviewActionAddToBookmarksActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Add to Bookmarks", comment: "Label for preview action on Tab Tray Tab to add current tab to Bookmarks")
  public static let previewActionCopyURLActionTitle = NSLocalizedString("PreviewActionCopyURLActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Copy URL", comment: "Label for preview action on Tab Tray Tab to copy the URL of the current tab to clipboard")
  public static let previewActionCloseTabActionTitle = NSLocalizedString("PreviewActionCloseTabActionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Close Tab", comment: "Label for preview action on Tab Tray Tab to close the current tab")
  public static let previewFormatAccessibilityLabel = NSLocalizedString("PreviewFormatAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Preview of %@", comment: "Accessibility label, associated to the 3D Touch action on the current tab in the tab tray, used to display a larger preview of the tab.")
}

// MARK:-  TabToolbar.swift
extension Strings {
  public static let tabToolbarBackButtonAccessibilityLabel = NSLocalizedString("TabToolbarBackButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Back", comment: "Accessibility label for the Back button in the tab toolbar.")
  public static let tabToolbarForwardButtonAccessibilityLabel = NSLocalizedString("TabToolbarForwardButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Forward", comment: "Accessibility Label for the tab toolbar Forward button")
  public static let tabToolbarShareButtonAccessibilityLabel = NSLocalizedString("TabToolbarShareButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Share", comment: "Accessibility Label for the browser toolbar Share button")
  public static let tabToolbarMenuButtonAccessibilityLabel = NSLocalizedString("TabToolbarMenuButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Menu", comment: "Accessibility Label for the browser toolbar Menu button")
  public static let tabToolbarAddTabButtonAccessibilityLabel = NSLocalizedString("TabToolbarAddTabButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.")
  public static let tabToolbarAccessibilityLabel = NSLocalizedString("TabToolbarAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Navigation Toolbar", comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.")
}

// MARK:-  TabTrayController.swift
extension Strings {
  public static let tabAccessibilityCloseActionLabel = NSLocalizedString("TabAccessibilityCloseActionLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)")
  public static let tabTrayAccessibilityLabel = NSLocalizedString("TabTrayAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Tabs Tray", comment: "Accessibility label for the Tabs Tray view.")
  public static let tabTrayEmptyVoiceOverText = NSLocalizedString("TabTrayEmptyVoiceOverText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "No tabs", comment: "Message spoken by VoiceOver to indicate that there are no tabs in the Tabs Tray")
  public static let tabTraySingleTabPositionFormatVoiceOverText = NSLocalizedString("TabTraySingleTabPositionFormatVoiceOverText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Tab %@ of %@", comment: "Message spoken by VoiceOver saying the position of the single currently visible tab in Tabs Tray, along with the total number of tabs. E.g. \"Tab 2 of 5\" says that tab 2 is visible (and is the only visible tab), out of 5 tabs total.")
  public static let tabTrayMultiTabPositionFormatVoiceOverText = NSLocalizedString("TabTrayMultiTabPositionFormatVoiceOverText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Tabs %@ to %@ of %@", comment: "Message spoken by VoiceOver saying the range of tabs that are currently visible in Tabs Tray, along with the total number of tabs. E.g. \"Tabs 8 to 10 of 15\" says tabs 8, 9 and 10 are visible, out of 15 tabs total.")
  public static let tabTrayClosingTabAccessibilityNotificationText = NSLocalizedString("TabTrayClosingTabAccessibilityNotificationText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Closing tab", comment: "Accessibility label (used by assistive technology) notifying the user that the tab is being closed.")
  public static let tabTrayCellCloseAccessibilityHint = NSLocalizedString("TabTrayCellCloseAccessibilityHint", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Swipe right or left with three fingers to close the tab.", comment: "Accessibility hint for tab tray's displayed tab.")
  public static let tabTrayAddTabAccessibilityLabel = NSLocalizedString("TabTrayAddTabAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.")
  public static let `private` = NSLocalizedString("Private", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Private", comment: "Private button title")
  public static let privateBrowsing = NSLocalizedString("PrivateBrowsing", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Private Browsing", comment: "")
  public static let tabTraySearchBarTitle = NSLocalizedString("TabTraySearchBarTitle", tableName: "BraveShared", bundle: .braveShared, value: "Search Tabs", comment: "Title displayed for placeholder inside Search Bar in Tab Tray")
}

// MARK:-  TabTrayButtonExtensions.swift
extension Strings {
  public static let tabPrivateModeToggleAccessibilityLabel = NSLocalizedString("TabPrivateModeToggleAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Private Mode", comment: "Accessibility label for toggling on/off private mode")
  public static let tabPrivateModeToggleAccessibilityHint = NSLocalizedString("TabPrivateModeToggleAccessibilityHint", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Turns private mode on or off", comment: "Accessiblity hint for toggling on/off private mode")
  public static let tabPrivateModeToggleAccessibilityValueOn = NSLocalizedString("TabPrivateModeToggleAccessibilityValueOn", tableName: "BraveShared", bundle: Bundle.braveShared, value: "On", comment: "Toggled ON accessibility value")
  public static let tabPrivateModeToggleAccessibilityValueOff = NSLocalizedString("TabPrivateModeToggleAccessibilityValueOff", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Off", comment: "Toggled OFF accessibility value")
  public static let tabTrayNewTabButtonAccessibilityLabel = NSLocalizedString("TabTrayNewTabButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "New Tab", comment: "Accessibility label for the New Tab button in the tab toolbar.")
}

// MARK:-  URLBarView.swift
extension Strings {
  public static let URLBarViewLocationTextViewAccessibilityLabel = NSLocalizedString("URLBarViewLocationTextViewAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
}

// MARK:-  LoginListViewController.swift
extension Strings {
  // Titles for selection/deselect/delete buttons
  public static let loginListDeselectAllButtonTitle = NSLocalizedString("LoginListDeselectAllButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Deselect All", comment: "Label for the button used to deselect all logins.")
  public static let loginListSelectAllButtonTitle = NSLocalizedString("LoginListSelectAllButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Select All", comment: "Label for the button used to select all logins.")
  public static let loginListScreenTitle = NSLocalizedString("LoginListScreenTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Logins", comment: "Title for Logins List View screen.")
  public static let loginListNoLoginTitle = NSLocalizedString("LoginListNoLoginTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "No logins found", comment: "Label displayed when no logins are found after searching.")
}

// MARK:-  LoginDetailViewController.swift
extension Strings {
  public static let loginDetailUsernameCellTitle = NSLocalizedString("LoginDetailUsernameCellTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "username", comment: "Label displayed above the username row in Login Detail View.")
  public static let loginDetailPasswordCellTitle = NSLocalizedString("LoginDetailPasswordCellTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "password", comment: "Label displayed above the password row in Login Detail View.")
  public static let loginDetailWebsiteCellTitle = NSLocalizedString("LoginDetailWebsiteCellTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "website", comment: "Label displayed above the website row in Login Detail View.")
  public static let loginDetailLastModifiedCellFormatTitle = NSLocalizedString("LoginDetailLastModifiedCellFormatTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Last modified %@", comment: "Footer label describing when the current login was last modified with the timestamp as the parameter.")
}

// MARK:-  ReaderModeHandlers.swift
extension Strings {
  public static let readerModeLoadingContentDisplayText = NSLocalizedString("ReaderModeLoadingContentDisplayText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Loading content…", comment: "Message displayed when the reader mode page is loading. This message will appear only when sharing to Brave reader mode from another app.")
  public static let readerModePageCantShowDisplayText = NSLocalizedString("ReaderModePageCantShowDisplayText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "The page could not be displayed in Reader View.", comment: "Message displayed when the reader mode page could not be loaded. This message will appear only when sharing to Brave reader mode from another app.")
  public static let readerModeLoadOriginalLinkText = NSLocalizedString("ReaderModeLoadOriginalLinkText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Load original page", comment: "Link for going to the non-reader page when the reader view could not be loaded. This message will appear only when sharing to Brave reader mode from another app.")
  public static let readerModeErrorConvertDisplayText = NSLocalizedString("ReaderModeErrorConvertDisplayText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "There was an error converting the page", comment: "Error displayed when reader mode cannot be enabled")
}

// MARK:-  ReaderModeStyleViewController.swift
extension Strings {
  public static let readerModeBrightSliderAccessibilityLabel = NSLocalizedString("ReaderModeBrightSliderAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Brightness", comment: "Accessibility label for brightness adjustment slider in Reader Mode display settings")
  public static let readerModeFontTypeButtonAccessibilityHint = NSLocalizedString("ReaderModeFontTypeButtonAccessibilityHint", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Changes font type.", comment: "Accessibility hint for the font type buttons in reader mode display settings")
  public static let readerModeFontButtonSansSerifTitle = NSLocalizedString("ReaderModeFontButtonSansSerifTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Sans-serif", comment: "Font type setting in the reading view settings")
  public static let readerModeFontButtonSerifTitle = NSLocalizedString("ReaderModeFontButtonSerifTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Serif", comment: "Font type setting in the reading view settings")
  public static let readerModeSmallerFontButtonTitle = NSLocalizedString("ReaderModeSmallerFontButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "-", comment: "Button for smaller reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
  public static let readerModeSmallerFontButtonAccessibilityLabel = NSLocalizedString("ReaderModeSmallerFontButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Decrease text size", comment: "Accessibility label for button decreasing font size in display settings of reader mode")
  public static let readerModeBiggerFontButtonTitle = NSLocalizedString("ReaderModeBiggerFontButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "+", comment: "Button for larger reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
  public static let readerModeBiggerFontButtonAccessibilityLabel = NSLocalizedString("ReaderModeBiggerFontButtonAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Increase text size", comment: "Accessibility label for button increasing font size in display settings of reader mode")
  public static let readerModeFontSizeLabelText = NSLocalizedString("ReaderModeFontSizeLabelText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Aa", comment: "Button for reader mode font size. Keep this extremely short! This is shown in the reader mode toolbar.")
  public static let readerModeThemeButtonAccessibilityHint = NSLocalizedString("ReaderModeThemeButtonAccessibilityHint", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Changes color theme.", comment: "Accessibility hint for the color theme setting buttons in reader mode display settings")

  public static let readerModeButtonTitle =
    NSLocalizedString(
      "readerModeSettingsButton",
      tableName: "BraveShared",
      bundle: .braveShared,
      value: "Reader Mode", comment: "Title of a bar that show up when you enter reader mode.")
}

// MARK:-  SearchEnginePicker.swift
extension Strings {
  public static let searchEnginePickerNavTitle = NSLocalizedString("SearchEnginePickerNavTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Default Search Engine", comment: "Title for default search engine picker.")
}

// MARK:-  SearchSettingsTableViewController.swift
extension Strings {
  public static let searchSettingNavTitle = NSLocalizedString("SearchSettingNavTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Search", comment: "Navigation title for search settings.")
  public static let searchSettingSuggestionCellTitle = NSLocalizedString("SearchSettingSuggestionCellTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Show Search Suggestions", comment: "Label for show search suggestions setting.")
  public static let searchSettingRecentSearchesCellTitle = NSLocalizedString("SearchSettingRecentSearchesCellTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Show Recent Searches", comment: "Label for showing recent search setting.")
  public static let searchSettingAddCustomEngineCellTitle =
    NSLocalizedString(
      "searchSettingAddCustomEngineCellTitle",
      bundle: .braveShared,
      value: "Add Custom Search Engine",
      comment: "Add Custom Search Engine Table Cell Row Title")
}

// MARK: - SearchCustomEngineViewController

extension Strings {
  public struct CustomSearchEngine {
    public static let customEngineNavigationTitle = NSLocalizedString(
      "customSearchEngine.navigationTitle",
      bundle: .braveShared,
      value: "Add Search Engine",
      comment: "Navigation Bar title")

    public static let customEngineAddDesription = NSLocalizedString(
      "customSearchEngine.addEngineDescription",
      bundle: Bundle.braveShared,
      value: "Write the search url and replace the query with %s.\nFor example: https://youtube.com/search?q=%s \n(If the site supports OpenSearch an option to add automatically will be provided while editing this field.)",
      comment: "Label explaining how to add search engine.")

    public static let customEngineAutoAddTitle = NSLocalizedString(
      "customSearchEngine.autoAddTitle",
      bundle: Bundle.braveShared,
      value: "Auto Add",
      comment: "Button title for Auto Add in header")

    public static let customEngineAddButtonTitle = NSLocalizedString(
      "customSearchEngine.addButtonTitle",
      bundle: Bundle.braveShared,
      value: "Add",
      comment: "Button title for Adding Engine in navigation Bar")

    public static let thirdPartySearchEngineAddErrorTitle = NSLocalizedString(
      "customSearchEngine.thirdPartySearchEngineAddErrorTitle",
      bundle: .braveShared,
      value: "Custom Search Engine Error",
      comment: "A title explaining that there is error while adding a search engine")

    public static let thirdPartySearchEngineAddErrorDescription = NSLocalizedString(
      "customSearchEngine.thirdPartySearchEngineAddErrorDescription",
      bundle: .braveShared,
      value: "The custom search engine could not be added. Please try again later.",
      comment: "A descriotion explaining that there is error while adding a search engine")

    public static let thirdPartySearchEngineMissingInfoErrorDescription = NSLocalizedString(
      "customSearchEngine.thirdPartySearchEngineMissingInfoErrorDescription",
      bundle: .braveShared,
      value: "Please fill both Title and URL fields.",
      comment: "A descriotion explaining that the fields must filled while adding a search engine. ")

    public static let thirdPartySearchEngineIncorrectFormErrorTitle = NSLocalizedString(
      "customSearchEngine.thirdPartySearchEngineIncorrectFormErrorTitle",
      bundle: .braveShared,
      value: "Search URL Query Error ",
      comment: "A title explaining that there is a formatting error in URL field")

    public static let thirdPartySearchEngineIncorrectFormErrorDescription = NSLocalizedString(
      "customSearchEngine.thirdPartySearchEngineIncorrectFormErrorDescription",
      bundle: .braveShared,
      value: "Write the search url and replace the query with %s. ",
      comment: "A description explaining that there is a formatting error in URL field")

    public static let thirdPartySearchEngineDuplicateErrorDescription = NSLocalizedString(
      "customSearchEngine.thirdPartySearchEngineDuplicateErrorDescription",
      bundle: .braveShared,
      value: "A search engine with this title or URL has already been added.",
      comment: "A message explaining a replica search engine is already added")

    public static let thirdPartySearchEngineInsecureURLErrorDescription = NSLocalizedString(
      "customSearchEngine.thirdPartySearchEngineInsecureURLErrorDescription",
      bundle: .braveShared,
      value: "The copied text should be a valid secure URL which starts with 'https://'",
      comment: "A description explaining the copied url should be secure")

    public static let thirdPartySearchEngineAddedToastTitle = NSLocalizedString(
      "custonmSearchEngine.thirdPartySearchEngineAddedToastTitle",
      bundle: .braveShared,
      value: "Added Search engine!",
      comment: "The success message that appears after a user sucessfully adds a new search engine")

    public static let thirdPartySearchEngineAddAlertTitle = NSLocalizedString(
      "customSearchEngine.thirdPartySearchEngineAddAlertTitle",
      bundle: .braveShared,
      value: "Add Search Provider?",
      comment: "The title that asks the user to Add the search provider")

    public static let thirdPartySearchEngineAddAlertDescription = NSLocalizedString(
      "customSearchEngine.thirdPartySearchEngineAddAlertDescription",
      bundle: .braveShared,
      value: "The new search engine will appear in the quick search bar.",
      comment: "The message that asks the user to Add the search provider explaining where the search engine will appear")
  
    public static let deleteEngineAlertTitle = NSLocalizedString(
      "customSearchEngine.deleteEngineAlertTitle",
      bundle: .braveShared,
      value: "Are you sure you want to delete %@?",
      comment: "The alert title shown to user when custom search engine will be deleted while it is default search engine. The parameter will be replace with name of the search engine.")
    
    public static let deleteEngineAlertDescription = NSLocalizedString(
      "customSearchEngine.deleteEngineAlertDescription",
      bundle: .braveShared,
      value: "Deleting a custom search engine while it is default will switch default engine automatically.",
      comment: "The warning description shown to user when custom search engine will be deleted while it is default search engine.")
  }
}

// MARK: - OptionsMenu

extension Strings {
  public struct OptionsMenu {
    public static let menuSectionTitle = NSLocalizedString(
      "optionsMenu.menuSectionTitle",
      tableName: "BraveShared",
      bundle: .braveShared,
      value: "Brave Features",
      comment: "Privacy Features Section title")
    public static let braveVPNItemTitle = NSLocalizedString(
      "optionsMenu.braveVPNItemTitle",
      tableName: "BraveShared",
      bundle: .braveShared,
      value: "VPN",
      comment: "Brave VPN Item Menu title")
    public static let braveVPNItemDescription = NSLocalizedString(
      "optionsMenu.braveVPNItemDescription",
      tableName: "BraveShared",
      bundle: .braveShared,
      value: "Protect your entire device online",
      comment: "The subtitle description of menu item Brave VPN")
    public static let braveTalkItemTitle = NSLocalizedString(
      "optionsMenu.braveTalkItemTitle",
      tableName: "BraveShared",
      bundle: .braveShared,
      value: "Talk",
      comment: "Brave Talk Item Menu title")
    public static let braveTalkItemDescription = NSLocalizedString(
      "optionsMenu.braveTalkItemDescription",
      tableName: "BraveShared",
      bundle: .braveShared,
      value: "Private video calls, right in your browser",
      comment: "The subtitle description of menu item Brave Talk")
    public static let braveNewsItemTitle = NSLocalizedString(
      "optionsMenu.braveNewsItemTitle",
      tableName: "BraveShared",
      bundle: .braveShared,
      value: "News",
      comment: "Brave News Item Menu title")
    public static let braveNewsItemDescription = NSLocalizedString(
      "optionsMenu.braveNewsItemDescription",
      tableName: "BraveShared",
      bundle: .braveShared,
      value: "Today's top stories in a private news feed",
      comment: "The subtitle description of menu item Brave News")
    public static let bravePlaylistItemTitle = NSLocalizedString(
      "optionsMenu.bravePlaylistItemTitle",
      tableName: "BraveShared",
      bundle: .braveShared,
      value: "Playlist",
      comment: "Brave News Item Menu title")
    public static let bravePlaylistItemDescription = NSLocalizedString(
      "optionsMenu.bravePlaylistItemDescription",
      tableName: "BraveShared",
      bundle: .braveShared,
      value: "Keep an offline playlist of any video/stream",
      comment: "The subtitle description of menu item Brave Playlist")
    public static let braveWalletItemDescription = NSLocalizedString(
      "optionsMenu.braveWalletItemDescription",
      tableName: "BraveShared",
      bundle: .braveShared,
      value: "The secure crypto wallet, no extension required",
      comment: "The subtitle description of menu item Brave Wallet")
  }
}

// MARK:-  SettingsContentViewController.swift
extension Strings {
  public static let settingsContentLoadErrorMessage = NSLocalizedString("SettingsContentLoadErrorMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Could not load page.", comment: "Error message that is shown in settings when there was a problem loading")
}

// MARK:-  SearchInputView.swift
extension Strings {
  public static let searchInputViewTextFieldAccessibilityLabel = NSLocalizedString("SearchInputViewTextFieldAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Search Input Field", comment: "Accessibility label for the search input field in the Logins list")
  public static let searchInputViewTitle = NSLocalizedString("SearchInputViewTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Search", comment: "Title for the search field at the top of the Logins list screen")
  public static let searchInputViewClearButtonTitle = NSLocalizedString("SearchInputViewClearButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Clear Search", comment: "Accessibility message e.g. spoken by VoiceOver after the user taps the close button in the search field to clear the search and exit search mode")
  public static let searchInputViewOverlayAccessibilityLabel = NSLocalizedString("SearchInputViewOverlayAccessibilityLabel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Enter Search Mode", comment: "Accessibility label for entering search mode for logins")
}

// MARK:-  MenuHelper.swift
extension Strings {
  public static let menuItemRevealPasswordTitle = NSLocalizedString("MenuItemRevealPasswordTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Reveal", comment: "Reveal password text selection menu item")
  public static let menuItemHidePasswordTitle = NSLocalizedString("MenuItemHidePasswordTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Hide", comment: "Hide password text selection menu item")
  public static let menuItemCopyTitle = NSLocalizedString("MenuItemCopyTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Copy", comment: "Copy password text selection menu item")
  public static let menuItemOpenWebsiteTitle = NSLocalizedString("MenuItemOpenTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Open Website", comment: "Open and Fill website text selection menu item")
}

// MARK: - Passcode / Browser Lock
extension Strings {
  public static let authenticationPasscode = NSLocalizedString("AuthenticationPasscode", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Passcode", comment: "Label for the Passcode item in Settings")

  public static let authenticationTouchIDPasscodeSetting = NSLocalizedString("AuthenticationTouchIDPasscodeSetting", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Touch ID & Passcode", comment: "Label for the Touch ID/Passcode item in Settings")

  public static let authenticationFaceIDPasscodeSetting = NSLocalizedString("AuthenticationFaceIDPasscodeSetting", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Face ID & Passcode", comment: "Label for the Face ID/Passcode item in Settings")

  public static let authenticationLoginsTouchReason = NSLocalizedString("AuthenticationLoginsTouchReason", tableName: "BraveShared", bundle: Bundle.braveShared, value: "This authenticates your access to Brave", comment: "Touch ID or PIN entry prompt subtitle when accessing Brave with the Browser Lock feature enabled")

  public static let browserLockMigrationTitle = NSLocalizedString("browserLockMigrationTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Open Brave with your Apple Face ID, Touch ID, or passcode", comment: "Title on the screen shown to the user when they are being migrated from the old Passcode feature to the new Browser Lock feature")

  public static let browserLockMigrationSubtitle = NSLocalizedString("browserLockMigrationSubtitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "We’ve simplified Brave Passcodes. You can now access Brave with the same ID or passcode you use on your phone.", comment: "Subtitle on the screen shown to the user when they are being migrated from the old Passcode feature to the new Browser Lock feature")

  public static let browserLockMigrationNoPasscodeSetup = NSLocalizedString("browserLockMigrationNoPasscodeSetup", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Haven't set an ID or passcode? Open Settings, then tap \"%@\"", comment: "Displayed to the user when they don't have a passcode set on their phone, therefore cannot use the Browser Lock feature. \"%@\" will be filled with either \"Touch ID & Passcode\" or \"Face ID & Passcode\"")

  public static let browserLockMigrationContinueButtonTitle = NSLocalizedString("browserLockMigrationContinueButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Continue", comment: "A button title for the action to move to the next step of the browser lock migration process.")
}

// MARK:- Settings.
extension Strings {
  public static let clearPrivateData = NSLocalizedString("ClearPrivateData", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Clear Private Data", comment: "Section title in settings panel")
  public static let clearPrivateDataAlertTitle = NSLocalizedString("ClearPrivateDataAlertTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Clear Data", comment: "")
  public static let clearPrivateDataAlertMessage = NSLocalizedString("ClearPrivateDataAlertMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Are you sure?", comment: "")
  public static let clearPrivateDataAlertYesAction = NSLocalizedString("ClearPrivateDataAlertYesAction", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Yes, Delete", comment: "")
  public static let clearDataNow = NSLocalizedString("ClearPrivateDataNow", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Clear Data Now", comment: "Button in settings that clears private data for the selected items.")
  public static let displaySettingsSection = NSLocalizedString("DisplaySettingsSection", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Display", comment: "Section name for display preferences.")
  public static let otherSettingsSection = NSLocalizedString("OtherSettingsSection", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Other Settings", comment: "Section name for other settings.")
  public static let otherPrivacySettingsSection = NSLocalizedString("OtherPrivacySettingsSection", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Other Privacy Settings", comment: "Section name for other privacy settings")
  public static let braveRewardsTitle = NSLocalizedString("BraveRewardsTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Brave Rewards", comment: "Brave Rewards settings title")
  public static let hideRewardsIcon = NSLocalizedString("HideRewardsIcon", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Hide Brave Rewards Icon", comment: "Hides the rewards icon")
  public static let hideRewardsIconSubtitle = NSLocalizedString("HideRewardsIconSubtitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Hides the Brave Rewards icon when Brave Rewards is not enabled", comment: "Hide the rewards icon explination.")
  public static let walletCreationDate = NSLocalizedString("WalletCreationDate", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Wallet Creation Date", comment: "The date your wallet was created")
  public static let copyWalletSupportInfo = NSLocalizedString("CopyWalletSupportInfo", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Copy Support Info", comment: "Copy rewards internals info for support")
  public static let settingsLicenses = NSLocalizedString("SettingsLicenses", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Licenses", comment: "Row name for licenses.")
  public static let openBraveRewardsSettings = NSLocalizedString("OpenBraveRewardsSettings", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Open Brave Rewards Settings", comment: "Button title for opening the Brave Rewards panel to settings")
  public static let setDefaultBrowserSettingsCell =
    NSLocalizedString("setDefaultBrowserSettingsCell", tableName: "BraveShared", bundle: .braveShared, value: "Set as Default Browser", comment: "Settings item to set the Brave as a default browser on the iOS device.")
  public static let setDefaultBrowserCalloutTitle =
    NSLocalizedString(
      "setDefaultBrowserCalloutTitle", tableName: "BraveShared", bundle: .braveShared,
      value: "Brave can now be set as your default browser in iOS. Tap here to open settings.", comment: "")
  public static let defaultBrowserCalloutCloseAccesabilityLabel =
    NSLocalizedString(
      "defaultBrowserCalloutCloseAccesabilityLabel", tableName: "BraveShared",
      bundle: .braveShared, value: "Close default browser callout", comment: "")
  public static let enablePullToRefresh =
    NSLocalizedString(
      "enablePullToRefresh", tableName: "BraveShared",
      bundle: .braveShared, value: "Enable Pull-to-refresh", comment: "Describes whether or not the feature that allows the user to pull down from the top of a web page a certain amount before it triggers a page refresh")
}

extension Strings {
  public struct Settings {
    public static let autocloseTabsSetting =
      NSLocalizedString(
        "settings.autocloseTabsSetting", tableName: "BraveShared",
        bundle: .braveShared, value: "Close Tabs",
        comment: "Name of app setting that allows users to automatically close tabs.")
    public static let autocloseTabsSettingFooter =
      NSLocalizedString(
        "settings.autocloseTabsSettingFooter", tableName: "BraveShared",
        bundle: .braveShared, value: "Allow Brave to automatically close tabs that haven't recently been viewed.",
        comment: "Description of autoclose tabs feature.")
    public static let autocloseTabsManualOption =
      NSLocalizedString(
        "settings.autocloseTabsManualOption", tableName: "BraveShared",
        bundle: .braveShared, value: "Manually",
        comment: "Settings option to never close tabs automatically, must be done manually")
    public static let autocloseTabsOneDayOption =
      NSLocalizedString(
        "settings.autocloseTabsOneDayOption", tableName: "BraveShared",
        bundle: .braveShared,
        value: "After One Day",
        comment: "Settings option to close old tabs after 1 day")
    public static let autocloseTabsOneWeekOption =
      NSLocalizedString(
        "settings.autocloseTabsOneWeekOption", tableName: "BraveShared",
        bundle: .braveShared,
        value: "After One Week",
        comment: "Settings option to close old tabs after 1 week")
    public static let autocloseTabsOneMonthOption =
      NSLocalizedString(
        "settings.autocloseTabsOneMonthOption", tableName: "BraveShared",
        bundle: .braveShared,
        value: "After One Month",
        comment: "Settings option to close old tabs after 1 month")
  }
}

// MARK:- Error pages.
extension Strings {
  public static let errorPagesCertWarningTitle = NSLocalizedString("ErrorPagesCertWarningTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Your connection is not private", comment: "Title on the certificate error page")

  public static let errorPagesCertErrorTitle = NSLocalizedString("ErrorPagesCertErrorTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "This site can’t provide a secure connection", comment: "Title on the certificate error page")

  public static let errorPagesMoreDetailsButton = NSLocalizedString("ErrorPagesMoreDetailsButton", tableName: "BraveShared", bundle: Bundle.braveShared, value: "More details", comment: "Label for button to perform advanced actions on the error page")

  public static let errorPagesHideDetailsButton = NSLocalizedString("ErrorPagesHideDetailsButton", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Hide details", comment: "Label for button to hide advanced actions on the error page")

  public static let errorPagesLearnMoreButton = NSLocalizedString("ErrorPagesLearnMoreButton", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Learn more", comment: "Label for learn more link on error page")

  public static let errorPagesAdvancedWarningTitle = NSLocalizedString("ErrorPagesAdvancedWarningTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Attackers might be trying to steal your information from %@ (for example, passwords, messages, or credit cards).", comment: "Warning text when clicking the Advanced button on error pages")

  public static let errorPagesAdvancedWarningDetails = NSLocalizedString("ErrorPagesAdvancedWarningDetails", tableName: "BraveShared", bundle: Bundle.braveShared, value: "This server could not prove that it is %@; its security certificate is not trusted by your device's operating system. This may be caused by a misconfiguration or an attacker trying to intercept your connection.", comment: "Additional warning text when clicking the Advanced button on error pages")

  public static let errorPagesBackToSafetyButton = NSLocalizedString("ErrorPagesBackToSafetyButton", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Back to safety", comment: "Label for button to go back from the error page")

  public static let errorPagesProceedAnywayButton = NSLocalizedString("ErrorPagesProceedAnywayButton", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Proceed to %@ (unsafe)", comment: "Button label to temporarily continue to the site from the certificate error page")

  public static let errorPagesNoInternetTitle = NSLocalizedString("ErrorPagesNoInternetTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "No internet access", comment: "Title of the No Internet error page")

  public static let errorPagesNoInternetTry = NSLocalizedString("ErrorPagesNoInternetTry", tableName: "BraveShared", bundle: Bundle.braveShared, value: "It appears you're not online. To fix this, try", comment: "Text telling the user to Try: The following list of things")

  public static let errorPagesNoInternetTryItem1 = NSLocalizedString("ErrorPagesNoInternetTryItem1", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Checking the network cables, modem, and router", comment: "List of things to try when internet is not working")

  public static let errorPagesNoInternetTryItem2 = NSLocalizedString("ErrorPagesNoInternetTryItem2", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Reconnecting to Wi-Fi", comment: "List of things to try when internet is not working")
}

// MARK: - Sync
extension Strings {
  public static let QRCode = NSLocalizedString("QRCode", tableName: "BraveShared", bundle: Bundle.braveShared, value: "QR Code", comment: "QR Code section title")
  public static let codeWords = NSLocalizedString("CodeWords", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Code Words", comment: "Code words section title")
  public static let sync = NSLocalizedString("Sync", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Sync", comment: "Sync settings section title")
  public static let syncSettingsHeader = NSLocalizedString("SyncSettingsHeader", tableName: "BraveShared", bundle: Bundle.braveShared, value: "The device list below includes all devices in your sync chain. Each device can be managed from any other device.", comment: "Header title for Sync settings")
  public static let syncThisDevice = NSLocalizedString("SyncThisDevice", tableName: "BraveShared", bundle: Bundle.braveShared, value: "This Device", comment: "This device cell")
  public static let braveSync = NSLocalizedString("BraveSync", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Sync", comment: "Sync page title")
  public static let braveSyncInternalsTitle = NSLocalizedString("BraveSyncInternalsTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Sync Internals", comment: "Sync-Internals screen title (Sync Internals or Sync Debugging is fine).")
  public static let braveSyncWelcome = NSLocalizedString("BraveSyncWelcome", tableName: "BraveShared", bundle: Bundle.braveShared, value: "To start, you will need Brave installed on all the devices you plan to sync. To chain them together, start a sync chain that you will use to securely link all of your devices together.", comment: "Sync settings welcome")
  public static let newSyncCode = NSLocalizedString("NewSyncCode", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Start a new Sync Chain", comment: "New sync code button title")
  public static let scanSyncCode = NSLocalizedString("ScanSyncCode", tableName: "BraveShared", bundle: Bundle.braveShared, value: "I have a Sync Code", comment: "Scan sync code button title")
  public static let scan = NSLocalizedString("Scan", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Scan", comment: "Scan sync code title")
  public static let syncChooseDevice = NSLocalizedString("SyncChooseDevice", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Choose Device Type", comment: "Choose device type for sync")
  public static let syncAddDeviceScan = NSLocalizedString("SyncAddDeviceScan", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Sync Chain QR Code", comment: "Add mobile device to sync with scan")
  public static let syncAddDeviceWords = NSLocalizedString("SyncAddDeviceWords", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Enter the sync code", comment: "Add device to sync with code words")
  public static let syncAddDeviceWordsTitle = NSLocalizedString("SyncAddDeviceWordsTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Enter Code Words", comment: "Add device to sync with code words navigation title")
  public static let syncToDevice = NSLocalizedString("SyncToDevice", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Sync to device", comment: "Sync to existing device")
  public static let syncToDeviceDescription = NSLocalizedString("SyncToDeviceDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Using existing synced device open Brave Settings and navigate to Settings -> Sync. Choose \"Add Device\" and scan the code displayed on the screen.", comment: "Sync to existing device description")

  public static let syncAddDeviceScanDescription = NSLocalizedString("SyncAddDeviceScanDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "On your second mobile device, navigate to Sync in the Settings panel and tap the button \"Scan Sync Code\". Use your camera to scan the QR Code below.\n\n Treat this code like a password. If someone gets hold of it, they can read and modify your synced data.", comment: "Sync add device description")
  public static let syncSwitchBackToCameraButton = NSLocalizedString("SyncSwitchBackToCameraButton", tableName: "BraveShared", bundle: Bundle.braveShared, value: "I'll use my camera...", comment: "Switch back to camera button")
  public static let syncAddDeviceWordsDescription = NSLocalizedString("SyncAddDeviceWordsDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "On your device, navigate to Sync in the Settings panel and tap the button \"%@\". Enter the sync chain code words shown below.\n\n Treat this code like a password. If someone gets hold of it, they can read and modify your synced data.", comment: "Sync add device description")
  public static let syncNoConnectionTitle = NSLocalizedString("SyncNoConnectionTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Can't connect to sync", comment: "No internet connection alert title.")
  public static let syncNoConnectionBody = NSLocalizedString("SyncNoConnectionBody", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Check your internet connection and try again.", comment: "No internet connection alert body.")
  public static let enterCodeWords = NSLocalizedString("EnterCodeWords", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Enter code words", comment: "Sync enter code words")
  public static let showCodeWords = NSLocalizedString("ShowCodeWords", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Show code words instead", comment: "Show code words instead")
  public static let syncDevices = NSLocalizedString("SyncDevices", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Devices & Settings", comment: "Sync you browser settings across devices.")
  public static let devices = NSLocalizedString("Devices", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Devices on sync chain", comment: "Sync device settings page title.")
  public static let codeWordInputHelp = NSLocalizedString("CodeWordInputHelp", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Type your supplied sync chain code words into the form below.", comment: "Code words input help")
  public static let copyToClipboard = NSLocalizedString("CopyToClipboard", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Copy to Clipboard", comment: "Copy codewords title")
  public static let copiedToClipboard = NSLocalizedString("CopiedToClipboard", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Copied to Clipboard!", comment: "Copied codewords title")
  public static let syncUnsuccessful = NSLocalizedString("SyncUnsuccessful", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Unsuccessful", comment: "")
  public static let syncUnableCreateGroup = NSLocalizedString("SyncUnableCreateGroup", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Can't sync this device", comment: "Description on popup when setting up a sync group fails")
  public static let copied = NSLocalizedString("Copied", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Copied!", comment: "Copied action complete title")
  public static let wordCount = NSLocalizedString("WordCount", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Word count: %i", comment: "Word count title")
  public static let unableToConnectTitle = NSLocalizedString("UnableToConnectTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Unable to Connect", comment: "Sync Alert")
  public static let unableToConnectDescription = NSLocalizedString("UnableToConnectDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Unable to join sync group. Please check the entered words and try again.", comment: "Sync Alert")
  public static let enterCodeWordsBelow = NSLocalizedString("EnterCodeWordsBelow", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Enter code words below", comment: "Enter sync code words below")
  public static let syncRemoveThisDevice = NSLocalizedString("SyncRemoveThisDevice", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Remove this device", comment: "Sync remove device.")
  public static let syncRemoveDeviceAction = NSLocalizedString("SyncRemoveDeviceAction", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Remove device", comment: "Remove device button for action sheet.")
  public static let syncRemoveThisDeviceQuestion = NSLocalizedString("SyncRemoveThisDeviceQuestion", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Remove this device?", comment: "Sync remove device?")
  public static let syncChooseDeviceHeader = NSLocalizedString("SyncChooseDeviceHeader", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Choose the type of device you would like to sync to.", comment: "Header for device choosing screen.")
  public static let syncRemoveThisDeviceQuestionDesc = NSLocalizedString("SyncRemoveThisDeviceQuestionDesc", tableName: "BraveShared", bundle: Bundle.braveShared, value: "This device will be disconnected from sync group and no longer receive or send sync data. All existing data will remain on device.", comment: "Sync remove device?")
  public static let pair = NSLocalizedString("Pair", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Pair", comment: "Sync pair device settings section title")
  public static let syncAddAnotherDevice = NSLocalizedString("SyncAddAnotherDevice", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Add New Device", comment: "Add New Device cell button.")
  public static let syncTabletOrMobileDevice = NSLocalizedString("SyncTabletOrMobileDevice", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Tablet or Phone", comment: "Tablet or phone button title")
  public static let syncAddTabletOrPhoneTitle = NSLocalizedString("SyncAddTabletOrPhoneTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Add a Tablet or Phone", comment: "Add Tablet or phone title")
  public static let syncComputerDevice = NSLocalizedString("SyncComputerDevice", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Computer", comment: "Computer device button title")
  public static let syncAddComputerTitle = NSLocalizedString("SyncAddComputerTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Add a Computer", comment: "Add a Computer title")
  public static let grantCameraAccess = NSLocalizedString("GrantCameraAccess", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Enable Camera", comment: "Grand camera access")
  public static let notEnoughWordsTitle = NSLocalizedString("NotEnoughWordsTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Not Enough Words", comment: "Sync Alert")
  public static let notEnoughWordsDescription = NSLocalizedString("NotEnoughWordsDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Please enter all of the words and try again.", comment: "Sync Alert")
  public static let invalidSyncCodeDescription = NSLocalizedString("InvalidSyncCodeDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Invalid Sync Code", comment: "Sync Alert")
  public static let removeDevice = NSLocalizedString("RemoveDevice", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Remove", comment: "Action button for removing sync device.")
  public static let syncInitErrorTitle = NSLocalizedString("SyncInitErrorTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Sync Communication Error", comment: "Title for sync initialization error alert")
  public static let syncInitErrorMessage = NSLocalizedString("SyncInitErrorMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "The Sync Agent is currently offline or not reachable. Please try again later.", comment: "Message for sync initialization error alert")
  // Remove device popups
  public static let syncRemoveLastDeviceTitle = NSLocalizedString("SyncRemoveLastDeviceTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Removing %@ will delete the Sync Chain.", comment: "Title for removing last device from Sync")
  public static let syncRemoveLastDeviceMessage = NSLocalizedString("SyncRemoveLastDeviceMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Data currently synced will be retained but all data in Brave’s Sync cache will be deleted. You will need to start a new sync chain to sync device data again.", comment: "Message for removing last device from Sync")
  public static let syncRemoveLastDeviceRemoveButtonName = NSLocalizedString("SyncRemoveLastDeviceRemoveButtonName", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Delete Sync Chain", comment: "Button name for removing last device from Sync")
  public static let syncRemoveCurrentDeviceTitle = NSLocalizedString("SyncRemoveCurrentDeviceTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Remove %@ from Sync Chain?", comment: "Title for removing the current device from Sync")
  public static let syncRemoveCurrentDeviceMessage = NSLocalizedString("SyncRemoveCurrentDeviceMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Local device data will remain intact on all devices. Other devices in this Sync Chain will remain synced. ", comment: "Message for removing the current device from Sync")
  public static let syncRemoveOtherDeviceTitle = NSLocalizedString("SyncRemoveOtherDeviceTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Remove %@ from Sync Chain?", comment: "Title for removing other device from Sync")
  public static let syncRemoveOtherDeviceMessage = NSLocalizedString("SyncRemoveOtherDeviceMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Removing the device from the Sync Chain will not clear previously synced data from the device.", comment: "Message for removing other device from Sync")
  public static let syncRemoveDeviceDefaultName = NSLocalizedString("SyncRemoveDeviceDefaultName", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Device", comment: "Default name for a device")
  public static let syncJoinChainCodewordsWarning = NSLocalizedString("syncJoinChainCodewordsWarning", tableName: "BraveShared", bundle: Bundle.braveShared, value: "This will share your Brave data, including potentially your passwords, with the device that generated these code words. Please double check that these code words were generated by a device that you own. Are you sure you want to do this?", comment: "Default name for a device")
  public static let syncJoinChainCameraWarning = NSLocalizedString("syncJoinChainCameraWarning", tableName: "BraveShared", bundle: Bundle.braveShared, value: "This will share your Brave data, including potentially your passwords, with the device that generated this QR code. Please double check that this QR code was generated by a device that you own. Are you sure you want to do this?", comment: "Default name for a device")
  public static let syncJoinChainWarningTitle = NSLocalizedString("syncJoinChainWarningTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Warning", comment: "Title for pairing sync device")
  public static let syncNewerVersionError = NSLocalizedString("syncNewerVersionError", tableName: "BraveShared", bundle: Bundle.braveShared, value: "This sync code was generated by a newer version of Brave on another device. Please update Brave on all synced devices and try again.", comment: "Sync Error Description")
  public static let syncInsecureVersionError = NSLocalizedString("syncInsecureVersionError", tableName: "BraveShared", bundle: Bundle.braveShared, value: "This sync code was generated by an outdated version of Brave on another device. Please update Brave on all synced devices and try again.", comment: "Sync Error Description")
  public static let syncInvalidVersionError = NSLocalizedString("syncInvalidVersionError", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Invalid Format", comment: "Sync Error Description")
  public static let syncExpiredError = NSLocalizedString("syncExpiredError", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Expired", comment: "Sync Error Description")
  public static let syncFutureVersionError = NSLocalizedString("syncFutureVersionError", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Too New", comment: "Sync Error Description")
  public static let syncGenericError = NSLocalizedString("syncGenericError", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Sorry, something went wrong", comment: "Sync Error Description")
}

extension Strings {
  public static let home = NSLocalizedString("Home", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Home", comment: "")
  public static let clearingData = NSLocalizedString("ClearData", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Clearing Data", comment: "")
}

extension Strings {

  public static let newFolder = NSLocalizedString("NewFolder", tableName: "BraveShared", bundle: Bundle.braveShared, value: "New Folder", comment: "Title for new folder popup")
  public static let enterFolderName = NSLocalizedString("EnterFolderName", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Enter folder name", comment: "Description for new folder popup")
  public static let edit = NSLocalizedString("Edit", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Edit", comment: "")

  public static let currentlyUsedSearchEngines = NSLocalizedString("CurrentlyUsedSearchEngines", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Currently used search engines", comment: "Currently usedd search engines section name.")
  public static let quickSearchEngines = NSLocalizedString("QuickSearchEngines", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Quick-Search Engines", comment: "Title for quick-search engines settings section.")
  public static let customSearchEngines = NSLocalizedString("CustomSearchEngines", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Custom-Search Engines", comment: "Title for quick-search engines settings section.")
  public static let standardTabSearch = NSLocalizedString("StandardTabSearch", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Standard Tab", comment: "Open search section of settings")
  public static let privateTabSearch = NSLocalizedString("PrivateTabSearch", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Private Tab", comment: "Default engine for private search.")
  public static let searchEngines = NSLocalizedString("SearchEngines", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Search Engines", comment: "Search engines section of settings")
  public static let settings = NSLocalizedString("Settings", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Settings", comment: "")
  public static let done = NSLocalizedString("Done", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Done", comment: "")
  public static let confirm = NSLocalizedString("Confirm", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Confirm", comment: "")
  public static let privacy = NSLocalizedString("Privacy", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Privacy", comment: "Settings privacy section title")
  public static let security = NSLocalizedString("Security", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Security", comment: "Settings security section title")
  public static let browserLock = NSLocalizedString("BrowserLock", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Browser Lock", comment: "Setting to enable the browser lock privacy feature")
  public static let browserLockDescription = NSLocalizedString("BrowserLockDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Unlock Brave with Touch ID, Face ID or system passcode.", comment: "")
  public static let saveLogins = NSLocalizedString("SaveLogins", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Save Logins", comment: "Setting to enable the built-in password manager")
  public static let showBookmarkButtonInTopToolbar = NSLocalizedString("ShowBookmarkButtonInTopToolbar", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Show Bookmarks Shortcut", comment: "Setting to show a bookmark button on the top level menu that triggers a panel of the user's bookmarks.")
  public static let alwaysRequestDesktopSite = NSLocalizedString("AlwaysRequestDesktopSite", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Always Request Desktop Site", comment: "Setting to always request the desktop version of a website.")
  public static let shieldsAdStats = NSLocalizedString("AdsrBlocked", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Ads \nBlocked", comment: "Shields Ads Stat")
  public static let shieldsAdAndTrackerStats = NSLocalizedString("AdsAndTrackersrBlocked", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Trackers & ads blocked", comment: "Shields Ads Stat")
  public static let shieldsTrackerStats = NSLocalizedString("TrackersrBlocked", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Trackers \nBlocked", comment: "Shields Trackers Stat")
  public static let dataSavedStat = NSLocalizedString("DataSavedStat", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Est. Data \nSaved", comment: "Data Saved Shield Stat")
  public static let shieldsTimeStats = NSLocalizedString("EstTimerSaved", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Est. Time \nSaved", comment: "Shields Time Saved Stat")
  public static let shieldsTimeStatsHour = NSLocalizedString("ShieldsTimeStatsHour", tableName: "BraveShared", bundle: Bundle.braveShared, value: "h", comment: "Time Saved Hours")
  public static let shieldsTimeStatsMinutes = NSLocalizedString("ShieldsTimeStatsMinutes", tableName: "BraveShared", bundle: Bundle.braveShared, value: "min", comment: "Time Saved Minutes")
  public static let shieldsTimeStatsSeconds = NSLocalizedString("ShieldsTimeStatsSeconds", tableName: "BraveShared", bundle: Bundle.braveShared, value: "s", comment: "Time Saved Seconds")
  public static let shieldsTimeStatsDays = NSLocalizedString("ShieldsTimeStatsDays", tableName: "BraveShared", bundle: Bundle.braveShared, value: "d", comment: "Time Saved Days")
  public static let delete = NSLocalizedString("Delete", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Delete", comment: "")

  public static let newTab = NSLocalizedString("NewTab", tableName: "BraveShared", bundle: Bundle.braveShared, value: "New Tab", comment: "New Tab title")
  public static let yes = NSLocalizedString("Yes", bundle: Bundle.braveShared, comment: "For search suggestions prompt. This string should be short so it fits nicely on the prompt row.")
  public static let no = NSLocalizedString("No", bundle: Bundle.braveShared, comment: "For search suggestions prompt. This string should be short so it fits nicely on the prompt row.")
  public static let openAllBookmarks = NSLocalizedString("OpenAllBookmarks", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Open All (%i)", comment: "Context menu item for opening all folder bookmarks")

  public static let bookmarkFolder = NSLocalizedString("BookmarkFolder", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Bookmark Folder", comment: "Bookmark Folder Section Title")
  public static let bookmarkInfo = NSLocalizedString("BookmarkInfo", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Bookmark Info", comment: "Bookmark Info Section Title")
  public static let name = NSLocalizedString("Name", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Name", comment: "Bookmark title / Device name")
  public static let URL = NSLocalizedString("URL", tableName: "BraveShared", bundle: Bundle.braveShared, value: "URL", comment: "Bookmark URL")
  public static let bookmarks = NSLocalizedString("Bookmarks", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Bookmarks", comment: "title for bookmarks panel")
  public static let today = NSLocalizedString("Today", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Today", comment: "History tableview section header")
  public static let yesterday = NSLocalizedString("Yesterday", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Yesterday", comment: "History tableview section header")
  public static let lastWeek = NSLocalizedString("LastWeek", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Last week", comment: "History tableview section header")
  public static let lastMonth = NSLocalizedString("LastMonth", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Last month", comment: "History tableview section header")
  public static let earlier = NSLocalizedString("Earlier", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Earlier", comment: "History tableview section header that indicated history items earlier than last month")
  public static let savedLogins = NSLocalizedString("SavedLogins", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Saved Logins", comment: "Settings item for clearing passwords and login data")
  public static let downloadedFiles = NSLocalizedString("DownloadedFiles", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Downloaded files", comment: "Settings item for clearing downloaded files.")
  public static let browsingHistory = NSLocalizedString("BrowsingHistory", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Browsing History", comment: "Settings item for clearing browsing history")
  public static let cache = NSLocalizedString("Cache", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Cache", comment: "Settings item for clearing the cache")
  public static let cookies = NSLocalizedString("Cookies", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Cookies and Site Data", comment: "Settings item for clearing cookies and site data")
  public static let findInPage = NSLocalizedString("FindInPage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Find in Page", comment: "Share action title")
  public static let searchWithBrave = NSLocalizedString("SearchWithBrave", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Search with Brave", comment: "Title of an action that allows user to perform a one-click web search for selected text")
  public static let addToFavorites = NSLocalizedString("AddToFavorites", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Add to Favorites", comment: "Add to favorites share action.")
  public static let createPDF = NSLocalizedString("CreatePDF", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Create PDF", comment: "Create PDF share action.")

  public static let showBookmarks = NSLocalizedString("ShowBookmarks", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Show Bookmarks", comment: "Button to show the bookmarks list")
  public static let showHistory = NSLocalizedString("ShowHistory", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Show History", comment: "Button to show the history list")
  public static let addBookmark = NSLocalizedString("AddBookmark", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Add Bookmark", comment: "Button to add a bookmark")
  public static let editBookmark = NSLocalizedString("EditBookmark", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Edit Bookmark", comment: "Button to edit a bookmark")
  public static let editFavorite = NSLocalizedString("EditFavorite", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Edit Favorite", comment: "Button to edit a favorite")
  public static let removeFavorite = NSLocalizedString("RemoveFavorite", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Remove Favorite", comment: "Button to remove a favorite")

  public static let deleteBookmarksFolderAlertTitle = NSLocalizedString("DeleteBookmarksFolderAlertTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Delete Folder?", comment: "Title for the alert shown when the user tries to delete a bookmarks folder")
  public static let deleteBookmarksFolderAlertMessage = NSLocalizedString("DeleteBookmarksFolderAlertMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "This will delete all folders and bookmarks inside. Are you sure you want to continue?", comment: "Message for the alert shown when the user tries to delete a bookmarks folder")
  public static let yesDeleteButtonTitle = NSLocalizedString("YesDeleteButtonTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Yes, Delete", comment: "Button title to confirm the deletion of a bookmarks folder")

  public static let close = NSLocalizedString("Close", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Close", comment: "Button title to close a menu.")
  public static let openWebsite = NSLocalizedString("OpenWebsite", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Open Website", comment: "Button title to that opens a website.")
  public static let viewOn = NSLocalizedString("ViewOn", tableName: "BraveShared", bundle: Bundle.braveShared, value: "View on %@", comment: "Label that says where to view an item. '%@' is a placeholder and will include things like 'Instagram', 'unsplash'. The full label will look like 'View  on Instagram'.")
  public static let photoBy = NSLocalizedString("PhotoBy", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Photo by %@", comment: "Label that says who took a photograph that will be displayed to the user. '%@' is a placeholder and will include be a specific person's name, example 'Bill Gates'.")

  public static let features = NSLocalizedString("Features", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Features", comment: "")

  public static let braveShieldsAndPrivacy = NSLocalizedString("BraveShieldsAndPrivacy", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Brave Shields & Privacy", comment: "")
  public static let bookmarksImportAction = NSLocalizedString("bookmarksImportAction", tableName: "BraveShared", bundle: .braveShared, value: "Import Bookmarks", comment: "Action to import bookmarks from a file.")
  public static let bookmarksExportAction = NSLocalizedString("bookmarksExportAction", tableName: "BraveShared", bundle: .braveShared, value: "Export Bookmarks", comment: "Action to export bookmarks to another device.")
}

extension Strings {
  public static let blockPopups = NSLocalizedString("BlockPopups", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Block Popups", comment: "Setting to enable popup blocking")
  public static let followUniversalLinks = NSLocalizedString("FollowUniversalLinks", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Allow universal links to open in external apps", comment: "Setting to follow universal links")
  public static let mediaAutoBackgrounding = NSLocalizedString("MediaAutoBackgrounding", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Enable Background Audio", comment: "Setting to allow media to play in the background")
  public static let showTabsBar = NSLocalizedString("ShowTabsBar", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Show Tabs Bar", comment: "Setting to show/hide the tabs bar")
  public static let privateBrowsingOnly = NSLocalizedString("PrivateBrowsingOnly", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Private Browsing Only", comment: "Setting to keep app in private mode")
  public static let shieldsDefaults = NSLocalizedString("ShieldsDefaults", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Brave Shields Global Defaults", comment: "Section title for adbblock, tracking protection, HTTPS-E, and cookies")
  public static let shieldsDefaultsFooter = NSLocalizedString("ShieldsDefaultsFooter", tableName: "BraveShared", bundle: Bundle.braveShared, value: "These are the default Shields settings for new sites. Changing these won't affect your existing per-site settings.", comment: "Section footer for global shields defaults")
  public static let blockAdsAndTracking = NSLocalizedString("BlockAdsAndTracking", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Block Cross-Site Trackers", comment: "")
  public static let blockAdsAndTrackingDescription = NSLocalizedString("BlockAdsAndTrackingDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Prevents ads, popups, and trackers from loading.", comment: "")
  public static let HTTPSEverywhere = NSLocalizedString("HTTPSEverywhere", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Upgrade Connections to HTTPS", comment: "")
  public static let HTTPSEverywhereDescription = NSLocalizedString("HTTPSEverywhereDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Opens sites using secure HTTPS instead of HTTP when possible.", comment: "")
  public static let blockPhishingAndMalware = NSLocalizedString("BlockPhishingAndMalware", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Block Phishing and Malware", comment: "")
  public static let googleSafeBrowsing = NSLocalizedString("GoogleSafeBrowsing", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Block dangerous sites", comment: "")
  public static let googleSafeBrowsingUsingWebKitDescription = NSLocalizedString("GoogleSafeBrowsingUsingWebKitDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Sends obfuscated URLs of some pages you visit to the Google Safe Browsing service, when your security is at risk.", comment: "")
  public static let blockScripts = NSLocalizedString("BlockScripts", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Block Scripts", comment: "")
  public static let blockScriptsDescription = NSLocalizedString("BlockScriptsDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Blocks JavaScript (may break sites).", comment: "")
  public static let blockCookiesDescription = NSLocalizedString("BlockCookiesDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Prevents websites from storing information about your previous visits.", comment: "")
  public static let fingerprintingProtection = NSLocalizedString("FingerprintingProtection", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Block Fingerprinting", comment: "")
  public static let fingerprintingProtectionDescription = NSLocalizedString("FingerprintingProtectionDescription", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Makes it harder for sites to recognize your device's distinctive characteristics. ", comment: "")
  public static let support = NSLocalizedString("Support", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Support", comment: "Support section title")
  public static let about = NSLocalizedString("About", tableName: "BraveShared", bundle: Bundle.braveShared, value: "About", comment: "About settings section title")
  public static let versionTemplate = NSLocalizedString("VersionTemplate", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Version %@ (%@)", comment: "Version number of Brave shown in settings")
  public static let deviceTemplate = NSLocalizedString("DeviceTemplate", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Device %@ (%@)", comment: "Current device model and iOS version copied to clipboard.")
  public static let copyAppInfoToClipboard = NSLocalizedString("CopyAppInfoToClipboard", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Copy app info to clipboard.", comment: "Copy app info to clipboard action sheet action.")
  public static let blockThirdPartyCookies = NSLocalizedString("Block3rdPartyCookies", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Block 3rd party cookies", comment: "cookie settings option")
  public static let blockAllCookies = NSLocalizedString("BlockAllCookies", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Block all Cookies", comment: "Title for setting to block all website cookies.")
  public static let blockAllCookiesAction = NSLocalizedString("BlockAllCookiesAction", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Block All", comment: "block all cookies settings action title")
  public static let blockAllCookiesAlertInfo = NSLocalizedString("BlockAllCookiesAlertInfo", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Blocking all Cookies will prevent some websites from working correctly.", comment: "Information displayed to user when block all cookie is enabled.")
  public static let blockAllCookiesAlertTitle = NSLocalizedString("BlockAllCookiesAlertTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Block all Cookies?", comment: "Title of alert displayed to user when block all cookie is enabled.")
  public static let blockAllCookiesFailedAlertMsg = NSLocalizedString("BlockAllCookiesFailedAlertMsg", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Failed to set the preference. Please try again.", comment: "Message of alert displayed to user when block all cookie operation fails")
  public static let dontBlockCookies = NSLocalizedString("DontBlockCookies", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Don't block cookies", comment: "cookie settings option")
  public static let cookieControl = NSLocalizedString("CookieControl", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Cookie Control", comment: "Cookie settings option title")
  public static let neverShow = NSLocalizedString("NeverShow", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Never Show", comment: "Setting preference to always hide the browser tabs bar.")
  public static let alwaysShow = NSLocalizedString("AlwaysShow", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Always Show", comment: "Setting preference to always show the browser tabs bar.")
  public static let showInLandscapeOnly = NSLocalizedString("ShowInLandscapeOnly", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Show in Landscape Only", comment: "Setting preference to only show the browser tabs bar when the device is in the landscape orientation.")
  public static let rateBrave = NSLocalizedString("RateBrave", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Rate Brave", comment: "Open the App Store to rate Brave.")
  public static let reportABug = NSLocalizedString("ReportABug", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Report a Bug", comment: "Providers the user an email page where they can submit a but report.")
  public static let privacyPolicy = NSLocalizedString("PrivacyPolicy", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Privacy Policy", comment: "Show Brave Browser Privacy Policy page from the Privacy section in the settings.")
  public static let termsOfUse = NSLocalizedString("TermsOfUse", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Terms of Use", comment: "Show Brave Browser TOS page from the Privacy section in the settings.")
  public static let privateTabBody = NSLocalizedString("PrivateTabBody", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Private Tabs aren’t saved in Brave, but they don’t make you anonymous online. Sites you visit in a private tab won’t show up in your history and their cookies always vanish when you close them — there won’t be any trace of them left in Brave. However, downloads will be saved.\nYour mobile carrier (or the owner of the Wi-Fi network or VPN you’re connected to) can see which sites you visit and those sites will learn your public IP address, even in Private Tabs.", comment: "Private tab details")
  public static let privateTabDetails = NSLocalizedString(
    "PrivateTabDetails", tableName: "BraveShared", bundle: Bundle.braveShared,
    value:
      "Using Private Tabs only changes what Brave does on your device, it doesn't change anyone else's behavior.\n\nSites always learn your IP address when you visit them. From this, they can often guess roughly where you are — typically your city. Sometimes that location guess can be much more specific. Sites also know everything you specifically tell them, such as search terms. If you log into a site, they'll know you're the owner of that account. You'll still be logged out when you close the Private Tabs because Brave will throw away the cookie which keeps you logged in.\n\nWhoever connects you to the Internet (your ISP) can see all of your network activity. Often, this is your mobile carrier. If you're connected to a Wi-Fi network, this is the owner of that network, and if you're using a VPN, then it's whoever runs that VPN. Your ISP can see which sites you visit as you visit them. If those sites use HTTPS, they can't make much more than an educated guess about what you do on those sites. But if a site only uses HTTP then your ISP can see everything: your search terms, which pages you read, and which links you follow.\n\nIf an employer manages your device, they might also keep track of what you do with it. Using Private Tabs probably won't stop them from knowing which sites you've visited. Someone else with access to your device could also have installed software which monitors your activity, and Private Tabs won't protect you from this either.",
    comment: "Private tab detail text")
  public static let privateTabLink = NSLocalizedString("PrivateTabLink", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Learn about Private Tabs.", comment: "Private tab information link")
  public static let privateBrowsingOnlyWarning = NSLocalizedString("PrivateBrowsingOnlyWarning", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Private Browsing Only mode will close all your current tabs and log you out of all sites.", comment: "When 'Private Browsing Only' is enabled, we need to alert the user of their normal tabs being destroyed")
  public static let bravePanel = NSLocalizedString("BravePanel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Brave Panel", comment: "Button to show the brave panel")
  public static let rewardsPanel = NSLocalizedString("RewardsPanel", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Rewards Panel", comment: "Button to show the rewards panel")
  public static let individualControls = NSLocalizedString("IndividualControls", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Individual Controls", comment: "title for per-site shield toggles")
  public static let blockingMonitor = NSLocalizedString("BlockingMonitor", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Blocking Monitor", comment: "title for section showing page blocking statistics")
  public static let siteShieldSettings = NSLocalizedString("SiteShieldSettings", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Shields", comment: "Brave panel topmost title")
  public static let blockPhishing = NSLocalizedString("BlockPhishing", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Block Phishing", comment: "Brave panel individual toggle title")
  public static let adsAndTrackers = NSLocalizedString("AdsAndTrackers", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Ads and Trackers", comment: "individual blocking statistic title")
  public static let HTTPSUpgrades = NSLocalizedString("HTTPSUpgrades", tableName: "BraveShared", bundle: Bundle.braveShared, value: "HTTPS Upgrades", comment: "individual blocking statistic title")
  public static let scriptsBlocked = NSLocalizedString("ScriptsBlocked", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Scripts Blocked", comment: "individual blocking statistic title")
  public static let fingerprintingMethods = NSLocalizedString("FingerprintingMethods", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Fingerprinting Methods", comment: "individual blocking statistic title")
  public static let shieldsOverview = NSLocalizedString("ShieldsOverview", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Site Shields allow you to control when ads and trackers are blocked for each site that you visit. If you prefer to see ads on a specific site, you can enable them here.", comment: "shields overview message")
  public static let shieldsOverviewFooter = NSLocalizedString("ShieldsOverviewFooter", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Note: Some sites may require scripts to work properly so this shield is turned off by default.", comment: "shields overview footer message")
  public static let useRegionalAdblock = NSLocalizedString("UseRegionalAdblock", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Use regional adblock", comment: "Setting to allow user in non-english locale to use adblock rules specifc to their language")
  public static let newFolderDefaultName = NSLocalizedString("NewFolderDefaultName", tableName: "BraveShared", bundle: Bundle.braveShared, value: "New Folder", comment: "Default name for creating a new folder.")
  public static let newBookmarkDefaultName = NSLocalizedString("NewBookmarkDefaultName", tableName: "BraveShared", bundle: Bundle.braveShared, value: "New Bookmark", comment: "Default name for creating a new bookmark.")
  public static let bookmarkTitlePlaceholderText = NSLocalizedString("BookmarkTitlePlaceholderText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Name", comment: "Placeholder text for adding or editing a bookmark")
  public static let bookmarkUrlPlaceholderText = NSLocalizedString("BookmarkUrlPlaceholderText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Address", comment: "Placeholder text for adding or editing a bookmark")
  public static let favoritesLocationFooterText = NSLocalizedString("FavoritesLocationFooterText", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Favorites are located on your home screen. These bookmarks are not synchronized with other devices.", comment: "Footer text when user selects to save to favorites when editing a bookmark")
  public static let bookmarkRootLevelCellTitle = NSLocalizedString("BookmarkRootLevelCellTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Bookmarks", comment: "Title for root level bookmarks cell")
  public static let favoritesRootLevelCellTitle = NSLocalizedString("FavoritesRootLevelCellTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Favorites", comment: "Title for favorites cell")
  public static let addFolderActionCellTitle = NSLocalizedString("AddFolderActionCellTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "New folder", comment: "Cell title for add folder action")
  public static let editBookmarkTableLocationHeader = NSLocalizedString("EditBookmarkTableLocationHeader", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Location", comment: "Header title for bookmark save location")
  public static let newBookmarkTitle = NSLocalizedString("NewBookmarkTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "New bookmark", comment: "Title for adding new bookmark")
  public static let newFolderTitle = NSLocalizedString("NewFolderTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "New folder", comment: "Title for adding new folder")
  public static let editBookmarkTitle = NSLocalizedString("EditBookmarkTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Edit bookmark", comment: "Title for editing a bookmark")
  public static let editFavoriteTitle = NSLocalizedString("EditFavoriteTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Edit favorite", comment: "Title for editing a favorite bookmark")
  public static let editFolderTitle = NSLocalizedString("EditFolderTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Edit folder", comment: "Title for editing a folder")
  public static let historyScreenTitle = NSLocalizedString("HistoryScreenTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "History", comment: "Title for history screen")
  public static let bookmarksMenuItem = NSLocalizedString("BookmarksMenuItem", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Bookmarks", comment: "Title for bookmarks menu item")
  public static let historyMenuItem = NSLocalizedString("HistortMenuItem", tableName: "BraveShared", bundle: Bundle.braveShared, value: "History", comment: "Title for history menu item")
  public static let settingsMenuItem = NSLocalizedString("SettingsMenuItem", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Settings", comment: "Title for settings menu item")
  public static let passwordsMenuItem = NSLocalizedString("PasswordsMenuItem", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Passwords", comment: "Title for passwords menu item")
  public static let addToMenuItem = NSLocalizedString("AddToMenuItem", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Add Bookmark", comment: "Title for the button to add a new website bookmark.")
  public static let shareWithMenuItem = NSLocalizedString("ShareWithMenuItem", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Share with...", comment: "Title for sharing url menu item")
  public static let openExternalAppURLTitle = NSLocalizedString("ExternalAppURLAlertTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Allow link to switch apps?", comment: "Allow link to switch apps?")
  public static let openExternalAppURLMessage = NSLocalizedString("ExternalAppURLAlertMessage", tableName: "BraveShared", bundle: Bundle.braveShared, value: "%@ will launch an external application", comment: "%@ will launch an external application")
  public static let openExternalAppURLAllow = NSLocalizedString("ExternalAppURLAllow", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Allow", comment: "Allow Brave to open the external app URL")
  public static let openExternalAppURLDontAllow = NSLocalizedString("ExternalAppURLDontAllow", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Don't Allow", comment: "Don't allow Brave to open the external app URL")
  public static let downloadsMenuItem = NSLocalizedString("DownloadsMenuItem", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Downloads", comment: "Title for downloads menu item")
  public static let downloadsPanelEmptyStateTitle = NSLocalizedString("DownloadsPanelEmptyStateTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Downloaded files will show up here.", comment: "Title for when a user has nothing downloaded onto their device, and the list is empty.")
  public static let playlistMenuItem = NSLocalizedString("PlaylistMenuItem", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Playlist", comment: "Playlist menu item")

  // MARK: - Themes

  public static let themesDisplayBrightness = NSLocalizedString("ThemesDisplayBrightness", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Appearance", comment: "Setting to choose the user interface theme for normal browsing mode, contains choices like 'light' or 'dark' themes")
  public static let themesDisplayBrightnessFooter = NSLocalizedString("ThemesDisplayBrightnessFooter", tableName: "BraveShared", bundle: Bundle.braveShared, value: "These settings are not applied in private browsing mode.", comment: "Text specifying that the above setting does not impact the user interface while they user is in private browsing mode.")
  public static let themesAutomaticOption = NSLocalizedString("ThemesAutomaticOption", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Automatic", comment: "Selection to automatically color/style the user interface.")
  public static let themesLightOption = NSLocalizedString("ThemesLightOption", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Light", comment: "Selection to color/style the user interface with a light theme.")
  public static let themesDarkOption = NSLocalizedString("ThemesDarkOption", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Dark", comment: "Selection to color/style the user interface with a dark theme")
  public static let themesSettings =
    NSLocalizedString(
      "themesSettings", tableName: "BraveShared", bundle: .braveShared,
      value: "Themes",
      comment: "Name for app theme settings")
  public static let defaultThemeName =
    NSLocalizedString(
      "defaultThemeName", tableName: "BraveShared", bundle: .braveShared,
      value: "Brave default",
      comment: "Name for default Brave theme.")
  public static let themeQRCodeShareTitle =
    NSLocalizedString(
      "themeQRCodeShareTitle", tableName: "BraveShared", bundle: .braveShared,
      value: "Share Brave with your friends!",
      comment: "Title for QR popup encouraging users to share the code with their friends.")
  public static let themeQRCodeShareButton =
    NSLocalizedString(
      "themeQRCodeShareButton", tableName: "BraveShared", bundle: .braveShared,
      value: "Share...",
      comment: "Text for button to share referral's QR code.")
}

// MARK: - Quick Actions
extension Strings {
  public static let quickActionNewTab = NSLocalizedString("ShortcutItemTitleNewTab", tableName: "BraveShared", bundle: Bundle.braveShared, value: "New Tab", comment: "Quick Action for 3D-Touch on the Application Icon")
  public static let quickActionNewPrivateTab = NSLocalizedString("ShortcutItemTitleNewPrivateTab", tableName: "BraveShared", bundle: Bundle.braveShared, value: "New Private Tab", comment: "Quick Action for 3D-Touch on the Application Icon")
  public static let quickActionScanQRCode = NSLocalizedString("ShortcutItemTitleQRCode", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Scan QR Code", comment: "Quick Action for 3D-Touch on the Application Icon")
}

// MARK: - Onboarding
extension Strings {
  public static let OBContinueButton = NSLocalizedString("OnboardingContinueButton", bundle: Bundle.braveShared, value: "Continue", comment: "Continue button to navigate to next onboarding screen.")
  public static let OBSkipButton = NSLocalizedString("OnboardingSkipButton", bundle: Bundle.braveShared, value: "Skip", comment: "Skip button to skip onboarding and start using the app.")
  public static let OBSaveButton = NSLocalizedString("OBSaveButton", bundle: Bundle.braveShared, value: "Save", comment: "Save button to save current selection")
  public static let OBFinishButton = NSLocalizedString("OBFinishButton", bundle: Bundle.braveShared, value: "Start browsing", comment: "Button to finish onboarding and start using the app.")
  public static let OBJoinButton = NSLocalizedString("OBJoinButton", bundle: Bundle.braveShared, value: "Join", comment: "Button to join Brave Rewards.")
  public static let OBTurnOnButton = NSLocalizedString("OBTurnOnButton", bundle: Bundle.braveShared, value: "Start", comment: "Button to show Brave Rewards.")
  public static let OBShowMeButton = NSLocalizedString("OBShowMeButton", bundle: Bundle.braveShared, value: "Show Me", comment: "Button to show the Brave Rewards Ads.")
  public static let OBDidntSeeAdButton = NSLocalizedString("OBDidntSeeAdButton", bundle: Bundle.braveShared, value: "I didn't see an ad", comment: "Button to show information on how to enable ads")
  public static let OBSearchEngineTitle = NSLocalizedString("OBSearchEngineTitle", bundle: Bundle.braveShared, value: "Welcome to Brave Browser", comment: "Title for search engine onboarding screen")
  public static let OBSearchEngineDetail = NSLocalizedString("OBSearchEngineDetail", bundle: Bundle.braveShared, value: "Select your default search engine", comment: "Detail text for search engine onboarding screen")
  public static let OBShieldsTitle = NSLocalizedString("OBShieldsTitle", bundle: Bundle.braveShared, value: "Brave Shields", comment: "Title for shields onboarding screen")
  public static let OBShieldsDetail = NSLocalizedString("OBShieldsDetail", bundle: Bundle.braveShared, value: "Block privacy-invading trackers so you can browse without being followed around the web", comment: "Detail text for shields onboarding screen")
  public static let OBRewardsTitle = NSLocalizedString("OBRewardsTitle", bundle: Bundle.braveShared, value: "Brave Rewards", comment: "Title for rewards onboarding screen")
  public static let OBAdsOptInTitle = NSLocalizedString("OBAdsOptInTitle", bundle: Bundle.braveShared, value: "Brave Ads is here!", comment: "Title when opting into brave Ads when region becomes available")
  public static let OBAdsOptInMessage = NSLocalizedString("OBAdsOptInMessage", bundle: Bundle.braveShared, value: "Earn tokens and reward creators for great content while you browse.", comment: "Message when opting into brave Ads when region becomes available")
  public static let OBAdsOptInMessageJapan = NSLocalizedString("OBAdsOptInMessageJapan", bundle: Bundle.braveShared, value: "Earn points and reward creators for great content while you browse.", comment: "Message when opting into brave Ads when region becomes available")
  public static let OBRewardsDetailInAdRegion = NSLocalizedString("OBRewardsDetailInAdRegion", bundle: Bundle.braveShared, value: "Earn tokens and reward creators for great content while you browse.", comment: "Detail text for rewards onboarding screen")
  public static let OBRewardsDetail = NSLocalizedString("OBRewardsDetail", bundle: Bundle.braveShared, value: "Opting into Brave Private Ads supports publishers and content creators with every ad viewed.", comment: "Detail text for rewards onboarding screen")
  public static let OBRewardsAgreementTitle = NSLocalizedString("OBRewardsAgreementTitle", bundle: Bundle.braveShared, value: "Brave Rewards", comment: "Title for rewards agreement onboarding screen")
  public static let OBRewardsAgreementDetail = NSLocalizedString("OBRewardsAgreementDetail", bundle: Bundle.braveShared, value: "By tapping Yes, you agree to the", comment: "Detail text for rewards agreement onboarding screen")
  public static let OBRewardsAgreementDetailLink = NSLocalizedString("OBRewardsAgreementDetailLink", bundle: Bundle.braveShared, value: "Terms of Service", comment: "Detail text for rewards agreement onboarding screen")
  public static let OBRewardsPrivacyPolicyDetailLink = NSLocalizedString("OBRewardsPrivacyPolicyDetailLink", bundle: Bundle.braveShared, value: "Privacy Policy", comment: "Detail text for rewards agreement onboarding screen")
  public static let OBRewardsAgreementDetailsAnd = NSLocalizedString("OBRewardsAgreementDetailsAnd", bundle: Bundle.braveShared, value: "and", comment: "Detail text for rewards agreement onboarding screen")
  public static let OBAdsTitle = NSLocalizedString("OBAdsTitle", bundle: Bundle.braveShared, value: "Brave will show your first ad in", comment: "Title for ads onboarding screen")
  public static let OBCompleteTitle = NSLocalizedString("OBCompleteTitle", bundle: Bundle.braveShared, value: "Now you're ready to go.", comment: "Title for when the user completes onboarding")
  public static let OBErrorTitle = NSLocalizedString("OBErrorTitle", bundle: Bundle.braveShared, value: "Sorry", comment: "A generic error title for onboarding")
  public static let OBErrorDetails = NSLocalizedString("OBErrorDetails", bundle: Bundle.braveShared, value: "Something went wrong while creating your wallet. Please try again", comment: "A generic error body for onboarding")
  public static let OBErrorOkay = NSLocalizedString("OBErrorOkay", bundle: Bundle.braveShared, value: "Okay", comment: "")
  public static let OBPrivacyConsentTitle = NSLocalizedString("OBPrivacyConsentTitle", bundle: .braveShared, value: "Anonymous referral code check", comment: "")
  public static let OBPrivacyConsentDetail = NSLocalizedString("OBPrivacyConsentDetail", bundle: .braveShared, value: "You may have downloaded Brave in support of your referrer. To detect your referrer, Brave performs a one-time check of your clipboard for the matching referral code. This check is limited to the code only and no other personal data will be transmitted.  If you opt out, your referrer won’t receive rewards from Brave.", comment: "")
  public static let OBPrivacyConsentClipboardPermission = NSLocalizedString("OBPrivacyConsentClipboardPermission", bundle: .braveShared, value: "Allow Brave to check my clipboard for a matching referral code", comment: "")
  public static let OBPrivacyConsentYesButton = NSLocalizedString("OBPrivacyConsentYesButton", bundle: .braveShared, value: "Allow one-time clipboard check", comment: "")
  public static let OBPrivacyConsentNoButton = NSLocalizedString("OBPrivacyConsentNoButton", bundle: .braveShared, value: "Do not allow this check", comment: "")
}

// MARK: - Ads Notifications
extension Strings {
  public static let monthlyAdsClaimNotificationTitle = NSLocalizedString("MonthlyAdsClaimNotificationTitle", bundle: Bundle.braveShared, value: "Brave Rewards 💵🎁", comment: "The title of the notification that goes out monthly to users who can claim an ads grant")
  public static let monthlyAdsClaimNotificationBody = NSLocalizedString("MonthlyAdsClaimNotificationBody", bundle: Bundle.braveShared, value: "Tap to claim your free tokens.", comment: "The body of the notification that goes out monthly to users who can claim an ads grant")
}

// MARK: - Bookmark restoration
extension Strings {
  public static let restoredBookmarksFolderName = NSLocalizedString("RestoredBookmarksFolderName", bundle: Bundle.braveShared, value: "Restored Bookmarks", comment: "Name of folder where restored bookmarks are retrieved")
  public static let restoredFavoritesFolderName = NSLocalizedString("RestoredFavoritesFolderName", bundle: Bundle.braveShared, value: "Restored Favorites", comment: "Name of folder where restored favorites are retrieved")
}

// MARK: - User Wallet
extension Strings {
  public static let userWalletCloseButtonTitle = NSLocalizedString("UserWalletCloseButtonTitle", bundle: Bundle.braveShared, value: "Close", comment: "")
  public static let userWalletGenericErrorTitle = NSLocalizedString("UserWalletGenericErrorTitle", bundle: Bundle.braveShared, value: "Sorry, something went wrong", comment: "")
  public static let userWalletGenericErrorMessage = NSLocalizedString("UserWalletGenericErrorMessage", bundle: Bundle.braveShared, value: "There was a problem logging into your Uphold account. Please try again", comment: "")
}

// MARK: - New tab page
extension Strings {
  public struct NTP {
    public static let turnRewardsTos =
      NSLocalizedString(
        "ntp.turnRewardsTos",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "By turning on Rewards, you agree to the %@.",
        comment: "The placeholder says 'Terms of Service'. So full sentence goes like: 'By turning Rewards, you agree to the Terms of Service'.")
    public static let sponsoredImageDescription =
      NSLocalizedString(
        "ntp.sponsoredImageDescription",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "You’re supporting content creators and publishers by viewing this sponsored image.",
        comment: "")
    public static let hideSponsoredImages =
      NSLocalizedString(
        "ntp.hideSponsoredImages",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Hide sponsored images",
        comment: "")
    public static let goodJob =
      NSLocalizedString(
        "ntp.goodJob",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Way to go!",
        comment: "The context is to praise the user that they did a good job, to keep it up. It is used in full sentence like: 'Way to go! You earned 40 BAT last month.'")
    public static let earningsReport =
      NSLocalizedString(
        "ntp.earningsReport",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "You earned %@ by browsing with Brave.",
        comment: "Placeholder example: 'You earned 42 BAT by browsing with Brave.'")
    public static let claimRewards =
      NSLocalizedString(
        "ntp.claimRewards",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Claim Tokens",
        comment: "")

    public static let learnMoreAboutRewards =
      NSLocalizedString(
        "ntp.learnMoreAboutRewards",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Learn more about Brave Rewards",
        comment: "")

    public static let learnMoreAboutSI =
      NSLocalizedString(
        "ntp.learnMoreAboutSI",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Learn more about sponsored images",
        comment: "")

    public static let braveSupportFavoriteTitle =
      NSLocalizedString(
        "ntp.braveSupportFavoriteTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Brave Support",
        comment: "Bookmark title for Brave Support")

    public static let settingsTitle = NSLocalizedString("ntp.settingsTitle", tableName: "BraveShared", bundle: Bundle.braveShared, value: "New Tab Page", comment: "Title on settings page to adjust the primary home screen functionality.")
    public static let settingsBackgroundImages = NSLocalizedString("ntp.settingsBackgroundImages", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Show Background Images", comment: "A setting to enable or disable background images on the main screen.")
    public static let settingsBackgroundImageSubMenu = NSLocalizedString("ntp.settingsBackgroundImageSubMenu", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Background Images", comment: "A button that leads to a 'more' menu, letting users configure additional settings.")
    public static let settingsDefaultImagesOnly = NSLocalizedString("ntp.settingsDefaultImagesOnly", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Default Images Only", comment: "A selection to let the users only see a set of predefined, default images on the background of the app.")
    public static let settingsSponsoredImagesSelection = NSLocalizedString("ntp.settingsSponsoredImagesSelection", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Sponsored Images", comment: "A selection to let the users see sponsored image backgrounds when opening a new tab.")
    public static let settingsAutoOpenKeyboard = NSLocalizedString("ntp.settingsAutoOpenKeyboard", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Auto Open Keyboard", comment: "A setting to enable or disable the device's keyboard from opening automatically when creating a new tab.")

    public static let showMoreFavorites = NSLocalizedString("ntp.showMoreFavorites", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Show More", comment: "A button title to show more bookmarks, that opens a new menu.")

  }

}

// MARK: - Popover Views
extension Strings {
  public struct Popover {
    public static let closeContextMenu = NSLocalizedString("PopoverDefaultClose", bundle: Bundle.braveShared, value: "Close Context Menu", comment: "Description for closing a popover menu that is displayed.")
    public static let closeShieldsMenu = NSLocalizedString("PopoverShieldsMenuClose", bundle: Bundle.braveShared, value: "Close Shields Menu", comment: "Description for closing the `Brave Shields` popover menu that is displayed.")
  }
}

// MARK: - Shields
extension Strings {
  public struct Shields {
    public static let toggleHint = NSLocalizedString("BraveShieldsToggleHint", bundle: Bundle.braveShared, value: "Double-tap to toggle Brave Shields", comment: "The accessibility hint spoken when focused on the main shields toggle")
    public static let statusTitle = NSLocalizedString("BraveShieldsStatusTitle", bundle: Bundle.braveShared, value: "Brave Shields", comment: "Context: 'Brave Shields Up' or 'Brave Shields Down'")
    public static let statusValueUp = NSLocalizedString("BraveShieldsStatusValueUp", bundle: Bundle.braveShared, value: "Up", comment: "Context: The 'Up' in 'Brave Shields Up'")
    public static let statusValueDown = NSLocalizedString("BraveShieldsStatusValueDown", bundle: Bundle.braveShared, value: "Down", comment: "Context: The 'Down' in 'Brave Shields Down'")
    public static let blockedCountLabel = NSLocalizedString("BraveShieldsBlockedCountLabel", bundle: Bundle.braveShared, value: "Ads and other creepy things blocked", comment: "The number of ads and trackers blocked will be next to this")
    public static let blockedInfoButtonAccessibilityLabel = NSLocalizedString("BraveShieldsBlockedInfoButtonAccessibilityLabel", bundle: Bundle.braveShared, value: "Learn more", comment: "What the screen reader will read out when the user has VoiceOver on and taps on the question-mark info button on the shields panel")
    public static let siteBroken = NSLocalizedString("BraveShieldsSiteBroken", bundle: Bundle.braveShared, value: "If this site appears broken, try Shields down", comment: "")
    public static let advancedControls = NSLocalizedString("BraveShieldsAdvancedControls", bundle: Bundle.braveShared, value: "Advanced controls", comment: "")
    public static let aboutBraveShieldsTitle = NSLocalizedString("AboutBraveShields", bundle: Bundle.braveShared, value: "About Brave Shields", comment: "The title of the screen explaining Brave Shields")
    public static let aboutBraveShieldsBody = NSLocalizedString("AboutBraveShieldsBody", bundle: Bundle.braveShared, value: "Sites often include cookies and scripts which try to identify you and your device. They want to work out who you are and follow you across the web — tracking what you do on every site.\n\nBrave blocks these things so that you can browse without being followed around.", comment: "The body of the screen explaining Brave Shields")
    public static let shieldsDownDisclaimer = NSLocalizedString("ShieldsDownDisclaimer", bundle: Bundle.braveShared, value: "You're browsing this site without Brave's privacy protections. Does it not work right with Shields up?", comment: "")
    public static let reportABrokenSite = NSLocalizedString("ReportABrokenSite", bundle: Bundle.braveShared, value: "Report a broken site", comment: "")
    public static let reportBrokenSiteBody1 = NSLocalizedString("ReportBrokenSiteBody1", bundle: Bundle.braveShared, value: "Let Brave's developers know that this site doesn't work properly with Shields:", comment: "First part of the report a broken site copy. After the colon is a new line and then a website address")
    public static let reportBrokenSiteBody2 = NSLocalizedString("ReportBrokenSiteBody2", bundle: Bundle.braveShared, value: "Note: This site address will be submitted with your Brave version number and your IP address (which will not be stored).", comment: "")
    public static let reportBrokenSubmitButtonTitle = NSLocalizedString("ReportBrokenSubmitButtonTitle", bundle: Bundle.braveShared, value: "Submit", comment: "")
    public static let globalControls = NSLocalizedString("BraveShieldsGlobalControls", bundle: Bundle.braveShared, value: "Global Controls", comment: "")
    public static let globalChangeButton = NSLocalizedString("BraveShieldsGlobalChangeButton", bundle: Bundle.braveShared, value: "Change global Shields defaults", comment: "")
    public static let siteReportedTitle = NSLocalizedString("SiteReportedTitle", bundle: Bundle.braveShared, value: "Thank You", comment: "")
    public static let siteReportedBody = NSLocalizedString("SiteReportedBody", bundle: Bundle.braveShared, value: "Thanks for letting Brave's developers know that there's something wrong with this site. We'll do our best to fix it!", comment: "")
  }
}

// MARK: ShieldEducation

extension Strings {
  public struct ShieldEducation {
    public static let trackerCountShareTitle =
      NSLocalizedString(
        "shieldEducation.trackerCountShareTitle",
        bundle: .braveShared,
        value: "%ld trackers & ads blocked!",
        comment: "Title for Shield Education Tracker Count Share. The parameter substituted for \"%ld\" is the count of the trackers and ads blocked in total until present. E.g.: 5000 trackers & ads blocked")

    public static let videoAdBlockTitle =
      NSLocalizedString(
        "shieldEducation.videoAdBlockTitle",
        bundle: .braveShared,
        value: "Ads are blocked while watching videos on this website.",
        comment: "Title for Shield Education Tracker Video Ad Block")

    public static let trackerCountShareSubtitle =
      NSLocalizedString(
        "shieldEducation.trackerCountShareSubtitle",
        bundle: .braveShared,
        value: "Congratulations. You're pretty special.",
        comment: "Subtitle for Shield Education Tracker Count Share")

    public static let trackerAdWarningSubtitle =
      NSLocalizedString(
        "shieldEducation.trackerAdWarningSubTitle",
        bundle: .braveShared,
        value: "Brave Shields just protected your online privacy.",
        comment: "Subtitle for Shield Education Tracker Ad Warning")

    public static let videoAdBlockSubtitle =
      NSLocalizedString(
        "shieldEducation.videoAdBlockSubtitle",
        bundle: .braveShared,
        value: "Videos without ads use less data.",
        comment: "Subtitle for Shield Education Tracker Video Ad Block")

    public static let shareTheNewsTitle =
      NSLocalizedString(
        "shieldEducation.shareTheNewsTitle",
        bundle: .braveShared,
        value: "Share the news",
        comment: "Action title for actionable Share warnings")

    public static let benchmarkAnyTierTitle =
      NSLocalizedString(
        "shieldEducation.benchmarkAnyTierTitle",
        bundle: .braveShared,
        value: "Congrats on reaching this privacy milestone.",
        comment: "Subtitle for tracker benchmark Share")

    public static let benchmarkSpecialTierTitle =
      NSLocalizedString(
        "shieldEducation.benchmarkSpecialTierTitle",
        bundle: .braveShared,
        value: "Congratulations. You’re pretty special.",
        comment: "Subtitle for tracker benchmark Share")

    public static let benchmarkExclusiveTierTitle =
      NSLocalizedString(
        "shieldEducation.benchmarkExclusiveTierTitle",
        bundle: .braveShared,
        value: "Congratulations. You’re part of an exclusive club.",
        comment: "Subtitle for tracker benchmark Share")

    public static let benchmarkProfessionalTierTitle =
      NSLocalizedString(
        "shieldEducation.benchmarkProfessionalTierTitle",
        bundle: .braveShared,
        value: "Congratulations. You joined the pros.",
        comment: "Subtitle for tracker benchmark Share")

    public static let benchmarkPrimeTierTitle =
      NSLocalizedString(
        "shieldEducation.benchmarkPrimeTierTitle",
        bundle: .braveShared,
        value: "Congratulations. You’ve become a master.",
        comment: "Subtitle for tracker benchmark Share")

    public static let benchmarkGrandTierTitle =
      NSLocalizedString(
        "shieldEducation.benchmarkGrandTierTitle",
        bundle: .braveShared,
        value: "Congratulations. You’ve become a Grand Master.",
        comment: "Subtitle for tracker benchmark Share")

    public static let benchmarkLegendaryTierTitle =
      NSLocalizedString(
        "shieldEducation.benchmarkLegendaryTierTitle",
        bundle: .braveShared,
        value: "Congratulations. You are legendary.",
        comment: "Subtitle for tracker benchmark Share")

    public static let shareDescriptionTitle =
      NSLocalizedString(
        "socialSharing.shareDescriptionTitle",
        bundle: .braveShared,
        value: "Every day I save data by browsing the web with Brave.",
        comment: "Text used for social sharing together with Brave Shield values")

    public static let domainSpecificDataSavedTitle =
      NSLocalizedString(
        "socialSharing.domainSpecificDataSavedTitle",
        bundle: .braveShared,
        value: "Every day I save data by browsing the web with Brave.",
        comment: "Title used when in warning pop-over when domain specific data save appears ")

    public static let domainSpecificDataSavedSubtitle =
      NSLocalizedString(
        "shieldEducation.domainSpecificDataSavedSubtitle",
        bundle: .braveShared,
        value: "Average data saved\n%@ MB",
        comment: "Subtitle for  The parameter substituted for \"%@\" is the amount of data saved in MB. E.g.: Average Data Saved: 17.43 MB")

    public static let dontShowThisTitle =
      NSLocalizedString(
        "shieldEducation.dontShowThisTitle",
        bundle: .braveShared,
        value: "Don't show this again",
        comment: "Action title for button at domain specific data saved pop-up")
  }
}

// MARK: PlayList

extension Strings {
  public struct PlayList {
    public static let playListSectionTitle =
      NSLocalizedString(
        "playList.playListSectionTitle",
        bundle: .braveShared,
        value: "Playlist",
        comment: "Title For the Section that videos are listed")

    public static let removeActionButtonTitle =
      NSLocalizedString(
        "playList.removeActionButtonTitle",
        bundle: .braveShared,
        value: "Remove",
        comment: "Title for removing offline mode storage")

    public static let noticeAlertTitle =
      NSLocalizedString(
        "playList.noticeAlertTitle",
        bundle: .braveShared,
        value: "Notice",
        comment: "Title for download video error alert")

    public static let okayButtonTitle =
      NSLocalizedString(
        "playList.okayButtonTitle",
        bundle: .braveShared,
        value: "Okay",
        comment: "Okay Alert button title")

    public static let reopenButtonTitle =
      NSLocalizedString(
        "playList.reopenButtonTitle",
        bundle: .braveShared,
        value: "Reopen",
        comment: "Reopen Alert button title")

    public static let sorryAlertTitle =
      NSLocalizedString(
        "playList.sorryAlertTitle",
        bundle: .braveShared,
        value: "Sorry",
        comment: "Title for load resources error alert")

    public static let loadResourcesErrorAlertDescription =
      NSLocalizedString(
        "playList.loadResourcesErrorAlertDescription",
        bundle: .braveShared,
        value: "There was a problem loading the resource!",
        comment: "Description for load resources error alert")

    public static let addToPlayListAlertTitle =
      NSLocalizedString(
        "playList.addToPlayListAlertTitle",
        bundle: .braveShared,
        value: "Add to Brave Playlist",
        comment: "Alert Title for adding videos to playlist")

    public static let addToPlayListAlertDescription =
      NSLocalizedString(
        "playList.addToPlayListAlertDescription",
        bundle: .braveShared,
        value: "Would you like to add this video to your playlist?",
        comment: "Alert Description for adding videos to playlist")

    public static let savingForOfflineLabelTitle =
      NSLocalizedString(
        "playList.savingForOfflineLabelTitle",
        bundle: .braveShared,
        value: "Saving for Offline…",
        comment: "Text indicator on the table cell while saving a video for offline")

    public static let savedForOfflineLabelTitle =
      NSLocalizedString(
        "playList.savedForOfflineLabelTitle",
        bundle: .braveShared,
        value: "Saved for Offline",
        comment: "Text indicator on the table cell while saving a video for offline with percentage eg: %25 Saved for Offline")

    public static let noItemLabelTitle =
      NSLocalizedString(
        "playList.noItemLabelTitle",
        bundle: .braveShared,
        value: "No Items Available",
        comment: "Text when there are no items in the playlist")

    public static let noItemLabelDetailLabel =
      NSLocalizedString(
        "playList.noItemLabelDetailLabel",
        bundle: .braveShared,
        value: "You can add items to your Brave Playlist within the browser",
        comment: "Detail Text when there are no items in the playlist")

    public static let expiredLabelTitle =
      NSLocalizedString(
        "playList.expiredLabelTitle",
        bundle: .braveShared,
        value: "Expired",
        comment: "Text indicator on the table cell If a video is expired")

    public static let expiredAlertTitle =
      NSLocalizedString(
        "playList.expiredAlertTitle",
        bundle: .braveShared,
        value: "Expired Video",
        comment: "The title for the alert that shows up when an item is expired")

    public static let expiredAlertDescription =
      NSLocalizedString(
        "playList.expiredAlertDescription",
        bundle: .braveShared,
        value: "This video was a live stream or the time limit was reached. Please reopen the link to refresh.",
        comment: "The description for the alert that shows up when an item is expired")

    public static let pictureInPictureErrorTitle =
      NSLocalizedString(
        "playList.pictureInPictureErrorTitle",
        bundle: .braveShared,
        value: "Sorry, an error occurred while attempting to display picture-in-picture.",
        comment: "The title for the alert that shows up when an item is expired")

    public static let toastAddToPlaylistTitle =
      NSLocalizedString(
        "playList.toastAddToPlaylistTitle",
        bundle: .braveShared,
        value: "Add to Brave Playlist",
        comment: "The title for the toast that shows up on a page containing a playlist item")

    public static let toastAddedToPlaylistTitle =
      NSLocalizedString(
        "playList.toastAddedToPlaylistTitle",
        bundle: .braveShared,
        value: "Added to Brave Playlist",
        comment: "The title for the toast that shows up on a page containing a playlist item that was added to playlist")

    public static let toastAddToPlaylistOpenButton =
      NSLocalizedString(
        "playList.toastAddToPlaylistOpenButton",
        bundle: .braveShared,
        value: "Open",
        comment: "The title for the toast button when an item was added to playlist")

    public static let toastExitingItemPlaylistTitle =
      NSLocalizedString(
        "playList.toastExitingItemPlaylistTitle",
        bundle: .braveShared,
        value: "View in Brave Playlist",
        comment: "The title for the toast that shows up on a page when an item that has already been added, was updated.")

    public static let removePlaylistVideoAlertTitle =
      NSLocalizedString(
        "playlist.removePlaylistVideoAlertTitle",
        bundle: .braveShared,
        value: "Remove Media Item from Playlist?",
        comment: "Title for the alert shown when the user tries to remove an item from playlist")

    public static let removePlaylistVideoAlertMessage =
      NSLocalizedString(
        "playlist.removePlaylistVideoAlertMessage",
        bundle: .braveShared,
        value: "This will remove the media item from the list. Are you sure you want to continue?",
        comment: "Message for the alert shown when the user tries to remove a video from playlist")

    public static let removePlaylistOfflineDataAlertTitle =
      NSLocalizedString(
        "playlist.removePlaylistOfflineDataAlertTitle",
        bundle: .braveShared,
        value: "Remove Offline Data",
        comment: "Title for the alert shown when the user tries to remove offline data of an item from playlist")

    public static let removePlaylistOfflineDataAlertMessage =
      NSLocalizedString(
        "playlist.removePlaylistOfflineDataAlertMessage",
        bundle: .braveShared,
        value: "This will delete the media from offline storage. Are you sure you want to continue?",
        comment: "Message for the alert shown when the user tries to remove offline data of an item from playlist")

    public static let urlBarButtonOptionTitle =
      NSLocalizedString(
        "playlist.urlBarButtonOptionTitle",
        bundle: .braveShared,
        value: "Enable quick-access button",
        comment: "Title for option to disable URL-Bar button")

    public static let urlBarButtonOptionFooter =
      NSLocalizedString(
        "playlist.urlBarButtonOptionFooter",
        bundle: .braveShared,
        value: "Adds a playlist button (it looks like 4 lines with a + symbol) beside the address bar in the Brave browser. This button gives you quick access to open Playlist, or add or remove media.",
        comment: "Footer for option to disable URL-Bar button")

    public static let sharePlaylistActionTitle =
      NSLocalizedString(
        "playlist.sharePlaylistActionTitle",
        bundle: .braveShared,
        value: "Brave Playlist Menu",
        comment: "Title of the ActionSheet/Alert when sharing a playlist item from the Swipe-Action")

    public static let sharePlaylistActionDetailsTitle =
      NSLocalizedString(
        "playlist.sharePlaylistActionDetailsTitle",
        bundle: .braveShared,
        value: "You can open the current item in a New Tab, or share it via the System Share Menu",
        comment: "Details Title of the ActionSheet/Alert when sharing a playlist item from the Swipe-Action")

    public static let sharePlaylistOpenInNewTabTitle =
      NSLocalizedString(
        "playlist.sharePlaylistOpenInNewTabTitle",
        bundle: .braveShared,
        value: "Open In New Tab",
        comment: "Button Title of the ActionSheet/Alert Button when sharing a playlist item from the Swipe-Action")

    public static let sharePlaylistOpenInNewPrivateTabTitle =
      NSLocalizedString(
        "playlist.sharePlaylistOpenInNewPrivateTabTitle",
        bundle: .braveShared,
        value: "Open In Private Tab",
        comment: "Button Title of the ActionSheet/Alert Button when sharing a playlist item from the Swipe-Action")

    public static let sharePlaylistMoveActionMenuTitle =
      NSLocalizedString(
        "playlist.movePlaylistShareActionMenuTitle",
        bundle: .braveShared,
        value: "Move...",
        comment: "Button Title of the ActionSheet/Alert Button when moving a playlist item from the Swipe-Action to a new folder")

    public static let sharePlaylistShareActionMenuTitle =
      NSLocalizedString(
        "playlist.sharePlaylistShareActionMenuTitle",
        bundle: .braveShared,
        value: "Share...",
        comment: "Button Title of the ActionSheet/Alert Button when sharing a playlist item from the Swipe-Action")

    public static let menuBadgeOptionTitle =
      NSLocalizedString(
        "playlist.menuBadgeOptionTitle",
        bundle: .braveShared,
        value: "Show Menu Notification Badge",
        comment: "Title for playlist menu badge option")

    public static let menuBadgeOptionFooterText =
      NSLocalizedString(
        "playlist.menuBadgeOptionFooterText",
        bundle: .braveShared,
        value: "When enabled, a badge will be displayed on the main menu icon, indicating media on the page may be added to Brave Playlist.",
        comment: "Description footer for playlist menu badge option")

    public static let playlistLongPressSettingsOptionTitle =
      NSLocalizedString(
        "playlist.playlistLongPressSettingsOptionTitle",
        bundle: .braveShared,
        value: "Enable Long Press",
        comment: "Title for the Playlist Settings Option for long press gesture")

    public static let playlistLongPressSettingsOptionFooterText =
      NSLocalizedString(
        "playlist.playlistLongPressSettingsOptionFooterText",
        bundle: .braveShared,
        value: "When enabled, you can long-press on most video/audio files to add them to your Playlist.",
        comment: "Footer Text for the Playlist Settings Option for long press gesture")

    public static let playlistAutoPlaySettingsOptionTitle =
      NSLocalizedString(
        "playlist.playlistAutoPlaySettingsOptionTitle",
        bundle: .braveShared,
        value: "Auto-Play",
        comment: "Title for the Playlist Settings Option for Enable/Disable Auto-Play")

    public static let playlistAutoPlaySettingsOptionFooterText =
      NSLocalizedString(
        "playlist.playlistAutoPlaySettingsOptionFooterText",
        bundle: .braveShared,
        value: "This option will enable/disable auto-play when Playlist is opened. However, this option will not affect auto-play when loading the next video on the list.",
        comment: "Footer Text for the Playlist Settings Option for Enable/Disable Auto-Play")

    public static let playlistSidebarLocationTitle =
      NSLocalizedString(
        "playlist.playlistSidebarLocationTitle",
        bundle: .braveShared,
        value: "Sidebar Location",
        comment: "Title for the Playlist Settings Option for Sidebar Location (Left/Right)")

    public static let playlistSidebarLocationFooterText =
      NSLocalizedString(
        "playlist.playlistSidebarLocationFooterText",
        bundle: .braveShared,
        value: "This setting will change video list location between left-hand side/ right-hand side.",
        comment: "Footer Text for the Playlist Settings Option for Sidebar Location (Left/Right)")

    public static let playlistSidebarLocationOptionLeft =
      NSLocalizedString(
        "playlist.playlistSidebarLocationOptionLeft",
        bundle: .braveShared,
        value: "Left",
        comment: "Option Text for Sidebar Location Left")

    public static let playlistSidebarLocationOptionRight =
      NSLocalizedString(
        "playlist.playlistSidebarLocationOptionRight",
        bundle: .braveShared,
        value: "Right",
        comment: "Option Text for Sidebar Location Right")

    public static let playlistAutoSaveSettingsTitle =
      NSLocalizedString(
        "playlist.playlistAutoSaveSettingsTitle",
        bundle: .braveShared,
        value: "Auto-Save for Offline",
        comment: "Title for the Playlist Settings Option for Auto Save Videos for Offline (Off/On/Only Wi-fi)")

    public static let playlistAutoSaveSettingsDescription =
      NSLocalizedString(
        "playlist.playlistAutoSaveSettingsDescription",
        bundle: .braveShared,
        value: "Adding video and audio files for offline use can use a lot of storage on your device as well as use your cellular data",
        comment: "Description for the Playlist Settings Option for Auto Save Videos for Offline (Off/On/Only Wi-fi)")

    public static let playlistAutoSaveSettingsFooterText =
      NSLocalizedString(
        "playlist.playlistAutoSaveSettingsFooterText",
        bundle: .braveShared,
        value: "This option will automatically keep your playlist items on your device so you can play them without an internet connection.",
        comment: "Footer Text for the Playlist Settings Option for Auto Save Videos for Offline (Off/On/Only Wi-fi))")

    public static let playlistStartPlaybackSettingsOptionTitle =
      NSLocalizedString(
        "playlist.playlistStartPlaybackSettingsOptionTitle",
        bundle: .braveShared,
        value: "Start Playback where I last left off",
        comment: "Title for the Playlist Settings Option for Enable/Disable ability to start playing from the point where user last left-off")

    public static let playlistStartPlaybackSettingsFooterText =
      NSLocalizedString(
        "playlist.playlistStartPlaybackSettingsFooterText",
        bundle: .braveShared,
        value: "This option will enable/disable the ability to start playback of media (video/audio) from the time where you last left off.",
        comment: "Footer Text for the Playlist Settings Option for Enable/Disable ability to start playing from the point where user last left-off")

    public static let playlistAutoSaveOptionOn =
      NSLocalizedString(
        "playlist.playlistAutoSaveOptionOn",
        bundle: .braveShared,
        value: "On",
        comment: "Auto Save turn On Option")

    public static let playlistAutoSaveOptionOff =
      NSLocalizedString(
        "playlist.playlistAutoSaveOptionOff",
        bundle: .braveShared,
        value: "Off",
        comment: "Auto Download turn Off Option")

    public static let playlistAutoSaveOptionOnlyWifi =
      NSLocalizedString(
        "playlist.playlistAutoSaveOptionOnlyWifi",
        bundle: .braveShared,
        value: "Only Wi-Fi",
        comment: "Option Text for Auto Save Only Wi-Fi Option")

    public static let playlistOfflineDataToggleOption =
      NSLocalizedString(
        "playlist.playlistOfflineDataToggleOption",
        bundle: .braveShared,
        value: "Playlist Offline Data",
        comment: "Text for Playlist Offline Data Toggle while clearing the offline data storage in settings")

    public static let playlistMediaAndOfflineDataToggleOption =
      NSLocalizedString(
        "playlist.playlistMediaAndOfflineDataToggleOption",
        bundle: .braveShared,
        value: "Playlist Media & Offline Data",
        comment: "Text for Playlist Media & Offline Data Toggle while clearing the offline data storage in settings")

    public static let playlistResetAlertTitle =
      NSLocalizedString(
        "playList.playlistResetAlertTitle",
        bundle: .braveShared,
        value: "Reset",
        comment: "The title for the alert that shows up when removing all videos and their offline mode storage.")

    public static let playlistResetPlaylistOptionFooterText =
      NSLocalizedString(
        "playlist.playlistResetPlaylistOptionFooterText",
        bundle: .braveShared,
        value: "This option will remove all videos from Playlist as well as Offline mode storage.",
        comment: "Footer Text for the Playlist Settings Option for resetting Playlist.")

    public static let playlistSaveForOfflineErrorTitle =
      NSLocalizedString(
        "playlist.playlistSaveForOfflineErrorTitle",
        bundle: .braveShared,
        value: "Sorry, something went wrong",
        comment: "Title of alert when saving a playlist item for offline mode")

    public static let playlistSaveForOfflineErrorMessage =
      NSLocalizedString(
        "playlist.playlistSaveForOfflineErrorMessage",
        bundle: .braveShared,
        value: "Sorry, this item could not be saved for offline mode at this time.",
        comment: "Error message when saving a playlist item for offline fails")

    public static let playlistWebCompatibilityTitle =
      NSLocalizedString(
        "playlist.playlistWebCompatibilityTitle",
        bundle: .braveShared,
        value: "Web Compatibility",
        comment: "Title for Playlist setting")

    public static let playlistWebCompatibilityDescription =
      NSLocalizedString(
        "playlist.playlistWebCompatibilityDescription",
        bundle: .braveShared,
        value: "Disables the WebKit MediaSource API",
        comment: "Description for Playlist setting")

    public static let playlistLiveMediaStream =
      NSLocalizedString(
        "playlist.playlistLiveMediaStream",
        bundle: .braveShared,
        value: "Live Stream",
        comment: "When a video or audio is live and has no duration")

    public static let playlistDiskSpaceWarningTitle =
      NSLocalizedString(
        "playlist.playlistDiskSpaceWarningTitle",
        bundle: .braveShared,
        value: "Storage Almost Full",
        comment: "When the user's disk space is almost full")

    public static let playlistDiskSpaceWarningMessage =
      NSLocalizedString(
        "playlist.playlistDiskSpaceWarningMessage",
        bundle: .braveShared,
        value: "Adding video and audio files for offline use can use a lot of storage on your device. Please remove some files to free up storage space.",
        comment: "When the user's disk space is almost full")

    public static let playlistPopoverAddTitle =
      NSLocalizedString(
        "playlist.popoverAddTitle",
        bundle: .braveShared,
        value: "Would you like to add this media to your Brave Playlist?",
        comment: "Title of the popover that shows when you tap on the 'Add to Playlist' button in the URL bar")

    public static let playlistPopoverAddBody =
      NSLocalizedString(
        "playlist.popoverAddBody",
        bundle: .braveShared,
        value: "Brave Playlists support Offline Playback, Picture-in-picture, continuous playback and repeat modes.",
        comment: "Body of the popover that shows when you tap on the 'Add to Playlist' button in the URL bar")

    public static let playlistPopoverAddedTitle =
      NSLocalizedString(
        "playlist.popoverAddedTitle",
        bundle: .braveShared,
        value: "This media is in your Brave Playlist",
        comment: "Title of the popover that shows when you already have the current media item in your playlist and you tap on the 'Add to Playlist' button in the URL bar")

    public static let playlistPopoverOpenInBravePlaylist =
      NSLocalizedString(
        "playlist.popoverOpenInBravePlaylist",
        bundle: .braveShared,
        value: "Open In Brave Playlist",
        comment: "Button title in the popover when an item is already in your playlist and you tap the 'Add to Playlist' button in the URL bar")

    public static let playlistPopoverRemoveFromBravePlaylist =
      NSLocalizedString(
        "playlist.popoverRemoveFromBravePlaylist",
        bundle: .braveShared,
        value: "Remove",
        comment: "Button title in the popover when an item is already in your playlist and you tap the 'Add to Playlist' button in the URL bar")

    public static let playlistCarplayTitle =
      NSLocalizedString(
        "playlist.carplayTitle",
        bundle: .braveShared,
        value: "Brave Playlist",
        comment: "The title of the playlist when in Carplay mode")

    public static let playlistCarplaySettingsSectionTitle =
      NSLocalizedString(
        "playlist.carplaySettingsSectionTitle",
        bundle: .braveShared,
        value: "Settings",
        comment: "The title of the section containing settings/options in CarPlay")

    public static let playlistCarplayOptionsScreenTitle =
      NSLocalizedString(
        "playlist.carplayOptionsScreenTitle",
        bundle: .braveShared,
        value: "Playback Options",
        comment: "The title of the screen in CarPlay that contains all the audio/playback options")

    public static let playlistCarplayRestartPlaybackOptionTitle =
      NSLocalizedString(
        "playlist.carplayRestartPlaybackOptionTitle",
        bundle: .braveShared,
        value: "Restart Playback",
        comment: "The title of the checkbox that allows the user to restart audio/video playback")

    public static let playlistCarplayRestartPlaybackOptionDetailsTitle =
      NSLocalizedString(
        "playlist.carplayRestartPlaybackOptionDetailsTitle",
        bundle: .braveShared,
        value: "Decide whether or not selecting an already playing item will restart playback, or continue playing where last left off",
        comment: "The description of the checkbox that allows the user to restart audio/video playback")

    public static let playlistCarplayRestartPlaybackButtonStateEnabled =
      NSLocalizedString(
        "playlist.carplayRestartPlaybackButtonStateEnabled",
        bundle: .braveShared,
        value: "Enabled. Tap to disable playback restarting.",
        comment: "The already enabled button title with instructions telling the user they can tap it to disable playback.")

    public static let playlistCarplayRestartPlaybackButtonStateDisabled =
      NSLocalizedString(
        "playlist.carplayRestartPlaybackButtonStateDisabled",
        bundle: .braveShared,
        value: "Disabled. Tap to enable playback restarting.",
        comment: "The already disabled button title with instructions telling the user they can tap it to enable playback.")

    public static let playlistSaveForOfflineButtonTitle =
      NSLocalizedString(
        "playlist.saveForOfflineButtonTitle",
        bundle: .braveShared,
        value: "Save for Offline",
        comment: "The title of the button indicating that the user can save a video for offline playback. (playing without internet)")

    public static let playlistDeleteForOfflineButtonTitle =
      NSLocalizedString(
        "playlist.deleteForOfflineButtonTitle",
        bundle: .braveShared,
        value: "Delete Offline Cache",
        comment: "The title of the button indicating that the user delete the offline data. (deletes the data that allows them to play offline)")
  }

  public struct PlaylistFolders {
    public static let playlistSavedFolderTitle =
      NSLocalizedString(
        "playlistFolders.savedFolderTitle",
        bundle: .braveShared,
        value: "Saved",
        comment: "The title of the default playlist folder")

    public static let playlistUntitledFolderTitle =
      NSLocalizedString(
        "playlistFolders.untitledFolderTitle",
        bundle: .braveShared,
        value: "Untitled Folder",
        comment: "The title of a folder when the user enters no name (untitled)")

    public static let playlistEditFolderScreenTitle =
      NSLocalizedString(
        "playlistFolders.editFolderScreenTitle",
        bundle: .braveShared,
        value: "Edit Folder",
        comment: "The title of the screen where the user edits folder names")

    public static let playlistNewFolderScreenTitle =
      NSLocalizedString(
        "playlistFolders.newFolderScreenTitle",
        bundle: .braveShared,
        value: "New Folder",
        comment: "The title of the screen to create a new folder")

    public static let playlistNewFolderButtonTitle =
      NSLocalizedString(
        "playlistFolders.newFolderButtonTitle",
        bundle: .braveShared,
        value: "New Folder",
        comment: "The title of the button to create a new folder")

    public static let playlistCreateNewFolderButtonTitle =
      NSLocalizedString(
        "playlistFolders.createNewFolderButtonTitle",
        bundle: .braveShared,
        value: "Create",
        comment: "The title of the button to create a new folder")

    public static let playlistFolderSubtitleItemSingleCount =
      NSLocalizedString(
        "playlistFolders.subtitleItemSingleCount",
        bundle: .braveShared,
        value: "1 Item",
        comment: "The sub-title of the folder. Example: This folder contains ONE item. This folder contains 1 Item.")

    public static let playlistFolderSubtitleItemCount =
      NSLocalizedString(
        "playlistFolders.subtitleItemCount",
        bundle: .braveShared,
        value: "%lld Items",
        comment: "The sub-title of the folder. Example: This folder contains 10 Items. This folder contains 3 Items.")

    public static let playlistFolderErrorSavingMessage =
      NSLocalizedString(
        "playlistFolders.errorSavingMessage",
        bundle: .braveShared,
        value: "Sorry we were unable to save the changes you made to this folder",
        comment: "The error shown to the user when we cannot save their changes made on a folder")

    public static let playlistFolderEditMenuTitle =
      NSLocalizedString(
        "playlistFolders.editMenuTitle",
        bundle: .braveShared,
        value: "Edit Folder",
        comment: "The title of the menu option that allows the user to edit the name of a folder")

    public static let playlistFolderEditButtonTitle =
      NSLocalizedString(
        "playlistFolders.editButtonTitle",
        bundle: .braveShared,
        value: "Edit",
        comment: "The title of the button that allows the user to edit the name of a folder")

    public static let playlistFolderNewFolderSectionTitle =
      NSLocalizedString(
        "playlistFolders.newFolderSectionTitle",
        bundle: .braveShared,
        value: "Add videos to this folder",
        comment: "The title of the section where the user can select videos to add to the new folder being created")

    public static let playlistFolderNewFolderSectionSubtitle =
      NSLocalizedString(
        "playlistFolders.newFolderSectionSubtitle",
        bundle: .braveShared,
        value: "Tap to select videos",
        comment: "The sub-title of the section where the user can select videos to add to the new folder being created")

    public static let playlistFolderMoveFolderCurrentSectionTitle =
      NSLocalizedString(
        "playlistFolders.moveFolderCurrentSectionTitle",
        bundle: .braveShared,
        value: "Current Folder",
        comment: "The title of the section indicating the currently selected folder")

    public static let playlistFolderSelectAFolderTitle =
      NSLocalizedString(
        "playlistFolders.selectAFolderTitle",
        bundle: .braveShared,
        value: "Select a folder to move %lld items to",
        comment: "The title of the section indicating that the user should select a folder to move `%zu` items to. %lld should not be translated. It will be replaced by a number so the sentence becomes: 'Select a folder to move 10 items to.'")

    public static let playlistFolderSelectASingleFolderTitle =
      NSLocalizedString(
        "playlistFolders.selectASingleFolderTitle",
        bundle: .braveShared,
        value: "Select a folder to move 1 item to",
        comment: "The title of the section indicating that the user should select a folder to move 1 item to.")

    public static let playlistFolderMoveFolderScreenTitle =
      NSLocalizedString(
        "playlistFolders.moveFolderScreenTitle",
        bundle: .braveShared,
        value: "Move",
        comment: "The title of the screen where the user will move an item from one folder to another folder.")

    public static let playlistFolderMoveFolderButtonTitle =
      NSLocalizedString(
        "playlistFolders.moveFolderButtonTitle",
        bundle: .braveShared,
        value: "Move",
        comment: "The title of the button where the user will move an item from one folder to another folder.")

    public static let playlistFolderMoveItemDescription =
      NSLocalizedString(
        "playlistFolders.moveItemDescription",
        bundle: .braveShared,
        value: "%@ and 1 more item",
        comment: "%@ Should NOT be localized. It is a placeholder. Example: Brave Folder and 1 more item.")

    public static let playlistFolderMoveMultipleItemDescription =
      NSLocalizedString(
        "playlistFolders.moveMultipleItemDescription",
        bundle: .braveShared,
        value: "%@ and %lld more items",
        comment: "%@ and %lld Should NOT be localized. They are placeholders. Example: Brave Folder and 3 more items. Music and 2 more items.")

    public static let playlistFolderMoveItemWithNoNameTitle =
      NSLocalizedString(
        "playlistFolders.moveItemWithNoNameTitle",
        bundle: .braveShared,
        value: "1 item",
        comment: "Sometimes an item can have no name. So this is a generic title to use")

    public static let playlistFolderMoveItemWithMultipleNoNameTitle =
      NSLocalizedString(
        "playlistFolders.moveItemWithMultipleNoNameTitle",
        bundle: .braveShared,
        value: "%lld items",
        comment: "%lld is a placeholder and should not be localized. Sometimes items can have no name. So this is a generic title to use")
  }
}

// MARK: - SSL Certificate Viewer

extension Strings {
  public struct CertificateViewer {
    public static let certificateIsValidTitle =
      NSLocalizedString(
        "certificateViewer.certificateIsValidTitle",
        bundle: .braveShared,
        value: "This certificate is valid",
        comment: "The description for when an SSL certificate is valid")
    
    public static let subjectNameTitle =
      NSLocalizedString(
        "certificateViewer.subjectNameTitle",
        bundle: .braveShared,
        value: "Subject Name",
        comment: "Section Title for Subject Name in the SSL Certificate")

    public static let issuerNameTitle =
      NSLocalizedString(
        "certificateViewer.issuerNameTitle",
        bundle: .braveShared,
        value: "Issuer Name",
        comment: "Section Title for Issuer Name in the SSL Certificate")

    public static let commonInfoTitle =
      NSLocalizedString(
        "certificateViewer.commonInfoTitle",
        bundle: .braveShared,
        value: "Common Info",
        comment: "Section Title displaying common information")

    public static let serialNumberTitle =
      NSLocalizedString(
        "certificateViewer.serialNumberTitle",
        bundle: .braveShared,
        value: "Serial Number",
        comment: "Certificates have a serial number to identify that it's unique")

    public static let versionNumberTitle =
      NSLocalizedString(
        "certificateViewer.versionNumberTitle",
        bundle: .braveShared,
        value: "Version",
        comment: "Certificates have a version number")

    public static let signatureAlgorithmTitle =
      NSLocalizedString(
        "certificateViewer.signatureAlgorithmTitle",
        bundle: .braveShared,
        value: "Signature Algorithm",
        comment: "Title for the section where we display information about the algorithm used to sign the certificate")

    public static let signatureAlgorithmSignatureDescription =
      NSLocalizedString(
        "certificateViewer.signatureAlgorithmSignatureDescription",
        bundle: .braveShared,
        value: "%@ Signature with %@",
        comment: "Do NOT translate the %@. They are place holders. Example: 'ECDSA Signature' with 'SHA-256'")

    public static let signatureAlgorithmEncryptionDescription =
      NSLocalizedString(
        "certificateViewer.signatureAlgorithmEncryptionDescription",
        bundle: .braveShared,
        value: "%@ with %@ Encryption",
        comment: "Do NOT translate the %@. They are place holders. Example: 'SHA256' with 'RSA' Encryption")

    public static let validityDatesTitle =
      NSLocalizedString(
        "certificateViewer.validityDatesTitle",
        bundle: .braveShared,
        value: "Validity Dates",
        comment: "Title of section that determines if the dates on a certificate is valid.")

    public static let notValidBeforeTitle =
      NSLocalizedString(
        "certificateViewer.notValidBeforeTitle",
        bundle: .braveShared,
        value: "Not Valid Before",
        comment: "Certificate is 'not valid before' January 1st, 2022 for example.")

    public static let notValidAfterTitle =
      NSLocalizedString(
        "certificateViewer.notValidAfterTitle",
        bundle: .braveShared,
        value: "Not Valid After",
        comment: "Certificate is 'not valid after' January 31st, 2022 for example.")

    public static let publicKeyInfoTitle =
      NSLocalizedString(
        "certificateViewer.publicKeyInfoTitle",
        bundle: .braveShared,
        value: "Public Key Info",
        comment: "Information about a Public Key section title.")

    public static let signatureTitle =
      NSLocalizedString(
        "certificateViewer.signatureTitle",
        bundle: .braveShared,
        value: "Signature",
        comment: "Title of the view that states whether or not something was signed with an encryption algorithm or hash.")

    public static let fingerPrintsTitle =
      NSLocalizedString(
        "certificateViewer.fingerPrintsTitle",
        bundle: .braveShared,
        value: "Fingerprints",
        comment: "Fingerprints/Hashes are algorithms used to determine if the certificate is legitimate")

    public static let countryOrRegionTitle =
      NSLocalizedString(
        "certificateViewer.countryOrRegionTitle",
        bundle: .braveShared,
        value: "Country or Region",
        comment: "Title of the section for the certificate's issuing country or region. Example: Canada, or USA")

    public static let stateOrProvinceTitle =
      NSLocalizedString(
        "certificateViewer.stateOrProvinceTitle",
        bundle: .braveShared,
        value: "State/Province",
        comment: "Title of the section for the certificate's issuing state or province. Example: Ontario Province or California State")

    public static let localityTitle =
      NSLocalizedString(
        "certificateViewer.localityTitle",
        bundle: .braveShared,
        value: "Locality",
        comment: "Title of the section for the certificate's issuing city. Example: Toronto, New York, or San Francisco")

    public static let organizationTitle =
      NSLocalizedString(
        "certificateViewer.organizationTitle",
        bundle: .braveShared,
        value: "Organization",
        comment: "Title of the section for Name of the Company. Example: Brave Inc.")

    public static let organizationalUnitTitle =
      NSLocalizedString(
        "certificateViewer.organizationalUnitTitle",
        bundle: .braveShared,
        value: "Organizational Unit",
        comment: "Title of the section for Department of the Company. Example: Human Resources.")

    public static let commonNameTitle =
      NSLocalizedString(
        "certificateViewer.commonNameTitle",
        bundle: .braveShared,
        value: "Common Name",
        comment: "Title of the section for Commonly used Name for the certificate. Example: Alias, Commonly used name, DigiCert High Assurance TLS.")

    public static let streetAddressTitle =
      NSLocalizedString(
        "certificateViewer.streetAddressTitle",
        bundle: .braveShared,
        value: "Street Address",
        comment: "Title of the section for the address of where the certificate came from.")

    public static let domainComponentTitle =
      NSLocalizedString(
        "certificateViewer.domainComponentTitle",
        bundle: .braveShared,
        value: "Domain Component",
        comment: "Title of the section for the Domain Component such as: DNS or brave.com or a website's domain.")

    public static let userIDTitle =
      NSLocalizedString(
        "certificateViewer.userIDTitle",
        bundle: .braveShared,
        value: "User ID",
        comment: "Title of the section for the User's ID (Identifier).")

    public static let noneTitle =
      NSLocalizedString(
        "certificateViewer.noneTitle",
        bundle: .braveShared,
        value: "None",
        comment: "Title indicating 'None' or no information or empty.")

    public static let parametersTitle =
      NSLocalizedString(
        "certificateViewer.parametersTitle",
        bundle: .braveShared,
        value: "Parameters",
        comment: "Title indicating 'Parameters' or Input passed to a function/algorithm.")

    public static let encryptionTitle =
      NSLocalizedString(
        "certificateViewer.encryptionTitle",
        bundle: .braveShared,
        value: "Encryption",
        comment: "Title of the section indication which 'Encryption' algorithm was used.")

    public static let bytesUnitTitle =
      NSLocalizedString(
        "certificateViewer.bytesUnitTitle",
        bundle: .braveShared,
        value: "bytes",
        comment: "A measurement unit used in computing to indicate or how memory is used.")

    public static let bitsUnitTitle =
      NSLocalizedString(
        "certificateViewer.bitsUnitTitle",
        bundle: .braveShared,
        value: "bits",
        comment: "A measurement unit used in computing to indicate or how memory is used.")

    public static let encryptTitle =
      NSLocalizedString(
        "certificateViewer.encryptTitle",
        bundle: .braveShared,
        value: "Encrypt",
        comment: "Title indicating whether or not a private key can be used to encrypt data")

    public static let verifyTitle =
      NSLocalizedString(
        "certificateViewer.verifyTitle",
        bundle: .braveShared,
        value: "Verify",
        comment: "Title indicating whether or not a private key can be used to verify data is legitimate")

    public static let wrapTitle =
      NSLocalizedString(
        "certificateViewer.wrapTitle",
        bundle: .braveShared,
        value: "Wrap",
        comment: "Title indicating whether or not a private key can be used to wrap or enclose some data")

    public static let deriveTitle =
      NSLocalizedString(
        "certificateViewer.deriveTitle",
        bundle: .braveShared,
        value: "Derive",
        comment: "Title indicating whether or not a private key can be used to derive some data from another piece of data. IE: Use one key to generate another")

    public static let anyTitle =
      NSLocalizedString(
        "certificateViewer.anyTitle",
        bundle: .braveShared,
        value: "Any",
        comment: "Title indicating whether or not a private key can be used for 'Anything' (encrypting, deriving, wrapping, verifying, signing, etc)")

    public static let algorithmTitle =
      NSLocalizedString(
        "certificateViewer.algorithmTitle",
        bundle: .braveShared,
        value: "Algorithm",
        comment: "Title indicating whether the section for the algorithm used")

    public static let publicKeyTitle =
      NSLocalizedString(
        "certificateViewer.publicKeyTitle",
        bundle: .braveShared,
        value: "Public Key",
        comment: "Title indicating whether the key used is public (not private)")

    public static let exponentTitle =
      NSLocalizedString(
        "certificateViewer.exponentTitle",
        bundle: .braveShared,
        value: "Exponent",
        comment: "Title indicating whether the mathematical exponent used. x³, x², etc.")

    public static let keySizeTitle =
      NSLocalizedString(
        "certificateViewer.keySizeTitle",
        bundle: .braveShared,
        value: "Key Size",
        comment: "Title indicating the size of the private or public key used in bytes. Example: KeySize - 1024 Bytes. Key Size - 2048 Bytes.")

    public static let keyUsageTitle =
      NSLocalizedString(
        "certificateViewer.keyUsageTitle",
        bundle: .braveShared,
        value: "Key Usage",
        comment: "Title indicating what the private or public key can be used for.")
  }
}

// MARK: - Shortcuts

extension Strings {
  public struct Shortcuts {
    public static let activityTypeNewTabTitle =
      NSLocalizedString(
        "shortcuts.activityTypeNewTabTitle",
        bundle: .braveShared,
        value: "Open a New Browser Tab",
        comment: "")

    public static let activityTypeNewPrivateTabTitle =
      NSLocalizedString(
        "shortcuts.activityTypeNewPrivateTabTitle",
        bundle: .braveShared,
        value: "Open a New Private Browser Tab",
        comment: "")

    public static let activityTypeClearHistoryTitle =
      NSLocalizedString(
        "shortcuts.activityTypeClearHistoryTitle",
        bundle: .braveShared,
        value: "Clear Brave Browsing History",
        comment: "")

    public static let activityTypeEnableVPNTitle =
      NSLocalizedString(
        "shortcuts.activityTypeEnableVPNTitle",
        bundle: .braveShared,
        value: "Open Brave Browser and Enable VPN",
        comment: "")

    public static let activityTypeOpenBraveNewsTitle =
      NSLocalizedString(
        "shortcuts.activityTypeOpenBraveNewsTitle",
        bundle: .braveShared,
        value: "Open Brave News",
        comment: "")

    public static let activityTypeOpenPlaylistTitle =
      NSLocalizedString(
        "shortcuts.activityTypeOpenPlaylistTitle",
        bundle: .braveShared,
        value: "Open Playlist",
        comment: "")

    public static let activityTypeTabDescription =
      NSLocalizedString(
        "shortcuts.activityTypeTabDescription",
        bundle: .braveShared,
        value: "Start Searching the Web Securely with Brave",
        comment: "")

    public static let activityTypeClearHistoryDescription =
      NSLocalizedString(
        "shortcuts.activityTypeClearHistoryDescription",
        bundle: .braveShared,
        value: "Open Browser in a New Tab and Delete All Private Browser History Data",
        comment: "")

    public static let activityTypeEnableVPNDescription =
      NSLocalizedString(
        "shortcuts.activityTypeEnableVPNDescription",
        bundle: .braveShared,
        value: "Open Browser in a New Tab and Enable VPN",
        comment: "")

    public static let activityTypeBraveNewsDescription =
      NSLocalizedString(
        "shortcuts.activityTypeBraveNewsDescription",
        bundle: .braveShared,
        value: "Open Brave News and Check Today's Top Stories",
        comment: "")

    public static let activityTypeOpenPlaylistDescription =
      NSLocalizedString(
        "shortcuts.activityTypeOpenPlaylistDescription",
        bundle: .braveShared,
        value: "Start Playing your Videos in Playlist",
        comment: "")

    public static let activityTypeNewTabSuggestedPhrase =
      NSLocalizedString(
        "shortcuts.activityTypeNewTabSuggestedPhrase",
        bundle: .braveShared,
        value: "Open New Tab",
        comment: "")

    public static let activityTypeNewPrivateTabSuggestedPhrase =
      NSLocalizedString(
        "shortcuts.activityTypeNewPrivateTabSuggestedPhrase",
        bundle: .braveShared,
        value: "Open New Private Tab",
        comment: "")

    public static let activityTypeClearHistorySuggestedPhrase =
      NSLocalizedString(
        "shortcuts.activityTypeClearHistorySuggestedPhrase",
        bundle: .braveShared,
        value: "Clear Browser History",
        comment: "")

    public static let activityTypeEnableVPNSuggestedPhrase =
      NSLocalizedString(
        "shortcuts.activityTypeEnableVPNSuggestedPhrase",
        bundle: .braveShared,
        value: "Enable VPN",
        comment: "")

    public static let activityTypeOpenBraveNewsSuggestedPhrase =
      NSLocalizedString(
        "shortcuts.activityTypeOpenBraveTodaySuggestedPhrase",
        bundle: .braveShared,
        value: "Open Brave News",
        comment: "")

    public static let activityTypeOpenPlaylistSuggestedPhrase =
      NSLocalizedString(
        "shortcuts.activityTypeOpenPlaylistSuggestedPhrase",
        bundle: .braveShared,
        value: "Open Playlist",
        comment: "")

    public static let customIntentOpenWebsiteSuggestedPhrase =
      NSLocalizedString(
        "shortcuts.customIntentOpenWebsiteSuggestedPhrase",
        bundle: .braveShared,
        value: "Open Website",
        comment: "")

    public static let customIntentOpenHistorySuggestedPhrase =
      NSLocalizedString(
        "shortcuts.customIntentOpenHistorySuggestedPhrase",
        bundle: .braveShared,
        value: "Open History Website",
        comment: "")

    public static let customIntentOpenBookmarkSuggestedPhrase =
      NSLocalizedString(
        "shortcuts.customIntentOpenBookmarkSuggestedPhrase",
        bundle: .braveShared,
        value: "Open Bookmark Website",
        comment: "")

    public static let shortcutSettingsTitle =
      NSLocalizedString(
        "shortcuts.shortcutSettingsTitle",
        bundle: .braveShared,
        value: "Siri Shortcuts",
        comment: "")

    public static let shortcutSettingsOpenNewTabTitle =
      NSLocalizedString(
        "shortcuts.shortcutSettingsOpenNewTabTitle",
        bundle: .braveShared,
        value: "Open New Tab",
        comment: "")

    public static let shortcutSettingsOpenNewTabDescription =
      NSLocalizedString(
        "shortcuts.shortcutSettingsOpenNewTabDescription",
        bundle: .braveShared,
        value: "Use Shortcuts to open a new tab via Siri - Voice Assistant",
        comment: "")

    public static let shortcutSettingsOpenNewPrivateTabTitle =
      NSLocalizedString(
        "shortcuts.shortcutSettingsOpenNewPrivateTabTitle",
        bundle: .braveShared,
        value: "Open New Private Tab",
        comment: "")

    public static let shortcutSettingsOpenNewPrivateTabDescription =
      NSLocalizedString(
        "shortcuts.shortcutSettingsOpenNewPrivateTabDescription",
        bundle: .braveShared,
        value: "Use Shortcuts to open a new private tab via Siri - Voice Assistant",
        comment: "")

    public static let shortcutSettingsClearBrowserHistoryTitle =
      NSLocalizedString(
        "shortcuts.shortcutSettingsClearBrowserHistoryTitle",
        bundle: .braveShared,
        value: "Clear Browser History",
        comment: "")

    public static let shortcutSettingsClearBrowserHistoryDescription =
      NSLocalizedString(
        "shortcuts.shortcutSettingsClearBrowserHistoryDescription",
        bundle: .braveShared,
        value: "Use Shortcuts to open a new tab & clear browser history via Siri - Voice Assistant",
        comment: "Description of Clear Browser History Siri Shortcut in Settings Screen")

    public static let shortcutSettingsEnableVPNTitle =
      NSLocalizedString(
        "shortcuts.shortcutSettingsEnableVPNTitle",
        bundle: .braveShared,
        value: "Enable VPN",
        comment: "")

    public static let shortcutSettingsEnableVPNDescription =
      NSLocalizedString(
        "shortcuts.shortcutSettingsEnableVPNDescription",
        bundle: .braveShared,
        value: "Use Shortcuts to enable Brave VPN via Siri - Voice Assistant",
        comment: "")

    public static let shortcutSettingsOpenBraveNewsTitle =
      NSLocalizedString(
        "shortcuts.shortcutSettingsOpenBraveNewsTitle",
        bundle: .braveShared,
        value: "Open Brave News",
        comment: "")

    public static let shortcutSettingsOpenBraveNewsDescription =
      NSLocalizedString(
        "shortcuts.shortcutSettingsOpenBraveNewsDescription",
        bundle: .braveShared,
        value: "Use Shortcuts to open a new tab & show Brave News Feed via Siri - Voice Assistant",
        comment: "Description of Open Brave News Siri Shortcut in Settings Screen")

    public static let shortcutSettingsOpenPlaylistTitle =
      NSLocalizedString(
        "shortcuts.shortcutSettingsOpenPlaylistTitle",
        bundle: .braveShared,
        value: "Open Playlist",
        comment: "")

    public static let shortcutSettingsOpenPlaylistDescription =
      NSLocalizedString(
        "shortcuts.shortcutSettingsOpenPlaylistDescription",
        bundle: .braveShared,
        value: "Use Shortcuts to open Playlist via Siri - Voice Assistant",
        comment: "Description of Open Playlist Siri Shortcut in Settings Screen")

    public static let shortcutOpenApplicationSettingsTitle =
      NSLocalizedString(
        "shortcuts.shortcutOpenApplicationSettingsTitle",
        bundle: .braveShared,
        value: "Open Settings",
        comment: "Button title that open application settings")

    public static let shortcutOpenApplicationSettingsDescription =
      NSLocalizedString(
        "shortcuts.shortcutOpenApplicationSettingsDescription",
        bundle: .braveShared,
        value: "This option will open Brave Settings. In order to change various Siri options, please select 'Siri & Search' menu item and customize your choices.",
        comment: "Description for opening Brave Settings for altering Siri shortcut.")
  }
}

// MARK: - VPN
extension Strings {
  public struct VPN {
    public static let vpnName =
      NSLocalizedString(
        "vpn.buyVPNTitle",
        bundle: .braveShared,
        value: "Brave Firewall + VPN",
        comment: "Title for screen to buy the VPN.")

    public static let poweredBy =
      NSLocalizedString(
        "vpn.poweredBy",
        bundle: .braveShared,
        value: "Powered by",
        comment: "It is used in context: 'Powered by BRAND_NAME'")

    public static let freeTrial =
      NSLocalizedString(
        "vpn.freeTrial",
        bundle: .braveShared,
        value: "All plans include a free 7-day trial!",
        comment: "")

    public static let restorePurchases =
      NSLocalizedString(
        "vpn.restorePurchases",
        bundle: .braveShared,
        value: "Restore",
        comment: "")

    public static let monthlySubTitle =
      NSLocalizedString(
        "vpn.monthlySubTitle",
        bundle: .braveShared,
        value: "Monthly Subscription",
        comment: "")

    public static let monthlySubDetail =
      NSLocalizedString(
        "vpn.monthlySubDetail",
        bundle: .braveShared,
        value: "Renews monthly",
        comment: "Used in context: 'Monthly subscription, (it) renews monthly'")

    public static let yearlySubTitle =
      NSLocalizedString(
        "vpn.yearlySubTitle",
        bundle: .braveShared,
        value: "One year",
        comment: "One year lenght vpn subcription")

    public static let yearlySubDetail =
      NSLocalizedString(
        "vpn.yearlySubDetail",
        bundle: .braveShared,
        value: "Renew annually save %@",
        comment: "Used in context: 'yearly subscription, renew annually (to) save 16%'. The placeholder is for percent value")

    public static let yearlySubDisclaimer =
      NSLocalizedString(
        "vpn.yearlySubDisclaimer",
        bundle: .braveShared,
        value: "Best value",
        comment: "It's like when there's few subscription plans, and one plan has the best value to price ratio, so this label says next to that plan: '(plan) - Best value'")

    // MARK: Checkboxes
    public static let checkboxBlockAds =
      NSLocalizedString(
        "vpn.checkboxBlockAds",
        bundle: .braveShared,
        value: "Blocks unwanted network connections",
        comment: "Text for a checkbox to present the user benefits for using Brave VPN")

    public static let checkboxGeoSelector =
      NSLocalizedString(
        "vpn.checkboxGeoSelector",
        bundle: .braveShared,
        value: "Choose your geo/country location",
        comment: "Text for a checkbox to present the user benefits for using Brave VPN")

    public static let checkboxFast =
      NSLocalizedString(
        "vpn.checkboxFast",
        bundle: .braveShared,
        value: "Supports speeds of up to 100 Mbps",
        comment: "Text for a checkbox to present the user benefits for using Brave VPN")

    public static let checkboxNoSellout =
      NSLocalizedString(
        "vpn.checkboxNoSellout",
        bundle: .braveShared,
        value: "We never share or sell your info",
        comment: "Text for a checkbox to present the user benefits for using Brave VPN")

    public static let checkboxNoIPLog =
      NSLocalizedString(
        "vpn.checkboxNoIPLog",
        bundle: .braveShared,
        value: "Keeps you anonymous online",
        comment: "Text for a checkbox to present the user benefits for using Brave VPN")

    public static let checkboxEncryption =
      NSLocalizedString(
        "vpn.checkboxEncryption",
        bundle: .braveShared,
        value: "Uses IKEv2 secure encrypted VPN tunnel",
        comment: "Text for a checkbox to present the user benefits for using Brave VPN")

    public static let installTitle =
      NSLocalizedString(
        "vpn.installTitle",
        bundle: .braveShared,
        value: "Install VPN",
        comment: "Title for screen to install the VPN.")

    public static let installProfileTitle =
      NSLocalizedString(
        "vpn.installProfileTitle",
        bundle: .braveShared,
        value: "Brave will now install a VPN profile.",
        comment: "")

    public static let popupCheckmarkSecureConnections =
      NSLocalizedString(
        "vpn.popupCheckmarkSecureConnections",
        bundle: .braveShared,
        value: "Secures all connections",
        comment: "Text for a checkbox to present the user benefits for using Brave VPN")

    public static let popupCheckmark247Support =
      NSLocalizedString(
        "vpn.popupCheckmark247Support",
        bundle: .braveShared,
        value: "24/7 support",
        comment: "Text for a checkbox to present the user benefits for using Brave VPN")

    public static let installProfileBody =
      NSLocalizedString(
        "vpn.installProfileBody",
        bundle: .braveShared,
        value: "This profile allows the VPN to automatically connect and secure traffic across your device all the time. This VPN connection will be encrypted and routed through Brave's intelligent firewall to block potentially harmful and invasive connections.",
        comment: "Text explaining how the VPN works.")

    public static let installProfileButtonText =
      NSLocalizedString(
        "vpn.installProfileButtonText",
        bundle: .braveShared,
        value: "Install VPN Profile",
        comment: "Text for 'install vpn profile' button")

    public static let settingsVPNEnabled =
      NSLocalizedString(
        "vpn.settingsVPNEnabled",
        bundle: .braveShared,
        value: "Enabled",
        comment: "Whether the VPN is enabled or not")

    public static let settingsVPNExpired =
      NSLocalizedString(
        "vpn.settingsVPNExpired",
        bundle: .braveShared,
        value: "Expired",
        comment: "Whether the VPN plan has expired")

    public static let settingsVPNDisabled =
      NSLocalizedString(
        "vpn.settingsVPNDisabled",
        bundle: .braveShared,
        value: "Disabled",
        comment: "Whether the VPN is enabled or not")

    public static let settingsSubscriptionSection =
      NSLocalizedString(
        "vpn.settingsSubscriptionSection",
        bundle: .braveShared,
        value: "Subscription",
        comment: "Header title for vpn settings subscription section.")

    public static let settingsServerSection =
      NSLocalizedString(
        "vpn.settingsServerSection",
        bundle: .braveShared,
        value: "Server",
        comment: "Header title for vpn settings server section.")

    public static let settingsSubscriptionStatus =
      NSLocalizedString(
        "vpn.settingsSubscriptionStatus",
        bundle: .braveShared,
        value: "Status",
        comment: "Table cell title for status of current VPN subscription.")

    public static let settingsSubscriptionExpiration =
      NSLocalizedString(
        "vpn.settingsSubscriptionExpiration",
        bundle: .braveShared,
        value: "Expires",
        comment: "Table cell title for cell that shows when the VPN subscription expires.")

    public static let settingsManageSubscription =
      NSLocalizedString(
        "vpn.settingsManageSubscription",
        bundle: .braveShared,
        value: "Manage Subscription",
        comment: "Button to manage your VPN subscription")

    public static let settingsServerHost =
      NSLocalizedString(
        "vpn.settingsServerHost",
        bundle: .braveShared,
        value: "Host",
        comment: "Table cell title for vpn's server host")

    public static let settingsServerLocation =
      NSLocalizedString(
        "vpn.settingsServerLocation",
        bundle: .braveShared,
        value: "Location",
        comment: "Table cell title for vpn's server location")

    public static let settingsResetConfiguration =
      NSLocalizedString(
        "vpn.settingsResetConfiguration",
        bundle: .braveShared,
        value: "Reset Configuration",
        comment: "Button to reset VPN configuration")

    public static let settingsChangeLocation =
      NSLocalizedString(
        "vpn.settingsChangeLocation",
        bundle: .braveShared,
        value: "Change Location",
        comment: "Button to change VPN server location")

    public static let settingsContactSupport =
      NSLocalizedString(
        "vpn.settingsContactSupport",
        bundle: .braveShared,
        value: "Contact Technical Support",
        comment: "Button to contact tech support")

    public static let settingsFAQ =
      NSLocalizedString(
        "vpn.settingsFAQ",
        bundle: .braveShared,
        value: "VPN Support",
        comment: "Button for FAQ")

    public static let enableButton =
      NSLocalizedString(
        "vpn.enableButton",
        bundle: .braveShared,
        value: "Enable",
        comment: "Button text to enable Brave VPN")

    public static let buyButton =
      NSLocalizedString(
        "vpn.buyButton",
        bundle: .braveShared,
        value: "Buy",
        comment: "Button text to buy Brave VPN")

    public static let tryForFreeButton =
      NSLocalizedString(
        "vpn.learnMore",
        bundle: .braveShared,
        value: "Try for FREE",
        comment: "Button text to try free Brave VPN")

    public static let settingHeaderBody =
      NSLocalizedString(
        "vpn.settingHeaderBody",
        bundle: .braveShared,
        value: "Upgrade to a VPN to protect your connection and block invasive trackers everywhere.",
        comment: "VPN Banner Description")

    public static let errorCantGetPricesTitle =
      NSLocalizedString(
        "vpn.errorCantGetPricesTitle",
        bundle: .braveShared,
        value: "App Store Error",
        comment: "Title for an alert when the VPN can't get prices from the App Store")

    public static let errorCantGetPricesBody =
      NSLocalizedString(
        "vpn.errorCantGetPricesBody",
        bundle: .braveShared,
        value: "Could not connect to the App Store, please try again in few minutes.",
        comment: "Message for an alert when the VPN can't get prices from the App Store")

    public static let vpnConfigGenericErrorTitle =
      NSLocalizedString(
        "vpn.vpnConfigGenericErrorTitle",
        bundle: .braveShared,
        value: "Error",
        comment: "Title for an alert when the VPN can't be configured")

    public static let vpnConfigGenericErrorBody =
      NSLocalizedString(
        "vpn.vpnConfigGenericErrorBody",
        bundle: .braveShared,
        value: "There was a problem initializing the VPN. Please try again or try resetting configuration in the VPN settings page.",
        comment: "Message for an alert when the VPN can't be configured.")

    public static let vpnConfigPermissionDeniedErrorTitle =
      NSLocalizedString(
        "vpn.vpnConfigPermissionDeniedErrorTitle",
        bundle: .braveShared,
        value: "Permission denied",
        comment: "Title for an alert when the user didn't allow to install VPN profile")

    public static let vpnConfigPermissionDeniedErrorBody =
      NSLocalizedString(
        "vpn.vpnConfigPermissionDeniedErrorBody",
        bundle: .braveShared,
        value: "The Brave Firewall + VPN requires a VPN profile to be installed on your device to work. ",
        comment: "Title for an alert when the user didn't allow to install VPN profile")

    public static let vpnSettingsMonthlySubName =
      NSLocalizedString(
        "vpn.vpnSettingsMonthlySubName",
        bundle: .braveShared,
        value: "Monthly subscription",
        comment: "Name of monthly subscription in VPN Settings")

    public static let vpnSettingsYearlySubName =
      NSLocalizedString(
        "vpn.vpnSettingsYearlySubName",
        bundle: .braveShared,
        value: "Yearly subscription",
        comment: "Name of annual subscription in VPN Settings")

    public static let vpnErrorPurchaseFailedTitle =
      NSLocalizedString(
        "vpn.vpnErrorPurchaseFailedTitle",
        bundle: .braveShared,
        value: "Error",
        comment: "Title for error when VPN could not be purchased.")

    public static let vpnErrorPurchaseFailedBody =
      NSLocalizedString(
        "vpn.vpnErrorPurchaseFailedBody",
        bundle: .braveShared,
        value: "Unable to complete purchase. Please try again, or check your payment details on Apple and try again.",
        comment: "Message for error when VPN could not be purchased.")

    public static let vpnResetAlertTitle =
      NSLocalizedString(
        "vpn.vpnResetAlertTitle",
        bundle: .braveShared,
        value: "Reset configuration",
        comment: "Title for alert to reset vpn configuration")

    public static let vpnResetAlertBody =
      NSLocalizedString(
        "vpn.vpnResetAlertBody",
        bundle: .braveShared,
        value: "This will reset your Brave Firewall + VPN configuration and fix any errors. This process may take a minute.",
        comment: "Message for alert to reset vpn configuration")

    public static let vpnResetButton =
      NSLocalizedString(
        "vpn.vpnResetButton",
        bundle: .braveShared,
        value: "Reset",
        comment: "Button name to reset vpn configuration")

    public static let contactFormHostname =
      NSLocalizedString(
        "vpn.contactFormHostname",
        bundle: .braveShared,
        value: "VPN Hostname",
        comment: "VPN Hostname field for customer support contact form.")

    public static let contactFormSubscriptionType =
      NSLocalizedString(
        "vpn.contactFormSubscriptionType",
        bundle: .braveShared,
        value: "Subscription Type",
        comment: "Subscription Type field for customer support contact form.")

    public static let contactFormAppStoreReceipt =
      NSLocalizedString(
        "vpn.contactFormAppStoreReceipt",
        bundle: .braveShared,
        value: "AppStore Receipt",
        comment: "AppStore Receipt field for customer support contact form.")

    public static let contactFormAppVersion =
      NSLocalizedString(
        "vpn.contactFormAppVersion",
        bundle: .braveShared,
        value: "App Version",
        comment: "App Version field for customer support contact form.")

    public static let contactFormTimezone =
      NSLocalizedString(
        "vpn.contactFormTimezone",
        bundle: .braveShared,
        value: "iOS Timezone",
        comment: "iOS Timezone field for customer support contact form.")

    public static let contactFormNetworkType =
      NSLocalizedString(
        "vpn.contactFormNetworkType",
        bundle: .braveShared,
        value: "Network Type",
        comment: "Network Type field for customer support contact form.")

    public static let contactFormCarrier =
      NSLocalizedString(
        "vpn.contactFormCarrier",
        bundle: .braveShared,
        value: "Cellular Carrier",
        comment: "Cellular Carrier field for customer support contact form.")

    public static let contactFormLogs =
      NSLocalizedString(
        "vpn.contactFormLogs",
        bundle: .braveShared,
        value: "Error Logs",
        comment: "VPN logs field for customer support contact form.")

    public static let contactFormIssue =
      NSLocalizedString(
        "vpn.contactFormIssue",
        bundle: .braveShared,
        value: "Issue",
        comment: "Specific issue field for customer support contact form.")

    public static let contactFormFooterSharedWithGuardian =
      NSLocalizedString(
        "vpn.contactFormFooterSharedWithGuardian",
        bundle: .braveShared,
        value: "Support provided with the help of the Guardian team.",
        comment: "Footer for customer support contact form.")

    public static let contactFormFooter =
      NSLocalizedString(
        "vpn.contactFormFooter",
        bundle: .braveShared,
        value: "Please select the information you're comfortable sharing with us.\n\nThe more information you initially share with us the easier it will be for our support staff to help you resolve your issue.",
        comment: "Footer for customer support contact form.")

    public static let contactFormSendButton =
      NSLocalizedString(
        "vpn.contactFormSendButton",
        bundle: .braveShared,
        value: "Continue to Email",
        comment: "Button name to send contact form.")

    public static let contactFormIssueOtherConnectionError =
      NSLocalizedString(
        "vpn.contactFormIssueOtherConnectionError",
        bundle: .braveShared,
        value: "Cannot connect to the VPN (Other error)",
        comment: "Other connection problem for contact form issue field.")

    public static let contactFormIssueNoInternet =
      NSLocalizedString(
        "vpn.contactFormIssueNoInternet",
        bundle: .braveShared,
        value: "No internet when connected",
        comment: "No internet problem for contact form issue field.")

    public static let contactFormIssueSlowConnection =
      NSLocalizedString(
        "vpn.contactFormIssueSlowConnection",
        bundle: .braveShared,
        value: "Slow connection",
        comment: "Slow connection problem for contact form issue field.")

    public static let contactFormIssueWebsiteProblems =
      NSLocalizedString(
        "vpn.contactFormIssueWebsiteProblems",
        bundle: .braveShared,
        value: "Website doesn't work",
        comment: "Website problem for contact form issue field.")

    public static let contactFormIssueConnectionReliability =
      NSLocalizedString(
        "vpn.contactFormIssueConnectionReliability",
        bundle: .braveShared,
        value: "Connection reliability problem",
        comment: "Connection problems for contact form issue field.")

    public static let contactFormIssueOther =
      NSLocalizedString(
        "vpn.contactFormIssueOther",
        bundle: .braveShared,
        value: "Other",
        comment: "Other problem for contact form issue field.")

    public static let subscriptionStatusExpired =
      NSLocalizedString(
        "vpn.planExpired",
        bundle: .braveShared,
        value: "Expired",
        comment: "Text to show user when their vpn plan has expired")

    public static let resetVPNErrorTitle =
      NSLocalizedString(
        "vpn.resetVPNErrorTitle",
        bundle: .braveShared,
        value: "Error",
        comment: "Title for error message when vpn configuration reset fails.")

    public static let resetVPNErrorBody =
      NSLocalizedString(
        "vpn.resetVPNErrorBody",
        bundle: .braveShared,
        value: "Failed to reset vpn configuration, please try again later.",
        comment: "Message to show when vpn configuration reset fails.")

    public static let contactFormDoNotEditText =
      NSLocalizedString(
        "vpn.contactFormDoNotEditText",
        bundle: .braveShared,
        value: "Please do not edit any information below",
        comment: "Text to tell user to not modify support info below email's body.")

    public static let contactFormTitle =
      NSLocalizedString(
        "vpn.contactFormTitle",
        bundle: .braveShared,
        value: "Brave Firewall + VPN Issue",
        comment: "Title for contact form email.")

    public static let freeTrialDisclaimer =
      NSLocalizedString(
        "vpn.freeTrialDisclaimer",
        bundle: .braveShared,
        value: "Try free for 7 days. After 7 days, you will be charged the plan price. ",
        comment: "Disclaimer about free trial")

    public static let iapDisclaimer =
      NSLocalizedString(
        "vpn.iapDisclaimer",
        bundle: .braveShared,
        value: "All subscriptions are auto-renewed but can be cancelled before renewal.",
        comment: "Disclaimer about in app subscription")

    public static let installSuccessPopup =
      NSLocalizedString(
        "vpn.installSuccessPopup",
        bundle: .braveShared,
        value: "VPN is now enabled",
        comment: "Popup that shows after user installs the vpn for the first time.")

    public static let vpnBackgroundNotificationTitle =
      NSLocalizedString(
        "vpn.vpnBackgroundNotificationTitle",
        bundle: .braveShared,
        value: "Brave Firewall + VPN is ON",
        comment: "Notification title to tell user that the vpn is turned on even in background")

    public static let vpnBackgroundNotificationBody =
      NSLocalizedString(
        "vpn.vpnBackgroundNotificationBody",
        bundle: .braveShared,
        value: "Even in the background, Brave will continue to protect you.",
        comment: "Notification title to tell user that the vpn is turned on even in background")

    public static let vpnIAPBoilerPlate =
      NSLocalizedString(
        "vpn.vpnIAPBoilerPlate",
        bundle: .braveShared,
        value: "Subscriptions will be charged via your iTunes account.\n\nAny unused portion of the free trial, if offered, is forfeited when you buy a subscription.\n\nYour subscription will renew automatically unless it is cancelled at least 24 hours before the end of the current period.\n\nYou can manage your subscriptions in Settings.\n\nBy using Brave, you agree to the Terms of Use and Privacy Policy.",
        comment: "Disclaimer for user purchasing the VPN plan.")

    public static let regionPickerTitle =
      NSLocalizedString(
        "vpn.regionPickerTitle",
        bundle: .braveShared,
        value: "Server Region",
        comment: "Title for vpn region selector screen")

    public static let regionPickerAutomaticModeCellText =
      NSLocalizedString(
        "vpn.regionPickerAutomaticModeCellText",
        bundle: .braveShared,
        value: "Automatic",
        comment: "Name of automatic vpn region selector")

    public static let regionPickerAutomaticDescription =
      NSLocalizedString(
        "vpn.regionPickerAutomaticDescription",
        bundle: .braveShared,
        value: "A server region most proximate to you will be automatically selected, based on your system timezone. This is recommended in order to ensure fast internet speeds.",
        comment: "Description of what automatic server selection does.")

    public static let regionPickerErrorTitle =
      NSLocalizedString(
        "vpn.regionPickerErrorTitle",
        bundle: .braveShared,
        value: "Server Error",
        comment: "Title for error when we fail to switch vpn server for the user")

    public static let regionPickerErrorMessage =
      NSLocalizedString(
        "vpn.regionPickerErrorMessage",
        bundle: .braveShared,
        value: "Failed to switch servers, please try again later.",
        comment: "Message for error when we fail to switch vpn server for the user")

    public static let regionSwitchSuccessPopupText =
      NSLocalizedString(
        "vpn.regionSwitchSuccessPopupText",
        bundle: .braveShared,
        value: "VPN region changed.",
        comment: "Message that we show after successfully changing vpn region.")

    public static let settingsFailedToFetchServerList =
      NSLocalizedString(
        "vpn.settingsFailedToFetchServerList",
        bundle: .braveShared,
        value: "Failed to retrieve server list, please try again later.",
        comment: "Error message shown if we failed to retrieve vpn server list.")

    public static let contactFormEmailNotConfiguredBody =
      NSLocalizedString(
        "vpn.contactFormEmailNotConfiguredBody",
        bundle: .braveShared,
        value: "Can't send email. Please check your email configuration.",
        comment: "Button name to send contact form.")
  }
}

extension Strings {
  public struct Sync {
    public static let syncV1DeprecationText =
      NSLocalizedString(
        "sync.syncV1DeprecationText",
        bundle: .braveShared,
        value: "A new Brave Sync is coming and will affect your setup. Get ready for the upgrade.",
        comment: "Text that informs a user about Brave Sync service deprecation.")
    public static let bookmarksImportPopupErrorTitle =
      NSLocalizedString(
        "sync.bookmarksImportPopupErrorTitle",
        bundle: .braveShared,
        value: "Bookmarks",
        comment: "Title of the bookmark import popup.")
    public static let bookmarksImportPopupSuccessMessage =
      NSLocalizedString(
        "sync.bookmarksImportPopupSuccessMessage",
        bundle: .braveShared,
        value: "Bookmarks Imported Successfully",
        comment: "Message of the popup if bookmark import succeeds.")
    public static let bookmarksImportPopupFailureMessage =
      NSLocalizedString(
        "sync.bookmarksImportPopupFailureMessage",
        bundle: .braveShared,
        value: "Bookmark Import Failed",
        comment: "Message of the popup if bookmark import fails.")
    public static let v2MigrationInterstitialTitle =
      NSLocalizedString(
        "sync.v2MigrationInterstitialTitle",
        bundle: .braveShared,
        value: "Bookmarks migration",
        comment: "Bookmarks migration website title")
    public static let v2MigrationInterstitialPageDescription =
      NSLocalizedString(
        "sync.v2MigrationInterstitialPageDescription",
        bundle: .braveShared,
        value: "Some of your bookmarks failed to migrate. You can add them back manually.",
        comment: "Bookmarks migration website page description")
    /// Important: Do NOT change the `KEY` parameter without updating it in
    /// BraveCore's brave_bookmarks_importer.mm file.
    public static let importFolderName = NSLocalizedString("SyncImportFolderName", tableName: "BraveShared", bundle: Bundle.braveShared, value: "Imported Bookmarks", comment: "Folder name for where bookmarks are imported into when the root folder is not empty.")
    public static let v2MigrationTitle =
      NSLocalizedString(
        "sync.v2MigrationTitle", tableName: "BraveShared", bundle: .braveShared,
        value: "Migration required",
        comment: "Title for popup to inform the user that bookmarks migration is required for sync")
    public static let v2MigrationMessage =
      NSLocalizedString(
        "sync.v2MigrationMessage", tableName: "BraveShared", bundle: .braveShared,
        value: "In order to use Brave Sync your existing bookmarks must be migrated to use the new system. This operation will not delete your bookmarks.",
        comment: "Message for popup to inform the user that bookmarks migration is required for sync")
    public static let v2MigrationOKButton =
      NSLocalizedString(
        "sync.v2MigrationOKButton", tableName: "BraveShared", bundle: .braveShared,
        value: "Migrate",
        comment: "Button to perform bookmarks migration in order to support sync")
    public static let v2MigrationErrorTitle =
      NSLocalizedString(
        "sync.v2MigrationErrorTitle", tableName: "BraveShared", bundle: .braveShared,
        value: "Error",
        comment: "Title for popup when the bookmark migration fails")
    public static let v2MigrationErrorMessage =
      NSLocalizedString(
        "sync.v2MigrationErrorMessage", tableName: "BraveShared", bundle: .braveShared,
        value: "Failed to migrate bookmarks. Please try again later.",
        comment: "Message for popup when the bookmark migration fails")
    /// History Migration localization text
    public static let syncConfigurationInformationText =
      NSLocalizedString(
        "sync.syncConfigurationInformationText", tableName: "BraveShared", bundle: .braveShared,
        value: "Manage what information you would like to sync between devices. These settings only affect this device.",
        comment: "Information Text underneath the toggles for enable/disable different sync types for the device")
    public static let syncSettingsTitle =
      NSLocalizedString(
        "sync.syncSettingsTitle", tableName: "BraveShared", bundle: .braveShared,
        value: "Sync Settings",
        comment: "Title for Sync Settings Toggle Header")
  }
}

extension Strings {
  public struct History {
    public static let historyClearAlertTitle =
      NSLocalizedString(
        "history.historyClearAlertTitle", tableName: "BraveShared", bundle: .braveShared,
        value: "Clear Browsing History",
        comment: "Title for Clear All History Alert Title")
    public static let historyClearAlertDescription =
      NSLocalizedString(
        "history.historyClearAlertDescription", tableName: "BraveShared", bundle: .braveShared,
        value: "This will clear all browsing history.",
        comment: "Description for Clear All History Alert Description")
    public static let historyClearActionTitle =
      NSLocalizedString(
        "history.historyClearActionTitle", tableName: "BraveShared", bundle: .braveShared,
        value: "Clear History",
        comment: "Title for History Clear All Action")

    public static let historyEmptyStateTitle =
      NSLocalizedString(
        "history.historyEmptyStateTitle", tableName: "BraveShared", bundle: .braveShared,
        value: "History will show up here.",
        comment: "Title which is displayed when History screen is empty.")

    public static let historyPrivateModeOnlyStateTitle =
      NSLocalizedString(
        "history.historyPrivateModeOnlyStateTitle", tableName: "BraveShared", bundle: .braveShared,
        value: "History is not available in Private Browsing Only mode.",
        comment: "Title which is displayed on History screen as a overlay when Private Browsing Only enabled")
    public static let historySearchBarTitle =
      NSLocalizedString(
        "history.historySearchBarTitle", tableName: "BraveShared", bundle: .braveShared,
        value: "Search History",
        comment: "Title displayed for placeholder inside Search Bar in History")
  }
}

extension Strings {
  public struct Login {
    public static let loginListEmptyScreenTitle =
      NSLocalizedString(
        "login.loginListEmptyScreenTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "No logins found",
        comment: "The message displayed on the password list screen when there is not password found")
    public static let loginListNavigationTitle =
      NSLocalizedString(
        "login.loginListNavigationTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Logins & Passwords",
        comment: "Title for navigation bar of the login list screen")
    public static let loginListSearchBarPlaceHolderTitle =
      NSLocalizedString(
        "login.loginListSearchBarPlaceHolderTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Filter",
        comment: "The text for placeholder inside search bar in login list")
    public static let loginListSavedLoginsHeaderTitle =
      NSLocalizedString(
        "login.loginListSavedLoginsHeaderTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Saved Logins",
        comment: "The header title displayed over the login list")
    public static let loginInfoDetailsHeaderTitle =
      NSLocalizedString(
        "login.loginInfoDetailsHeaderTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Login Details",
        comment: "The header title displayed over the details of login entry")
    public static let loginInfoDetailsWebsiteFieldTitle =
      NSLocalizedString(
        "login.loginInfoDetailsWebsiteFieldTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Website",
        comment: "Title for the website field in password detail page")
    public static let loginInfoDetailsUsernameFieldTitle =
      NSLocalizedString(
        "login.loginInfoDetailsUsernameFieldTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Username",
        comment: "Title for the username field in password detail page")
    public static let loginInfoDetailsPasswordFieldTitle =
      NSLocalizedString(
        "login.loginInfoDetailsPasswordFieldTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Password",
        comment: "Title for the password field in password detail page")
    public static let loginEntryDeleteAlertMessage =
      NSLocalizedString(
        "login.loginEntryDeleteAlertMessage",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Saved Login will be removed permanently.",
        comment: "The message displayed in alert when a login entry deleted")
    public static let loginInfoCreatedHeaderTitle =
      NSLocalizedString(
        "login.loginInfoCreatedHeaderTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Created %@",
        comment: "The message displayed in alert when a login entry deleted")
    public static let loginInfoSetPasscodeAlertTitle =
      NSLocalizedString(
        "login.loginInfoSetPasscodeAlertTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Set a Passcode",
        comment: "The title displayed in alert when a user needs to set passcode")
    public static let loginInfoSetPasscodeAlertDescription =
      NSLocalizedString(
        "login.loginInfoSetPasscodeAlertDescription",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "To see passwords, you must first set a passcode on your device.",
        comment: "The message displayed in alert when a user needs to set a passcode")
  }
}

extension Strings {
  public struct BraveNews {
    public static let braveNews = NSLocalizedString(
      "today.braveToday",
      bundle: .braveShared,
      value: "Brave News",
      comment: "The name of the feature"
    )
    public static let sourcesAndSettings = NSLocalizedString(
      "today.sourcesAndSettings",
      bundle: .braveShared,
      value: "Sources & Settings",
      comment: ""
    )
    public static let turnOnBraveNews = NSLocalizedString(
      "today.turnOnBraveToday",
      bundle: .braveShared,
      value: "Turn on Brave News",
      comment: ""
    )
    public static let learnMoreTitle = NSLocalizedString(
      "today.learnMoreTitle",
      bundle: .braveShared,
      value: "Learn more about your data",
      comment: ""
    )
    public static let introCardTitle = NSLocalizedString(
      "today.introCardTitle",
      bundle: .braveShared,
      value: "Today's top stories in a completely private feed, just for you.",
      comment: ""
    )
    public static let introCardBody = NSLocalizedString(
      "today.introCardBody",
      bundle: .braveShared,
      value: "Brave News is ad-supported with completely private and anonymized ads matched on your device.",
      comment: ""
    )
    public static let introCardNew = NSLocalizedString(
      "today.introCardNew",
      bundle: .braveShared,
      value: "New",
      comment: "\"New\" as in a new feature being introduced, displayed above a body of text explaining said feature"
    )
    public static let introCardNewTextBody = NSLocalizedString(
      "today.introCardNewTextBody",
      bundle: .braveShared,
      value: "Customize your feed using hundreds of leading content sources delivered through our private CDN, and add RSS feeds from your favorite publishers to make a feed that works just for you.",
      comment: ""
    )
    public static let refresh = NSLocalizedString(
      "today.refresh",
      bundle: .braveShared,
      value: "Refresh",
      comment: ""
    )
    public static let emptyFeedTitle = NSLocalizedString(
      "today.emptyFeedTitle",
      bundle: .braveShared,
      value: "No articles to show",
      comment: ""
    )
    public static let emptyFeedBody = NSLocalizedString(
      "today.emptyFeedBody",
      bundle: .braveShared,
      value: "Try turning on some news sources",
      comment: ""
    )
    public static let deals = NSLocalizedString(
      "today.deals",
      bundle: .braveShared,
      value: "Deals",
      comment: ""
    )
    public static let allSources = NSLocalizedString(
      "today.allSources",
      bundle: .braveShared,
      value: "All Sources",
      comment: ""
    )
    public static let enableAll = NSLocalizedString(
      "today.enableAll",
      bundle: .braveShared,
      value: "Enable All",
      comment: ""
    )
    public static let disableAll = NSLocalizedString(
      "today.disableAll",
      bundle: .braveShared,
      value: "Disable All",
      comment: ""
    )
    public static let errorNoInternetTitle = NSLocalizedString(
      "today.noInternet",
      bundle: .braveShared,
      value: "No Internet",
      comment: ""
    )
    public static let errorNoInternetBody = NSLocalizedString(
      "today.noInternetBody",
      bundle: .braveShared,
      value: "Try checking your connection or reconnecting to Wi-Fi.",
      comment: ""
    )
    public static let errorGeneralTitle = NSLocalizedString(
      "today.errorGeneralTitle",
      bundle: .braveShared,
      value: "Oops…",
      comment: ""
    )
    public static let errorGeneralBody = NSLocalizedString(
      "today.errorGeneralBody",
      bundle: .braveShared,
      value: "Brave News is experiencing some issues. Try again.",
      comment: ""
    )
    public static let disablePublisherContent = NSLocalizedString(
      "today.disablePublisherContent",
      bundle: .braveShared,
      value: "Disable content from %@",
      comment: "'%@' will turn into the name of a publisher (verbatim), for example: Brave Blog"
    )
    public static let enablePublisherContent = NSLocalizedString(
      "today.enablePublisherContent",
      bundle: .braveShared,
      value: "Enable content from %@",
      comment: "'%@' will turn into the name of a publisher (verbatim), for example: Brave Blog"
    )
    public static let disabledAlertTitle = NSLocalizedString(
      "today.disabledAlertTitle",
      bundle: .braveShared,
      value: "Disabled",
      comment: ""
    )
    public static let disabledAlertBody = NSLocalizedString(
      "today.disabledAlertBody",
      bundle: .braveShared,
      value: "Brave News will stop showing content from %@",
      comment: "'%@' will turn into the name of a publisher (verbatim), for example: Brave Blog"
    )
    public static let isEnabledToggleLabel = NSLocalizedString(
      "today.isEnabledToggleLabel",
      bundle: .braveShared,
      value: "Show Brave News",
      comment: ""
    )
    public static let settingsSourceHeaderTitle = NSLocalizedString(
      "today.settingsSourceHeaderTitle",
      bundle: .braveShared,
      value: "Default Sources",
      comment: ""
    )
    public static let resetSourceSettingsButtonTitle = NSLocalizedString(
      "today.resetSourceSettingsButtonTitle",
      bundle: .braveShared,
      value: "Reset Source Settings to Default",
      comment: ""
    )
    public static let contentAvailableButtonTitle = NSLocalizedString(
      "today.contentAvailableButtonTitle",
      bundle: .braveShared,
      value: "New Content Available",
      comment: ""
    )
    public static let sourceSearchPlaceholder = NSLocalizedString(
      "today.sourceSearchPlaceholder",
      bundle: .braveShared,
      value: "Search",
      comment: ""
    )
    public static let moreBraveOffers = NSLocalizedString(
      "today.moreBraveOffers",
      bundle: .braveShared,
      value: "More Brave Offers",
      comment: "'Brave Offers' is a product name"
    )
    public static let promoted = NSLocalizedString(
      "today.promoted",
      bundle: .braveShared,
      value: "Promoted",
      comment: "A button title that is placed on promoted cards"
    )
    public static let addSourceShareTitle = NSLocalizedString(
      "today.addSourceShareTitle",
      bundle: .braveShared,
      value: "Add Source to Brave News",
      comment: "The action title displayed in the iOS share menu"
    )
    public static let addSourceFailureTitle = NSLocalizedString(
      "today.addSourceFailureTitle",
      bundle: .braveShared,
      value: "Failed to Add Source",
      comment: "The title in the alert when a source fails to add"
    )
    public static let addSourceNetworkFailureMessage = NSLocalizedString(
      "today.addSourceNetworkFailureMessage",
      bundle: .braveShared,
      value: "Sorry, we couldn’t find that feed address.",
      comment: ""
    )
    public static let addSourceInvalidDataMessage = NSLocalizedString(
      "today.addSourceInvalidDataMessage",
      bundle: .braveShared,
      value: "Sorry, we couldn’t recognize that feed address.",
      comment: ""
    )
    public static let addSourceNoFeedsFoundMessage = NSLocalizedString(
      "today.addSourceNoFeedsFoundMessage",
      bundle: .braveShared,
      value: "Sorry, that feed address doesn’t have any content.",
      comment: ""
    )
    public static let addSourceAddButtonTitle = NSLocalizedString(
      "today.addSourceAddButtonTitle",
      bundle: .braveShared,
      value: "Add",
      comment: "To add a list of 1 or more rss feeds"
    )
    public static let insecureSourcesHeader = NSLocalizedString(
      "today.insecureSourcesHeader",
      bundle: .braveShared,
      value: "Insecure Sources - Add at your own risk",
      comment: "The header above the list of insecure sources"
    )
    public static let searchTextFieldPlaceholder = NSLocalizedString(
      "today.searchTextFieldPlaceholder",
      bundle: .braveShared,
      value: "Feed or Site URL",
      comment: "The placeholder displayed on the text field where a user is expected to type in a website URL"
    )
    public static let searchButtonTitle = NSLocalizedString(
      "today.searchButtonTitle",
      bundle: .braveShared,
      value: "Search",
      comment: "An action title where the user is executing a search based on inputted text"
    )
    public static let importOPML = NSLocalizedString(
      "today.importOPML",
      bundle: .braveShared,
      value: "Import OPML",
      comment: "\"OPML\" is a file extension that contains a list of rss feeds."
    )
    public static let yourSources = NSLocalizedString(
      "today.yourSources",
      bundle: .braveShared,
      value: "Your Sources",
      comment: "The header above a list of the users RSS feed sources"
    )
    public static let addSource = NSLocalizedString(
      "today.addSource",
      bundle: .braveShared,
      value: "Add Source",
      comment: "The button title for adding a user RSS feed"
    )
    public static let deleteUserSourceTitle = NSLocalizedString(
      "today.deleteUserSourceTitle",
      bundle: .braveShared,
      value: "Delete",
      comment: "A button title for an action that deletes a users custom source"
    )
  }
}

// MARK: - Rewards Internals
extension Strings {
  public struct RewardsInternals {
    public static let title = NSLocalizedString("RewardsInternalsTitle", bundle: Bundle.braveShared, value: "Rewards Internals", comment: "'Rewards' as in 'Brave Rewards'")
    public static let walletInfoHeader = NSLocalizedString("RewardsInternalsWalletInfoHeader", bundle: Bundle.braveShared, value: "Wallet Info", comment: "")
    public static let legacyWalletInfoHeader = NSLocalizedString("RewardsInternalsLegacyWalletInfoHeader", bundle: Bundle.braveShared, value: "Legacy Wallet Info", comment: "")
    public static let legacyWalletHasTransferrableBalance = NSLocalizedString("RewardsInternalsLegacyWalletHasTransferrableBalance", bundle: Bundle.braveShared, value: "Has Transferrable Balance", comment: "")
    public static let keyInfoSeed = NSLocalizedString("RewardsInternalsKeyInfoSeed", bundle: Bundle.braveShared, value: "Key Info Seed", comment: "")
    public static let valid = NSLocalizedString("RewardsInternalsValid", bundle: Bundle.braveShared, value: "Valid", comment: "")
    public static let invalid = NSLocalizedString("RewardsInternalsInvalid", bundle: Bundle.braveShared, value: "Invalid", comment: "")
    public static let walletPaymentID = NSLocalizedString("RewardsInternalsWalletPaymentID", bundle: Bundle.braveShared, value: "Wallet Payment ID", comment: "")
    public static let walletCreationDate = NSLocalizedString("RewardsInternalsWalletCreationDate", bundle: Bundle.braveShared, value: "Wallet Creation Date", comment: "")
    public static let deviceInfoHeader = NSLocalizedString("RewardsInternalsDeviceInfoHeader", bundle: Bundle.braveShared, value: "Device Info", comment: "")
    public static let status = NSLocalizedString("RewardsInternalsStatus", bundle: Bundle.braveShared, value: "Status", comment: "")
    public static let supported = NSLocalizedString("RewardsInternalsSupported", bundle: Bundle.braveShared, value: "Supported", comment: "")
    public static let notSupported = NSLocalizedString("RewardsInternalsNotSupported", bundle: Bundle.braveShared, value: "Not supported", comment: "")
    public static let enrollmentState = NSLocalizedString("RewardsInternalsEnrollmentState", bundle: Bundle.braveShared, value: "Enrollment State", comment: "")
    public static let enrolled = NSLocalizedString("RewardsInternalsEnrolled", bundle: Bundle.braveShared, value: "Enrolled", comment: "")
    public static let notEnrolled = NSLocalizedString("RewardsInternalsNotEnrolled", bundle: Bundle.braveShared, value: "Not enrolled", comment: "")
    public static let balanceInfoHeader = NSLocalizedString("RewardsInternalsBalanceInfoHeader", bundle: Bundle.braveShared, value: "Balance Info", comment: "")
    public static let totalBalance = NSLocalizedString("RewardsInternalsTotalBalance", bundle: Bundle.braveShared, value: "Total Balance", comment: "")
    public static let anonymous = NSLocalizedString("RewardsInternalsAnonymous", bundle: Bundle.braveShared, value: "Anonymous", comment: "")
    public static let logsTitle = NSLocalizedString("RewardsInternalsLogsTitle", bundle: Bundle.braveShared, value: "Logs", comment: "")
    public static let logsCount = NSLocalizedString("RewardsInternalsLogsCount", bundle: Bundle.braveShared, value: "%d logs shown", comment: "%d will be the number of logs currently being shown, i.e. '10 logs shown'")
    public static let clearLogsTitle = NSLocalizedString("RewardsInternalsClearLogsTitle", bundle: Bundle.braveShared, value: "Clear Logs", comment: "")
    public static let clearLogsConfirmation = NSLocalizedString("RewardsInternalsClearLogsConfirmation", bundle: Bundle.braveShared, value: "Are you sure you wish to clear all Rewards logs?", comment: "")
    public static let promotionsTitle = NSLocalizedString("RewardsInternalsPromotionsTitle", bundle: Bundle.braveShared, value: "Promotions", comment: "")
    public static let amount = NSLocalizedString("RewardsInternalsAmount", bundle: Bundle.braveShared, value: "Amount", comment: "")
    public static let type = NSLocalizedString("RewardsInternalsType", bundle: Bundle.braveShared, value: "Type", comment: "")
    public static let expiresAt = NSLocalizedString("RewardsInternalsExpiresAt", bundle: Bundle.braveShared, value: "Expires At", comment: "")
    public static let legacyPromotion = NSLocalizedString("RewardsInternalsLegacyPromotion", bundle: Bundle.braveShared, value: "Legacy Promotion", comment: "")
    public static let version = NSLocalizedString("RewardsInternalsVersion", bundle: Bundle.braveShared, value: "Version", comment: "")
    public static let claimedAt = NSLocalizedString("RewardsInternalsClaimedAt", bundle: Bundle.braveShared, value: "Claimed at", comment: "")
    public static let claimID = NSLocalizedString("RewardsInternalsClaimID", bundle: Bundle.braveShared, value: "Claim ID", comment: "")
    public static let promotionStatusActive = NSLocalizedString("RewardsInternalsPromotionStatusActive", bundle: Bundle.braveShared, value: "Active", comment: "")
    public static let promotionStatusAttested = NSLocalizedString("RewardsInternalsPromotionStatusAttested", bundle: Bundle.braveShared, value: "Attested", comment: "")
    public static let promotionStatusCorrupted = NSLocalizedString("RewardsInternalsPromotionStatusCorrupted", bundle: Bundle.braveShared, value: "Corrupted", comment: "")
    public static let promotionStatusFinished = NSLocalizedString("RewardsInternalsPromotionStatusFinished", bundle: Bundle.braveShared, value: "Finished", comment: "")
    public static let promotionStatusOver = NSLocalizedString("RewardsInternalsPromotionStatusOver", bundle: Bundle.braveShared, value: "Over", comment: "")
    public static let contributionsTitle = NSLocalizedString("RewardsInternalsContributionsTitle", bundle: Bundle.braveShared, value: "Contributions", comment: "")
    public static let rewardsTypeAutoContribute = NSLocalizedString("RewardsInternalsRewardsTypeAutoContribute", bundle: Bundle.braveShared, value: "Auto-Contribute", comment: "")
    public static let rewardsTypeOneTimeTip = NSLocalizedString("RewardsInternalsRewardsTypeOneTimeTip", bundle: Bundle.braveShared, value: "One time tip", comment: "")
    public static let rewardsTypeRecurringTip = NSLocalizedString("RewardsInternalsRewardsTypeRecurringTip", bundle: Bundle.braveShared, value: "Recurring tip", comment: "")
    public static let contributionsStepACOff = NSLocalizedString("RewardsInternalsContributionsStepACOff", bundle: Bundle.braveShared, value: "Auto-Contribute Off", comment: "")
    public static let contributionsStepRewardsOff = NSLocalizedString("RewardsInternalsContributionsStepRewardsOff", bundle: Bundle.braveShared, value: "Rewards Off", comment: "")
    public static let contributionsStepACTableEmpty = NSLocalizedString("RewardsInternalsContributionsStepACTableEmpty", bundle: Bundle.braveShared, value: "AC table empty", comment: "'AC' refers to Auto-Contribute")
    public static let contributionsStepNotEnoughFunds = NSLocalizedString("RewardsInternalsContributionsStepNotEnoughFunds", bundle: Bundle.braveShared, value: "Not enough funds", comment: "")
    public static let contributionsStepFailed = NSLocalizedString("RewardsInternalsContributionsStepFailed", bundle: Bundle.braveShared, value: "Failed", comment: "")
    public static let contributionsStepCompleted = NSLocalizedString("RewardsInternalsContributionsStepCompleted", bundle: Bundle.braveShared, value: "Completed", comment: "")
    public static let contributionsStepStart = NSLocalizedString("RewardsInternalsContributionsStepStart", bundle: Bundle.braveShared, value: "Start", comment: "")
    public static let contributionsStepPrepare = NSLocalizedString("RewardsInternalsContributionsStepPrepare", bundle: Bundle.braveShared, value: "Prepare", comment: "")
    public static let contributionsStepReserve = NSLocalizedString("RewardsInternalsContributionsStepReserve", bundle: Bundle.braveShared, value: "Reserve", comment: "")
    public static let contributionsStepExternalTransaction = NSLocalizedString("RewardsInternalsContributionsStepExternalTransaction", bundle: Bundle.braveShared, value: "External Transaction", comment: "")
    public static let contributionsStepCreds = NSLocalizedString("RewardsInternalsContributionsStepCreds", bundle: Bundle.braveShared, value: "Credentials", comment: "")
    public static let contributionProcessorBraveTokens = NSLocalizedString("RewardsInternalsContributionProcessorBraveTokens", bundle: Bundle.braveShared, value: "Brave Tokens", comment: "")
    public static let contributionProcessorUserFunds = NSLocalizedString("RewardsInternalsContributionProcessorUserFunds", bundle: Bundle.braveShared, value: "User Funds", comment: "")
    public static let contributionProcessorUphold = NSLocalizedString("RewardsInternalsContributionProcessorUphold", bundle: Bundle.braveShared, value: "Uphold", comment: "")
    public static let contributionProcessorNone = NSLocalizedString("RewardsInternalsContributionProcessorNone", bundle: Bundle.braveShared, value: "None", comment: "")
    public static let createdAt = NSLocalizedString("RewardsInternalsCreatedAt", bundle: Bundle.braveShared, value: "Created at", comment: "")
    public static let step = NSLocalizedString("RewardsInternalsStep", bundle: Bundle.braveShared, value: "Step", comment: "i.e. 'Step: Started'")
    public static let retryCount = NSLocalizedString("RewardsInternalsRetryCount", bundle: Bundle.braveShared, value: "Retry Count", comment: "")
    public static let processor = NSLocalizedString("RewardsInternalsProcessor", bundle: Bundle.braveShared, value: "Processor", comment: "")
    public static let publishers = NSLocalizedString("RewardsInternalsPublishers", bundle: Bundle.braveShared, value: "Publishers", comment: "")
    public static let publisher = NSLocalizedString("RewardsInternalsPublisher", bundle: Bundle.braveShared, value: "Publisher", comment: "")
    public static let totalAmount = NSLocalizedString("RewardsInternalsTotalAmount", bundle: Bundle.braveShared, value: "Total amount", comment: "")
    public static let contributionAmount = NSLocalizedString("RewardsInternalsContributionAmount", bundle: Bundle.braveShared, value: "Contribution amount", comment: "")
    public static let shareInternalsTitle = NSLocalizedString("RewardsInternalsShareInternalsTitle", bundle: Bundle.braveShared, value: "Share Rewards Internals", comment: "'Rewards' as in 'Brave Rewards'")
    public static let share = NSLocalizedString("RewardsInternalsShare", bundle: Bundle.braveShared, value: "Share", comment: "")
    public static let sharableBasicTitle = NSLocalizedString("RewardsInternalsSharableBasicTitle", bundle: Bundle.braveShared, value: "Basic Info", comment: "")
    public static let sharableBasicDescription = NSLocalizedString("RewardsInternalsSharableBasicDescription", bundle: Bundle.braveShared, value: "Wallet, device & balance info (always shared)", comment: "")
    public static let sharableLogsDescription = NSLocalizedString("RewardsInternalsSharableLogsDescription", bundle: Bundle.braveShared, value: "Rewards specific logging", comment: "")
    public static let sharablePromotionsDescription = NSLocalizedString("RewardsInternalsSharablePromotionsDescription", bundle: Bundle.braveShared, value: "Any BAT promotions you have claimed or have pending from Ads or Grants", comment: "")
    public static let sharableContributionsDescription = NSLocalizedString("RewardsInternalsSharableContributionsDescription", bundle: Bundle.braveShared, value: "Any contributions made to publishers through tipping or auto-contribute", comment: "")
    public static let sharableDatabaseTitle = NSLocalizedString("RewardsInternalsSharableDatabaseTitle", bundle: Bundle.braveShared, value: "Rewards Database", comment: "")
    public static let sharableDatabaseDescription = NSLocalizedString("RewardsInternalsSharableDatabaseDescription", bundle: Bundle.braveShared, value: "The internal data store", comment: "")
    public static let sharingWarningTitle = NSLocalizedString("RewardsInternalsSharingWarningTitle", bundle: Bundle.braveShared, value: "Warning", comment: "")
    public static let sharingWarningMessage = NSLocalizedString("RewardsInternalsSharingWarningMessage", bundle: Bundle.braveShared, value: "Data on this page may be sensitive. Treat them as you would your wallet private keys. Be careful who you share them with.", comment: "")
  }
}

// MARK: - Rewards
extension Strings {
  public struct Rewards {
    public static let enabledBody = NSLocalizedString(
      "rewards.enabledBody",
      bundle: .braveShared,
      value: "You are helping support content creators",
      comment: "Displayed when Brave Rewards is enabled"
    )
    public static let disabledBody = NSLocalizedString(
      "rewards.disabledBody",
      bundle: .braveShared,
      value: "Turn on to help support content creators",
      comment: "Displayed when Brave Rewards is disabled"
    )
    public static let supportingPublisher = NSLocalizedString(
      "rewards.supportingPublisher",
      bundle: .braveShared,
      value: "You are helping support content creators like this one.",
      comment: "Displayed under verified publishers"
    )
    public static let unverifiedPublisher = NSLocalizedString(
      "rewards.unverifiedPublisher",
      bundle: .braveShared,
      value: "This creator has not verified and will not be included in creator support",
      comment: "Displayed under unverified publishers"
    )
    public static let enabledStatusBody = NSLocalizedString(
      "rewards.enabledStatusBody",
      bundle: .braveShared,
      value: "Thank you for helping support content creators as you browse!",
      comment: "Displayed in the status container when rewards is enabled but you're not currently supporting any publishers (0 AC count)"
    )
    public static let disabledStatusBody = NSLocalizedString(
      "rewards.disabledStatusBody",
      bundle: .braveShared,
      value: "Using Brave Rewards helps support content creators as you browse.",
      comment: "Displayed in the status container when rewards is disabled"
    )
    public static let totalSupportedCount = NSLocalizedString(
      "rewards.totalSupportedCount",
      bundle: .braveShared,
      value: "Number of content creators you are helping support this month.",
      comment: "Displayed next to a number representing the total number of publishers supported"
    )
    public static let walletTransferTitle = NSLocalizedString(
      "rewards.walletTransferTitle",
      bundle: .braveShared,
      value: "Wallet Transfer Status",
      comment: "Title of the legacy wallet transfer screen"
    )
    public static let walletTransferFailureAlertTitle = NSLocalizedString(
      "rewards.walletTransferFailureAlertTitle",
      bundle: .braveShared,
      value: "Connection Error",
      comment: "Title on the alert presented if wallet transfer fails"
    )
    public static let walletTransferFailureAlertMessage = NSLocalizedString(
      "rewards.walletTransferFailureAlertMessage",
      bundle: .braveShared,
      value: "The Brave Rewards server did not respond. Please try again in a moment.",
      comment: "Message on the alert presented if wallet transfer fails"
    )
    public static let walletTransferStepsTitle = NSLocalizedString(
      "rewards.walletTransferStepsTitle",
      bundle: .braveShared,
      value: "Scan One-Time Transfer Code",
      comment: "Title above the steps to use wallet transfer"
    )
    public static let walletTransferStepsBody = NSLocalizedString(
      "rewards.walletTransferStepsBody",
      bundle: .braveShared,
      value: "Your Brave Rewards token balance can be transfered to an existing Brave Rewards desktop wallet, one time.\n\n1. Open Brave Browser on your desktop\n2. Navigate to brave://rewards\n3. Click “QR Code”\n4. Scan QR Code with your device",
      comment: "Describes the steps for using wallet transfer"
    )
    public static let walletTransferCompleteTitle = NSLocalizedString(
      "rewards.walletTransferCompleteTitle",
      bundle: .braveShared,
      value: "Balance transfer has initiated",
      comment: "Title shown above the confirmation message after completing a wallet transfer successfully"
    )
    public static let walletTransferCompleteBody = NSLocalizedString(
      "rewards.walletTransferCompleteBody",
      bundle: .braveShared,
      value: "Your transfer has initiated. Any existing BAT balance may take several minutes to appear in your desktop Brave Rewards wallet. Check your Rewards summary on Desktop for details when transfer has completed.\n\nYou may close this window and continue using Brave as your transfer is in progress.",
      comment: "A confirmation message shown to the user after completing a wallet transfer successfully"
    )
    public static let legacyWalletTransfer = NSLocalizedString(
      "rewards.legacyWalletTransfer",
      bundle: .braveShared,
      value: "Legacy Wallet Transfer",
      comment: ""
    )
    public static let legacyWalletTransferSubtitle = NSLocalizedString(
      "rewards.legacyWalletTransferSubtitle",
      bundle: .braveShared,
      value: "One-time transfer-out existing tokens",
      comment: ""
    )
    public static let settingsToggleTitle = NSLocalizedString(
      "rewards.settingsToggleTitle",
      bundle: .braveShared,
      value: "Enable Brave Rewards",
      comment: ""
    )
    public static let settingsToggleMessage = NSLocalizedString(
      "rewards.settingsToggleMessage",
      bundle: .braveShared,
      value: "Support content creators and publishers automatically by enabling Brave Private Ads. Brave Private Ads are privacy-respecting ads that give back to content creators.",
      comment: ""
    )
    public static let settingsFooterMessage = NSLocalizedString(
      "rewards.settingsFooterMessage",
      bundle: .braveShared,
      value: "Brave Rewards payouts are temporarily unavailable on this device. Transfer your existing wallet funds to a desktop wallet to keep your tokens.",
      comment: ""
    )
    public static let onProviderText = NSLocalizedString("OnProviderText", bundle: .braveShared, value: "on %@", comment: "This is a suffix statement. example: SomeChannel on Twitter")
    public static let transferNoLongerAvailableWarningMessage = NSLocalizedString(
      "rewards.transferNoLongerAvailableWarningMessage",
      bundle: .braveShared,
      value: "Please use the wallet transfer by March 13, 2021. Wallet transfer will no longer be available after March 13.",
      comment: ""
    )
    public static let legacyWalletTransferStatusShortformInvalid = NSLocalizedString(
      "rewards.legacyWalletTransferStatusShortformInvalid",
      bundle: .braveShared,
      value: "Invalid",
      comment: "Invalid as in: stating that the status of the users transfer is invalid"
    )
    public static let legacyWalletTransferStatusButtonInvalidTitle = NSLocalizedString(
      "rewards.legacyWalletTransferStatusButtonInvalidTitle",
      bundle: .braveShared,
      value: "Your legacy wallet transfer is invalid",
      comment: ""
    )
    public static let legacyWalletTransferStatusInvalidTitle = NSLocalizedString(
      "rewards.legacyWalletTransferStatusInvalidTitle",
      bundle: .braveShared,
      value: "Transfer Invalid",
      comment: "Title shown above body of text explaining that their transfer is invalid"
    )
    public static let legacyWalletTransferStatusInvalidBody = NSLocalizedString(
      "rewards.legacyWalletTransferStatusInvalidBody",
      bundle: .braveShared,
      value: "Your legacy wallet transfer is invalid and cannot be completed",
      comment: ""
    )
    public static let legacyWalletTransferStatusShortformPending = NSLocalizedString(
      "rewards.legacyWalletTransferStatusShortformPending",
      bundle: .braveShared,
      value: "Pending",
      comment: "Pending as in: stating that the status of the users transfer is pending"
    )
    public static let legacyWalletTransferStatusButtonPendingTitle = NSLocalizedString(
      "rewards.legacyWalletTransferStatusButtonPendingTitle",
      bundle: .braveShared,
      value: "Your legacy wallet transfer status is pending",
      comment: ""
    )
    public static let legacyWalletTransferStatusPendingTitle = NSLocalizedString(
      "rewards.legacyWalletTransferStatusPendingTitle",
      bundle: .braveShared,
      value: "Transfer Pending",
      comment: "Title shown above body of text explaining that their transfer is pending"
    )
    public static let legacyWalletTransferStatusPendingBody = NSLocalizedString(
      "rewards.legacyWalletTransferStatusPendingBody",
      bundle: .braveShared,
      value: "Your legacy wallet transfer status is pending and should begin processing shortly.",
      comment: ""
    )
    public static let legacyWalletTransferStatusShortformInProgress = NSLocalizedString(
      "rewards.legacyWalletTransferStatusShortformInProgress",
      bundle: .braveShared,
      value: "In Progress",
      comment: "In Progress as in: stating that the status of the users transfer is in progress"
    )
    public static let legacyWalletTransferStatusButtonInProgressTitle = NSLocalizedString(
      "rewards.legacyWalletTransferStatusButtonInProgressTitle",
      bundle: .braveShared,
      value: "Your legacy wallet transfer is in progress",
      comment: ""
    )
    public static let legacyWalletTransferStatusInProgressTitle = NSLocalizedString(
      "rewards.legacyWalletTransferStatusInProgressTitle",
      bundle: .braveShared,
      value: "Transfer In-Progress",
      comment: "Title shown above body of text explaining that their transfer is in progress"
    )
    public static let legacyWalletTransferStatusInProgressBody = NSLocalizedString(
      "rewards.legacyWalletTransferStatusInProgressBody",
      bundle: .braveShared,
      value: "Your legacy wallet transfer is in-progress and may take several minutes to complete.",
      comment: ""
    )
    public static let legacyWalletTransferStatusShortformDelayed = NSLocalizedString(
      "rewards.legacyWalletTransferStatusShortformDelayed",
      bundle: .braveShared,
      value: "Delayed",
      comment: "Delayed as in: stating that the status of the users transfer is in delayed"
    )
    public static let legacyWalletTransferStatusButtonDelayedTitle = NSLocalizedString(
      "rewards.legacyWalletTransferStatusButtonDelayedTitle",
      bundle: .braveShared,
      value: "Your legacy wallet transfer has been delayed…",
      comment: ""
    )
    public static let legacyWalletTransferStatusDelayedTitle = NSLocalizedString(
      "rewards.legacyWalletTransferStatusDelayedTitle",
      bundle: .braveShared,
      value: "Transfer Delayed",
      comment: "Title shown above body of text explaining that their transfer is delayed"
    )
    public static let legacyWalletTransferStatusDelayedBody = NSLocalizedString(
      "rewards.legacyWalletTransferStatusDelayedBody",
      bundle: .braveShared,
      value: "Your legacy wallet transfer has been delayed and may take several minutes to resume.",
      comment: ""
    )
    public static let legacyWalletTransferStatusShortformCompleted = NSLocalizedString(
      "rewards.legacyWalletTransferStatusShortformCompleted",
      bundle: .braveShared,
      value: "Completed!",
      comment: "Completed as in: stating that the status of the users transfer is in completed"
    )
    public static let legacyWalletTransferStatusButtonCompletedTitle = NSLocalizedString(
      "rewards.legacyWalletTransferStatusButtonCompletedTitle",
      bundle: .braveShared,
      value: "Your legacy wallet transfer has completed!",
      comment: ""
    )
    public static let legacyWalletTransferStatusCompletedTitle = NSLocalizedString(
      "rewards.legacyWalletTransferStatusCompletedTitle",
      bundle: .braveShared,
      value: "Transfer Completed!",
      comment: "Title shown above body of text explaining that their transfer is completed"
    )
    public static let legacyWalletTransferStatusCompletedBody = NSLocalizedString(
      "rewards.legacyWalletTransferStatusCompletedBody",
      bundle: .braveShared,
      value: "Your legacy wallet transfer is done! Your existing balance may still take several minutes to appear on your desktop Brave Rewards wallet.",
      comment: ""
    )

    public static let braveTalkRewardsOptInTitle =
      NSLocalizedString(
        "rewards.braveTalkRewardsOptInTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "To start a free call, turn on Brave Rewards",
        comment: "Title for Brave Talk rewards opt-in screen")

    public static let braveTalkRewardsOptInBody =
      NSLocalizedString(
        "rewards.braveTalkRewardsOptInBody",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "With Brave Rewards, you can view privacy-preserving ads from the Brave Ads network. No trackers. No slowdowns. And your data stays totally safe.",
        comment: "Body for Brave Talk rewards opt-in screen")

    public static let braveTalkRewardsOptInButtonTitle =
      NSLocalizedString(
        "rewards.braveTalkRewardsOptInButtonTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Turn on Rewards",
        comment: "Title for Brave Talk rewards opt-in screen button")

    public static let braveTalkRewardsOptInDisclaimer =
      NSLocalizedString(
        "rewards.optInDisclaimer",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "By clicking, you agree to the %@ and %@. Disable any time in Settings.",
        comment: "The placeholders say 'Terms of Service' and 'Privacy Policy'. So full sentence goes like: 'By clicking, you agree to the Terms of Service and Privacy Policy...'")

    public static let braveTalkRewardsOptInSuccessTitle =
      NSLocalizedString(
        "rewards.braveTalkRewardsOptInSuccessTitle",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "You can now start a free call",
        comment: "Title for successful Brave Talk rewards opt-in")

    public static let braveTalkRewardsOptInSuccessBody =
      NSLocalizedString(
        "rewards.braveTalkRewardsOptInSuccessBody",
        tableName: "BraveShared",
        bundle: .braveShared,
        value: "Click anywhere on the screen to continue to Brave Talk.",
        comment: "Body for successful Brave Talk rewards opt-in")
  }
}

// MARK: - Talk
extension Strings {
  public struct BraveTalk {
    public static let braveTalkTitle = NSLocalizedString(
      "bravetalk.braveTalkTitle",
      bundle: .braveShared,
      value: "Brave Talk",
      comment: "The name of the feature")
  }
}

// MARK: - Ads
extension Strings {
  public struct Ads {
    public static let myFirstAdTitle = NSLocalizedString("MyFirstAdTitle", bundle: .braveShared, value: "This is your first Brave ad", comment: "")
    public static let myFirstAdBody = NSLocalizedString("MyFirstAdBody", bundle: .braveShared, value: "Tap here to learn more.", comment: "")
    public static let open = NSLocalizedString("BraveRewardsOpen", bundle: .braveShared, value: "Open", comment: "")
    public static let adNotificationTitle = NSLocalizedString("BraveRewardsAdNotificationTitle", bundle: .braveShared, value: "Brave Rewards", comment: "")
  }
}

// MARK: - Recent Searches
extension Strings {
  public static let recentSearchFavorites = NSLocalizedString("RecentSearchFavorites", bundle: .braveShared, value: "Favorites", comment: "Recent Search Favorites Section Title")
  public static let recentSearchPasteAndGo = NSLocalizedString("RecentSearchPasteAndGo", bundle: .braveShared, value: "Paste & Go", comment: "Recent Search Paste & Go Button Title")
  public static let recentSearchSectionTitle = NSLocalizedString("RecentSearchSectionTitle", bundle: .braveShared, value: "Recent Searches", comment: "Recent Search Section Title")
  public static let recentSearchSectionDescription = NSLocalizedString("RecentSearchSectionDescription", bundle: .braveShared, value: "Recent Searches allow you to privately access past searches. Would you like to enable Recent Searches?", comment: "Recent Search Section Description")
  public static let recentSearchClear = NSLocalizedString("RecentSearchClear", bundle: .braveShared, value: "Clear", comment: "Recent Search Clear Button")
  public static let recentSearchShow = NSLocalizedString("RecentSearchShow", bundle: .braveShared, value: "Show", comment: "Recent Search Show Button")
  public static let recentSearchHide = NSLocalizedString("RecentSearchHide", bundle: .braveShared, value: "Hide", comment: "Recent Search Hide Button")
  public static let recentShowMore = NSLocalizedString("RecentSearchShowMore", bundle: .braveShared, value: "Show more", comment: "Recent Search Show More button")
  public static let recentSearchScanned = NSLocalizedString("RecentSearchScanned", bundle: .braveShared, value: "Scanned", comment: "Recent Search Scanned text when a user scans a qr code")
  public static let recentSearchQuickSearchOnWebsite = NSLocalizedString("RecentSearchQuickSearchOnWebsite", bundle: .braveShared, value: "on", comment: "Recent Search 'on' text when a user searches 'on' a website")
  public static let recentSearchSuggestionsTitle = NSLocalizedString("RecentSearchSuggestionsTitle", bundle: .braveShared, value: "Search Suggestions", comment: "Recent Search suggestions title when prompting to turn on suggestions")
  public static let recentSearchEnableSuggestions = NSLocalizedString("RecentSearchEnableSuggestions", bundle: .braveShared, value: "Enable", comment: "Recent Search button title to enable suggestions")
  public static let recentSearchDisableSuggestions = NSLocalizedString("RecentSearchDisableSuggestions", bundle: .braveShared, value: "Disable", comment: "Recent Search button title to disable suggestions")
  public static let recentSearchClearDataToggleOption = NSLocalizedString("RecentSearchClearDataToggleOption", bundle: .braveShared, value: "Recent Search Data", comment: "Recent Search setting title to clear recent searches")
  public static let recentSearchScannerTitle = NSLocalizedString("RecentSearchScannerTitle", bundle: .braveShared, value: "Scan QR Code", comment: "Scanning a QR Code for searching")
  public static let recentSearchScannerDescriptionTitle = NSLocalizedString("RecentSearchScannerDescriptionTitle", bundle: .braveShared, value: "Instructions", comment: "Scanning a QR Code for title")
  public static let recentSearchScannerDescriptionBody = NSLocalizedString("RecentSearchScannerDescriptionBody", bundle: .braveShared, value: "To search by QR Code, align the QR Code in the center of the frame.", comment: "Scanning a QR Code for searching body")
  public static let recentSearchClearAlertButton = NSLocalizedString("RecentSearchClearAlertButton", bundle: .braveShared, value: "Clear Recent", comment: "The button title that shows when you clear all recent searches")
}

// MARK: - Widgets
extension Strings {
  public struct Widgets {
    public static let noFavoritesFound = NSLocalizedString(
      "widgets.noFavoritesFound",
      bundle: .braveShared,
      value: "Please open Brave to view your favorites here",
      comment: "This shows when you add a widget but have no favorites added in your app")

    public static let favoritesWidgetTitle = NSLocalizedString(
      "widgets.favoritesWidgetTitle",
      bundle: .braveShared,
      value: "Favorites",
      comment: "Title for favorites widget on 'add widget' screen.")

    public static let favoritesWidgetDescription = NSLocalizedString(
      "widgets.favoritesWidgetDescription",
      bundle: .braveShared,
      value: "Quickly access your favorite websites.",
      comment: "Description for favorites widget on 'add widget' screen.")

    public static let shortcutsWidgetTitle = NSLocalizedString(
      "widgets.shortcutsWidgetTitle",
      bundle: .braveShared,
      value: "Shortcuts",
      comment: "Title for shortcuts widget on 'add widget' screen.")

    public static let shortcutsWidgetDescription = NSLocalizedString(
      "widgets.shortcutsWidgetDescription",
      bundle: .braveShared,
      value: "Quick access to search the web or open web pages in Brave.",
      comment: "Description for shortcuts widget on 'add widget' screen.")

    public static let shortcutsNewTabButton = NSLocalizedString(
      "widgets.shortcutsNewTabButton",
      bundle: .braveShared,
      value: "New Tab",
      comment: "Button to open new browser tab.")

    public static let shortcutsPrivateTabButton = NSLocalizedString(
      "widgets.shortcutsPrivateTabButton",
      bundle: .braveShared,
      value: "Private Tab",
      comment: "Button to open new private browser tab.")

    public static let shortcutsPlaylistButton = NSLocalizedString(
      "widgets.shortcutsPlaylistButton",
      bundle: .braveShared,
      value: "Playlist",
      comment: "Button to open video playlist window.")

    public static let shortcutsEnterURLButton = NSLocalizedString(
      "widgets.shortcutsEnterURLButton",
      bundle: .braveShared,
      value: "Search or type a URL",
      comment: "Button to the browser and enter URL or make a search query there.")

    public static let shieldStatsTitle = NSLocalizedString(
      "widgets.shieldStatsTitle",
      bundle: .braveShared,
      value: "Privacy Stats",
      comment: "Title for Brave Shields widget on 'add widget' screen.")

    public static let shieldStatsDescription = NSLocalizedString(
      "widgets.shieldStatsDescription",
      bundle: .braveShared,
      value: "A summary of how Brave saves you time and protects you online.",
      comment: "Description for Brave Shields widget on 'add widget' screen.")

    public static let shieldStatsWidgetTitle = NSLocalizedString(
      "widgets.shieldStatsWidgetTitle",
      bundle: .braveShared,
      value: "Privacy Stats",
      comment: "Title of Brave Shields widget shown above stat numbers.")

    public static let singleStatTitle = NSLocalizedString(
      "widgets.singleStatTitle",
      bundle: .braveShared,
      value: "Privacy Stat",
      comment: "Title for Brave Shields single stat widget on 'add widget' screen.")

    public static let singleStatDescription = NSLocalizedString(
      "widgets.singleStatDescription",
      bundle: .braveShared,
      value: "A summary of how Brave has protected you online.",
      comment: "Description for Brave Shields single stat widget on 'add widget' screen.")
  }
}

// MARK: - Night Mode

extension Strings {
  public struct NightMode {
    public static let sectionTitle = NSLocalizedString(
      "nightMode.modeTitle",
      bundle: .braveShared,
      value: "Mode",
      comment: "It refers to a night mode, to a type of mode a user can change referring to website appearance."
    )
    public static let settingsTitle = NSLocalizedString(
      "nightMode.settingsTitle",
      bundle: .braveShared,
      value: "Night Mode",
      comment: "A table cell title for Night Mode - defining element for the toggle"
    )
    public static let settingsDescription = NSLocalizedString(
      "nightMode.settingsDescription",
      bundle: .braveShared,
      value: "Turn on/off Night Mode",
      comment: "A table cell subtitle for Night Mode - explanatory element for the toggle preference"
    )
    public static let sectionDescription = NSLocalizedString(
      "nightMode.sectionDescription",
      bundle: .braveShared,
      value: "Night mode will effect website appearance and general system appearance at the same time.",
      comment: "A table cell subtitle for Night Mode - explanatory element for the toggle preference"
    )
  }
}

// MARK: - ManageWebsiteData
extension Strings {
  public static let manageWebsiteDataTitle = NSLocalizedString(
    "websiteData.manageWebsiteDataTitle",
    bundle: .braveShared,
    value: "Manage Website Data",
    comment: "A button or screen title describing that the user is there to manually manage website data that is persisted to their device. I.e. to manage data specific to a web page the user has visited"
  )
  public static let loadingWebsiteData = NSLocalizedString(
    "websiteData.loadingWebsiteData",
    bundle: .braveShared,
    value: "Loading website data…",
    comment: "A message displayed to users while the system fetches all website data to display."
  )
  public static let dataRecordCookies = NSLocalizedString(
    "websiteData.dataRecordCookies",
    bundle: .braveShared,
    value: "Cookies",
    comment: "The word used to describe small bits of state stored locally in a web browser (e.g. Browser cookies)"
  )
  public static let dataRecordCache = NSLocalizedString(
    "websiteData.dataRecordCache",
    bundle: .braveShared,
    value: "Cache",
    comment: "Temporary data that is stored on the users device to speed up future requests and interactions."
  )
  public static let dataRecordLocalStorage = NSLocalizedString(
    "websiteData.dataRecordLocalStorage",
    bundle: .braveShared,
    value: "Local storage",
    comment: "A kind of browser storage particularely for saving data on the users device for a specific webpage for the given session or longer time periods."
  )
  public static let dataRecordDatabases = NSLocalizedString(
    "websiteData.dataRecordDatabases",
    bundle: .braveShared,
    value: "Databases",
    comment: "Some data stored on disk that is a kind of database (such as WebSQL or IndexedDB.)"
  )
  public static let removeDataRecord = NSLocalizedString(
    "websiteData.removeDataRecord",
    bundle: .braveShared,
    value: "Remove",
    comment: "Shown when a user has attempted to delete a single webpage data record such as cookies, caches, or local storage that has been persisted on their device. Tapping it will delete that records and remove it from the list"
  )
  public static let removeSelectedDataRecord = NSLocalizedString(
    "websiteData.removeSelectedDataRecord",
    bundle: .braveShared,
    value: "Remove %ld items",
    comment: "Shown on a button when a user has selected multiple webpage data records (such as cookies, caches, or local storage) that has been persisted on their device. Tapping it will delete those records and remove them from the list"
  )
  public static let removeAllDataRecords = NSLocalizedString(
    "websiteData.removeAllDataRecords",
    bundle: .braveShared,
    value: "Remove All",
    comment: "Shown on a button to delete all displayed webpage records (such as cookies, caches, or local storage) that has been persisted on their device. Tapping it will delete those records and remove them from the list"
  )
  public static let noSavedWebsiteData = NSLocalizedString(
    "websiteData.noSavedWebsiteData",
    bundle: .braveShared,
    value: "No Saved Website Data",
    comment: "Shown when the user has no website data (such as cookies, caches, or local storage) persisted to their device."
  )
}

// MARK: - Privacy hub
extension Strings {
  public struct PrivacyHub {
    public static let privacyReportsTitle = NSLocalizedString(
      "privacyHub.privacyReportsTitle",
      bundle: .braveShared,
      value: "Privacy Hub",
      comment: "Title of main privacy hub screen. This screen shows various stats caught by Brave's ad blockers."
    )
    
    public static let notificationCalloutBody = NSLocalizedString(
      "privacyHub.notificationCalloutBody",
      bundle: .braveShared,
      value: "Get weekly privacy updates on tracker & ad blocking.",
      comment: "Text of a callout to encourage user to enable Apple notification system."
    )
    
    public static let notificationCalloutButtonText = NSLocalizedString(
      "privacyHub.notificationCalloutButtonText",
      bundle: .braveShared,
      value: "Turn on notifications",
      comment: "Text of a button to encourage user to enable Apple notification system."
    )
    
    public static let noDataCalloutBody = NSLocalizedString(
      "privacyHub.noDataCalloutBody",
      bundle: .braveShared,
      value: "Visit some websites to see data here.",
      comment: "Text of a callout that tell user they need to browser some websites first in order to see privacy stats data"
    )
    
    public static let lastWeekHeader = NSLocalizedString(
      "privacyHub.lastWeekHeader",
      bundle: .braveShared,
      value: "Last week",
      comment: "Header text, under it we display blocked items from last week"
    )
    
    public static let mostFrequentTrackerAndAdTitle = NSLocalizedString(
      "privacyHub.mostFrequentTrackerAndAdTitle",
      bundle: .braveShared,
      value: "Most Frequent Tracker & Ad",
      comment: "Title under which we display a tracker which was most frequently detected by our ad blocking mechanism."
    )
    
    public static let mostFrequentTrackerAndAdBody = NSLocalizedString(
      "privacyHub.mostFrequentTrackerAndAdBody",
      bundle: .braveShared,
      value: "**%@** was blocked by Brave Shields on **%lld** sites",
      comment: "Do NOT localize asterisk('*') characters, they are used to make the text bold in the app. It says which tracker was blocked on how many websites, example usage: 'Google Analytics was blocked by Brave Shields on 42 sites'"
    )
    
    public static let noDataToShow = NSLocalizedString(
      "privacyHub.noDataToShow",
      bundle: .braveShared,
      value: "No data to show yet.",
      comment: "This text is diplayed when there is no data to display to the user. The data is about blocked trackers or sites with trackers on them."
    )
    
    public static let riskiestWebsiteTitle = NSLocalizedString(
      "privacyHub.riskiestWebsiteTitle",
      bundle: .braveShared,
      value: "Riskiest website you visited",
      comment: "Title of a website that contained the most trackers per visit."
    )
    
    public static let riskiestWebsiteBody = NSLocalizedString(
      "privacyHub.riskiestWebsiteBody",
      bundle: .braveShared,
      value: "**%@** had an average of **%lld** trackers & ads blocked per visit",
      comment: "Do NOT localize asterisk('*') characters, they are used to make the text bold in the app. It says which website had the most tracker per visit, example usage: 'example.com had an average of 10 trackers & ads blocked per visit '"
    )
    
    public static let vpnAlertsHeader = NSLocalizedString(
      "privacyHub.vpnAlertsHeader",
      bundle: .braveShared,
      value: "Brave Firewall + VPN Alerts",
      comment: "Section title, this section displays vpn alerts: items which the vpn managed to block on users behalf."
    )
    
    public static let allVPNAlertsButtonText = NSLocalizedString(
      "privacyHub.allVPNAlertsButtonText",
      bundle: .braveShared,
      value: "All alerts",
      comment: "Text for a button to display a list of all alerts caught by the Brave VPN. VPN alert is a notificaion of what item has been blocked by the vpn, similar to a regular adblocker"
    )
    
    public static let allTimeListsHeader = NSLocalizedString(
      "privacyHub.allTimeListsHeader",
      bundle: .braveShared,
      value: "All time",
      comment: "Header text, under it we show items blocked by our ad blocker. 'All  time' sentence context is like 'All time items blocked by our ad blocker."
    )
    
    public static let allTimeTrackerTitle = NSLocalizedString(
      "privacyHub.allTimeTrackerTitle",
      bundle: .braveShared,
      value: "Tracker & Ad",
      comment: "Title under which we display most name of the most blocked tracker or ad."
    )
    
    public static let allTimeWebsiteTitle = NSLocalizedString(
      "privacyHub.allTimeWebsiteTitle",
      bundle: .braveShared,
      value: "Website",
      comment: "Title under which we display a website on which there's the highest number of trackers or ads."
    )
    
    public static let allTimeSitesCount = NSLocalizedString(
      "privacyHub.allTimeSitesCount",
      bundle: .braveShared,
      value: "%lld sites",
      comment: "Displays a number of websites on which we blocked trackers, example usage: '23 sites'"
    )
    
    public static let allTimeTrackersCount = NSLocalizedString(
      "privacyHub.allTimeTrackersCount",
      bundle: .braveShared,
      value: "%lld trackers & ads",
      comment: "Displays a number of trackers we blocked on a particular website, example usage: '23 trackers & ads'"
    )
    
    public static let allTimeListsButtonText = NSLocalizedString(
      "privacyHub.allTimeListsButtonText",
      bundle: .braveShared,
      value: "All time lists",
      comment: "Button text that takes user to a list of all trackers and ads we blocked. 'All time lists' refer to list of blocked trackers or websites which have the most trackers"
    )
    
    public static let allTimeListsTrackersView = NSLocalizedString(
      "privacyHub.allTimeListsTrackersView",
      bundle: .braveShared,
      value: "Trackers & ads",
      comment: "Title of a section to show total count of trackers blocked by Brave"
    )
    
    public static let allTimeListsWebsitesView = NSLocalizedString(
      "privacyHub.allTimeListsWebsitesView",
      bundle: .braveShared,
      value: "Websites",
      comment: "Title of a section to show websites containing highest amount of trackers"
    )
    
    public static let blockedBy = NSLocalizedString(
      "privacyHub.blockedBy",
      bundle: .braveShared,
      value: "Blocked by",
      comment: "Text which explain by what type of ad blocker a given resource was blocked. Context is like: 'Blocked by Brave Shields', 'Blocked by BraveVPN"
    )
    
    public static let allTimeListTrackersHeaderTitle = NSLocalizedString(
      "privacyHub.allTimeListTrackersHeaderTitle",
      bundle: .braveShared,
      value: "Most frequent trackers & ads on sites you Visit",
      comment: "Header title for a list of most frequent ads and trackers detected."
    )
    
    public static let allTimeListWebsitesHeaderTitle = NSLocalizedString(
      "privacyHub.allTimeListWebsitesHeaderTitle",
      bundle: .braveShared,
      value: "Websites with the most trackers & ads",
      comment: "Header title for a list of websites with ads and trackers."
    )
    
    public static let vpvnAlertsTotalCount = NSLocalizedString(
      "privacyHub.vpvnAlertsTotalCount",
      bundle: .braveShared,
      value: "Total count",
      comment: "It shows a total count of items blocked by our VPN shields"
    )
    
    public static let shieldsLabel = NSLocalizedString(
      "privacyHub.shieldsLabel",
      bundle: .braveShared,
      value: "Shields",
      comment: "This label says shields, as a source of by what a resource was blocked. Think of it in context of 'Blocked by Shields'"
    )
    
    public static let vpnLabel = NSLocalizedString(
      "privacyHub.vpnLabel",
      bundle: .braveShared,
      value: "Firewall + VPN",
      comment: "This label says about Brave VPN, as a source of by what the resource was blocked by. Think of it in context of 'Blocked by VPN'"
    )
    
    public static let blockedLabel = NSLocalizedString(
      "privacyHub.blockedLabel",
      bundle: .braveShared,
      value: "Blocked",
      comment: "It says that a ad or tracker was blocked. Think of it in context of 'A tracker X was blocked'"
    )
    
    public static let vpnAlertRegularTrackerTypeSingular = NSLocalizedString(
      "privacyHub.vpnAlertRegularTrackerTypeSingular",
      bundle: .braveShared,
      value: "Tracker or Ad",
      comment: "Type of tracker blocked by the VPN, it's a regular tracker or an ad."
    )
    
    public static let vpnAlertLocationTrackerTypeSingular = NSLocalizedString(
      "privacyHub.vpnAlertLocationTrackerTypeSingular",
      bundle: .braveShared,
      value: "Location Ping",
      comment: "Type of tracker blocked by the VPN, it's a tracker that asks you for your location."
    )
    
    public static let vpnAlertEmailTrackerTypeSingular = NSLocalizedString(
      "privacyHub.vpnAlertEmailTrackerTypeSingular",
      bundle: .braveShared,
      value: "Email Tracker",
      comment: "Type of tracker blocked by the VPN, it's a tracker contained in an email."
    )
    
    public static let vpnAlertRegularTrackerTypePlural = NSLocalizedString(
      "privacyHub.vpnAlertRegularTrackerTypePlural",
      bundle: .braveShared,
      value: "Trackers & Ads",
      comment: "Type of tracker blocked by the VPN, it's a regular tracker or an ad."
    )
    
    public static let vpnAlertLocationTrackerTypePlural = NSLocalizedString(
      "privacyHub.vpnAlertLocationTrackerTypePlural",
      bundle: .braveShared,
      value: "Location Pings",
      comment: "Type of tracker blocked by the VPN, it's a tracker that asks you for your location."
    )
    
    public static let vpnAlertEmailTrackerTypePlural = NSLocalizedString(
      "privacyHub.vpnAlertEmailTrackerTypePlural",
      bundle: .braveShared,
      value: "Email Trackers",
      comment: "Type of tracker blocked by the VPN, it's a tracker contained in an email."
    )
    
    public static let notificationTitle = NSLocalizedString(
      "privacyHub.notificationTitle",
      bundle: .braveShared,
      value: "Your weekly privacy report is ready",
      comment: "Title of a notification we show to the user, on tapping it, the Privacy Hub screen will open."
    )
    
    public static let notificationMessage = NSLocalizedString(
      "privacyHub.notificationMessage",
      bundle: .braveShared,
      value: "See a report of the ads & trackers Brave blocked this week, plus the riskiest sites you visited.",
      comment: "Message of a notification we show to the user, on tapping it, the Privacy Hub screen will open."
    )
    
    public static let settingsEnableShieldsTitle = NSLocalizedString(
      "privacyHub.settingsEnableShieldsTitle",
      bundle: .braveShared,
      value: "Capture Shields Data",
      comment: "Title of a setting that lets Brave monitor blocked network requests"
    )
    
    public static let settingsEnableShieldsFooter = NSLocalizedString(
      "privacyHub.settingsEnableShieldsFooter",
      bundle: .braveShared,
      value: "This setting will not affect the shield stats counter on the New Tab Page. Shields data is not captured when in Private Browsing Mode",
      comment: "This text explains a setting that lets Brave monitor blocked network requests"
    )
    
    public static let settingsEnableVPNAlertsTitle = NSLocalizedString(
      "privacyHub.settingsEnableVPNAlertsTitle",
      bundle: .braveShared,
      value: "Capture VPN Alerts",
      comment: "Title of a setting that lets Brave monitor blocked network requests captured by Brave VPN"
    )
    
    public static let settingsEnableVPNAlertsFooter = NSLocalizedString(
      "privacyHub.settingsEnableVPNAlertsFooter",
      bundle: .braveShared,
      value: "This setting has no effect if you have not purchased the Brave VPN",
      comment: "This text explains a setting that lets Brave monitor blocked network requests captured by Brave VPN"
    )
    
    public static let settingsSlearDataTitle = NSLocalizedString(
      "privacyHub.settingsSlearDataTitle",
      bundle: .braveShared,
      value: "Clear Privacy Hub Data",
      comment: "Button that lets user clear all blocked requests and vpn alerts data that Brave captured for them."
    )
    
    public static let clearAllDataPrompt = NSLocalizedString(
      "privacyHub.clearAllDataPrompt",
      bundle: .braveShared,
      value: "Clear all data?",
      comment: "A prompt message we show to the user if they want to clear all data gathered by the Privacy Reports Feature"
    )
    
    public static let clearAllDataAccessibility = NSLocalizedString(
      "privacyHub.clearAllDataAccessibility",
      bundle: .braveShared,
      value: "Clear Privacy Hub data",
      comment: "Accessibility label for the 'clear all data' button."
    )
    
    public static let privacyReportsDisclaimer = NSLocalizedString(
      "privacyHub.privacyReportsDisclaimer",
      bundle: .braveShared,
      value: "Privacy Hub data is stored locally and never sent anywhere.",
      comment: "Text of a disclaimer that explains how the data for generating privacy reprots is stored."
    )
    
    public static let onboardingButtonTitle = NSLocalizedString(
      "privacyHub.onboardingButtonTitle",
      bundle: .braveShared,
      value: "Open Privacy Hub",
      comment: "Text of a button that opens up a Privacy Reports screen."
    )
  }
}
