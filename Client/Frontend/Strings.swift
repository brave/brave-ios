/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct Strings {}

/// Return the main application bundle. Even if called from an extension. If for some reason we cannot find the
/// application bundle, the current bundle is returned, which will then result in an English base language string.
private func applicationBundle() -> Bundle {
    let bundle = Bundle.main
    guard bundle.bundleURL.pathExtension == "appex", let applicationBundleURL = (bundle.bundleURL as NSURL).deletingLastPathComponent?.deletingLastPathComponent() else {
        return bundle
    }
    return Bundle(url: applicationBundleURL) ?? bundle
}

extension Strings {
    public static let OKString = NSLocalizedString("OK", value: "OK", comment: "OK button")
    public static let CancelString = NSLocalizedString("Cancel", value: "Cancel", comment: "Label for Cancel button")
}

// Table date section titles.
extension Strings {
    public static let TableDateSectionTitleToday = NSLocalizedString("Today", value: "Today", comment: "History tableview section header")
    public static let TableDateSectionTitleYesterday = NSLocalizedString("Yesterday", value: "Yesterday", comment: "History tableview section header")
    public static let TableDateSectionTitleLastWeek = NSLocalizedString("LastWeek", value: "Last week", comment: "History tableview section header")
    public static let TableDateSectionTitleLastMonth = NSLocalizedString("LastMonth", value: "Last month", comment: "History tableview section header")
}

// Top Sites.
extension Strings {
    public static let TopSitesEmptyStateDescription = NSLocalizedString("TopSitesEmptyStateDescription", value: "Your most visited sites will show up here.", comment: "Description label for the empty Top Sites state.")
    public static let TopSitesEmptyStateTitle = NSLocalizedString("TopSitesEmptyStateTitle", value: "Welcome to Top Sites", comment: "The title for the empty Top Sites state")
    public static let TopSitesRemoveButtonAccessibilityLabel = NSLocalizedString("TopSitesRemovePageButton", value: "Remove page — %@", comment: "Button shown in editing mode to remove this site from the top sites panel.")
}

// Activity Stream.
extension Strings {
    public static let HighlightIntroTitle = NSLocalizedString("ActivityStreamHighlightIntroTitle", value: "Be on the Lookout", comment: "The title that appears for the introduction to highlights in AS.")
    public static let HighlightIntroDescription = NSLocalizedString("ActivityStreamHighlightIntroDescription", value: "Firefox will place things here that you’ve discovered on the web so you can find your way back to the great articles, videos, bookmarks and other pages", comment: "The detailed text that explains what highlights are in AS.")
    public static let ASPageControlButton = NSLocalizedString("ActivityStreamPageControlButton", value: "Next Page", comment: "The page control button that lets you switch between pages in top sites")
    public static let ASHighlightsTitle =  NSLocalizedString("ActivityStreamHighlightsTitle", value: "Highlights", comment: "Section title label for the Highlights section")
    public static let ASTopSitesTitle =  NSLocalizedString("ActivityStreamTopSitesSectionTitle", value: "Top Sites", comment: "Section title label for Top Sites")
    public static let HighlightVistedText = NSLocalizedString("ActivityStreamHighlightsVisited", value: "Visited", comment: "The description of a highlight if it is a site the user has visited")
    public static let HighlightBookmarkText = NSLocalizedString("ActivityStreamHighlightsBookmark", value: "Bookmarked", comment: "The description of a highlight if it is a site the user has bookmarked")
}

// Home Panel Context Menu.
extension Strings {
    public static let OpenInNewTabContextMenuTitle = NSLocalizedString("HomePanelContextMenuOpenInNewTab", value: "Open in New Tab", comment: "The title for the Open in New Tab context menu action for sites in Home Panels")
    public static let OpenInNewPrivateTabContextMenuTitle = NSLocalizedString("HomePanelContextMenuOpenInNewPrivateTab", value: "Open in New Private Tab", comment: "The title for the Open in New Private Tab context menu action for sites in Home Panels")
    public static let BookmarkContextMenuTitle = NSLocalizedString("HomePanelContextMenuBookmark", value: "Bookmark", comment: "The title for the Bookmark context menu action for sites in Home Panels")
    public static let RemoveBookmarkContextMenuTitle = NSLocalizedString("HomePanelContextMenuRemoveBookmark", value: "Remove Bookmark", comment: "The title for the Remove Bookmark context menu action for sites in Home Panels")
    public static let DeleteFromHistoryContextMenuTitle = NSLocalizedString("HomePanelContextMenuDeleteFromHistory", value: "Delete from History", comment: "The title for the Delete from History context menu action for sites in Home Panels")
    public static let ShareContextMenuTitle = NSLocalizedString("HomePanelContextMenuShare", value: "Share", comment: "The title for the Share context menu action for sites in Home Panels")
    public static let RemoveContextMenuTitle = NSLocalizedString("HomePanelContextMenuRemove", value: "Remove", comment: "The title for the Remove context menu action for sites in Home Panels")
    public static let PinTopsiteActionTitle = NSLocalizedString("ActivityStreamContextMenuPinTopsite", value: "Pin to Top Sites", comment: "The title for the pinning a topsite action")
    public static let RemovePinTopsiteActionTitle = NSLocalizedString("ActivityStreamContextMenuRemovePinTopsite", value: "Remove Pinned Site", comment: "The title for removing a pinned topsite action")
}

//  PhotonActionSheet Strings
extension Strings {
    public static let CloseButtonTitle = NSLocalizedString("PhotonMenuClose", value: "Close", comment: "Button for closing the menu action sheet")

}

