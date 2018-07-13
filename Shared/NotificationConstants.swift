/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

extension Notification.Name {
    public static let DataLoginDidChange = Notification.Name("DataLoginDidChange")

    public static let PrivateDataClearedHistory = Notification.Name("PrivateDataClearedHistory")
    public static let PrivateDataClearedDownloadedFiles = Notification.Name("PrivateDataClearedDownloadedFiles")

    // Fired when the user finishes navigating to a page and the location has changed
    public static let OnLocationChange = Notification.Name("OnLocationChange")
    public static let DidRestoreSession = Notification.Name("DidRestoreSession")

    // MARK: Notification UserInfo Keys
    public static let UserInfoKeyHasSyncableAccount = Notification.Name("UserInfoKeyHasSyncableAccount")
  
    // Fired when the login synchronizer has finished applying remote changes
    public static let DataRemoteLoginChangesWereApplied = Notification.Name("DataRemoteLoginChangesWereApplied")

    // Fired when a the page metadata extraction script has completed and is being passed back to the native client
    public static let OnPageMetadataFetched = Notification.Name("OnPageMetadataFetched")

    // Leaving these here in case we want to use these for our own sync implementation
    public static let ProfileDidStartSyncing = Notification.Name("ProfileDidStartSyncing")
    public static let ProfileDidFinishSyncing = Notification.Name("ProfileDidFinishSyncing")

    public static let DatabaseWasRecreated = Notification.Name("DatabaseWasRecreated")

    public static let PasscodeDidChange = Notification.Name("PasscodeDidChange")

    public static let PasscodeDidCreate = Notification.Name("PasscodeDidCreate")

    public static let PasscodeDidRemove = Notification.Name("PasscodeDidRemove")

    public static let DynamicFontChanged = Notification.Name("DynamicFontChanged")

    public static let UserInitiatedSyncManually = Notification.Name("UserInitiatedSyncManually")

    public static let BookmarkBufferValidated = Notification.Name("BookmarkBufferValidated")

    public static let FaviconDidLoad = Notification.Name("FaviconDidLoad")

    public static let ReachabilityStatusChanged = Notification.Name("ReachabilityStatusChanged")

    public static let ContentBlockerTabSetupRequired = Notification.Name("ContentBlockerTabSetupRequired")

    public static let HomePanelPrefsChanged = Notification.Name("HomePanelPrefsChanged")

    public static let FileDidDownload = Notification.Name("FileDidDownload")
    
    public static let ThumbnailEditOn = Notification.Name("ThumbnailEditOn")
    public static let ThumbnailEditOff = Notification.Name("ThumbnailEditOff")
    
    public static let PrivacyModeChanged = Notification.Name("PrivacyModeChanged")
    public static let TopSitesConversion = Notification.Name("TopSitesConversion")
}
