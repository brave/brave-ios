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
    public static let OKString = NSLocalizedString("OKString", value: "OK", comment: "OK button")
    public static let CancelString = NSLocalizedString("CancelString", value: "Cancel", comment: "Label for Cancel button")
}

// Table date section titles.
extension Strings {
    public static let TableDateSectionTitleYesterday = NSLocalizedString("TableDateSectionTitleYesterday", value: "Yesterday", comment: "History tableview section header")
    public static let TableDateSectionTitleLastWeek = NSLocalizedString("TableDateSectionTitleLastWeek", value: "Last week", comment: "History tableview section header")
    public static let TableDateSectionTitleLastMonth = NSLocalizedString("TableDateSectionTitleLastMonth", value: "Last month", comment: "History tableview section header")
}

// Top Sites.
extension Strings {
    public static let TopSitesEmptyStateDescription = NSLocalizedString("TopSitesEmptyStateDescription", value: "Your most visited sites will show up here.", comment: "Description label for the empty Top Sites state.")
    public static let TopSitesEmptyStateTitle = NSLocalizedString("TopSitesEmptyStateTitle", value: "Welcome to Top Sites", comment: "The title for the empty Top Sites state")
    public static let TopSitesRemoveButtonAccessibilityLabel = NSLocalizedString("TopSitesRemoveButtonAccessibilityLabel", value: "Remove page — %@", comment: "Button shown in editing mode to remove this site from the top sites panel.")
}

// Activity Stream.
extension Strings {
    public static let HighlightIntroTitle = NSLocalizedString("HighlightIntroTitle", value: "Be on the Lookout", comment: "The title that appears for the introduction to highlights in AS.")
    public static let HighlightIntroDescription = NSLocalizedString("HighlightIntroDescription", value: "Firefox will place things here that you’ve discovered on the web so you can find your way back to the great articles, videos, bookmarks and other pages", comment: "The detailed text that explains what highlights are in AS.")
    public static let ASPageControlButton = NSLocalizedString("ASPageControlButton", value: "Next Page", comment: "The page control button that lets you switch between pages in top sites")
    public static let ASHighlightsTitle = NSLocalizedString("ASHighlightsTitle", value: "Highlights", comment: "Section title label for the Highlights section")
    public static let ASTopSitesTitle = NSLocalizedString("ASTopSitesTitle", value: "Top Sites", comment: "Section title label for Top Sites")
    public static let HighlightVistedText = NSLocalizedString("HighlightVistedText", value: "Visited", comment: "The description of a highlight if it is a site the user has visited")
    public static let HighlightBookmarkText = NSLocalizedString("HighlightBookmarkText", value: "Bookmarked", comment: "The description of a highlight if it is a site the user has bookmarked")
}

// Home Panel Context Menu.
extension Strings {
    public static let OpenInNewTabContextMenuTitle = NSLocalizedString("OpenInNewTabContextMenuTitle", value: "Open in New Tab", comment: "The title for the Open in New Tab context menu action for sites in Home Panels")
    public static let OpenInNewPrivateTabContextMenuTitle = NSLocalizedString("OpenInNewPrivateTabContextMenuTitle", value: "Open in New Private Tab", comment: "The title for the Open in New Private Tab context menu action for sites in Home Panels")
    public static let BookmarkContextMenuTitle = NSLocalizedString("BookmarkContextMenuTitle", value: "Bookmark", comment: "The title for the Bookmark context menu action for sites in Home Panels")
    public static let RemoveBookmarkContextMenuTitle = NSLocalizedString("RemoveBookmarkContextMenuTitle", value: "Remove Bookmark", comment: "The title for the Remove Bookmark context menu action for sites in Home Panels")
    public static let DeleteFromHistoryContextMenuTitle = NSLocalizedString("DeleteFromHistoryContextMenuTitle", value: "Delete from History", comment: "The title for the Delete from History context menu action for sites in Home Panels")
    public static let ShareContextMenuTitle = NSLocalizedString("ShareContextMenuTitle", value: "Share", comment: "The title for the Share context menu action for sites in Home Panels")
    public static let RemoveContextMenuTitle = NSLocalizedString("RemoveContextMenuTitle", value: "Remove", comment: "The title for the Remove context menu action for sites in Home Panels")
    public static let PinTopsiteActionTitle = NSLocalizedString("PinTopsiteActionTitle", value: "Pin to Top Sites", comment: "The title for the pinning a topsite action")
    public static let RemovePinTopsiteActionTitle = NSLocalizedString("RemovePinTopsiteActionTitle", value: "Remove Pinned Site", comment: "The title for removing a pinned topsite action")
}

