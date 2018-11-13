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

// PRAGMA MARK: SendTo extension.
public extension Strings {
    public static let CancelButtonTitle = NSLocalizedString("CancelButtonTitle", tableName: "BraveShared", value: "Cancel", comment: "")
//    public static let lastBookmarkTitle = NSLocalizedString("OpenLastBookmark", value: "Open Last Bookmark", comment: "String describing the action of opening the last added bookmark from the home screen Quick Actions via 3D Touch")
//    public static let _lastTabTitle = NSLocalizedString("OpenLastTab", value: "Open Last Tab", comment: "String describing the action of opening the last tab sent to Brave from the home screen Quick Actions via 3D Touch")
    
}

// PRAGMA MARK: UIAlertControllerExtensions.swift
public extension Strings {
    public static let SendCrashReportAlertTitle = NSLocalizedString("SendCrashReportAlertTitle", value: "Oops! Brave crashed", comment: "Title for prompt displayed to user after the app crashes")
    public static let SendCrashReportAlertMessage = NSLocalizedString("SendCrashReportAlertMessage", value: "Send a crash report so Brave can fix the problem?", comment: "Message displayed in the crash dialog above the buttons used to select when sending reports")
    public static let SendReportButtonTitle = NSLocalizedString("SendReport", value: "Send Report", comment: "Used as a button label for crash dialog prompt")
    public static let AlwaysSendButtonTitle = NSLocalizedString("AlwaysSend", value: "Always Send", comment: "Used as a button label for crash dialog prompt")
    public static let DontSendButtonTitle = NSLocalizedString("DontSend", value: "Don’t Send", comment: "Used as a button label for crash dialog prompt")
    public static let RestoreTabOnCrashAlertTitle = NSLocalizedString("WellThisIsEmbarrassing", value: "Well, this is embarrassing.", comment: "Restore Tabs Prompt Title")
    public static let RestoreTabOnCrashAlertMessage = NSLocalizedString("LooksLikeBraveCrashedPreviouslyWouldYouLikeToRestoreYourTabs", value: "Looks like Brave crashed previously. Would you like to restore your tabs?", comment: "Restore Tabs Prompt Description")
    public static let RestoreTabNegativeButtonTitle = NSLocalizedString("No", value: "No", comment: "Restore Tabs Negative Action")
    public static let RestoreTabAffirmativeButtonTitle = NSLocalizedString("Okay", value: "Okay", comment: "Restore Tabs Affirmative Action")
    public static let ClearPrivateDataAlertMessage = NSLocalizedString("ThisActionWillClearAllOfYourPrivateDataItCannotBeUndone", value: "This action will clear all of your private data. It cannot be undone.", comment: "Description of the confirmation dialog shown when a user tries to clear their private data.")
    public static let ClearPrivateDataAlertCancelButtonTitle = NSLocalizedString("Cancel", value: "Cancel", comment: "The cancel button when confirming clear private data.")
    public static let ClearPrivateDataAlertOkButtonTitle = NSLocalizedString("OK", value: "OK", comment: "The button that clears private data.")
    public static let ClearSyncedHistoryAlertMessage = NSLocalizedString("ThisActionWillClearAllOfYourPrivateDataIncludingHistoryFromYourSyncedDevices", value: "This action will clear all of your private data, including history from your synced devices.", comment: "Description of the confirmation dialog shown when a user tries to clear history that's synced to another device.")
    public static let ClearSyncedHistoryAlertCancelButtoTitle = NSLocalizedString("Cancel", value: "Cancel", comment: "The cancel button when confirming clear history.")
    public static let ClearSyncedHistoryAlertOkButtoTitle = NSLocalizedString("OK", value: "OK", comment: "The confirmation button that clears history even when Sync is connected.")
    public static let DeleteLoginAlertTitle = NSLocalizedString("AreYouSure", value: "Are you sure?", comment: "Prompt title when deleting logins")
    public static let DeleteLoginAlertLocalMessage = NSLocalizedString("LoginsWillBePermanentlyRemoved", value: "Logins will be permanently removed.", comment: "Prompt message warning the user that deleting non-synced logins will permanently remove them")
    public static let DeleteLoginAlertSyncedDevicesMessage = NSLocalizedString("LoginsWillBeRemovedFromAllConnectedDevices", value: "Logins will be removed from all connected devices.", comment: "Prompt message warning the user that deleted logins will remove logins from all connected devices")
    public static let DeleteLoginAlertCancelActionTitle = NSLocalizedString("Cancel", value: "Cancel", comment: "Prompt option for cancelling out of deletion")
    public static let DeleteLoginAlertDeleteActionTitle = NSLocalizedString("Delete", value: "Delete", comment: "Label for the button used to delete the current login.")
}

// PRAGMA MARK: BasePasscodeViewController.swift
public extension Strings {
    public static let PasscodeConfirmMisMatchErrorText = NSLocalizedString("PasscodesDidntMatchTryAgain", value: "Passcodes didn’t match. Try again.", comment: "Error message displayed to user when their confirming passcode doesn't match the first code.")
    public static let PasscodeMatchOldErrorText = NSLocalizedString("NewPasscodeMustBeDifferentThanExistingCode", value: "New passcode must be different than existing code.", comment: "Error message displayed when user tries to enter the same passcode as their existing code when changing it.")
}

// PRAGMA MARK: AuthenticationManagerConstants.swift
public extension Strings {
    
}

// PRAGMA MARK: SearchViewController.swift
public extension Strings {
    public static let SearchSettingsButtonTitle = NSLocalizedString("SearchSettings", value: "Search Settings", comment: "Label for search settings button.")
    public static let SearchEngineFormatText = NSLocalizedString("Search", value: "%@ search", comment: "Label for search engine buttons. The argument corresponds to the name of the search engine.")
    public static let SearchSuggestionFromFormatText = NSLocalizedString("SearchSuggestionsFrom", value: "Search suggestions from %@", comment: "Accessibility label for image of default search engine displayed left to the actual search suggestions from the engine. The parameter substituted for \"%@\" is the name of the search engine. E.g.: Search suggestions from Google")
    public static let SearchesForSuggestionButtonAccessibilityText = NSLocalizedString("SearchesForTheSuggestion", value: "Searches for the suggestion", comment: "Accessibility hint describing the action performed when a search suggestion is clicked")
}

// PRAGMA MARK: Authenticator.swift
public extension Strings {
    public static let AuthPromptAlertCancelButtonTitle = NSLocalizedString("Cancel", value: "Cancel", comment: "Label for Cancel button")
    public static let AuthPromptAlertLogInButtonTitle  = NSLocalizedString("LogIn", value: "Log in", comment: "Authentication prompt log in button")
    public static let AuthPromptAlertTitle = NSLocalizedString("AuthenticationRequired", value: "Authentication required", comment: "Authentication prompt title")
    public static let AuthPromptAlertFormatRealmMessageText = NSLocalizedString("AUsernameAndPasswordAreBeingRequestedByTheSiteSays", value: "A username and password are being requested by %@. The site says: %@", comment: "Authentication prompt message with a realm. First parameter is the hostname. Second is the realm string")
    public static let AuthPromptAlertMessageText = NSLocalizedString("AUsernameAndPasswordAreBeingRequestedBy", value: "A username and password are being requested by %@.", comment: "Authentication prompt message with no realm. Parameter is the hostname of the site")
    public static let AuthPromptAlertUsernamePlaceholderText = NSLocalizedString("Username", value: "Username", comment: "Username textbox in Authentication prompt")
    public static let AuthPromptAlertPasswordPlaceholderText = NSLocalizedString("Password", value: "Password", comment: "Password textbox in Authentication prompt")
    
}

// PRAGMA MARK: BrowserViewController.swift
public extension Strings {
    public static let CloseTabCancelButtonTitle = NSLocalizedString("Cancel", value: "Cancel", comment: "Label for Cancel button")
    public static let WebContentAccessibilityLabel = NSLocalizedString("WebContent", value: "Web content", comment: "Accessibility label for the main web content view")
    public static let OpenNewTabButtonTitle = NSLocalizedString("OpenInNewTab", value: "Open in New Tab", comment: "Context menu item for opening a link in a new tab")
    public static  let OpenNewPrivateTabButtonTitle = NSLocalizedString("OpenInNewPrivateTab", value: "Open in New Private Tab", comment: "Context menu option for opening a link in a new private tab")
    public static let DownloadLinkActionTitle = NSLocalizedString("DownloadLink", value: "Download Link", comment: "Context menu item for downloading a link URL")
    public static let CopyLinkActionTitle = NSLocalizedString("CopyLink", value: "Copy Link", comment: "Context menu item for copying a link URL to the clipboard")
    public static let ShareLinkActionTitle = NSLocalizedString("ShareLink", value: "Share Link", comment: "Context menu item for sharing a link URL")
    public static let SaveImageActionTitle = NSLocalizedString("SaveImage", value: "Save Image", comment: "Context menu item for saving an image")
    public static let AccessPhotoDeniedAlertTitle = NSLocalizedString("BraveWouldLikeToAccessYourPhotos", value: "Brave would like to access your Photos", comment: "See http://mzl.la/1G7uHo7")
    public static let AccessPhotoDeniedAlertMessage = NSLocalizedString("ThisAllowsYouToSaveTheImageToYourCameraRoll", value: "This allows you to save the image to your Camera Roll.", comment: "See http://mzl.la/1G7uHo7")
    public static let OpenPhoneSettingsActionTitle = NSLocalizedString("OpenSettings", value: "Open Settings", comment: "See http://mzl.la/1G7uHo7")
    public static let CopyImageActionTitle = NSLocalizedString("CopyImage", value: "Copy Image", comment: "Context menu item for copying an image to the clipboard")
}

// PRAGMA MARK: ErrorPageHelper.swift
public extension Strings {
    public static let ErrorPageReloadButtonTitle = NSLocalizedString("TryAgain", value: "Try again", comment: "Shown in error pages on a button that will try to load the page again")
    public static let ErrorPageOpenInSafariButtonTitle = NSLocalizedString("OpenInSafari", value: "Open in Safari", comment: "Shown in error pages for files that can't be shown and need to be downloaded.")
}

// PRAGMA MARK: FindInPageBar.swift
public extension Strings {
    public static let FindInPagePreviousResultButtonAccessibilityLabel = NSLocalizedString("PreviousInPageResult", value: "Previous in-page result", comment: "Accessibility label for previous result button in Find in Page Toolbar.")
    public static let FindInPageNextResultButtonAccessibilityLabel = NSLocalizedString("NextInPageResult", value: "Next in-page result", comment: "Accessibility label for next result button in Find in Page Toolbar.")
    public static let FindInPageDoneButtonAccessibilityLabel = NSLocalizedString("Done", value: "Done", comment: "Done button in Find in Page Toolbar.")
}