// Settings.
extension Strings {
    public static let SettingsGeneralSectionTitle = NSLocalizedString("SettingsGeneralSectionName", value: "General", comment: "General settings section title")
    public static let SettingsClearPrivateDataClearButton = NSLocalizedString("SettingsClearPrivateDataClearButton", value: "Clear Private Data", comment: "Button in settings that clears private data for the selected items.")
    public static let SettingsClearPrivateDataSectionName = NSLocalizedString("SettingsClearPrivateDataSectionName", value: "Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsClearPrivateDataTitle = NSLocalizedString("SettingsClearPrivateDataTitle", value: "Clear Private Data", comment: "Title displayed in header of the setting panel.")
    public static let SettingsDisconnectSyncAlertTitle = NSLocalizedString("SettingsDisconnectTitle", value: "Disconnect Sync?", comment: "Title of the alert when prompting the user asking to disconnect.")
    public static let SettingsDisconnectSyncAlertBody = NSLocalizedString("SettingsDisconnectBody", value: "Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.", comment: "Body of the alert when prompting the user asking to disconnect.")
    public static let SettingsDisconnectSyncButton = NSLocalizedString("SettingsDisconnectButton", value: "Disconnect Sync", comment: "Button displayed at the bottom of settings page allowing users to Disconnect from FxA")
    public static let SettingsDisconnectCancelAction = NSLocalizedString("SettingsDisconnectCancelButton", value: "Cancel", comment: "Cancel action button in alert when user is prompted for disconnect")
    public static let SettingsDisconnectDestructiveAction = NSLocalizedString("SettingsDisconnectDestructiveButton", value: "Disconnect", comment: "Destructive action button in alert when user is prompted for disconnect")
    public static let SettingsSearchDoneButton = NSLocalizedString("SettingsSearchDoneButton", value: "Done", comment: "Button displayed at the top of the search settings.")
    public static let SettingsSearchEditButton = NSLocalizedString("SettingsSearchEditButton", value: "Edit", comment: "Button displayed at the top of the search settings.")
    public static let UseTouchID = NSLocalizedString("UseTouchID", value: "Use Touch ID", comment: "List section title for when to use Touch ID")
    public static let UseFaceID = NSLocalizedString("UseFaceID", value: "Use Face ID", comment: "List section title for when to use Face ID")
}

// Logins Helper.
extension Strings {
    public static let LoginsHelperSaveLoginButtonTitle = NSLocalizedString("LoginsHelperSaveLoginButton", value: "Save Login", comment: "Button to save the user's password")
    public static let LoginsHelperDontSaveButtonTitle = NSLocalizedString("LoginsHelperDontSaveButton", value: "Don’t Save", comment: "Button to not save the user's password")
    public static let LoginsHelperUpdateButtonTitle = NSLocalizedString("LoginsHelperUpdateButton", value: "Update", comment: "Button to update the user's password")
    public static let LoginsHelperDontUpdateButtonTitle = NSLocalizedString("LoginsHelperDontUpdateButton", value: "Don’t Update", comment: "Button to not update the user's password")
}

// Downloads Panel
extension Strings {
    public static let DownloadsPanelEmptyStateTitle = NSLocalizedString("DownloadsPanelEmptyStateTitle", value: "Downloaded files will show up here.", comment: "Title for the Downloads Panel empty state.")
}

// History Panel
extension Strings {
    public static let SyncedTabsTableViewCellTitle = NSLocalizedString("HistoryPanelSyncedTabsCellTitle", value: "Synced Devices", comment: "Title for the Synced Tabs Cell in the History Panel")
    public static let HistoryBackButtonTitle = NSLocalizedString("HistoryPanelHistoryBackButtonTitle", value: "History", comment: "Title for the Back to History button in the History Panel")
    public static let HistoryPanelEmptyStateTitle = NSLocalizedString("HistoryPanelEmptyStateTitle", value: "Websites you’ve visited recently will show up here.", comment: "Title for the History Panel empty state.")
    public static let RecentlyClosedTabsButtonTitle = NSLocalizedString("HistoryPanelRecentlyClosedTabsButtonTitle", value: "Recently Closed", comment: "Title for the Recently Closed button in the History Panel")
    public static let RecentlyClosedTabsPanelTitle = NSLocalizedString("RecentlyClosedTabsPanelTitle", value: "Recently Closed", comment: "Title for the Recently Closed Tabs Panel")
}

// Syncing
extension Strings {
    public static let SyncingMessageWithEllipsis = NSLocalizedString("SyncSyncingEllipsisLabel", value: "Syncing…", comment: "Message displayed when the user's account is syncing with ellipsis at the end")
    public static let SyncingMessageWithoutEllipsis = NSLocalizedString("SyncSyncingLabel", value: "Syncing", comment: "Message displayed when the user's account is syncing with no ellipsis")