//  PhotonActionSheet Strings
extension Strings {
    public static let CloseButtonTitle = NSLocalizedString("CloseButtonTitle", value: "Close", comment: "Button for closing the menu action sheet")

}

// Settings.
extension Strings {
    public static let SettingsGeneralSectionTitle = NSLocalizedString("SettingsGeneralSectionTitle", value: "General", comment: "General settings section title")
    public static let SettingsClearPrivateDataClearButton = NSLocalizedString("SettingsClearPrivateDataClearButton", value: "Clear Private Data", comment: "Button in settings that clears private data for the selected items.")
    public static let SettingsClearPrivateDataSectionName = NSLocalizedString("SettingsClearPrivateDataSectionName", value: "Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsClearPrivateDataTitle = NSLocalizedString("SettingsClearPrivateDataTitle", value: "Clear Private Data", comment: "Title displayed in header of the setting panel.")
    public static let SettingsDisconnectSyncAlertTitle = NSLocalizedString("SettingsDisconnectSyncAlertTitle", value: "Disconnect Sync?", comment: "Title of the alert when prompting the user asking to disconnect.")
    public static let SettingsDisconnectSyncAlertBody = NSLocalizedString("SettingsDisconnectSyncAlertBody", value: "Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.", comment: "Body of the alert when prompting the user asking to disconnect.")
    public static let SettingsDisconnectSyncButton = NSLocalizedString("SettingsDisconnectSyncButton", value: "Disconnect Sync", comment: "Button displayed at the bottom of settings page allowing users to Disconnect from FxA")
    public static let SettingsDisconnectCancelAction = NSLocalizedString("SettingsDisconnectCancelAction", value: "Cancel", comment: "Cancel action button in alert when user is prompted for disconnect")
    public static let SettingsDisconnectDestructiveAction = NSLocalizedString("SettingsDisconnectDestructiveAction", value: "Disconnect", comment: "Destructive action button in alert when user is prompted for disconnect")
    public static let SettingsSearchDoneButton = NSLocalizedString("SettingsSearchDoneButton", value: "Done", comment: "Button displayed at the top of the search settings.")
    public static let SettingsSearchEditButton = NSLocalizedString("SettingsSearchEditButton", value: "Edit", comment: "Button displayed at the top of the search settings.")
    public static let UseTouchID = NSLocalizedString("UseTouchID", value: "Use Touch ID", comment: "List section title for when to use Touch ID")
    public static let UseFaceID = NSLocalizedString("UseFaceID", value: "Use Face ID", comment: "List section title for when to use Face ID")
}

// Logins Helper.
extension Strings {
    public static let LoginsHelperSaveLoginButtonTitle = NSLocalizedString("LoginsHelperSaveLoginButtonTitle", value: "Save Login", comment: "Button to save the user's password")
    public static let LoginsHelperDontSaveButtonTitle = NSLocalizedString("LoginsHelperDontSaveButtonTitle", value: "Don’t Save", comment: "Button to not save the user's password")
    public static let LoginsHelperUpdateButtonTitle = NSLocalizedString("LoginsHelperUpdateButtonTitle", value: "Update", comment: "Button to update the user's password")
    public static let LoginsHelperDontUpdateButtonTitle = NSLocalizedString("LoginsHelperDontUpdateButtonTitle", value: "Don’t Update", comment: "Button to not update the user's password")
}

// Downloads Panel
extension Strings {
    public static let DownloadsPanelEmptyStateTitle = NSLocalizedString("DownloadsPanelEmptyStateTitle", value: "Downloaded files will show up here.", comment: "Title for the Downloads Panel empty state.")
}

// History Panel
extension Strings {
    public static let SyncedTabsTableViewCellTitle = NSLocalizedString("SyncedTabsTableViewCellTitle", value: "Synced Devices", comment: "Title for the Synced Tabs Cell in the History Panel")
    public static let HistoryBackButtonTitle = NSLocalizedString("HistoryBackButtonTitle", value: "History", comment: "Title for the Back to History button in the History Panel")
    public static let HistoryPanelEmptyStateTitle = NSLocalizedString("HistoryPanelEmptyStateTitle", value: "Websites you’ve visited recently will show up here.", comment: "Title for the History Panel empty state.")
    public static let RecentlyClosedTabsButtonTitle = NSLocalizedString("RecentlyClosedTabsButtonTitle", value: "Recently Closed", comment: "Title for the Recently Closed button in the History Panel")
    public static let RecentlyClosedTabsPanelTitle = NSLocalizedString("RecentlyClosedTabsPanelTitle", value: "Recently Closed", comment: "Title for the Recently Closed Tabs Panel")
}

// Syncing
extension Strings {
    public static let SyncingMessageWithEllipsis = NSLocalizedString("SyncingMessageWithEllipsis", value: "Syncing…", comment: "Message displayed when the user's account is syncing with ellipsis at the end")
    public static let SyncingMessageWithoutEllipsis = NSLocalizedString("SyncingMessageWithoutEllipsis", value: "Syncing", comment: "Message displayed when the user's account is syncing with no ellipsis")

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
    public static let SaveLoginUsernamePrompt = NSLocalizedString("SaveLoginUsernamePrompt", value: "Save login %@ for %@?", comment: "Prompt for saving a login. The first parameter is the username being saved. The second parameter is the hostname of the site.")
    public static let SaveLoginPrompt = NSLocalizedString("SaveLoginPrompt", value: "Save password for %@?", comment: "Prompt for saving a password with no username. The parameter is the hostname of the site.")
    public static let UpdateLoginUsernamePrompt = NSLocalizedString("UpdateLoginUsernamePrompt", value: "Update login %@ for %@?", comment: "Prompt for updating a login. The first parameter is the username for which the password will be updated for. The second parameter is the hostname of the site.")
    public static let UpdateLoginPrompt = NSLocalizedString("UpdateLoginPrompt", value: "Update login %@ for %@?", comment: "Prompt for updating a login. The first parameter is the username for which the password will be updated for. The second parameter is the hostname of the site.")
}

//Hotkey Titles
extension Strings {
    public static let ReloadPageTitle = NSLocalizedString("ReloadPageTitle", value: "Reload Page", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let BackTitle = NSLocalizedString("BackTitle", value: "Back", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ForwardTitle = NSLocalizedString("ForwardTitle", value: "Forward", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")

    public static let FindTitle = NSLocalizedString("FindTitle", value: "Find", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let SelectLocationBarTitle = NSLocalizedString("SelectLocationBarTitle", value: "Select Location Bar", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let NewTabTitle = NSLocalizedString("NewTabTitle", value: "New Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let NewPrivateTabTitle = NSLocalizedString("NewPrivateTabTitle", value: "New Private Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let CloseTabTitle = NSLocalizedString("CloseTabTitle", value: "Close Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ShowNextTabTitle = NSLocalizedString("ShowNextTabTitle", value: "Show Next Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ShowPreviousTabTitle = NSLocalizedString("ShowPreviousTabTitle", value: "Show Previous Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
}

// Home page.
extension Strings {
    public static let SettingsHomePageSectionName = NSLocalizedString("SettingsHomePageSectionName", value: "Homepage", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the home page and its uses.")
    public static let SettingsHomePageTitle = NSLocalizedString("SettingsHomePageTitle", value: "Homepage Settings", comment: "Title displayed in header of the setting panel.")
    public static let SettingsHomePageURLSectionTitle = NSLocalizedString("SettingsHomePageURLSectionTitle", value: "Current Homepage", comment: "Title of the setting section containing the URL of the current home page.")
    public static let SettingsHomePageUseCurrentPage = NSLocalizedString("SettingsHomePageUseCurrentPage", value: "Use Current Page", comment: "Button in settings to use the current page as home page.")
    public static let SettingsHomePagePlaceholder = NSLocalizedString("SettingsHomePagePlaceholder", value: "Enter a webpage", comment: "Placeholder text in the homepage setting when no homepage has been set.")
    public static let SettingsHomePageUseCopiedLink = NSLocalizedString("SettingsHomePageUseCopiedLink", value: "Use Copied Link", comment: "Button in settings to use the current link on the clipboard as home page.")
    public static let SettingsHomePageUseDefault = NSLocalizedString("SettingsHomePageUseDefault", value: "Use Default", comment: "Button in settings to use the default home page. If no default is set, then this button isn't shown.")
    public static let SettingsHomePageClear = NSLocalizedString("SettingsHomePageClear", value: "Clear", comment: "Button in settings to clear the home page.")
    public static let SetHomePageDialogTitle = NSLocalizedString("SetHomePageDialogTitle", value: "Do you want to use this web page as your home page?", comment: "Alert dialog title when the user opens the home page for the first time.")
    public static let SetHomePageDialogMessage = NSLocalizedString("SetHomePageDialogMessage", value: "You can change this at any time in Settings", comment: "Alert dialog body when the user opens the home page for the first time.")
    public static let SetHomePageDialogYes = NSLocalizedString("SetHomePageDialogYes", value: "Set Homepage", comment: "Button accepting changes setting the home page for the first time.")
    public static let SetHomePageDialogNo = NSLocalizedString("SetHomePageDialogNo", value: "Cancel", comment: "Button cancelling changes setting the home page for the first time.")
}

// New tab choice settings
extension Strings {
    public static let SettingsNewTabSectionName = NSLocalizedString("SettingsNewTabSectionName", value: "New Tab", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the new tab behaviour.")
    public static let SettingsNewTabTitle = NSLocalizedString("SettingsNewTabTitle", value: "New Tab Settings", comment: "Title displayed in header of the setting panel.")
    public static let SettingsNewTabTopSites = NSLocalizedString("SettingsNewTabTopSites", value: "Show your Top Sites", comment: "Option in settings to show top sites when you open a new tab")
    public static let SettingsNewTabBookmarks = NSLocalizedString("SettingsNewTabBookmarks", value: "Show your Bookmarks", comment: "Option in settings to show bookmarks when you open a new tab")
    public static let SettingsNewTabHistory = NSLocalizedString("SettingsNewTabHistory", value: "Show your History", comment: "Option in settings to show history when you open a new tab")
    public static let SettingsNewTabReadingList = NSLocalizedString("SettingsNewTabReadingList", value: "Show your Reading List", comment: "Option in settings to show reading list when you open a new tab")
    public static let SettingsNewTabBlankPage = NSLocalizedString("SettingsNewTabBlankPage", value: "Show a Blank Page", comment: "Option in settings to show a blank page when you open a new tab")
    public static let SettingsNewTabHomePage = NSLocalizedString("SettingsNewTabHomePage", value: "Show your Homepage", comment: "Option in settings to show your homepage when you open a new tab")
    public static let SettingsNewTabDescription = NSLocalizedString("SettingsNewTabDescription", value: "When you open a New Tab:", comment: "A description in settings of what the new tab choice means")
    // AS Panel settings
    public static let SettingsNewTabASTitle = NSLocalizedString("SettingsNewTabASTitle", value: "Additional Content", comment: "The title of the section in newtab that lets you modify the topsites panel")
    public static let SettingsNewTabHiglightsHistory = NSLocalizedString("SettingsNewTabHiglightsHistory", value: "Visited", comment: "Option in settings to turn off history in the highlights section")
    public static let SettingsNewTabHighlightsBookmarks = NSLocalizedString("SettingsNewTabHighlightsBookmarks", value: "Recent Bookmarks", comment: "Option in the settings to turn off recent bookmarks in the Highlights section")
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
    public static let ThirdPartySearchEngineAdded = NSLocalizedString("ThirdPartySearchEngineAdded", value: "Added Search engine!", comment: "The success message that appears after a user sucessfully adds a new search engine")
    public static let ThirdPartySearchAddTitle = NSLocalizedString("ThirdPartySearchAddTitle", value: "Add Search Provider?", comment: "The title that asks the user to Add the search provider")
    public static let ThirdPartySearchAddMessage = NSLocalizedString("ThirdPartySearchAddMessage", value: "The new search engine will appear in the quick search bar.", comment: "The message that asks the user to Add the search provider explaining where the search engine will appear")
    public static let ThirdPartySearchCancelButton = NSLocalizedString("ThirdPartySearchCancelButton", value: "Cancel", comment: "The cancel button if you do not want to add a search engine.")
    public static let ThirdPartySearchOkayButton = NSLocalizedString("ThirdPartySearchOkayButton", value: "OK", comment: "The confirmation button")
    public static let ThirdPartySearchFailedTitle = NSLocalizedString("ThirdPartySearchFailedTitle", value: "Failed", comment: "A title explaining that we failed to add a search engine")
    public static let ThirdPartySearchFailedMessage = NSLocalizedString("ThirdPartySearchFailedMessage", value: "The search provider could not be added.", comment: "A title explaining that we failed to add a search engine")
    public static let CustomEngineFormErrorTitle = NSLocalizedString("CustomEngineFormErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.")
    public static let CustomEngineFormErrorMessage = NSLocalizedString("CustomEngineFormErrorMessage", value: "Please fill all fields correctly.", comment: "A message explaining fault in custom search engine form.")
    public static let CustomEngineDuplicateErrorTitle = NSLocalizedString("CustomEngineDuplicateErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.")
    public static let CustomEngineDuplicateErrorMessage = NSLocalizedString("CustomEngineDuplicateErrorMessage", value: "A search engine with this title or URL has already been added.", comment: "A message explaining fault in custom search engine form.")
}

// Bookmark Management
extension Strings {
    public static let BookmarksTitle = NSLocalizedString("BookmarksTitle", value: "Title", comment: "The label for the title of a bookmark")
    public static let BookmarksURL = NSLocalizedString("BookmarksURL", value: "URL", comment: "The label for the URL of a bookmark")
    public static let BookmarksFolder = NSLocalizedString("BookmarksFolder", value: "Folder", comment: "The label to show the location of the folder where the bookmark is located")
    public static let BookmarksNewFolder = NSLocalizedString("BookmarksNewFolder", value: "New Folder", comment: "The button to create a new folder")
    public static let BookmarksFolderName = NSLocalizedString("BookmarksFolderName", value: "Folder Name", comment: "The label for the title of the new folder")
    public static let BookmarksFolderLocation = NSLocalizedString("BookmarksFolderLocation", value: "Location", comment: "The label for the location of the new folder")
}

// Tabs Delete All Undo Toast
extension Strings {
    public static let TabsDeleteAllUndoTitle = NSLocalizedString("TabsDeleteAllUndoTitle", value: "%d tab(s) closed", comment: "The label indicating that all the tabs were closed")
    public static let TabsDeleteAllUndoAction = NSLocalizedString("TabsDeleteAllUndoAction", value: "Undo", comment: "The button to undo the delete all tabs")
}

//Clipboard Toast
extension Strings {
    public static let GoToCopiedLink = NSLocalizedString("GoToCopiedLink", value: "Go to copied link?", comment: "Message displayed when the user has a copied link on the clipboard")
    public static let GoButtonTittle = NSLocalizedString("GoButtonTittle", value: "Go", comment: "The button to open a new tab with the copied link")

    public static let SettingsOfferClipboardBarTitle = NSLocalizedString("SettingsOfferClipboardBarTitle", value: "Offer to Open Copied Links", comment: "Title of setting to enable the Go to Copied URL feature. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
    public static let SettingsOfferClipboardBarStatus = NSLocalizedString("SettingsOfferClipboardBarStatus", value: "When Opening Firefox", comment: "Description displayed under the ”Offer to Open Copied Link” option. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
}

// errors
extension Strings {
    public static let UnableToDownloadError = NSLocalizedString("UnableToDownloadError", value: "Downloads aren’t supported in Firefox yet.", comment: "The message displayed to a user when they try and perform the download of an asset that Firefox cannot currently handle.")
    public static let UnableToAddPassErrorTitle = NSLocalizedString("UnableToAddPassErrorTitle", value: "Failed to Add Pass", comment: "Title of the 'Add Pass Failed' alert. See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorMessage = NSLocalizedString("UnableToAddPassErrorMessage", value: "An error occured while adding the pass to Wallet. Please try again later.", comment: "Text of the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorDismiss = NSLocalizedString("UnableToAddPassErrorDismiss", value: "OK", comment: "Button to dismiss the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToOpenURLError = NSLocalizedString("UnableToOpenURLError", value: "Firefox cannot open the page because it has an invalid address.", comment: "The message displayed to a user when they try to open a URL that cannot be handled by Firefox, or any external app.")
    public static let UnableToOpenURLErrorTitle = NSLocalizedString("UnableToOpenURLErrorTitle", value: "Cannot Open Page", comment: "Title of the message shown when the user attempts to navigate to an invalid link.")
}

// Download Helper
extension Strings {
    public static let OpenInDownloadHelperAlertDownloadNow = NSLocalizedString("OpenInDownloadHelperAlertDownloadNow", value: "Download Now", comment: "The label of the button the user will press to start downloading a file")
    public static let DownloadsButtonTitle = NSLocalizedString("DownloadsButtonTitle", value: "Downloads", comment: "The button to open a new tab with the Downloads home panel")
    public static let CancelDownloadDialogTitle = NSLocalizedString("CancelDownloadDialogTitle", value: "Cancel Download", comment: "Alert dialog title when the user taps the cancel download icon.")
    public static let CancelDownloadDialogMessage = NSLocalizedString("CancelDownloadDialogMessage", value: "Are you sure you want to cancel this download?", comment: "Alert dialog body when the user taps the cancel download icon.")
    public static let CancelDownloadDialogResume = NSLocalizedString("CancelDownloadDialogResume", value: "Resume", comment: "Button declining the cancellation of the download.")
    public static let CancelDownloadDialogCancel = NSLocalizedString("CancelDownloadDialogCancel", value: "Cancel", comment: "Button confirming the cancellation of the download.")
    public static let DownloadCancelledToastLabelText = NSLocalizedString("DownloadCancelledToastLabelText", value: "Download Cancelled", comment: "The label text in the Download Cancelled toast for showing confirmation that the download was cancelled.")
    public static let DownloadFailedToastLabelText = NSLocalizedString("DownloadFailedToastLabelText", value: "Download Failed", comment: "The label text in the Download Failed toast for showing confirmation that the download has failed.")
    public static let DownloadFailedToastButtonTitled = NSLocalizedString("DownloadFailedToastButtonTitled", value: "Retry", comment: "The button to retry a failed download from the Download Failed toast.")
    public static let DownloadMultipleFilesToastDescriptionText = NSLocalizedString("DownloadMultipleFilesToastDescriptionText", value: "1 of %d files", comment: "The description text in the Download progress toast for showing the number of files when multiple files are downloading.")
    public static let DownloadProgressToastDescriptionText = NSLocalizedString("DownloadProgressToastDescriptionText", value: "%1$@/%2$@", comment: "The description text in the Download progress toast for showing the downloaded file size (1$) out of the total expected file size (2$).")
    public static let DownloadMultipleFilesAndProgressToastDescriptionText = NSLocalizedString("DownloadMultipleFilesAndProgressToastDescriptionText", value: "%1$@ %2$@", comment: "The description text in the Download progress toast for showing the number of files (1$) and download progress (2$). This string only consists of two placeholders for purposes of displaying two other strings side-by-side where 1$ is Downloads.Toast.MultipleFiles.DescriptionText and 2$ is Downloads.Toast.Progress.DescriptionText. This string should only consist of the two placeholders side-by-side separated by a single space and 1$ should come before 2$ everywhere except for right-to-left locales.")
}

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
    public static let ReaderModeResetFontSizeAccessibilityLabel = NSLocalizedString("ReaderModeResetFontSizeAccessibilityLabel", value: "Reset text size", comment: "Accessibility label for button resetting font size in display settings of reader mode")
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
    public static let AppMenuAddToReadingListTitleString = NSLocalizedString("AppMenuAddToReadingListTitleString", value: "Add to Reading List", comment: "Label for the button, displayed in the menu, used to add a page to the reading list.")
    public static let AppMenuShowTabsTitleString = NSLocalizedString("AppMenuShowTabsTitleString", value: "Show Tabs", comment: "Label for the button, displayed in the menu, used to open the tabs tray")
    public static let AppMenuSharePageTitleString = NSLocalizedString("AppMenuSharePageTitleString", value: "Share Page With…", comment: "Label for the button, displayed in the menu, used to open the share dialog.")
    public static let AppMenuNewTabTitleString = NSLocalizedString("AppMenuNewTabTitleString", value: "Open New Tab", comment: "Label for the button, displayed in the menu, used to open a new tab")
    public static let AppMenuNewPrivateTabTitleString = NSLocalizedString("AppMenuNewPrivateTabTitleString", value: "Open New Private Tab", comment: "Label for the button, displayed in the menu, used to open a new private tab.")
    public static let AppMenuAddBookmarkTitleString = NSLocalizedString("AppMenuAddBookmarkTitleString", value: "Bookmark This Page", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.")
    public static let AppMenuRemoveBookmarkTitleString = NSLocalizedString("AppMenuRemoveBookmarkTitleString", value: "Remove Bookmark", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.")
    public static let AppMenuFindInPageTitleString = NSLocalizedString("AppMenuFindInPageTitleString", value: "Find in Page", comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.")
    public static let AppMenuViewDesktopSiteTitleString = NSLocalizedString("AppMenuViewDesktopSiteTitleString", value: "Request Desktop Site", comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.")
    public static let AppMenuViewMobileSiteTitleString = NSLocalizedString("AppMenuViewMobileSiteTitleString", value: "Request Mobile Site", comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.")
    public static let AppMenuScanQRCodeTitleString = NSLocalizedString("AppMenuScanQRCodeTitleString", value: "Scan QR Code", comment: "Label for the button, displayed in the menu, used to open the QR code scanner.")
    public static let AppMenuSettingsTitleString = NSLocalizedString("AppMenuSettingsTitleString", value: "Settings", comment: "Label for the button, displayed in the menu, used to open the Settings menu.")
    public static let AppMenuCloseAllTabsTitleString = NSLocalizedString("AppMenuCloseAllTabsTitleString", value: "Close All Tabs", comment: "Label for the button, displayed in the menu, used to close all tabs currently open.")
    public static let AppMenuOpenHomePageTitleString = NSLocalizedString("AppMenuOpenHomePageTitleString", value: "Open Homepage", comment: "Label for the button, displayed in the menu, used to navigate to the home page.")
    public static let AppMenuTopSitesTitleString = NSLocalizedString("AppMenuTopSitesTitleString", value: "Top Sites", comment: "Accessibility label for the button, displayed in the menu, used to open the Top Sites home panel.")
    public static let AppMenuBookmarksTitleString = NSLocalizedString("AppMenuBookmarksTitleString", value: "Bookmarks", comment: "Accessibility label for the button, displayed in the menu, used to open the Bbookmarks home panel.")
    public static let AppMenuReadingListTitleString = NSLocalizedString("AppMenuReadingListTitleString", value: "Reading List", comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel.")
    public static let AppMenuHistoryTitleString = NSLocalizedString("AppMenuHistoryTitleString", value: "History", comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel.")
    public static let AppMenuDownloadsTitleString = NSLocalizedString("AppMenuDownloadsTitleString", value: "Downloads", comment: "Accessibility label for the button, displayed in the menu, used to open the Downloads home panel.")
    public static let AppMenuButtonAccessibilityLabel = NSLocalizedString("AppMenuButtonAccessibilityLabel", value: "Menu", comment: "Accessibility label for the Menu button.")
    public static let TabTrayDeleteMenuButtonAccessibilityLabel = NSLocalizedString("TabTrayDeleteMenuButtonAccessibilityLabel", value: "Close All Tabs", comment: "Accessibility label for the Close All Tabs menu button.")
    public static let AppMenuNightMode = NSLocalizedString("AppMenuNightMode", value: "Enable Night Mode", comment: "Label for the button, displayed in the menu, turns on night mode.")
    public static let AppMenuNoImageMode = NSLocalizedString("AppMenuNoImageMode", value: "Hide Images", comment: "Label for the button, displayed in the menu, hides images on the webpage when pressed.")
    public static let AppMenuCopyURLConfirmMessage = NSLocalizedString("AppMenuCopyURLConfirmMessage", value: "URL Copied To Clipboard", comment: "Toast displayed to user after copy url pressed.")
    public static let AppMenuAddBookmarkConfirmMessage = NSLocalizedString("AppMenuAddBookmarkConfirmMessage", value: "Bookmark Added", comment: "Toast displayed to the user after a bookmark has been added.")
    public static let AppMenuRemoveBookmarkConfirmMessage = NSLocalizedString("AppMenuRemoveBookmarkConfirmMessage", value: "Bookmark Removed", comment: "Toast displayed to the user after a bookmark has been removed.")
    public static let AppMenuAddToReadingListConfirmMessage = NSLocalizedString("AppMenuAddToReadingListConfirmMessage", value: "Added To Reading List", comment: "Toast displayed to the user after adding the item to their reading list.")
    public static let PageActionMenuTitle = NSLocalizedString("PageActionMenuTitle", value: "Page Actions", comment: "Label for title in page action menu.")
}

// Snackbar shown when tapping app store link
extension Strings {
    public static let ExternalLinkAppStoreConfirmationTitle = NSLocalizedString("ExternalLinkAppStoreConfirmationTitle", value: "Open this link in the App Store app?", comment: "Question shown to user when tapping a link that opens the App Store app")
}

// Location bar long press menu
extension Strings {
    public static let PasteAndGoTitle = NSLocalizedString("PasteAndGoTitle", value: "Paste & Go", comment: "The title for the button that lets you paste and go to a URL")
    public static let PasteTitle = NSLocalizedString("PasteTitle", value: "Paste", comment: "The title for the button that lets you paste into the location bar")
    public static let CopyAddressTitle = NSLocalizedString("CopyAddressTitle", value: "Copy Address", comment: "The title for the button that lets you copy the url from the location bar.")
}

// Keyboard short cuts
extension Strings {
    public static let ShowTabTrayFromTabKeyCodeTitle = NSLocalizedString("ShowTabTrayFromTabKeyCodeTitle", value: "Show All Tabs", comment: "Hardware shortcut to open the tab tray from a tab. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let CloseTabFromTabTrayKeyCodeTitle = NSLocalizedString("CloseTabFromTabTrayKeyCodeTitle", value: "Close Selected Tab", comment: "Hardware shortcut to close the selected tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let CloseAllTabsFromTabTrayKeyCodeTitle = NSLocalizedString("CloseAllTabsFromTabTrayKeyCodeTitle", value: "Close All Tabs", comment: "Hardware shortcut to close all tabs from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let OpenSelectedTabFromTabTrayKeyCodeTitle = NSLocalizedString("OpenSelectedTabFromTabTrayKeyCodeTitle", value: "Open Selected Tab", comment: "Hardware shortcut open the selected tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let OpenNewTabFromTabTrayKeyCodeTitle = NSLocalizedString("OpenNewTabFromTabTrayKeyCodeTitle", value: "Open New Tab", comment: "Hardware shortcut to open a new tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let ReopenClosedTabKeyCodeTitle = NSLocalizedString("ReopenClosedTabKeyCodeTitle", value: "Reopen Closed Tab", comment: "Hardware shortcut to reopen the last closed tab, from the tab or the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let SwitchToPBMKeyCodeTitle = NSLocalizedString("SwitchToPBMKeyCodeTitle", value: "Private Browsing Mode", comment: "Hardware shortcut switch to the private browsing tab or tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let SwitchToNonPBMKeyCodeTitle = NSLocalizedString("SwitchToNonPBMKeyCodeTitle", value: "Normal Browsing Mode", comment: "Hardware shortcut for non-private tab or tab. Shown in the Discoverability overlay when the hardware Command Key is held down.")
}