// PRAGMA MARK: ReaderModeBarView.swift
public extension Strings {
    public static let ReaderModeDisplaySettingsButtonTitle = NSLocalizedString("DisplaySettings", value: "Display Settings", comment: "Name for display settings button in reader mode. Display in the meaning of presentation, not monitor.")
}

// PRAGMA MARK: Tab.swift
public extension Strings {
    public static let TabWebContentViewAccessibilityLabel = NSLocalizedString("WebContent", value: "Web content", comment: "Accessibility label for the main web content view")
}

// PRAGMA MARK: TabLocationView.swift
public extension Strings {
    public static let TabToolbarStopButtonAccessibilityLabel = NSLocalizedString("Stop", value: "Stop", comment: "Accessibility Label for the tab toolbar Stop button")
    public static let TabToolbarReloadButtonAccessibilityLabel = NSLocalizedString("Reload", value: "Reload", comment: "Accessibility Label for the tab toolbar Reload button")
    public static let TabToolbarSearchAddressPlaceholderText = NSLocalizedString("SearchOrEnterAddress", value: "Search or enter address", comment: "The text shown in the URL bar on about:home")
    public static let TabToolbarLockImageAccessibilityLabel = NSLocalizedString("SecureConnection", value: "Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure")
    public static let TabToolbarReaderViewButtonAccessibilityLabel = NSLocalizedString("ReaderView", value: "Reader View", comment: "Accessibility label for the Reader View button")
    public static let TabToolbarReaderViewButtonTitle = NSLocalizedString("AddToReadingList", value: "Add to Reading List", comment: "Accessibility label for action adding current page to reading list.")
}

// PRAGMA MARK: TabPeekViewController.swift
public extension Strings {
    public static let PreviewActionAddToBookmarksActionTitle = NSLocalizedString("AddToBookmarks", value: "Add to Bookmarks", comment: "Label for preview action on Tab Tray Tab to add current tab to Bookmarks")
    public static let PreviewActionCopyURLActionTitle = NSLocalizedString("CopyURL", value: "Copy URL", comment: "Label for preview action on Tab Tray Tab to copy the URL of the current tab to clipboard")
    public static let PreviewActionCloseTabActionTitle = NSLocalizedString("CloseTab", value: "Close Tab", comment: "Label for preview action on Tab Tray Tab to close the current tab")
    public static let PreviewFormatAccessibilityLabel = NSLocalizedString("PreviewOf", value: "Preview of %@", comment: "Accessibility label, associated to the 3D Touch action on the current tab in the tab tray, used to display a larger preview of the tab.")
}