    public static func localizedStringForSyncComponent(_ componentName: String) -> String? {
        switch componentName {
        case "bookmarks":
            return NSLocalizedString("SyncStateBookmarkTitle", value: "Bookmarks", comment: "The Bookmark sync component, used in SyncState.Partial.Title")
        case "clients":
            return NSLocalizedString("SyncStateClientsTitle", value: "Remote Clients", comment: "The Remote Clients sync component, used in SyncState.Partial.Title")
        case "tabs":
            return NSLocalizedString("SyncStateTabsTitle", value: "Tabs", comment: "The Tabs sync component, used in SyncState.Partial.Title")
        case "logins":
            return NSLocalizedString("SyncStateLoginsTitle", value: "Logins", comment: "The Logins sync component, used in SyncState.Partial.Title")
        case "history":
            return NSLocalizedString("SyncStateHistoryTitle", value: "History", comment: "The History sync component, used in SyncState.Partial.Title")
        default: return nil
        }
    }
}

// Firefox Logins
extension Strings {
    public static let SaveLoginUsernamePrompt = NSLocalizedString("LoginsHelperPromptSaveLoginTitle", value: "Save login %@ for %@?", comment: "Prompt for saving a login. The first parameter is the username being saved. The second parameter is the hostname of the site.")
    public static let SaveLoginPrompt = NSLocalizedString("LoginsHelperPromptSavePasswordTitle", value: "Save password for %@?", comment: "Prompt for saving a password with no username. The parameter is the hostname of the site.")
    public static let UpdateLoginUsernamePrompt = NSLocalizedString("LoginsHelperPromptUpdateLoginTitle", value: "Update login %@ for %@?", comment: "Prompt for updating a login. The first parameter is the username for which the password will be updated for. The second parameter is the hostname of the site.")
    public static let UpdateLoginPrompt = NSLocalizedString("LoginsHelperPromptUpdateLoginTitle", value: "Update login %@ for %@?", comment: "Prompt for updating a login. The first parameter is the username for which the password will be updated for. The second parameter is the hostname of the site.")
}

//Hotkey Titles
extension Strings {
    public static let ReloadPageTitle = NSLocalizedString("HotkeysReloadDiscoveryTitle", value: "Reload Page", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let BackTitle = NSLocalizedString("HotkeysBackDiscoveryTitle", value: "Back", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ForwardTitle = NSLocalizedString("HotkeysForwardDiscoveryTitle", value: "Forward", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")

    public static let FindTitle = NSLocalizedString("HotkeysFindDiscoveryTitle", value: "Find", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let SelectLocationBarTitle = NSLocalizedString("HotkeysSelectLocationBarDiscoveryTitle", value: "Select Location Bar", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let NewTabTitle = NSLocalizedString("HotkeysNewTabDiscoveryTitle", value: "New Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let NewPrivateTabTitle = NSLocalizedString("HotkeysNewPrivateTabDiscoveryTitle", value: "New Private Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let CloseTabTitle = NSLocalizedString("HotkeysCloseTabDiscoveryTitle", value: "Close Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ShowNextTabTitle = NSLocalizedString("HotkeysShowNextTabDiscoveryTitle", value: "Show Next Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ShowPreviousTabTitle = NSLocalizedString("HotkeysShowPreviousTabDiscoveryTitle", value: "Show Previous Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
}

// Home page.
extension Strings {
    public static let SettingsHomePageSectionName = NSLocalizedString("SettingsHomePageSectionName", value: "Homepage", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the home page and its uses.")
    public static let SettingsHomePageTitle = NSLocalizedString("SettingsHomePageTitle", value: "Homepage Settings", comment: "Title displayed in header of the setting panel.")
    public static let SettingsHomePageURLSectionTitle = NSLocalizedString("SettingsHomePageURLTitle", value: "Current Homepage", comment: "Title of the setting section containing the URL of the current home page.")
    public static let SettingsHomePageUseCurrentPage = NSLocalizedString("SettingsHomePageUseCurrentButton", value: "Use Current Page", comment: "Button in settings to use the current page as home page.")
    public static let SettingsHomePagePlaceholder = NSLocalizedString("SettingsHomePageURLPlaceholder", value: "Enter a webpage", comment: "Placeholder text in the homepage setting when no homepage has been set.")
    public static let SettingsHomePageUseCopiedLink = NSLocalizedString("SettingsHomePageUseCopiedLinkButton", value: "Use Copied Link", comment: "Button in settings to use the current link on the clipboard as home page.")
    public static let SettingsHomePageUseDefault = NSLocalizedString("SettingsHomePageUseDefaultButton", value: "Use Default", comment: "Button in settings to use the default home page. If no default is set, then this button isn't shown.")
    public static let SettingsHomePageClear = NSLocalizedString("SettingsHomePageClearButton", value: "Clear", comment: "Button in settings to clear the home page.")
    public static let SetHomePageDialogTitle = NSLocalizedString("HomePageSetDialogTitle", value: "Do you want to use this web page as your home page?", comment: "Alert dialog title when the user opens the home page for the first time.")
    public static let SetHomePageDialogMessage = NSLocalizedString("HomePageSetDialogMessage", value: "You can change this at any time in Settings", comment: "Alert dialog body when the user opens the home page for the first time.")
    public static let SetHomePageDialogYes = NSLocalizedString("HomePageSetDialogOK", value: "Set Homepage", comment: "Button accepting changes setting the home page for the first time.")
    public static let SetHomePageDialogNo = NSLocalizedString("HomePageSetDialogCancel", value: "Cancel", comment: "Button cancelling changes setting the home page for the first time.")
}

// New tab choice settings
extension Strings {
    public static let SettingsNewTabSectionName = NSLocalizedString("SettingsNewTabSectionName", value: "New Tab", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the new tab behaviour.")
    public static let SettingsNewTabTitle = NSLocalizedString("SettingsNewTabTitle", value: "New Tab Settings", comment: "Title displayed in header of the setting panel.")
    public static let SettingsNewTabTopSites = NSLocalizedString("SettingsNewTabOptionTopSites", value: "Show your Top Sites", comment: "Option in settings to show top sites when you open a new tab")
    public static let SettingsNewTabBookmarks = NSLocalizedString("SettingsNewTabOptionBookmarks", value: "Show your Bookmarks", comment: "Option in settings to show bookmarks when you open a new tab")
    public static let SettingsNewTabHistory = NSLocalizedString("SettingsNewTabOptionHistory", value: "Show your History", comment: "Option in settings to show history when you open a new tab")
    public static let SettingsNewTabReadingList = NSLocalizedString("SettingsNewTabOptionReadingList", value: "Show your Reading List", comment: "Option in settings to show reading list when you open a new tab")
    public static let SettingsNewTabBlankPage = NSLocalizedString("SettingsNewTabOptionBlankPage", value: "Show a Blank Page", comment: "Option in settings to show a blank page when you open a new tab")
    public static let SettingsNewTabHomePage = NSLocalizedString("SettingsNewTabOptionHomePage", value: "Show your Homepage", comment: "Option in settings to show your homepage when you open a new tab")
    public static let SettingsNewTabDescription = NSLocalizedString("SettingsNewTabDescription", value: "When you open a New Tab:", comment: "A description in settings of what the new tab choice means")
    // AS Panel settings
    public static let SettingsNewTabASTitle = NSLocalizedString("SettingsNewTabOptionASTitle", value: "Additional Content", comment: "The title of the section in newtab that lets you modify the topsites panel")
    public static let SettingsNewTabHiglightsHistory = NSLocalizedString("SettingsNewTabOptionHighlightsHistory", value: "Visited", comment: "Option in settings to turn off history in the highlights section")
    public static let SettingsNewTabHighlightsBookmarks = NSLocalizedString("SettingsNewTabOptionHighlightsBookmarks", value: "Recent Bookmarks", comment: "Option in the settings to turn off recent bookmarks in the Highlights section")
}

// Custom account settings - These strings did not make it for the v10 l10n deadline so we have turned them into regular strings. These strings will come back localized in a next version.

extension Strings {
    // Settings.AdvanceAccount.SectionName
    // Label used as an item in Settings. When touched it will open a dialog to setup advance Firefox account settings.
    public static let SettingsAdvanceAccountSectionName = "Account Settings"

    // Settings.AdvanceAccount.SectionFooter
    // Details for using custom Firefox Account service.
    public static let SettingsAdvanceAccountSectionFooter = "To use a custom Firefox Account and sync servers, specify the root Url of the Firefox Account site. This will download the configuration and setup this device to use the new service. After the new service has been set, you will need to create a new Firefox Account or login with an existing one."

    // Settings.AdvanceAccount.SectionName
    // Title displayed in header of the setting panel.
    public static let SettingsAdvanceAccountTitle = "Advance Account Settings"

    // Settings.AdvanceAccount.UrlPlaceholder
    // Title displayed in header of the setting panel.
    public static let SettingsAdvanceAccountUrlPlaceholder = "Custom Account Url"

    // Settings.AdvanceAccount.UpdatedAlertMessage
    // Messaged displayed when sync service has been successfully set.
    public static let SettingsAdvanceAccountUrlUpdatedAlertMessage = "Firefox account service updated. To begin using custom server, please log out and re-login."

    // Settings.AdvanceAccount.UpdatedAlertOk
    // Ok button on custom sync service updated alert
    public static let SettingsAdvanceAccountUrlUpdatedAlertOk = "OK"

    // Settings.AdvanceAccount.ErrorAlertTitle
    // Error alert message title.
    public static let SettingsAdvanceAccountUrlErrorAlertTitle = "Error"

    // Settings.AdvanceAccount.ErrorAlertMessage
    // Messaged displayed when sync service has an error setting a custom sync url.
    public static let SettingsAdvanceAccountUrlErrorAlertMessage = "There was an error while attempting to parse the url. Please make sure that it is a valid Firefox Account root url."

    // Settings.AdvanceAccount.ErrorAlertOk
    // Ok button on custom sync service error alert.
    public static let SettingsAdvanceAccountUrlErrorAlertOk = "OK"

    // Settings.AdvanceAccount.UseCustomAccountsServiceTitle
    // Toggle switch to use custom FxA server
    public static let SettingsAdvanceAccountUseCustomAccountsServiceTitle = "Use Custom Account Service"

    // Settings.AdvanceAccount.UrlEmptyErrorAlertMessage
    // No custom service set.
    public static let SettingsAdvanceAccountEmptyUrlErrorAlertMessage = "Please enter a custom account url before enabling."
}

// Open With Settings
extension Strings {
    public static let SettingsOpenWithSectionName = NSLocalizedString("SettingsOpenWithSectionName", value: "Mail App", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the open with (mail links) behaviour.")
    public static let SettingsOpenWithPageTitle = NSLocalizedString("SettingsOpenWithPageTitle", value: "Open mail links with", comment: "Title for Open With Settings")
}

// Third Party Search Engines
extension Strings {
    public static let ThirdPartySearchEngineAdded = NSLocalizedString("SearchThirdPartyEnginesAddSuccess", value: "Added Search engine!", comment: "The success message that appears after a user sucessfully adds a new search engine")
    public static let ThirdPartySearchAddTitle = NSLocalizedString("SearchThirdPartyEnginesAddTitle", value: "Add Search Provider?", comment: "The title that asks the user to Add the search provider")
    public static let ThirdPartySearchAddMessage = NSLocalizedString("SearchThirdPartyEnginesAddMessage", value: "The new search engine will appear in the quick search bar.", comment: "The message that asks the user to Add the search provider explaining where the search engine will appear")
    public static let ThirdPartySearchCancelButton = NSLocalizedString("SearchThirdPartyEnginesCancel", value: "Cancel", comment: "The cancel button if you do not want to add a search engine.")
    public static let ThirdPartySearchOkayButton = NSLocalizedString("SearchThirdPartyEnginesOK", value: "OK", comment: "The confirmation button")
    public static let ThirdPartySearchFailedTitle = NSLocalizedString("SearchThirdPartyEnginesFailedTitle", value: "Failed", comment: "A title explaining that we failed to add a search engine")
    public static let ThirdPartySearchFailedMessage = NSLocalizedString("SearchThirdPartyEnginesFailedMessage", value: "The search provider could not be added.", comment: "A title explaining that we failed to add a search engine")
    public static let CustomEngineFormErrorTitle = NSLocalizedString("SearchThirdPartyEnginesFormErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.")
    public static let CustomEngineFormErrorMessage = NSLocalizedString("SearchThirdPartyEnginesFormErrorMessage", value: "Please fill all fields correctly.", comment: "A message explaining fault in custom search engine form.")
    public static let CustomEngineDuplicateErrorTitle = NSLocalizedString("SearchThirdPartyEnginesDuplicateErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.")
    public static let CustomEngineDuplicateErrorMessage = NSLocalizedString("SearchThirdPartyEnginesDuplicateErrorMessage", value: "A search engine with this title or URL has already been added.", comment: "A message explaining fault in custom search engine form.")
}

// Bookmark Management
extension Strings {
    public static let BookmarksTitle = NSLocalizedString("BookmarksTitleLabel", value: "Title", comment: "The label for the title of a bookmark")
    public static let BookmarksURL = NSLocalizedString("BookmarksURLLabel", value: "URL", comment: "The label for the URL of a bookmark")
    public static let BookmarksFolder = NSLocalizedString("BookmarksFolderLabel", value: "Folder", comment: "The label to show the location of the folder where the bookmark is located")
    public static let BookmarksNewFolder = NSLocalizedString("BookmarksNewFolderLabel", value: "New Folder", comment: "The button to create a new folder")
    public static let BookmarksFolderName = NSLocalizedString("BookmarksFolderNameLabel", value: "Folder Name", comment: "The label for the title of the new folder")
    public static let BookmarksFolderLocation = NSLocalizedString("BookmarksFolderLocationLabel", value: "Location", comment: "The label for the location of the new folder")
}

// Tabs Delete All Undo Toast
extension Strings {
    public static let TabsDeleteAllUndoTitle = NSLocalizedString("TabsDeleteAllUndoTitle", value: "%d tab(s) closed", comment: "The label indicating that all the tabs were closed")
    public static let TabsDeleteAllUndoAction = NSLocalizedString("TabsDeleteAllUndoButton", value: "Undo", comment: "The button to undo the delete all tabs")
}

//Clipboard Toast
extension Strings {
    public static let GoToCopiedLink = NSLocalizedString("ClipboardToastGoToCopiedLinkTitle", value: "Go to copied link?", comment: "Message displayed when the user has a copied link on the clipboard")
    public static let GoButtonTittle = NSLocalizedString("ClipboardToastGoToCopiedLinkButton", value: "Go", comment: "The button to open a new tab with the copied link")

    public static let SettingsOfferClipboardBarTitle = NSLocalizedString("SettingsOfferClipboardBarTitle", value: "Offer to Open Copied Links", comment: "Title of setting to enable the Go to Copied URL feature. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
    public static let SettingsOfferClipboardBarStatus = NSLocalizedString("SettingsOfferClipboardBarStatus", value: "When Opening Firefox", comment: "Description displayed under the ”Offer to Open Copied Link” option. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
}

// errors
extension Strings {
    public static let UnableToDownloadError = NSLocalizedString("DownloadsErrorMessage", value: "Downloads aren’t supported in Firefox yet.", comment: "The message displayed to a user when they try and perform the download of an asset that Firefox cannot currently handle.")
    public static let UnableToAddPassErrorTitle = NSLocalizedString("AddPassErrorTitle", value: "Failed to Add Pass", comment: "Title of the 'Add Pass Failed' alert. See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorMessage = NSLocalizedString("AddPassErrorMessage", value: "An error occured while adding the pass to Wallet. Please try again later.", comment: "Text of the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorDismiss = NSLocalizedString("AddPassErrorDismiss", value: "OK", comment: "Button to dismiss the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToOpenURLError = NSLocalizedString("OpenURLErrorMessage", value: "Firefox cannot open the page because it has an invalid address.", comment: "The message displayed to a user when they try to open a URL that cannot be handled by Firefox, or any external app.")
    public static let UnableToOpenURLErrorTitle = NSLocalizedString("OpenURLErrorTitle", value: "Cannot Open Page", comment: "Title of the message shown when the user attempts to navigate to an invalid link.")
}

// Download Helper
extension Strings {
    public static let OpenInDownloadHelperAlertDownloadNow = NSLocalizedString("DownloadsAlertDownloadNow", value: "Download Now", comment: "The label of the button the user will press to start downloading a file")
    public static let DownloadsButtonTitle = NSLocalizedString("DownloadsToastGoToDownloadsButton", value: "Downloads", comment: "The button to open a new tab with the Downloads home panel")
    public static let CancelDownloadDialogTitle = NSLocalizedString("DownloadsCancelDialogTitle", value: "Cancel Download", comment: "Alert dialog title when the user taps the cancel download icon.")
    public static let CancelDownloadDialogMessage = NSLocalizedString("DownloadsCancelDialogMessage", value: "Are you sure you want to cancel this download?", comment: "Alert dialog body when the user taps the cancel download icon.")
    public static let CancelDownloadDialogResume = NSLocalizedString("DownloadsCancelDialogResume", value: "Resume", comment: "Button declining the cancellation of the download.")
    public static let CancelDownloadDialogCancel = NSLocalizedString("DownloadsCancelDialogCancel", value: "Cancel", comment: "Button confirming the cancellation of the download.")
    public static let DownloadCancelledToastLabelText = NSLocalizedString("DownloadsToastCancelledLabelText", value: "Download Cancelled", comment: "The label text in the Download Cancelled toast for showing confirmation that the download was cancelled.")
    public static let DownloadFailedToastLabelText = NSLocalizedString("DownloadsToastFailedLabelText", value: "Download Failed", comment: "The label text in the Download Failed toast for showing confirmation that the download has failed.")
    public static let DownloadFailedToastButtonTitled = NSLocalizedString("DownloadsToastFailedRetryButton", value: "Retry", comment: "The button to retry a failed download from the Download Failed toast.")
    public static let DownloadMultipleFilesToastDescriptionText = NSLocalizedString("DownloadsToastMultipleFilesDescriptionText", value: "1 of %d files", comment: "The description text in the Download progress toast for showing the number of files when multiple files are downloading.")
    public static let DownloadProgressToastDescriptionText = NSLocalizedString("DownloadsToastProgressDescriptionText", value: "%1$@/%2$@", comment: "The description text in the Download progress toast for showing the downloaded file size (1$) out of the total expected file size (2$).")
    public static let DownloadMultipleFilesAndProgressToastDescriptionText = NSLocalizedString("DownloadsToastMultipleFilesAndProgressDescriptionText", value: "%1$@ %2$@", comment: "The description text in the Download progress toast for showing the number of files (1$) and download progress (2$). This string only consists of two placeholders for purposes of displaying two other strings side-by-side where 1$ is Downloads.Toast.MultipleFiles.DescriptionText and 2$ is Downloads.Toast.Progress.DescriptionText. This string should only consist of the two placeholders side-by-side separated by a single space and 1$ should come before 2$ everywhere except for right-to-left locales.")
}

// Add Custom Search Engine
//extension Strings {
//    public static let SettingsAddCustomEngine = NSLocalizedString("SettingsAddCustomEngine", value: "Add Search Engine", comment: "The button text in Search Settings that opens the Custom Search Engine view.")
//    public static let SettingsAddCustomEngineTitle = NSLocalizedString("SettingsAddCustomEngineTitle", value: "Add Search Engine", comment: "The title of the  Custom Search Engine view.")
//    public static let SettingsAddCustomEngineTitleLabel = NSLocalizedString("SettingsAddCustomEngineTitleLabel", value: "Title", comment: "The title for the field which sets the title for a custom search engine.")
//    public static let SettingsAddCustomEngineURLLabel = NSLocalizedString("SettingsAddCustomEngineURLLabel", value: "URL", comment: "The title for URL Field")
//    public static let SettingsAddCustomEngineTitlePlaceholder = NSLocalizedString("SettingsAddCustomEngineTitlePlaceholder", value: "Search Engine", comment: "The placeholder for Title Field when saving a custom search engine.")
//    public static let SettingsAddCustomEngineURLPlaceholder = NSLocalizedString("SettingsAddCustomEngineURLPlaceholder", value: "URL (Replace Query with %s)", comment: "The placeholder for URL Field when saving a custom search engine")
//    public static let SettingsAddCustomEngineSaveButtonText = NSLocalizedString("SettingsAddCustomEngineSaveButtonText", value: "Save", comment: "The text on the Save button when saving a custom search engine")
//}

// Context menu ButtonToast instances.
extension Strings {
    public static let ContextMenuButtonToastNewTabOpenedLabelText = NSLocalizedString("ContextMenuButtonToastNewTabOpenedLabelText", value: "New Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Tab.")
    public static let ContextMenuButtonToastNewTabOpenedButtonText = NSLocalizedString("ContextMenuButtonToastNewTabOpenedButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Tab.")
    public static let ContextMenuButtonToastNewPrivateTabOpenedLabelText = NSLocalizedString("ContextMenuButtonToastNewPrivateTabOpenedLabelText", value: "New Private Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Private Tab.")
    public static let ContextMenuButtonToastNewPrivateTabOpenedButtonText = NSLocalizedString("ContextMenuButtonToastNewPrivateTabOpenedButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Private Tab.")
}

// Reader Mode.
extension Strings {
    public static let ReaderModeAvailableVoiceOverAnnouncement = NSLocalizedString("ReaderModeAvailableVoiceOverAnnouncement", value: "Reader Mode available", comment: "Accessibility message e.g. spoken by VoiceOver when Reader Mode becomes available.")
    public static let ReaderModeResetFontSizeAccessibilityLabel = NSLocalizedString("ResetTextSize", value: "Reset text size", comment: "Accessibility label for button resetting font size in display settings of reader mode")
}

// QR Code scanner.
extension Strings {
    public static let ScanQRCodeViewTitle = NSLocalizedString("ScanQRCodeViewTitle", value: "Scan QR Code", comment: "Title for the QR code scanner view.")
    public static let ScanQRCodeInstructionsLabel = NSLocalizedString("ScanQRCodeInstructionsLabel", value: "Align QR code within frame to scan", comment: "Text for the instructions label, displayed in the QR scanner view")
    public static let ScanQRCodeInvalidDataErrorMessage = NSLocalizedString("ScanQRCodeInvalidDataErrorMessage", value: "The data is invalid", comment: "Text of the prompt that is shown to the user when the data is invalid")
    public static let ScanQRCodePermissionErrorMessage = NSLocalizedString("ScanQRCodePermissionErrorMessage", value: "Please allow Firefox to access your device’s camera in ‘Settings’ -> ‘Privacy’ -> ‘Camera’.", comment: "Text of the prompt user to setup the camera authorization.")
    public static let ScanQRCodeErrorOKButton = NSLocalizedString("ScanQRCodeErrorOKButton", value: "OK", comment: "OK button to dismiss the error prompt.")
}

// App menu.
extension Strings {
    public static let AppMenuAddToReadingListTitleString = NSLocalizedString("MenuAddToReadingListTitle", value: "Add to Reading List", comment: "Label for the button, displayed in the menu, used to add a page to the reading list.")
    public static let AppMenuShowTabsTitleString = NSLocalizedString("MenuShowTabsTitle", value: "Show Tabs", comment: "Label for the button, displayed in the menu, used to open the tabs tray")
    public static let AppMenuSharePageTitleString = NSLocalizedString("MenuSharePageActionTitle", value: "Share Page With…", comment: "Label for the button, displayed in the menu, used to open the share dialog.")
    public static let AppMenuCopyURLTitleString = NSLocalizedString("MenuCopyAddressTitle", value: "Copy Address", comment: "Label for the button, displayed in the menu, used to copy the page url to the clipboard.")
    public static let AppMenuNewTabTitleString = NSLocalizedString("MenuNewTabActionTitle", value: "Open New Tab", comment: "Label for the button, displayed in the menu, used to open a new tab")
    public static let AppMenuNewPrivateTabTitleString = NSLocalizedString("MenuNewPrivateTabActionTitle", value: "Open New Private Tab", comment: "Label for the button, displayed in the menu, used to open a new private tab.")
    public static let AppMenuAddBookmarkTitleString = NSLocalizedString("MenuAddBookmarkActionTitle", value: "Bookmark This Page", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.")
    public static let AppMenuRemoveBookmarkTitleString = NSLocalizedString("MenuRemoveBookmarkActionTitle", value: "Remove Bookmark", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.")
    public static let AppMenuFindInPageTitleString = NSLocalizedString("MenuFindInPageActionTitle", value: "Find in Page", comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.")
    public static let AppMenuViewDesktopSiteTitleString = NSLocalizedString("MenuViewDekstopSiteActionTitle", value: "Request Desktop Site", comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.")
    public static let AppMenuViewMobileSiteTitleString = NSLocalizedString("MenuViewMobileSiteActionTitle", value: "Request Mobile Site", comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.")
    public static let AppMenuScanQRCodeTitleString = NSLocalizedString("MenuScanQRCodeActionTitle", value: "Scan QR Code", comment: "Label for the button, displayed in the menu, used to open the QR code scanner.")
    public static let AppMenuSettingsTitleString = NSLocalizedString("MenuOpenSettingsActionTitle", value: "Settings", comment: "Label for the button, displayed in the menu, used to open the Settings menu.")
    public static let AppMenuCloseAllTabsTitleString = NSLocalizedString("MenuCloseAllTabsActionTitle", value: "Close All Tabs", comment: "Label for the button, displayed in the menu, used to close all tabs currently open.")
    public static let AppMenuOpenHomePageTitleString = NSLocalizedString("MenuOpenHomePageActionTitle", value: "Open Homepage", comment: "Label for the button, displayed in the menu, used to navigate to the home page.")
    public static let AppMenuTopSitesTitleString = NSLocalizedString("MenuOpenTopSitesActionAccessibilityLabel", value: "Top Sites", comment: "Accessibility label for the button, displayed in the menu, used to open the Top Sites home panel.")
    public static let AppMenuBookmarksTitleString = NSLocalizedString("MenuOpenBookmarksActionAccessibilityLabel", value: "Bookmarks", comment: "Accessibility label for the button, displayed in the menu, used to open the Bbookmarks home panel.")
    public static let AppMenuReadingListTitleString = NSLocalizedString("MenuOpenReadingListActionAccessibilityLabel", value: "Reading List", comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel.")
    public static let AppMenuHistoryTitleString = NSLocalizedString("MenuOpenHistoryActionAccessibilityLabel", value: "History", comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel.")
    public static let AppMenuDownloadsTitleString = NSLocalizedString("MenuOpenDownloadsActionAccessibilityLabel", value: "Downloads", comment: "Accessibility label for the button, displayed in the menu, used to open the Downloads home panel.")
    public static let AppMenuButtonAccessibilityLabel = NSLocalizedString("ToolbarMenuAccessibilityLabel", value: "Menu", comment: "Accessibility label for the Menu button.")
    public static let TabTrayDeleteMenuButtonAccessibilityLabel = NSLocalizedString("ToolbarMenuCloseAllTabs", value: "Close All Tabs", comment: "Accessibility label for the Close All Tabs menu button.")
    public static let AppMenuNightMode = NSLocalizedString("MenuNightModeTurnOnLabel", value: "Enable Night Mode", comment: "Label for the button, displayed in the menu, turns on night mode.")
    public static let AppMenuNoImageMode = NSLocalizedString("MenuNoImageModeHideImagesLabel", value: "Hide Images", comment: "Label for the button, displayed in the menu, hides images on the webpage when pressed.")
    public static let AppMenuCopyURLConfirmMessage = NSLocalizedString("MenuCopyURLConfirm", value: "URL Copied To Clipboard", comment: "Toast displayed to user after copy url pressed.")
    public static let AppMenuAddBookmarkConfirmMessage = NSLocalizedString("MenuAddBookmarkConfirm", value: "Bookmark Added", comment: "Toast displayed to the user after a bookmark has been added.")
    public static let AppMenuRemoveBookmarkConfirmMessage = NSLocalizedString("MenuRemoveBookmarkConfirm", value: "Bookmark Removed", comment: "Toast displayed to the user after a bookmark has been removed.")
    public static let AppMenuAddToReadingListConfirmMessage = NSLocalizedString("MenuAddToReadingListConfirm", value: "Added To Reading List", comment: "Toast displayed to the user after adding the item to their reading list.")
    public static let PageActionMenuTitle = NSLocalizedString("MenuPageActionsTitle", value: "Page Actions", comment: "Label for title in page action menu.")
}

// Snackbar shown when tapping app store link
extension Strings {
    public static let ExternalLinkAppStoreConfirmationTitle = NSLocalizedString("ExternalLinkAppStoreConfirmationTitle", value: "Open this link in the App Store app?", comment: "Question shown to user when tapping a link that opens the App Store app")
}

// ContentBlocker/TrackingProtection strings
//extension Strings {
//    public static let SettingsTrackingProtectionSectionName = NSLocalizedString("SettingsTrackingProtectionSectionName", value: "Tracking Protection", comment: "Row in top-level of settings that gets tapped to show the tracking protection settings detail view.")
//    public static let TrackingProtectionOptionOnInPrivateBrowsing = NSLocalizedString("SettingsTrackingProtectionOptionOnInPrivateBrowsingLabel", value: "Private Browsing Mode", comment: "Settings option to specify that Tracking Protection is on only in Private Browsing mode.")
//    public static let TrackingProtectionOptionOnInNormalBrowsing = NSLocalizedString("SettingsTrackingProtectionOptionOnInNormalBrowsingLabel", value: "Normal Browsing Mode", comment: "Settings option to specify that Tracking Protection is on only in Private Browsing mode.")
//    public static let TrackingProtectionOptionOnOffHeader = NSLocalizedString("SettingsTrackingProtectionOptionEnabledStateHeaderLabel", value: "Enable", comment: "Description label shown at the top of tracking protection options screen.")
//    public static let TrackingProtectionOptionOnOffFooter = NSLocalizedString("SettingsTrackingProtectionOptionEnabledStateFooterLabel", value: "Tracking is the collection of your browsing data across multiple websites.", comment: "Description label shown on tracking protection options screen.")
//    public static let TrackingProtectionOptionBlockListsTitle = NSLocalizedString("SettingsTrackingProtectionBlockListsTitle", value: "Block Lists", comment: "Title for tracking protection options section where Basic/Strict block list can be selected")
//    public static let TrackingProtectionOptionBlockListsHeader = NSLocalizedString("SettingsTrackingProtectionBlockListsHeader", value: "You can choose which list Firefox will use to block Web elements that may track your browsing activity.", comment: "Header description for tracking protection options section where Basic/Strict block list can be selected")
//    public static let TrackingProtectionOptionBlockListTypeBasic = NSLocalizedString("SettingsTrackingProtectionOptionBlockListBasic", value: "Basic (Recommended)", comment: "Tracking protection settings option for using the basic blocklist.")
//    public static let TrackingProtectionOptionBlockListTypeBasicDescription = NSLocalizedString("SettingsTrackingProtectionOptionBlockListBasicDescription", value: "Allows some trackers so websites function properly.", comment: "Tracking protection settings option description for using the basic blocklist.")
//    public static let TrackingProtectionOptionBlockListTypeStrict = NSLocalizedString("SettingsTrackingProtectionOptionBlockListStrict", value: "Strict", comment: "Tracking protection settings option for using the strict blocklist.")
//    public static let TrackingProtectionOptionBlockListTypeStrictDescription = NSLocalizedString("SettingsTrackingProtectionOptionBlockListStrictDescription", value: "Blocks known trackers. Some websites may not function properly.", comment: "Tracking protection settings option description for using the strict blocklist.")
//    public static let TrackingProtectionReloadWithout = NSLocalizedString("MenuReloadWithoutTrackingProtectionTitle", value: "Reload Without Tracking Protection", comment: "Label for the button, displayed in the menu, used to reload the current website without Tracking Protection")
//    public static let TrackingProtectionReloadWith = NSLocalizedString("MenuReloadWithTrackingProtectionTitle", value: "Reload With Tracking Protection", comment: "Label for the button, displayed in the menu, used to reload the current website with Tracking Protection enabled")
//}

// Tracking Protection menu
//extension Strings {
//    public static let TPMenuTitle = NSLocalizedString("MenuTrackingProtectionTitle", value: "Tracking Protection", comment: "Label for the button, displayed in the menu, used to get more info about Tracking Protection")
//    public static let TPBlockingDescription = NSLocalizedString("MenuTrackingProtectionBlockingDescription", value: "Firefox is blocking parts of the page that may track your browsing.", comment: "Description of the Tracking protection menu when TP is blocking parts of the page")
//    public static let TPNoBlockingDescription = NSLocalizedString("MenuTrackingProtectionNoBlockingDescription", value: "No tracking elements detected on this page.", comment: "The description of the Tracking Protection menu item when no scripts are blocked but tracking protection is enabled.")
//    public static let TPBlockingDisabledDescription = NSLocalizedString("MenuTrackingProtectionBlockingDisabledDescription", value: "Block online trackers", comment: "The description of the Tracking Protection menu item when tracking is enabled")
//    public static let TPBlockingMoreInfo = NSLocalizedString("MenuTrackingProtectionMoreInfoDescription", value: "Learn more about how Tracking Protection blocks online trackers that collect your browsing data across multiple websites.", comment: "more info about what tracking protection is about")
//    public static let EnableTPBlocking = NSLocalizedString("MenuTrackingProtectionEnableTitle", value: "Enable Tracking Protection", comment: "A button to enable tracking protection inside the menu.")
//    public static let TrackingProtectionEnabledConfirmed = NSLocalizedString("MenuTrackingProtectionEnabledTitle", value: "Tracking Protection is now on for this site.", comment: "The confirmation toast once tracking protection has been enabled")
//    public static let TrackingProtectionDisabledConfirmed = NSLocalizedString("MenuTrackingProtectionDisabledTitle", value: "Tracking Protection is now off for this site.", comment: "The confirmation toast once tracking protection has been disabled")
//    public static let TrackingProtectionDisableTitle = NSLocalizedString("MenuTrackingProtectionDisableTitle", value: "Disable for this site", comment: "The button that disabled TP for a site.")
//    public static let TrackingProtectionTotalBlocked = NSLocalizedString("MenuTrackingProtectionTotalBlockedTitle", value: "Total trackers blocked", comment: "The title that shows the total number of scripts blocked")
//    public static let TrackingProtectionAdsBlocked = NSLocalizedString("MenuTrackingProtectionAdsBlockedTitle", value: "Ad trackers", comment: "The title that shows the number of Analytics scripts blocked")
//    public static let TrackingProtectionAnalyticsBlocked = NSLocalizedString("MenuTrackingProtectionAnalyticsBlockedTitle", value: "Analytic trackers", comment: "The title that shows the number of Analytics scripts blocked")
//    public static let TrackingProtectionSocialBlocked = NSLocalizedString("MenuTrackingProtectionSocialBlockedTitle", value: "Social trackers", comment: "The title that shows the number of social scripts blocked")
//    public static let TrackingProtectionContentBlocked = NSLocalizedString("MenuTrackingProtectionContentBlockedTitle", value: "Content trackers", comment: "The title that shows the number of content scripts blocked")
//    public static let TrackingProtectionWhiteListOn = NSLocalizedString("MenuTrackingProtectionOptionWhiteListOnDescription", value: "The site includes elements that may track your browsing. You have disabled protection.", comment: "label for the menu item to show when the website is whitelisted from blocking trackers.")
//    public static let TrackingProtectionWhiteListRemove = NSLocalizedString("MenuTrackingProtectionWhitelistRemoveTitle", value: "Enable for this site", comment: "label for the menu item that lets you remove a website from the tracking protection whitelist")
//}

// Location bar long press menu
extension Strings {
    public static let PasteAndGoTitle = NSLocalizedString("MenuPasteAndGoTitle", value: "Paste & Go", comment: "The title for the button that lets you paste and go to a URL")
    public static let PasteTitle = NSLocalizedString("MenuPasteTitle", value: "Paste", comment: "The title for the button that lets you paste into the location bar")
    public static let CopyAddressTitle = NSLocalizedString("MenuCopyTitle", value: "Copy Address", comment: "The title for the button that lets you copy the url from the location bar.")
}
//
//// Settings Home
//extension Strings {
//    public static let SendUsageSettingTitle = NSLocalizedString("SettingsSendUsageTitle", value: "Send Usage Data", comment: "The title for the setting to send usage data.")
//    public static let SendUsageSettingLink = NSLocalizedString("SettingsSendUsageLink", value: "Learn More.", comment: "title for a link that explains how mozilla collects telemetry")
//    public static let SendUsageSettingMessage = NSLocalizedString("SettingsSendUsageMessage", value: "Mozilla strives to only collect what we need to provide and improve Firefox for everyone.", comment: "A short description that explains why mozilla collects usage data.")
//}
//
//// Do not track
//extension Strings {
//    public static let SettingsDoNotTrackTitle = NSLocalizedString("SettingsDNTTitle", value: "Send websites a Do Not Track signal that you don’t want to be tracked", comment: "DNT Settings title")
//    public static let SettingsDoNotTrackOptionOnWithTP = NSLocalizedString("SettingsDNTOptionOnWithTP", value: "Only when using Tracking Protection", comment: "DNT Settings option for only turning on when Tracking Protection is also on")
//    public static let SettingsDoNotTrackOptionAlwaysOn = NSLocalizedString("SettingsDNTOptionAlwaysOn", value: "Always", comment: "DNT Settings option for always on")
//}
//
//// Intro Onboarding slides
//extension Strings {
//    public static let CardTitleWelcome = NSLocalizedString("IntroSlidesWelcomeTitle", value: "Thanks for choosing Firefox!", comment: "Title for the first panel 'Welcome' in the First Run tour.")
//    public static let CardTitleSearch = NSLocalizedString("IntroSlidesSearchTitle", value: "Your search, your way", comment: "Title for the second  panel 'Search' in the First Run tour.")
//    public static let CardTitlePrivate = NSLocalizedString("IntroSlidesPrivateTitle", value: "Browse like no one’s watching", comment: "Title for the third panel 'Private Browsing' in the First Run tour.")
//    public static let CardTitleMail = NSLocalizedString("IntroSlidesMailTitle", value: "You’ve got mail… options", comment: "Title for the fourth panel 'Mail' in the First Run tour.")
//    public static let CardTitleSync = NSLocalizedString("IntroSlidesSyncTitle", value: "Pick up where you left off", comment: "Title for the fifth panel 'Sync' in the First Run tour.")
//
//    public static let CardTextWelcome = NSLocalizedString("IntroSlidesWelcomeDescription", value: "A modern mobile browser from Mozilla, the non-profit committed to a free and open web.", comment: "Description for the 'Welcome' panel in the First Run tour.")
//    public static let CardTextSearch = NSLocalizedString("IntroSlidesSearchDescription", value: "Searching for something different? Choose another default search engine (or add your own) in Settings.", comment: "Description for the 'Favorite Search Engine' panel in the First Run tour.")
//    public static let CardTextPrivate = NSLocalizedString("IntroSlidesPrivateDescription", value: "Tap the mask icon to slip into Private Browsing mode.", comment: "Description for the 'Private Browsing' panel in the First Run tour.")
//    public static let CardTextMail = NSLocalizedString("IntroSlidesMailDescription", value: "Use any email app — not just Mail — with Firefox.", comment: "Description for the 'Mail' panel in the First Run tour.")
//    public static let CardTextSync = NSLocalizedString("IntroSlidesSyncDescription", value: "Use Sync to find the bookmarks, passwords, and other things you save to Firefox on all your devices.", comment: "Description for the 'Sync' panel in the First Run tour.")
//    public static let SignInButtonTitle = NSLocalizedString("SignInToFirefox", value: "Sign in to Firefox", comment: "See http://mzl.la/1T8gxwo")
//    public static let StartBrowsingButtonTitle = NSLocalizedString("StartBrowsing", value: "Start Browsing", comment: "See http://mzl.la/1T8gxwo")
//}

// Keyboard short cuts
extension Strings {
    public static let ShowTabTrayFromTabKeyCodeTitle = NSLocalizedString("TabShowTabTrayKeyCodeTitle", value: "Show All Tabs", comment: "Hardware shortcut to open the tab tray from a tab. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let CloseTabFromTabTrayKeyCodeTitle = NSLocalizedString("TabTrayCloseTabKeyCodeTitle", value: "Close Selected Tab", comment: "Hardware shortcut to close the selected tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let CloseAllTabsFromTabTrayKeyCodeTitle = NSLocalizedString("TabTrayCloseAllTabsKeyCodeTitle", value: "Close All Tabs", comment: "Hardware shortcut to close all tabs from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let OpenSelectedTabFromTabTrayKeyCodeTitle = NSLocalizedString("TabTrayOpenSelectedTabKeyCodeTitle", value: "Open Selected Tab", comment: "Hardware shortcut open the selected tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let OpenNewTabFromTabTrayKeyCodeTitle = NSLocalizedString("TabTrayOpenNewTabKeyCodeTitle", value: "Open New Tab", comment: "Hardware shortcut to open a new tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let ReopenClosedTabKeyCodeTitle = NSLocalizedString("ReopenClosedTabKeyCodeTitle", value: "Reopen Closed Tab", comment: "Hardware shortcut to reopen the last closed tab, from the tab or the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let SwitchToPBMKeyCodeTitle = NSLocalizedString("SwitchToPBMKeyCodeTitle", value: "Private Browsing Mode", comment: "Hardware shortcut switch to the private browsing tab or tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let SwitchToNonPBMKeyCodeTitle = NSLocalizedString("SwitchToNonPBMKeyCodeTitle", value: "Normal Browsing Mode", comment: "Hardware shortcut for non-private tab or tab. Shown in the Discoverability overlay when the hardware Command Key is held down.")
}

// Share extension
//extension Strings {
//    public static let SendToCancelButton = NSLocalizedString("SendToCancelButton", value: "Cancel", comment: "Button title for cancelling share screen")
//    public static let SendToErrorOKButton = NSLocalizedString("SendToErrorOKButton", value: "OK", comment: "OK button to dismiss the error prompt.")
//    public static let SendToErrorTitle = NSLocalizedString("SendToErrorTitle", value: "The link you are trying to share cannot be shared.", comment: "Title of error prompt displayed when an invalid URL is shared.")
//    public static let SendToErrorMessage = NSLocalizedString("SendToErrorMessage", value: "Only HTTP and HTTPS links can be shared.", comment: "Message in error prompt explaining why the URL is invalid.")
//
//    // The above items are re-used strings from the old extension. New strings below.
//
//    public static let ShareAddToReadingList = NSLocalizedString("ShareExtensionAddToReadingListActionTitle", value: "Add to Reading List", comment: "Action label on share extension to add page to the Firefox reading list.")
//    public static let ShareAddToReadingListDone = NSLocalizedString("ShareExtensionAddToReadingListActionDoneTitle", value: "Added to Reading List", comment: "Share extension label shown after user has performed 'Add to Reading List' action.")
//    public static let ShareBookmarkThisPage = NSLocalizedString("ShareExtensionBookmarkThisPageActionTitle", value: "Bookmark This Page", comment: "Action label on share extension to bookmark the page in Firefox.")
//    public static let ShareBookmarkThisPageDone = NSLocalizedString("ShareExtensionBookmarkThisPageActionDoneTitle", value: "Bookmarked", comment: "Share extension label shown after user has performed 'Bookmark this Page' action.")
//
//    public static let ShareOpenInFirefox = NSLocalizedString("ShareExtensionOpenInFirefoxActionTitle", value: "Open in Firefox", comment: "Action label on share extension to immediately open page in Firefox.")
//    public static let ShareSearchInFirefox = NSLocalizedString("ShareExtensionSeachInFirefoxActionTitle", value: "Search in Firefox", comment: "Action label on share extension to search for the selected text in Firefox.")
//    public static let ShareOpenInPrivateModeNow = NSLocalizedString("ShareExtensionOpenInPrivateModeActionTitle", value: "Open in Private Mode", comment: "Action label on share extension to immediately open page in Firefox in private mode.")
//
//    public static let ShareLoadInBackground = NSLocalizedString("ShareExtensionLoadInBackgroundActionTitle", value: "Load in Background", comment: "Action label on share extension to load the page in Firefox when user switches apps to bring it to foreground.")
//    public static let ShareLoadInBackgroundDone = NSLocalizedString("ShareExtensionLoadInBackgroundActionDoneTitle", value: "Loading in Firefox", comment: "Share extension label shown after user has performed 'Load in Background' action.")
//}

//// MARK: Deprecated Strings (to be removed in next version)
//private let logOut = NSLocalizedString("SettingsLogOutButtonTitle", value: "Log Out", comment: "Button in settings screen to disconnect from your account")
//private let logOutQuestion = NSLocalizedString("LogOut", value: "Log Out?", comment: "Title of the 'log out firefox account' alert")
//private let logOutDestructive = NSLocalizedString("LogOut", value: "Log Out", comment: "Disconnect button in the 'log out firefox account' alert")