// PRAGMA MARK: TabToolbar.swift
public extension Strings {
    public static let TabToolbarBackButtonAccessibilityLabel = NSLocalizedString("Back", value: "Back", comment: "Accessibility label for the Back button in the tab toolbar.")
    public static let TabToolbarForwardButtonAccessibilityLabel = NSLocalizedString("Forward", value: "Forward", comment: "Accessibility Label for the tab toolbar Forward button")
    public static let TabToolbarShareButtonAccessibilityLabel = NSLocalizedString("Share", tableName: "BraveShared", value: "Share", comment: "Accessibility Label for the browser toolbar Share button")
    public static let TabToolbarAddTabButtonAccessibilityLabel = NSLocalizedString("AddTab", tableName: "BraveShared", value: "Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.")
    public static let TabToolbarAccessibilityLabel = NSLocalizedString("NavigationToolbar", value: "Navigation Toolbar", comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.")
}

// PRAGMA MARK: TabTrayController.swift
public extension Strings {
    public static let TabAccessibilityCloseActionLabel = NSLocalizedString("Close", value: "Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)")
    public static let TabTrayAccessibilityLabel = NSLocalizedString("TabsTray", value: "Tabs Tray", comment: "Accessibility label for the Tabs Tray view.")
    public static let TabTrayEmptyVoiceOverText = NSLocalizedString("NoTabs", value: "No tabs", comment: "Message spoken by VoiceOver to indicate that there are no tabs in the Tabs Tray")
    public static let TabTraySingleTabPositionFormatVoiceOverText = NSLocalizedString("TabOf", value: "Tab %@ of %@", comment: "Message spoken by VoiceOver saying the position of the single currently visible tab in Tabs Tray, along with the total number of tabs. E.g. \"Tab 2 of 5\" says that tab 2 is visible (and is the only visible tab), out of 5 tabs total.")
    public static let TabTrayMultiTabPositionFormatVoiceOverText = NSLocalizedString("TabsToOf", value: "Tabs %@ to %@ of %@", comment: "Message spoken by VoiceOver saying the range of tabs that are currently visible in Tabs Tray, along with the total number of tabs. E.g. \"Tabs 8 to 10 of 15\" says tabs 8, 9 and 10 are visible, out of 15 tabs total.")
    public static let TabTrayClosingTabAccessibilityNotificationText = NSLocalizedString("ClosingTab", value: "Closing tab", comment: "Accessibility label (used by assistive technology) notifying the user that the tab is being closed.")
    public static let TabTrayCellCloseAccessibilityHint = NSLocalizedString("SwipeRightOrLeftWithThreeFingersToCloseTheTab", value: "Swipe right or left with three fingers to close the tab.", comment: "Accessibility hint for tab tray's displayed tab.")
    public static let TabTrayAddTabAccessibilityLabel = NSLocalizedString("AddTab", value: "Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.")
}

// PRAGMA MARK: TabTrayButtonExtensions.swift
public extension Strings {
    public static let TabPrivateModeToggleAccessibilityLabel = NSLocalizedString("PrivateMode", value: "Private Mode", comment: "Accessibility label for toggling on/off private mode")
    public static let TabPrivateModeToggleAccessibilityHint = NSLocalizedString("TurnsPrivateModeOnOrOff", value: "Turns private mode on or off", comment: "Accessiblity hint for toggling on/off private mode")
    public static let TabPrivateModeToggleAccessibilityValueOn = NSLocalizedString("On", value: "On", comment: "Toggled ON accessibility value")
    public static let TabPrivateModeToggleAccessibilityValueOff = NSLocalizedString("Off", value: "Off", comment: "Toggled OFF accessibility value")
    public static let TabTrayNewTabButtonAccessibilityLabel = NSLocalizedString("NewTab", value: "New Tab", comment: "Accessibility label for the New Tab button in the tab toolbar.")
    public static let TabTrayShowTabButtonAccessibilityLabel = NSLocalizedString("ToolbarShowTabsButtonAccessibilityLabel", value: "Show Tabs", comment: "Accessibility Label for the tabs button in the tab toolbar")
}

// PRAGMA MARK: URLBarView.swift
public extension Strings {
    public static let URLBarViewLocationTextViewAccessibilityLabel = NSLocalizedString("AddressAndSearch", value: "Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
}

// PRAGMA MARK: LoginListViewController.swift
public extension Strings {
    // Titles for selection/deselect/delete buttons
    public static let LoginListDeselectAllButtonTitle = NSLocalizedString("DeselectAll", value: "Deselect All", comment: "Label for the button used to deselect all logins.")
    public static let LoginListSelectAllButtonTitle = NSLocalizedString("SelectAll", value: "Select All", comment: "Label for the button used to select all logins.")
    public static let LoginListDeleteLoginButtonTitle = NSLocalizedString("Delete", value: "Delete", comment: "Label for the button used to delete the current login.")
    public static let LoginListScreenTitle = NSLocalizedString("Logins", value: "Logins", comment: "Title for Logins List View screen.")
    public static let LoginListNoLoginTitle = NSLocalizedString("NoLoginsFound", value: "No logins found", comment: "Label displayed when no logins are found after searching.")
}

// PRAGMA MARK: LoginDetailViewController.swift
public extension Strings {
    public static let LoginDetailUsernameCellTitle = NSLocalizedString("Username", value: "username", comment: "Label displayed above the username row in Login Detail View.")
    public static let LoginDetailPasswordCellTitle = NSLocalizedString("Password", value: "password", comment: "Label displayed above the password row in Login Detail View.")
    public static let LoginDetailWebsiteCellTitle = NSLocalizedString("Website", value: "website", comment: "Label displayed above the website row in Login Detail View.")
    public static let LoginDetailLastModifiedCellFormatTitle  = NSLocalizedString("LastModified", value: "Last modified %@", comment: "Footer label describing when the current login was last modified with the timestamp as the parameter.")
    public static let LoginDetailDeleteCellTitle = NSLocalizedString("Delete", value: "Delete", comment: "Label for the button used to delete the current login.")
}

// PRAGMA MARK: ReaderModeHandlers.swift
public extension Strings {
    public static let ReaderModeLoadingContentDisplayText = NSLocalizedString("LoadingContent", value: "Loading content…", comment: "Message displayed when the reader mode page is loading. This message will appear only when sharing to Firefox reader mode from another app.")
    public static let ReaderModePageCantShowDisplayText = NSLocalizedString("ThePageCouldNotBeDisplayedInReaderView", value: "The page could not be displayed in Reader View.", comment: "Message displayed when the reader mode page could not be loaded. This message will appear only when sharing to Firefox reader mode from another app.")
    public static let ReaderModeLoadOriginalLinkText = NSLocalizedString("LoadOriginalPage", value: "Load original page", comment: "Link for going to the non-reader page when the reader view could not be loaded. This message will appear only when sharing to Firefox reader mode from another app.")
    public static let ReaderModeErrorConvertDisplayText = NSLocalizedString("ThereWasAnErrorConvertingThePage", value: "There was an error converting the page", comment: "Error displayed when reader mode cannot be enabled")
}

// PRAGMA MARK: ReaderModeStyleViewController.swift
public extension Strings {
    public static let ReaderModeBrightSliderAccessibilityLabel = NSLocalizedString("Brightness", value: "Brightness", comment: "Accessibility label for brightness adjustment slider in Reader Mode display settings")
    public static let ReaderModeFontTypeButtonAccessibilityHint = NSLocalizedString("ChangesFontType", value: "Changes font type.", comment: "Accessibility hint for the font type buttons in reader mode display settings")
    public static let ReaderModeFontButtonSansSerifTitle = NSLocalizedString("SansSerif", value: "Sans-serif", comment: "Font type setting in the reading view settings")
    public static let ReaderModeFontButtonSerifTitle = NSLocalizedString("Serif", value: "Serif", comment: "Font type setting in the reading view settings")
    public static let ReaderModeSmallerFontButtonTitle = NSLocalizedString("", value: "-", comment: "Button for smaller reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
    public static let ReaderModeSmallerFontButtonAccessibilityLabel = NSLocalizedString("DecreaseTextSize", value: "Decrease text size", comment: "Accessibility label for button decreasing font size in display settings of reader mode")
    public static let ReaderModeBiggerFontButtonTitle = NSLocalizedString("", value: "+", comment: "Button for larger reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
    public static let ReaderModeBiggerFontButtonAccessibilityLabel = NSLocalizedString("IncreaseTextSize", value: "Increase text size", comment: "Accessibility label for button increasing font size in display settings of reader mode")
    public static let ReaderModeFontSizeLabelText = NSLocalizedString("Aa", value: "Aa", comment: "Button for reader mode font size. Keep this extremely short! This is shown in the reader mode toolbar.")
    public static let ReaderModeThemeButtonAccessibilityHint = NSLocalizedString("ChangesColorTheme", value: "Changes color theme.", comment: "Accessibility hint for the color theme setting buttons in reader mode display settings")
    public static let ReaderModeThemeButtonTitleLight = NSLocalizedString("Light", value: "Light", comment: "Light theme setting in Reading View settings")
    public static let ReaderModeThemeButtonTitleDark = NSLocalizedString("Dark", value: "Dark", comment: "Dark theme setting in Reading View settings")
    public static let ReaderModeThemeButtonTitleSepia = NSLocalizedString("Sepia", value: "Sepia", comment: "Sepia theme setting in Reading View settings")
}

// PRAGMA MARK: SearchEnginePicker.swift
public extension Strings {
    public static let SearchEnginePickerNavTitle = NSLocalizedString("SearchPickerDefaultSearchEngineTitle", value: "Default Search Engine", comment: "Title for default search engine picker.")
    public static let SearchEnginePickerCancelButtonTitle = NSLocalizedString("Cancel", value: "Cancel", comment: "Label for Cancel button")
}

// PRAGMA MARK: SearchSettingsTableViewController.swift
public extension Strings {
    public static let SearchSettingNavTitle = NSLocalizedString("SettingsSearchNavigationTitle", value: "Search", comment: "Navigation title for search settings.")
    public static let SearchSettingSuggestionCellTitle = NSLocalizedString("ShowSearchSuggestions", value: "Show Search Suggestions", comment: "Label for show search suggestions setting.")
}

// PRAGMA MARK: SettingsContentViewController.swift
public extension Strings {
    public static let SettingsContentLoadErrorMessage = NSLocalizedString("CouldNotLoadPage", value: "Could not load page.", comment: "Error message that is shown in settings when there was a problem loading")
}

// PRAGMA MARK: TabsButton.swift
public extension Strings {
    public static let BrowserToolbarShowTabsButtonAccessibilityLabel = NSLocalizedString("BrowserToolbarShowTabsButtonAccessibilityLabel", value: "Show Tabs", comment: "Accessibility label for the tabs button in the (top) tab toolbar")
}

// PRAGMA MARK: SearchInputView.swift
public extension Strings {
    public static let SearchInputViewTextFieldAccessibilityLabel = NSLocalizedString("SearchInputField", value: "Search Input Field", comment: "Accessibility label for the search input field in the Logins list")
    public static let SearchInputViewTitle = NSLocalizedString("SearchFieldTitle", value: "Search", comment: "Title for the search field at the top of the Logins list screen")
    public static let SearchInputViewClearButtonTitle = NSLocalizedString("ClearSearch", value: "Clear Search", comment: "Accessibility message e.g. spoken by VoiceOver after the user taps the close button in the search field to clear the search and exit search mode")
    public static let SearchInputViewOverlayAccessibilityLabel = NSLocalizedString("EnterSearchMode", value: "Enter Search Mode", comment: "Accessibility label for entering search mode for logins")
}

// PRAGMA MARK: MenuHelper.swift
public extension Strings {
    public static let MenuItemRevealPasswordTitle = NSLocalizedString("Reveal", value: "Reveal", comment: "Reveal password text selection menu item")
    public static let MenuItemHidePasswordTitle = NSLocalizedString("Hide", value: "Hide", comment: "Hide password text selection menu item")
    public static let MenuItemCopyTitle = NSLocalizedString("Copy", value: "Copy", comment: "Copy password text selection menu item")
    public static let MenuItemOpenAndFillTitle = NSLocalizedString("OpenFill", value: "Open & Fill", comment: "Open and Fill website text selection menu item")
    public static let MenuItemFindInPageTitle = NSLocalizedString("FindInPage", value: "Find in Page", comment: "Text selection menu item")
}

// PRAGMA MARK: AuthenticationManagerConstants.swift
public extension Strings {
    public static let AuthenticationPasscode =
        NSLocalizedString("PasscodeForLogins", value: "Passcode For Logins", comment: "Label for the Passcode item in Settings")
    
    public static let AuthenticationTouchIDPasscodeSetting =
        NSLocalizedString("TouchIDPasscode", value: "Touch ID & Passcode", comment: "Label for the Touch ID/Passcode item in Settings")
    
    public static let AuthenticationFaceIDPasscodeSetting =
        NSLocalizedString("FaceIDPasscode", value: "Face ID & Passcode", comment: "Label for the Face ID/Passcode item in Settings")
    
    public static let AuthenticationRequirePasscode =
        NSLocalizedString("RequirePasscode", value: "Require Passcode", comment: "Text displayed in the 'Interval' section, followed by the current interval setting, e.g. 'Immediately'")
    
    public static let AuthenticationEnterAPasscode =
        NSLocalizedString("EnterAPasscode", value: "Enter a passcode", comment: "Text displayed above the input field when entering a new passcode")
    
    public static let AuthenticationEnterPasscodeTitle =
        NSLocalizedString("EnterPasscode", value: "Enter Passcode", comment: "Title of the dialog used to request the passcode")
    
    public static let AuthenticationEnterPasscode =
        NSLocalizedString("EnterPasscode", value: "Enter passcode", comment: "Text displayed above the input field when changing the existing passcode")
    
    public static let AuthenticationReenterPasscode =
        NSLocalizedString("ReEnterPasscode", value: "Re-enter passcode", comment: "Text displayed above the input field when confirming a passcode")
    
    public static let AuthenticationSetPasscode =
        NSLocalizedString("SetPasscode", value: "Set Passcode", comment: "Title of the dialog used to set a passcode")
    
    public static let AuthenticationTurnOffPasscode =
        NSLocalizedString("TurnPasscodeOff", value: "Turn Passcode Off", comment: "Label used as a setting item to turn off passcode")
    
    public static let AuthenticationTurnOnPasscode =
        NSLocalizedString("TurnPasscodeOn", value: "Turn Passcode On", comment: "Label used as a setting item to turn on passcode")
    
    public static let AuthenticationChangePasscode =
        NSLocalizedString("ChangePasscode", value: "Change Passcode", comment: "Label used as a setting item and title of the following screen to change the current passcode")
    
    public static let AuthenticationEnterNewPasscode =
        NSLocalizedString("EnterANewPasscode", value: "Enter a new passcode", comment: "Text displayed above the input field when changing the existing passcode")
    
    public static let AuthenticationImmediately =
        NSLocalizedString("Immediately", value: "Immediately", comment: "Immediately' interval item for selecting when to require passcode")
    
    public static let AuthenticationOneMinute =
        NSLocalizedString("After1Minute", value: "After 1 minute", comment: "After 1 minute' interval item for selecting when to require passcode")
    
    public static let AuthenticationFiveMinutes =
        NSLocalizedString("After5Minutes", value: "After 5 minutes", comment: "After 5 minutes' interval item for selecting when to require passcode")
    
    public static let AuthenticationTenMinutes =
        NSLocalizedString("After10Minutes", value: "After 10 minutes", comment: "After 10 minutes' interval item for selecting when to require passcode")
    
    public static let AuthenticationFifteenMinutes =
        NSLocalizedString("After15Minutes", value: "After 15 minutes", comment: "After 15 minutes' interval item for selecting when to require passcode")
    
    public static let AuthenticationOneHour =
        NSLocalizedString("After1Hour", value: "After 1 hour", comment: "After 1 hour' interval item for selecting when to require passcode")
    
    public static let AuthenticationLoginsTouchReason =
        NSLocalizedString("UseYourFingerprintToAccessLoginsNow", value: "Use your fingerprint to access Logins now.", comment: "Touch ID prompt subtitle when accessing logins")
    
    public static let AuthenticationRequirePasscodeTouchReason =
        NSLocalizedString("TouchidRequirePasscodeReasonLabel", value: "Use your fingerprint to access configuring your required passcode interval.", comment: "Touch ID prompt subtitle when accessing the require passcode setting")
    
    public static let AuthenticationDisableTouchReason =
        NSLocalizedString("TouchidDisableReasonLabel", value: "Use your fingerprint to disable Touch ID.", comment: "Touch ID prompt subtitle when disabling Touch ID")
    
    public static let AuthenticationWrongPasscodeError =
        NSLocalizedString("IncorrectPasscodeTryAgain", value: "Incorrect passcode. Try again.", comment: "Error message displayed when user enters incorrect passcode when trying to enter a protected section of the app")
    
    public static let AuthenticationIncorrectAttemptsRemaining =
        NSLocalizedString("IncorrectPasscodeTryAgainAttemptsRemainingd", value: "Incorrect passcode. Try again (Attempts remaining: %d).", comment: "Error message displayed when user enters incorrect passcode when trying to enter a protected section of the app with attempts remaining")
    
    public static let AuthenticationMaximumAttemptsReached =
        NSLocalizedString("MaximumAttemptsReachedPleaseTryAgainInAnHour", value: "Maximum attempts reached. Please try again in an hour.", comment: "Error message displayed when user enters incorrect passcode and has reached the maximum number of attempts.")
    
    public static let AuthenticationMaximumAttemptsReachedNoTime =
        NSLocalizedString("MaximumAttemptsReachedPleaseTryAgainLater", value: "Maximum attempts reached. Please try again later.", comment: "Error message displayed when user enters incorrect passcode and has reached the maximum number of attempts.")
}


// PRAGMA MARK:
public extension Strings {
    
}

// PRAGMA MARK:Settings.
public extension Strings {
    public static let ClearPrivateData = NSLocalizedString("ClearPrivateData", tableName: "BraveShared", value: "Clear Private Data", comment: "Button in settings that clears private data for the selected items. Also used as section title in settings panel")
}

// PRAGMA MARK:Error pages.
public extension Strings {
    public static let ErrorPagesAdvancedButton = NSLocalizedString("Advanced", tableName: "BraveShared", value: "Advanced", comment: "Label for button to perform advanced actions on the error page")
    public static let ErrorPagesAdvancedWarning1 = NSLocalizedString("WarningWeCantConfirmYourConnectionToThisWebsiteIsSecure", tableName: "BraveShared", value: "Warning: we can't confirm your connection to this website is secure.", comment: "Warning text when clicking the Advanced button on error pages")
    public static let ErrorPagesAdvancedWarning2 = NSLocalizedString("ItMayBeAMisconfigurationOrTamperingByAnAttackerProceedIfYouAcceptThePotentialRisk", tableName: "BraveShared", value: "It may be a misconfiguration or tampering by an attacker. Proceed if you accept the potential risk.", comment: "Additional warning text when clicking the Advanced button on error pages")
    public static let ErrorPagesCertWarningDescription = NSLocalizedString("TheOwnerOfHasConfiguredTheirWebsiteImproperlyToProtectYourInformationFromBeingStolenBraveHasNotConnectedToThisWebsite", tableName: "BraveShared", value: "The owner of %@ has configured their website improperly. To protect your information from being stolen, Brave has not connected to this website.", comment: "Warning text on the certificate error page")
    public static let ErrorPagesCertWarningTitle = NSLocalizedString("YourConnectionIsNotPrivate", tableName: "BraveShared", value: "Your connection is not private", comment: "Title on the certificate error page")
    public static let ErrorPagesGoBackButton = NSLocalizedString("GoBack", tableName: "BraveShared", value: "Go Back", comment: "Label for button to go back from the error page")
    public static let ErrorPagesVisitOnceButton = NSLocalizedString("VisitSiteAnyway", tableName: "BraveShared", value: "Visit site anyway", comment: "Button label to temporarily continue to the site from the certificate error page")
}

// PRAGMA MARK:Logins Helper.
public extension Strings {
    public static let SaveLogin = NSLocalizedString("SaveLogin", tableName: "BraveShared", value: "Save Login", comment: "Button to save the user's password")
    public static let DontSave = NSLocalizedString("DontSave", tableName: "BraveShared", value: "Don’t Save", comment: "Button to not save the user's password")
    public static let Update = NSLocalizedString("Update", tableName: "BraveShared", value: "Update", comment: "Button to update the user's password")
}

public extension Strings {
    public static let Home = NSLocalizedString("Home", tableName: "BraveShared", value: "Home", comment: "")
    public static let SearchNewTabTitle = NSLocalizedString("SearchInNewTab", tableName: "BraveShared", value: "Search in New Tab", comment: "")
    public static let SearchNewPrivateTabTitle = NSLocalizedString("SearchInNewPrivateTab", tableName: "BraveShared", value: "Search in New Private Tab", comment: "")
    public static let CloseAllTabsTitle = NSLocalizedString("CloseAlliTabs", tableName: "BraveShared", value: "Close All %i Tabs", comment: "")
}

public extension Strings {
    
    public static let Allow = NSLocalizedString("Allow", tableName: "BraveShared", value: "Allow", comment: "")
    public static let DontAllow = NSLocalizedString("DontAllow", tableName: "BraveShared", value: "Don't Allow", comment: "")
    public static let NewFolder = NSLocalizedString("NewFolder", tableName: "BraveShared", value: "New Folder", comment: "Title for new folder popup")
    public static let EnterFolderName = NSLocalizedString("EnterFolderName", tableName: "BraveShared", value: "Enter folder name", comment: "Description for new folder popup")
    public static let Edit = NSLocalizedString("Edit", tableName: "BraveShared", value: "Edit", comment: "")
    
    public static let NewDevice = NSLocalizedString("DeviceName", tableName: "BraveShared", value: "Device Name", comment: "Title for new device popup")
    public static let DeviceFolderName = NSLocalizedString("PleaseEnterANameForThisDevice", tableName: "BraveShared", value: "Please enter a name for this device", comment: "Description for new device popup")
    
    public static let FavoritesPopupTitle = NSLocalizedString("TopSitesAreNowFavorites", tableName: "BraveShared", value: "Top sites are now favorites.", comment: "Title for convert favorites popup")
    public static let FavoritesPopupDescription = NSLocalizedString("YouCanNowEditAndArrangeFavoritesHoweverYouLikeAddFavoritesFromTheShareMenuWhenVisitingAWebsite", tableName: "BraveShared", value: "You can now edit and arrange favorites however you like. Add favorites from the share menu when visiting a website.", comment: "Description for convert favorites popup")
    public static let Convert = NSLocalizedString("Convert", tableName: "BraveShared", value: "Convert", comment: "Title for convert favorites popup convert button")
    public static let UseDefaults = NSLocalizedString("UseDefaults", tableName: "BraveShared", value: "Use Defaults", comment: "Title for convert favorites popup use defaults button")
    
    public static let RequestSwitchAppsTitle = NSLocalizedString("AllowLinkToSwitchApps", tableName: "BraveShared", value: "Allow link to switch apps?", comment: "")
    public static let RequestSwitchAppsMessage = NSLocalizedString("WillLaunchAnExternalApplication", tableName: "BraveShared", value: "%@ will launch an external application", comment: "")
    public static let SyncUnsuccessful = NSLocalizedString("Unsuccessful", tableName: "BraveShared", value: "Unsuccessful", comment: "")
    public static let SyncUnableCreateGroup = NSLocalizedString("UnableToCreateNewSyncGroup", tableName: "BraveShared", value: "Unable to create new sync group.", comment: "Description on popup when setting up a sync group fails")
    
    public static let ShowTour = NSLocalizedString("ShowTour", tableName: "BraveShared", value: "Show Tour", comment: "Show the on-boarding screen again from the settings")
    public static let CurrentlyUsedSearchEngines = NSLocalizedString("SettingsOpenDefaultSearchEngineForMode", tableName: "BraveShared", value: "Currently used search engines", comment: "Currently usedd search engines section name.")
    public static let QuickSearchEngines = NSLocalizedString("QuickSearchEngines", tableName: "BraveShared", value: "Quick-Search Engines", comment: "Title for quick-search engines settings section.")
    public static let StandardTabSearch = NSLocalizedString("StandardTab", tableName: "BraveShared", value: "Standard Tab", comment: "Open search section of settings")
    public static let PrivateTabSearch = NSLocalizedString("PrivateTab", tableName: "BraveShared", value: "Private Tab", comment: "Default engine for private search.")
    public static let SearchEngines = NSLocalizedString("SettingsOpenDefaultSearch", tableName: "BraveShared", value: "Search Engines", comment: "Search engines section of settings")
    public static let Logins = NSLocalizedString("Logins", tableName: "BraveShared", value: "Logins", comment: "Label used as an item in Settings. When touched, the user will be navigated to the Logins/Password manager.")
    public static let Settings = NSLocalizedString("Settings", tableName: "BraveShared", value: "Settings", comment: "")
    public static let OtherSettings = NSLocalizedString("OtherSettings", tableName: "BraveShared", value: "Other Settings", comment: "Other settings sectiont title")
    public static let Done = NSLocalizedString("Done", tableName: "BraveShared", value: "Done", comment: "")
    public static let Confirm = NSLocalizedString("Confirm", tableName: "BraveShared", value: "Confirm", comment: "")
    public static let Privacy = NSLocalizedString("Privacy", tableName: "BraveShared", value: "Privacy", comment: "Settings privacy section title")
    public static let Security = NSLocalizedString("Security", tableName: "BraveShared", value: "Security", comment: "Settings security section title")
    public static let BlockPopupWindows = NSLocalizedString("BlockPopUpWindows", tableName: "BraveShared", value: "Block Pop-up Windows", comment: "Block pop-up windows setting")
    public static let Save_Logins = NSLocalizedString("SaveLogins", tableName: "BraveShared", value: "Save Logins", comment: "Setting to enable the built-in password manager")
    public static let ShieldsAdStats = NSLocalizedString("AdsrBlocked", tableName: "BraveShared", value: "Ads \rBlocked", comment: "Shields Ads Stat")
    public static let ShieldsTrackerStats = NSLocalizedString("TrackersrBlocked", tableName: "BraveShared", value: "Trackers \rBlocked", comment: "Shields Trackers Stat")
    public static let ShieldsHttpsStats = NSLocalizedString("HTTPSrUpgrades", tableName: "BraveShared", value: "HTTPS \rUpgrades", comment: "Shields Https Stat")
    public static let ShieldsTimeStats = NSLocalizedString("EstTimerSaved", tableName: "BraveShared", value: "Est. Time \rSaved", comment: "Shields Time Saved Stat")
    public static let ShieldsTimeStatsHour = NSLocalizedString("H", tableName: "BraveShared", value: "h", comment: "Time Saved Hours")
    public static let ShieldsTimeStatsMinutes = NSLocalizedString("Min", tableName: "BraveShared", value: "min", comment: "Time Saved Minutes")
    public static let ShieldsTimeStatsSeconds = NSLocalizedString("S", tableName: "BraveShared", value: "s", comment: "Time Saved Seconds")
    public static let ShieldsTimeStatsDays = NSLocalizedString("D", tableName: "BraveShared", value: "d", comment: "Time Saved Days")
    public static let ThisWillClearAllPrivateDataItCannotBeUndone = NSLocalizedString("ThisActionWillClearAllOfYourPrivateDataItCannotBeUndone", tableName: "BraveShared", value: "This action will clear all of your private data. It cannot be undone.", comment: "Description of the confirmation dialog shown when a user tries to clear their private data.")
    public static let OK = NSLocalizedString("OK", tableName: "BraveShared", value: "OK", comment: "OK button")
    public static let AreYouSure = NSLocalizedString("AreYouSure", tableName: "BraveShared", value: "Are you sure?", comment: "")
    public static let LoginsWillBePermanentlyRemoved = NSLocalizedString("LoginsWillBePermanentlyRemoved", tableName: "BraveShared", value: "Logins will be permanently removed.", comment: "")
    public static let LoginsWillBeRemovedFromAllConnectedDevices = NSLocalizedString("LoginsWillBeRemovedFromAllConnectedDevices", tableName: "BraveShared", value: "Logins will be removed from all connected devices.", comment: "")
    public static let Delete = NSLocalizedString("Delete", tableName: "BraveShared", value: "Delete", comment: "")
    public static let Web_content = NSLocalizedString("WebContent", tableName: "BraveShared", value: "Web content", comment: "Accessibility label for the main web content view")
    public static let Search_or_enter_address = NSLocalizedString("SearchOrEnterWebsite", tableName: "BraveShared", value: "Search or enter website", comment: "The text shown in the URL bar on about:home")
    public static let Secure_connection = NSLocalizedString("SecureConnection", tableName: "BraveShared", value: "Secure connection", comment: "Accessibility label for the lock icon, which is only present if the connection is secure")
    public static let Private_mode_icon = NSLocalizedString("PrivateModeIcon", tableName: "BraveShared", value: "Private mode icon", comment: "Private mode icon next to location string")
    public static let Reader_View = NSLocalizedString("ReaderView", tableName: "BraveShared", value: "Reader View", comment: "Accessibility label for the Reader View button")
    public static let Add_to_Reading_List = NSLocalizedString("AddToReadingList", tableName: "BraveShared", value: "Add to Reading List", comment: "Accessibility label for action adding current page to reading list.")
    public static let Stop = NSLocalizedString("Stop", tableName: "BraveShared", value: "Stop", comment: "Accessibility Label for the browser toolbar Stop button")
    public static let Reload = NSLocalizedString("Reload", tableName: "BraveShared", value: "Reload", comment: "Accessibility Label for the browser toolbar Reload button")
    public static let Back = NSLocalizedString("Back", tableName: "BraveShared", value: "Back", comment: "Accessibility Label for the browser toolbar Back button")
    public static let Forward = NSLocalizedString("Forward", tableName: "BraveShared", value: "Forward", comment: "Accessibility Label for the browser toolbar Forward button")
    
    public static let PasswordManager = NSLocalizedString("PasswordManager", tableName: "BraveShared", value: "Password Manager", comment: "Accessibility Label for the browser toolbar Password Manager button")
    public static let Bookmark = NSLocalizedString("Bookmark", tableName: "BraveShared", value: "Bookmark", comment: "Accessibility Label for the browser toolbar Bookmark button")
    public static let FavoritesFolder = NSLocalizedString("Favorites", tableName: "BraveShared", value: "Favorites", comment: "Folder for storing favorite bookmarks.")
    public static let New_Tab = NSLocalizedString("NewTab", tableName: "BraveShared", value: "New Tab", comment: "New Tab title")
    
    public static let Navigation_Toolbar = NSLocalizedString("NavigationToolbar", tableName: "BraveShared", value: "Navigation Toolbar", comment: "Accessibility label for the navigation toolbar displayed at the bottom of the screen.")
    public static let Open_In_Background_Tab = NSLocalizedString("OpenLinkInNewTab", tableName: "BraveShared", value: "Open Link In New Tab", comment: "Context menu item for opening a link in a new tab")
    public static let Open_In_New_Private_Tab = NSLocalizedString("OpenInNewPrivateTab", tableName: "BraveShared", value: "Open In New Private Tab", comment: "Context menu option for opening a link in a new private tab")
    public static let Share_Image = NSLocalizedString("ShareImage", tableName: "BraveShared", value: "Share Image", comment: "Context menu option for sharing an image")
    public static let Copy_Link = NSLocalizedString("CopyLink", tableName: "BraveShared", value: "Copy Link", comment: "Context menu item for copying a link URL to the clipboard")
    public static let Open_All_Bookmarks = NSLocalizedString("OpenAlli", tableName: "BraveShared", value: "Open All (%i)", comment: "Context menu item for opening all folder bookmarks")
    public static let Share_Link = NSLocalizedString("ShareLink", tableName: "BraveShared", value: "Share Link", comment: "Context menu item for sharing a link URL")
    public static let Save_Image = NSLocalizedString("SaveImage", tableName: "BraveShared", value: "Save Image", comment: "Context menu item for saving an image")
    public static let Open_Image_In_Background_Tab = NSLocalizedString("OpenImageInNewTab", tableName: "BraveShared", value: "Open Image In New Tab", comment: "Context menu for opening image in new tab")
    public static let This_allows_you_to_save_the_image_to_your_CameraRoll = NSLocalizedString("ThisAllowsYouToSaveTheImageToYourCameraRoll", tableName: "BraveShared", value: "This allows you to save the image to your Camera Roll.", comment: "See http://mzl.la/1G7uHo7")
    public static let Open_Settings = NSLocalizedString("OpenSettings", tableName: "BraveShared", value: "Open Settings", comment: "See http://mzl.la/1G7uHo7")
    public static let Copy_Image = NSLocalizedString("CopyImage", tableName: "BraveShared", value: "Copy Image", comment: "Context menu item for copying an image to the clipboard")
    public static let Call = NSLocalizedString("Call", tableName: "BraveShared", value: "Call", comment: "Alert Call Button")
    public static let AllowOpenITunes_template = NSLocalizedString("AllowToOpenITunes", tableName: "BraveShared", value: "Allow %@ to open iTunes?", comment: "Ask user if site can open iTunes store URL")
    public static let Paste_and_Go = NSLocalizedString("PasteGo", tableName: "BraveShared", value: "Paste & Go", comment: "Paste the URL into the location bar and visit")
    public static let Paste = NSLocalizedString("Paste", tableName: "BraveShared", value: "Paste", comment: "Paste the URL into the location bar")
    public static let Copy_Address = NSLocalizedString("CopyAddress", tableName: "BraveShared", value: "Copy Address", comment: "Copy the URL from the location bar")
    public static let Try_again = NSLocalizedString("TryAgain", tableName: "BraveShared", value: "Try again", comment: "Shown in error pages on a button that will try to load the page again")
    public static let Open_in_Safari = NSLocalizedString("OpenInSafari", tableName: "BraveShared", value: "Open in Safari", comment: "Shown in error pages for files that can't be shown and need to be downloaded.")
    public static let Previous_inpage_result = NSLocalizedString("PreviousInPageResult", tableName: "BraveShared", value: "Previous in-page result", comment: "Accessibility label for previous result button in Find in Page Toolbar.")
    public static let Next_inpage_result = NSLocalizedString("NextInPageResult", tableName: "BraveShared", value: "Next in-page result", comment: "Accessibility label for next result button in Find in Page Toolbar.")
    public static let Save_login_for_template = NSLocalizedString("SaveLoginFor", tableName: "BraveShared", value: "Save login %@ for %@?", comment: "Prompt for saving a login. The first parameter is the username being saved. The second parameter is the hostname of the site.")
    public static let Save_password_for_template = NSLocalizedString("SavePasswordFor", tableName: "BraveShared", value: "Save password for %@?", comment: "Prompt for saving a password with no username. The parameter is the hostname of the site.")
    public static let Update_login_for_template = NSLocalizedString("UpdateLoginFor", tableName: "BraveShared", value: "Update login %@ for %@?", comment: "Prompt for updating a login. The first parameter is the username for which the password will be updated for. The second parameter is the hostname of the site.")
    public static let Update_password_for_template = NSLocalizedString("UpdatePasswordFor", tableName: "BraveShared", value: "Update password for %@?", comment: "Prompt for updating a password with no username. The parameter is the hostname of the site.")
    public static let Open_in = NSLocalizedString("OpenIn", tableName: "BraveShared", value: "Open in…", comment: "String indicating that the file can be opened in another application on the device")
    public static let Mark_as_Read = NSLocalizedString("MarkAsRead", tableName: "BraveShared", value: "Mark as Read", comment: "Name for Mark as read button in reader mode")
    public static let Mark_as_Unread = NSLocalizedString("MarkAsUnread", tableName: "BraveShared", value: "Mark as Unread", comment: "Name for Mark as unread button in reader mode")
    public static let Reader_Mode_Settings = NSLocalizedString("ReaderModeSettings", tableName: "BraveShared", value: "Reader Mode Settings", comment: "Name for display settings button in reader mode. Display in the meaning of presentation, not monitor.")
    public static let Could_not_add_page_to_Reading_List = NSLocalizedString("CouldNotAddPageToReadingListMaybeItsAlreadyThere", tableName: "BraveShared", value: "Could not add page to Reading List. Maybe it's already there?", comment: "Accessibility message e.g. spoken by VoiceOver after the user wanted to add current page to the Reading List and this was not done, likely because it already was in the Reading List, but perhaps also because of real failures.")
    public static let Remove_from_Reading_List = NSLocalizedString("RemoveFromReadingList", tableName: "BraveShared", value: "Remove from Reading List", comment: "Name for button removing current article from reading list in reader mode")
    public static let Turn_on_search_suggestions = NSLocalizedString("TurnOnSearchSuggestions", tableName: "BraveShared", value: "Turn on search suggestions?", comment: "Prompt shown before enabling provider search queries")
    public static let Yes = NSLocalizedString("Yes", tableName: "BraveShared", value: "Yes", comment: "For search suggestions prompt. This string should be short so it fits nicely on the prompt row.")
    public static let No = NSLocalizedString("No", tableName: "BraveShared", value: "No", comment: "For search suggestions prompt. This string should be short so it fits nicely on the prompt row.")
    public static let Search_arg_site_template = NSLocalizedString("Search", tableName: "BraveShared", value: "%@ search", comment: "Label for search engine buttons. The argument corresponds to the name of the search engine.")
    public static let Search_suggestions_from_template = NSLocalizedString("SearchSuggestionsFrom", tableName: "BraveShared", value: "Search suggestions from %@", comment: "Accessibility label for image of default search engine displayed left to the actual search suggestions from the engine. The parameter substituted for \"%@\" is the name of the search engine. E.g.: Search suggestions from Google")
    public static let Searches_for_the_suggestion = NSLocalizedString("SearchesForTheSuggestion", tableName: "BraveShared", value: "Searches for the suggestion", comment: "Accessibility hint describing the action performed when a search suggestion is clicked")
    public static let Close = NSLocalizedString("Close", tableName: "BraveShared", value: "Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)")
    public static let Private_Mode = NSLocalizedString("PrivateMode", tableName: "BraveShared", value: "Private Mode", comment: "Accessibility label for toggling on/off private mode")
    public static let Turns_private_mode_on_or_off = NSLocalizedString("TurnsPrivateModeOnOrOff", tableName: "BraveShared", value: "Turns private mode on or off", comment: "Accessiblity hint for toggling on/off private mode")
    public static let On = NSLocalizedString("On", tableName: "BraveShared", value: "On", comment: "Toggled ON accessibility value")
    public static let Off = NSLocalizedString("Off", tableName: "BraveShared", value: "Off", comment: "Toggled OFF accessibility value")
    public static let Private = NSLocalizedString("Private", tableName: "BraveShared", value: "Private", comment: "Private button title")
    public static let Tabs_Tray = NSLocalizedString("TabsTray", tableName: "BraveShared", value: "Tabs Tray", comment: "Accessibility label for the Tabs Tray view.")
    public static let Tabs = NSLocalizedString("Tabs", tableName: "BraveShared", value: "Tabs", comment: "Accessibility label for the Tabs.")
    public static let Tab = NSLocalizedString("Tab", tableName: "BraveShared", value: "Tab", comment: "Accessibility label for a Tab.")
    
    public static let No_tabs = NSLocalizedString("NoTabs", tableName: "BraveShared", value: "No tabs", comment: "Message spoken by VoiceOver to indicate that there are no tabs in the Tabs Tray")
    public static let Tab_xofx_template = NSLocalizedString("TabOf", tableName: "BraveShared", value: "Tab %@ of %@", comment: "Message spoken by VoiceOver saying the position of the single currently visible tab in Tabs Tray, along with the total number of tabs. E.g. \"Tab 2 of 5\" says that tab 2 is visible (and is the only visible tab), out of 5 tabs total.")
    public static let Tabs_xtoxofx_template = NSLocalizedString("TabsToOf", tableName: "BraveShared", value: "Tabs %@ to %@ of %@", comment: "Message spoken by VoiceOver saying the range of tabs that are currently visible in Tabs Tray, along with the total number of tabs. E.g. \"Tabs 8 to 10 of 15\" says tabs 8, 9 and 10 are visible, out of 15 tabs total.")
    public static let Closing_tab = NSLocalizedString("ClosingTab", tableName: "BraveShared", value: "Closing tab", comment: "")
    public static let Swipe_right_or_left_with_three_fingers_to_close_the_tab = NSLocalizedString("SwipeRightOrLeftWithThreeFingersToCloseTheTab", tableName: "BraveShared", value: "Swipe right or left with three fingers to close the tab.", comment: "Accessibility hint for tab tray's displayed tab.")
    public static let Learn_More = NSLocalizedString("LearnMore", tableName: "BraveShared", value: "Learn More", comment: "Text button displayed when there are no tabs open while in private mode")
    public static let Private_Browsing = NSLocalizedString("PrivateBrowsing", tableName: "BraveShared", value: "Private Browsing", comment: "")
    public static let Show_Tabs = NSLocalizedString("BrowserToolbarShowTabsButtonAccessibilityLabel", tableName: "BraveShared", value: "Show Tabs", comment: "Accessibility Label for the tabs button in the browser toolbar")
    public static let Address_and_Search = NSLocalizedString("AddressAndSearch", tableName: "BraveShared", value: "Address and Search", comment: "Accessibility label for address and search field, both words (Address, Search) are therefore nouns.")
    public static let This_folder_isnt_empty = NSLocalizedString("ThisFolderIsntEmpty", tableName: "BraveShared", value: "This folder isn't empty.", comment: "Title of the confirmation alert when the user tries to delete_a_folder_that_still_contains_bookmarks_and/or folders.")
    public static let Are_you_sure_you_want_to_delete_it_and_its_contents = NSLocalizedString("AreYouSureYouWantToDeleteItAndItsContents", tableName: "BraveShared", value: "Are you sure you want to delete it and its contents?", comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
    public static let Bookmark_Folder = NSLocalizedString("BookmarkFolder", tableName: "BraveShared", value: "Bookmark Folder", comment: "Bookmark Folder Section Title")
    public static let Bookmark_Info = NSLocalizedString("BookmarkInfo", tableName: "BraveShared", value: "Bookmark Info", comment: "Bookmark Info Section Title")
    public static let Name = NSLocalizedString("Name", tableName: "BraveShared", value: "Name", comment: "Bookmark title / Device name")
    public static let URL = NSLocalizedString("URL", tableName: "BraveShared", value: "URL", comment: "Bookmark URL")
    public static let Location = NSLocalizedString("Location", tableName: "BraveShared", value: "Location", comment: "Bookmark folder location")
    public static let Folder = NSLocalizedString("Folder", tableName: "BraveShared", value: "Folder", comment: "Folder")
    public static let Bookmarks = NSLocalizedString("Bookmarks", tableName: "BraveShared", value: "Bookmarks", comment: "title for bookmarks panel")
    public static let Today = NSLocalizedString("Today", tableName: "BraveShared", value: "Today", comment: "History tableview section header")
    public static let Yesterday = NSLocalizedString("Yesterday", tableName: "BraveShared", value: "Yesterday", comment: "History tableview section header")
    public static let Last_week = NSLocalizedString("LastWeek", tableName: "BraveShared", value: "Last week", comment: "History tableview section header")
    public static let Last_month = NSLocalizedString("LastMonth", tableName: "BraveShared", value: "Last month", comment: "History tableview section header")
    public static let Remove = NSLocalizedString("Remove", tableName: "BraveShared", value: "Remove", comment: "Action button for deleting_history_entries_in_the_history_panel.")
    public static let Top_sites = NSLocalizedString("TopSites", tableName: "BraveShared", value: "Top sites", comment: "Panel accessibility label")
    public static let History = NSLocalizedString("History", tableName: "BraveShared", value: "History", comment: "Panel accessibility label")
    public static let Reading_list = NSLocalizedString("ReadingList", tableName: "BraveShared", value: "Reading list", comment: "Panel accessibility label")
    public static let Panel_Chooser = NSLocalizedString("PanelChooser", tableName: "BraveShared", value: "Panel Chooser", comment: "Accessibility label for the Home panel's top toolbar containing list of the home panels (top sites, bookmarsk, history, remote tabs, reading list).")
    public static let Read = NSLocalizedString("Read", tableName: "BraveShared", value: "read", comment: "Accessibility label for read article in reading list. It's a past participle - functions as an adjective.")
    public static let Unread = NSLocalizedString("Unread", tableName: "BraveShared", value: "unread", comment: "Accessibility label for unread article in reading list. It's a past participle - functions as an adjective.")
    public static let Welcome_to_your_Reading_List = NSLocalizedString("WelcomeToYourReadingList", tableName: "BraveShared", value: "Welcome to your Reading List", comment: "See http://mzl.la/1LXbDOL")
    public static let Open_articles_in_Reader_View_by_tapping_the_book_icon = NSLocalizedString("OpenArticlesInReaderViewByTappingTheBookIconWhenItAppearsInTheTitleBar", tableName: "BraveShared", value: "Open articles in Reader View by tapping the book icon when it appears in the title bar.", comment: "See http://mzl.la/1LXbDOL")
    public static let Save_pages_to_your_Reading_List_by_tapping_the_book = NSLocalizedString("SavePagesToYourReadingListByTappingTheBookPlusIconInTheReaderViewControls", tableName: "BraveShared", value: "Save pages to your Reading List by tapping the book plus icon in the Reader View controls.", comment: "See http://mzl.la/1LXbDOL")
    public static let Start_Browsing = NSLocalizedString("StartBrowsing", tableName: "BraveShared", value: "Start Browsing", comment: "")
    public static let Welcome_to_Brave = NSLocalizedString("WelcomeToBrave", tableName: "BraveShared", value: "Welcome to Brave.", comment: "Shown in intro screens")
    public static let Get_ready_to_experience_a_Faster = NSLocalizedString("GetReadyToExperienceAFasterSaferBetterWeb", tableName: "BraveShared", value: "Get ready to experience a Faster, Safer, Better Web.", comment: "Shown in intro screens")
    public static let Brave_is_Faster = NSLocalizedString("BraveIsFasternandHeresWhy", tableName: "BraveShared", value: "Brave is Faster,\nand here's why...", comment: "Shown in intro screens")
    public static let Brave_blocks_ads_and_trackers = NSLocalizedString("BraveBlocksAdsnBraveStopsTrackersnBraveIsDesignedForSpeedAndEfficiency", tableName: "BraveShared", value: "Brave blocks ads.\nBrave stops trackers.\nBrave is designed for speed and efficiency.", comment: "Shown in intro screens")
    public static let Brave_keeps_you_safe_as_you_browse = NSLocalizedString("BraveKeepsYouSafeAsYouBrowse", tableName: "BraveShared", value: "Brave keeps you safe as you browse.", comment: "Shown in intro screens")
    public static let Browsewithusandyourprivacyisprotected = NSLocalizedString("BrowseWithUsAndYourPrivacyIsProtectedWithNothingFurtherToInstallLearnOrConfigure", tableName: "BraveShared", value: "Browse with us and your privacy is protected, with nothing further to install, learn or configure.", comment: "Shown in intro screens")
    public static let Incaseyouhitaspeedbump = NSLocalizedString("InCaseYouHitASpeedBump", tableName: "BraveShared", value: "In case you hit a speed bump", comment: "Shown in intro screens")
    public static let TapTheBraveButtonToTemporarilyDisable = NSLocalizedString("TapTheBraveButtonToTemporarilyDisableAdBlockingAndPrivacyFeatures", tableName: "BraveShared", value: "Tap the Brave button to temporarily disable ad blocking and privacy features.", comment: "Shown in intro screens")
    public static let IntroTourCarousel = NSLocalizedString("IntroTourCarousel", tableName: "BraveShared", value: "Intro Tour Carousel", comment: "Accessibility label for the introduction tour carousel")
    public static let IntroductorySlideXofX_template = NSLocalizedString("IntroductorySlideOf", tableName: "BraveShared", value: "Introductory slide %@ of %@", comment: "String spoken by assistive technology (like VoiceOver) stating on which page of the intro wizard we currently are. E.g. Introductory slide 1 of 3")
    public static let DeselectAll = NSLocalizedString("DeselectAll", tableName: "BraveShared", value: "Deselect All", comment: "Title for deselecting all selected logins")
    public static let SelectAll = NSLocalizedString("SelectAll", tableName: "BraveShared", value: "Select All", comment: "Title for selecting all logins")
    public static let NoLoginsFound = NSLocalizedString("NoLoginsFound", tableName: "BraveShared", value: "No logins found", comment: "Title displayed when no logins are found after searching")
    public static let LoadingContent = NSLocalizedString("LoadingContent", tableName: "BraveShared", value: "Loading content…", comment: "Message displayed when the reader mode page is loading. This message will appear only when sharing to Brave reader mode from another app.")
    public static let CantDisplayInReaderView = NSLocalizedString("ThePageCouldNotBeDisplayedInReaderView", tableName: "BraveShared", value: "The page could not be displayed in Reader View.", comment: "Message displayed when the reader mode page could not be loaded. This message will appear only when sharing to Brave reader mode from another app.")
    public static let LoadOriginalPage = NSLocalizedString("LoadOriginalPage", tableName: "BraveShared", value: "Load original page", comment: "Link for going to the non-reader page when the reader view could not be loaded. This message will appear only when sharing to Brave reader mode from another app.")
    public static let There_was_an_error_converting_the_page = NSLocalizedString("ThereWasAnErrorConvertingThePage", tableName: "BraveShared", value: "There was an error converting the page", comment: "Error displayed when reader mode cannot be enabled")
    public static let Brightness = NSLocalizedString("Brightness", tableName: "BraveShared", value: "Brightness", comment: "Accessibility label for brightness adjustment slider in Reader Mode display settings")
    public static let Changes_font_type = NSLocalizedString("ChangesFontType", tableName: "BraveShared", value: "Changes font type.", comment: "Accessibility hint for the font type buttons in reader mode display settings")
    public static let SansSerif = NSLocalizedString("SansSerif", tableName: "BraveShared", value: "Sans-serif", comment: "Font type setting in the reading view settings")
    public static let Serif = NSLocalizedString("Serif", tableName: "BraveShared", value: "Serif", comment: "Font type setting in the reading view settings")
    public static let Minus = NSLocalizedString("", tableName: "BraveShared", value: "-", comment: "Button for smaller reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
    public static let Decrease_text_size = NSLocalizedString("DecreaseTextSize", tableName: "BraveShared", value: "Decrease text size", comment: "Accessibility label for button decreasing font size in display settings of reader mode")
    public static let Plus = NSLocalizedString("", tableName: "BraveShared", value: "+", comment: "Button for larger reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
    public static let Increase_text_size = NSLocalizedString("IncreaseTextSize", tableName: "BraveShared", value: "Increase text size", comment: "Accessibility label for button increasing font size in display settings of reader mode")
    public static let FontSizeAa = NSLocalizedString("Aa", tableName: "BraveShared", value: "Aa", comment: "Button for reader mode font size. Keep this extremely short! This is shown in the reader mode toolbar.")
    public static let Changes_color_theme = NSLocalizedString("ChangesColorTheme", tableName: "BraveShared", value: "Changes color theme.", comment: "Accessibility hint for the color theme setting buttons in reader mode display settings")
    public static let Light = NSLocalizedString("Light", tableName: "BraveShared", value: "Light", comment: "Light theme setting in Reading View settings")
    public static let Dark = NSLocalizedString("Dark", tableName: "BraveShared", value: "Dark", comment: "Dark theme setting in Reading View settings")
    public static let Sepia = NSLocalizedString("Sepia", tableName: "BraveShared", value: "Sepia", comment: "Sepia theme setting in Reading View settings")
    public static let General = NSLocalizedString("General", tableName: "BraveShared", value: "General", comment: "General settings section title")
    public static let PinNew = NSLocalizedString("EnterNewPIN", tableName: "BraveShared", value: "Enter New PIN", comment: "Browser Lock New Pin")
    public static let PinNewRe = NSLocalizedString("ReEnterNewPIN", tableName: "BraveShared", value: "Re-Enter New PIN", comment: "Browser Lock Re-Enter New Pin")
    public static let PinSet = NSLocalizedString("SetPIN", tableName: "BraveShared", value: "Set PIN", comment: "Browser Lock Set Pin")
    public static let PinEnterToUnlock = NSLocalizedString("EnterPINToUnlockBrave", tableName: "BraveShared", value: "Enter PIN to Unlock Brave", comment: "Unlock Brave with Browser Lock Pin")
    public static let PinFingerprintUnlock = NSLocalizedString("UseYourFingerprintToUnlockBrave", tableName: "BraveShared", value: "Use your fingerprint to unlock Brave.", comment: "Unlock Brave with fingerprint.")
    public static let Close_Private_Tabs = NSLocalizedString("ClosePrivateTabs", tableName: "BraveShared", value: "Close Private Tabs", comment: "Setting for closing private tabs")
    public static let When_Leaving_Private_Browsing = NSLocalizedString("WhenLeavingPrivateBrowsing", tableName: "BraveShared", value: "When Leaving Private Browsing", comment: "Will be displayed in Settings under 'Close Private Tabs'")
    public static let Saved_Logins = NSLocalizedString("SavedLogins", tableName: "BraveShared", value: "Saved Logins", comment: "Settings item for clearing passwords and login data")
    public static let Browsing_History = NSLocalizedString("BrowsingHistory", tableName: "BraveShared", value: "Browsing History", comment: "Settings item for clearing browsing history")
    public static let GrantCameraAccess = NSLocalizedString("EnableCamera", tableName: "BraveShared", value: "Enable Camera", comment: "Grand camera access")
    public static let Cache = NSLocalizedString("Cache", tableName: "BraveShared", value: "Cache", comment: "Settings item for clearing the cache")
    public static let Offline_Website_Data = NSLocalizedString("OfflineWebsiteData", tableName: "BraveShared", value: "Offline Website Data", comment: "Settings item for clearing website data")
    public static let Cookies = NSLocalizedString("Cookies", tableName: "BraveShared", value: "Cookies", comment: "Settings item for clearing cookies")
    public static let Username = NSLocalizedString("Username", tableName: "BraveShared", value: "username", comment: "Title for username row in Login Detail View")
    public static let Password = NSLocalizedString("Password", tableName: "BraveShared", value: "password", comment: "Title for password row in Login Detail View")
    public static let ShowPicker = NSLocalizedString("ShowPicker", tableName: "BraveShared", value: "Show picker", comment: "Password Manager show picker option")
    public static let Website = NSLocalizedString("Website", tableName: "BraveShared", value: "website", comment: "Title for website row in Login Detail View")
    public static let Last_modified_date_template = NSLocalizedString("LastModified", tableName: "BraveShared", value: "Last modified %@", comment: "Footer label describing when the login was last modified with the timestamp as the parameter")
    public static let Show_Search_Suggestions = NSLocalizedString("ShowSearchSuggestions", tableName: "BraveShared", value: "Show Search Suggestions", comment: "Label for show search suggestions setting.")
    public static let Quicksearch_Engines = NSLocalizedString("QuickSearchEngines", tableName: "BraveShared", value: "Quick-search Engines", comment: "Title for quick-search engines settings section.")
    public static let Clear_Everything = NSLocalizedString("ClearEverything", tableName: "BraveShared", value: "Clear Everything", comment: "Title of the Clear private data dialog.")
    public static let Are_you_sure_you_want_to_clear_all_of_your_data = NSLocalizedString("AreYouSureYouWantToClearAllOfYourDataThisWillAlsoCloseAllOpenTabs", tableName: "BraveShared", value: "Are you sure you want to clear all of your data? This will also close all open tabs.", comment: "Message shown in the dialog prompting users if they want to clear everything")
    public static let Clear = NSLocalizedString("Clear", tableName: "BraveShared", value: "Clear", comment: "Used as a button label in the dialog to Clear private data dialog")
    public static let Find_in_Page = NSLocalizedString("FindInPage", tableName: "BraveShared", value: "Find in Page", comment: "Share action title")
    public static let Open_Desktop_Site_tab = NSLocalizedString("OpenDesktopSiteTab", tableName: "BraveShared", value: "Open Desktop Site tab", comment: "Share action title")
    public static let Add_to_favorites = NSLocalizedString("AddToFavorites", tableName: "BraveShared", value: "Add to Favorites", comment: "Add to favorites share action.")
    public static let Search_Input_Field = NSLocalizedString("SearchInputField", tableName: "BraveShared", value: "Search Input Field", comment: "Accessibility label for the search input field in the Logins list")
    
    public static let Clear_Search = NSLocalizedString("ClearSearch", tableName: "BraveShared", value: "Clear Search", comment: "")
    public static let Enter_Search_Mode = NSLocalizedString("EnterSearchMode", tableName: "BraveShared", value: "Enter Search Mode", comment: "Accessibility label for entering search mode for logins")
    public static let Remove_page = NSLocalizedString("RemovePage", tableName: "BraveShared", value: "Remove page", comment: "Button shown in editing mode to remove this site from the top sites panel.")
    
    public static let Show_Bookmarks = NSLocalizedString("ShowBookmarks", tableName: "BraveShared", value: "Show Bookmarks", comment: "Button to show the bookmarks list")
    public static let Show_History =  NSLocalizedString("ShowHistory", tableName: "BraveShared", value: "Show History", comment: "Button to show the history list")
    public static let Add_Bookmark = NSLocalizedString("AddBookmark", tableName: "BraveShared", value: "Add Bookmark", comment: "Button to add a bookmark")
    public static let Edit_Bookmark = NSLocalizedString("EditBookmark", tableName: "BraveShared", value: "Edit Bookmark", comment: "Button to edit a bookmark")
    public static let Remove_Bookmark = NSLocalizedString("RemoveBookmark", tableName: "BraveShared", value: "Remove Bookmark", comment: "Button to remove a bookmark")
    public static let Edit_Favorite = NSLocalizedString("EditFavorite", tableName: "BraveShared", value: "Edit Favorite", comment: "Button to edit a favorite")
    public static let Remove_Favorite = NSLocalizedString("RemoveFavorite", tableName: "BraveShared", value: "Remove Favorite", comment: "Button to remove a favorite")
}

public extension Strings {
    public static let Block_Popups = NSLocalizedString("BlockPopups", tableName: "BraveShared", value: "Block Popups", comment: "Setting to enable popup blocking")
    public static let Show_Tabs_Bar = NSLocalizedString("ShowTabsBar", tableName: "BraveShared", value: "Show Tabs Bar", comment: "Setting to show/hide the tabs bar")
    public static let Private_Browsing_Only = NSLocalizedString("PrivateBrowsingOnly", tableName: "BraveShared", value: "Private Browsing Only", comment: "Setting to keep app in private mode")
    public static let Browser_Lock = NSLocalizedString("BrowserLock", tableName: "BraveShared", value: "Browser Lock", comment: "Setting to enable browser pin locking")
    public static let Change_Pin = NSLocalizedString("PIN", tableName: "BraveShared", value: "PIN", comment: "Setting to change browser lock pin")
    public static let Brave_Shield_Defaults = NSLocalizedString("BraveShieldDefaults", tableName: "BraveShared", value: "Brave Shield Defaults", comment: "Section title for adbblock, tracking protection, HTTPS-E, and cookies")
    public static let Block_Ads_and_Tracking = NSLocalizedString("BlockAdsTracking", tableName: "BraveShared", value: "Block Ads & Tracking", comment: "")
    public static let HTTPS_Everywhere = NSLocalizedString("HTTPSEverywhere", tableName: "BraveShared", value: "HTTPS Everywhere", comment: "")
    public static let Block_Phishing_and_Malware = NSLocalizedString("BlockPhishingAndMalware", tableName: "BraveShared", value: "Block Phishing and Malware", comment: "")
    public static let Block_Scripts = NSLocalizedString("BlockScripts", tableName: "BraveShared", value: "Block Scripts", comment: "")
    public static let Fingerprinting_Protection = NSLocalizedString("FingerprintingProtection", tableName: "BraveShared", value: "Fingerprinting Protection", comment: "")
    public static let Support = NSLocalizedString("Support", tableName: "BraveShared", value: "Support", comment: "Support section title")
    public static let Opt_in_to_telemetry = NSLocalizedString("SendCrashReportsAndMetrics", tableName: "BraveShared", value: "Send crash reports and metrics", comment: "option in settings screen")
    public static let About = NSLocalizedString("About", tableName: "BraveShared", value: "About", comment: "About settings section title")
    public static let Version_template = NSLocalizedString("Version", tableName: "BraveShared", value: "Version %@ (%@)", comment: "Version number of Brave shown in settings")
    public static let Device_template = NSLocalizedString("Device", tableName: "BraveShared", value: "Device %@ (%@)", comment: "Current device model and iOS version copied to clipboard.")
    public static let Copy_app_info_to_clipboard = NSLocalizedString("CopyAppInfoToClipboard", tableName: "BraveShared", value: "Copy app info to clipboard.", comment: "Copy app info to clipboard action sheet action.")
    public static let Password_manager_button_settings_footer = NSLocalizedString("YouCanChooseToShowAPopupToPickYourPasswordManagerOrHaveTheSelectedOneOpenAutomatically", tableName: "BraveShared", value: "You can choose to show a popup to pick your password manager, or have the selected one open automatically.", comment: "Footer message on picker for 3rd party password manager setting")
    public static let Password_manager_button = NSLocalizedString("PasswordManagerButton", tableName: "BraveShared", value: "Password Manager Button", comment: "Setting for behaviour of password manager button")
    public static let Block_3rd_party_cookies = NSLocalizedString("Block3rdPartyCookies", tableName: "BraveShared", value: "Block 3rd party cookies", comment: "cookie settings option")
    public static let Block_all_cookies = NSLocalizedString("BlockAllCookies", tableName: "BraveShared", value: "Block all cookies", comment: "cookie settings option")
    public static let Dont_block_cookies = NSLocalizedString("DontBlockCookies", tableName: "BraveShared", value: "Don't block cookies", comment: "cookie settings option")
    public static let Cookie_Control = NSLocalizedString("CookieControl", tableName: "BraveShared", value: "Cookie Control", comment: "Cookie settings option title")
    public static let Never_show = NSLocalizedString("NeverShow", tableName: "BraveShared", value: "Never show", comment: "tabs bar show/hide option")
    public static let Always_show = NSLocalizedString("AlwaysShow", tableName: "BraveShared", value: "Always show", comment: "tabs bar show/hide option")
    public static let Show_in_landscape_only = NSLocalizedString("ShowInLandscapeOnly", tableName: "BraveShared", value: "Show in landscape only", comment: "tabs bar show/hide option")
    public static let Report_a_bug = NSLocalizedString("ReportABug", tableName: "BraveShared", value: "Report a bug", comment: "Show mail composer to report a bug.")
    public static let Brave_for_iOS_Feedback = NSLocalizedString("BraveForIOSFeedback", tableName: "BraveShared", value: "Brave for iOS Feedback", comment: "email subject")
    public static let Email_Body = "\n\n---\nApp & Device Version Information:\n"
    public static let Privacy_Policy = NSLocalizedString("PrivacyPolicy", tableName: "BraveShared", value: "Privacy Policy", comment: "Show Brave Browser Privacy Policy page from the Privacy section in the settings.")
    public static let Terms_of_Use = NSLocalizedString("TermsOfUse", tableName: "BraveShared", value: "Terms of Use", comment: "Show Brave Browser TOS page from the Privacy section in the settings.")
    public static let Bookmarks_and_History_Panel = NSLocalizedString("BookmarksAndHistoryPanel", tableName: "BraveShared", value: "Bookmarks and History Panel", comment: "Button to show the bookmarks and history panel")
    public static let Private_Tab_Title = NSLocalizedString("ThisIsAPrivateTab", tableName: "BraveShared", value: "This is a Private Tab", comment: "Private tab title")
    public static let Private_Tab_Body = NSLocalizedString("PrivateTabsArentSavedInBraveButTheyDontMakeYouAnonymousOnlineSitesYouVisitInAPrivateTabWontShowUpInYourHistoryAndTheirCookiesAlwaysVanishWhenYouCloseThemThereWontBeAnyTraceOfThemLeftInBraveYourMobileCarrierorTheOwnerOfTheWiFiNetworkOrVPNYoureConnectedToCanSeeWhichSitesYouVisitAndAndThoseSitesWillLearnYourPublicIPAddressEvenInPrivateTabs", tableName: "BraveShared", value: "Private Tabs aren't saved in Brave, but they don't make you anonymous online. Sites you visit in a private tab won't show up in your history and their cookies always vanish when you close them — there won't be any trace of them left in Brave. Your mobile carrier (or the owner of the WiFi network or VPN you're connected to) can see which sites you visit and and those sites will learn your public IP address, even in Private Tabs.", comment: "Private tab details")
    public static let Private_Tab_Details = NSLocalizedString("""
Using Private Tabs only changes what Brave does on your device, it doesn't change anyone else's behavior.

Sites always learn your IP address when you visit them. From this, they can often guess roughly where you are — typically your city. Sometimes that location guess can be much more specific. Sites also know everything you specifically tell them, such as search terms. If you log into a site, they'll know you're the owner of that account. You'll still be logged out when you close the Private Tabs because Brave will throw away the cookie which keeps you logged in.

Whoever connects you to the Internet (your ISP) can see all of your network activity. Often, this is your mobile carrier. If you're connected to a WiFi network, this is the owner of that network, and if you're using a VPN, then it's whoever runs that VPN. Your ISP can see which sites you visit as you visit them. If those sites use HTTPS, they can't make much more than an educated guess about what you do on those sites. But if a site only uses HTTP then your ISP can see everything: your search terms, which pages you read, and which links you follow.

If an employer manages your device, they might also keep track of what you do with it. Using Private Tabs probably won't stop them from knowing which sites you've visited. Someone else with access to your device could also have installed software which monitors your activity, and Private Tabs won't protect you from this either.
""", comment: "Private tab detail text")
    public static let Private_Tab_Link = NSLocalizedString("LearnAboutPrivateTabs", tableName: "BraveShared", value: "Learn about private tabs.", comment: "Private tab information link")
    public static let Brave_Panel = NSLocalizedString("BravePanel", tableName: "BraveShared", value: "Brave Panel", comment: "Button to show the brave panel")
    public static let Shields_Down = NSLocalizedString("ShieldsDown", tableName: "BraveShared", value: "Shields Down", comment: "message shown briefly in URL bar")
    public static let Shields_Up = NSLocalizedString("ShieldsUp", tableName: "BraveShared", value: "Shields Up", comment: "message shown briefly in URL bar")
    public static let Individual_Controls = NSLocalizedString("IndividualControls", tableName: "BraveShared", value: "Individual Controls", comment: "title for per-site shield toggles")
    public static let Blocking_Monitor = NSLocalizedString("BlockingMonitor", tableName: "BraveShared", value: "Blocking Monitor", comment: "title for section showing page blocking statistics")
    public static let Site_shield_settings = NSLocalizedString("Shields", tableName: "BraveShared", value: "Shields", comment: "Brave panel topmost title")
    public static let Down = NSLocalizedString("Down", tableName: "BraveShared", value: "Down", comment: "brave shield on/off toggle off state")
    public static let Up = NSLocalizedString("Up", tableName: "BraveShared", value: "Up", comment: "brave shield on/off toggle on state")
    public static let Block_Phishing = NSLocalizedString("BlockPhishing", tableName: "BraveShared", value: "Block Phishing", comment: "Brave panel individual toggle title")
    public static let Ads_and_Trackers = NSLocalizedString("AdsAndTrackers", tableName: "BraveShared", value: "Ads and Trackers", comment: "individual blocking statistic title")
    public static let HTTPS_Upgrades = NSLocalizedString("HTTPSUpgrades", tableName: "BraveShared", value: "HTTPS Upgrades", comment: "individual blocking statistic title")
    public static let Scripts_Blocked = NSLocalizedString("ScriptsBlocked", tableName: "BraveShared", value: "Scripts Blocked", comment: "individual blocking statistic title")
    public static let Fingerprinting_Methods = NSLocalizedString("FingerprintingMethods", tableName: "BraveShared", value: "Fingerprinting Methods", comment: "individual blocking statistic title")
    public static let Fingerprinting_Protection_wrapped = NSLocalizedString("FingerprintingnProtection", tableName: "BraveShared", value: "Fingerprinting\nProtection", comment: "blocking stat title")
    public static let Shields_Overview = NSLocalizedString("SiteShieldsAllowYouToControlWhenAdsAndTrackersAreBlockedForEachSiteThatYouVisitIfYouPreferToSeeAdsOnASpecificSiteYouCanEnableThemHere", tableName: "BraveShared", value: "Site Shields allow you to control when ads and trackers are blocked for each site that you visit. If you prefer to see ads on a specific site, you can enable them here.", comment: "shields overview message")
    public static let Shields_Overview_Footer = NSLocalizedString("NoteSomeSitesMayRequireScriptsToWorkProperlySoThisShieldIsTurnedOffByDefault", tableName: "BraveShared", value: "Note: Some sites may require scripts to work properly so this shield is turned off by default.", comment: "shields overview footer message")
    public static let Use_regional_adblock = NSLocalizedString("UseRegionalAdblock", tableName: "BraveShared", value: "Use regional adblock", comment: "Setting to allow user in non-english locale to use adblock rules specifc to their language")
    public static let Browser_lock_callout_title = NSLocalizedString("PrivateMeansPrivate", tableName: "BraveShared", value: "Private means private.", comment: "Browser Lock feature callout title.")
    public static let Browser_lock_callout_message = NSLocalizedString("WithBrowserLockYouWillNeedToEnterAPINInOrderToAccessBrave", tableName: "BraveShared", value: "With Browser Lock, you will need to enter a PIN in order to access Brave.", comment: "Browser Lock feature callout message.")
    public static let Browser_lock_callout_not_now = NSLocalizedString("NotNow", tableName: "BraveShared", value: "Not Now", comment: "Browser Lock feature callout not now action.")
    public static let Browser_lock_callout_enable = NSLocalizedString("Enable", tableName: "BraveShared", value: "Enable", comment: "Browser Lock feature callout enable action.")
    public static let DDG_callout_title = NSLocalizedString("PrivateSearchWithDuckDuckGo", tableName: "BraveShared", value: "Private search with DuckDuckGo?", comment: "DuckDuckGo callout title.")
    public static let DDG_callout_message = NSLocalizedString("WithPrivateSearchBraveWillUseDuckDuckGoToAnswerYourSearchesWhileYouAreInThisPrivateTabDuckDuckGoIsASearchEngineThatDoesNotTrackYourSearchHistoryEnablingYouToSearchPrivately", tableName: "BraveShared", value: "With private search, Brave will use DuckDuckGo to answer your searches while you are in this private tab. DuckDuckGo is a search engine that does not track your search history, enabling you to search privately.", comment: "DuckDuckGo message.")
    public static let DDG_callout_no = NSLocalizedString("No", tableName: "BraveShared", value: "No", comment: "DuckDuckGo callout no action.")
    public static let DDG_callout_enable = NSLocalizedString("Yes", tableName: "BraveShared", value: "Yes", comment: "DuckDuckGo callout enable action.")
    public static let DDG_promotion = NSLocalizedString("LearnAboutPrivateSearchrwithDuckDuckGo", tableName: "BraveShared", value: "Learn about private search \rwith DuckDuckGo", comment: "DuckDuckGo promotion label.")
}
