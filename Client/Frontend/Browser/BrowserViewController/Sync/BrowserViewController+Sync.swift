// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Shared
import BraveShared
import Storage
import UIKit
import WebKit
import XCGLogger

private let log = Logger.browserLogger

// MARK: - Sync Browser Extension

extension BrowserViewController {
    
    func doSyncMigration() {
        // We stop ever attempting migration after 3 times.
        if Preferences.Chromium.syncV2ObjectMigrationCount.value < 3 {
            self.migrateToSyncObjects { success, syncType in
                if !success {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: Strings.Sync.v2MigrationErrorTitle,
                                                      message: syncType == .bookmarks ?  Strings.Sync.v2MigrationErrorMessage : Strings.Sync.historyMigrationErrorMessage,
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: nil))
                        self.present(alert, animated: true)
                    }
                }
            }
        } else {
            // After 3 tries, we mark Migration as successful.
            // There is nothing more we can do for the user other than to let them export/import bookmarks.
            Preferences.Chromium.syncV2BookmarksMigrationCompleted.value = true
            // Also marking the history migration completed after 3 tries
            Preferences.Chromium.syncV2HistoryMigrationCompleted.value = true
        }
    }
    
    private func migrateToSyncObjects(_ completion: @escaping (_ success: Bool, _ type: MigrationSyncTypes?) -> Void) {
        let showInterstitialPage = { (url: URL?) -> Bool in
            guard let url = url else {
                log.error("Cannot open bookmarks page in new tab")
                return false
            }
            
            return BookmarksInterstitialPageHandler.showBookmarksPage(tabManager: self.tabManager, url: url)
        }
        
        Migration.braveCoreSyncObjectsMigrator?.migrate({ success, syncType in
            Preferences.Chromium.syncV2ObjectMigrationCount.value += 1
            
            if !success {
                switch syncType {
                    case .bookmarks:
                        guard let url = BraveCoreMigrator.datedBookmarksURL else {
                            completion(showInterstitialPage(BraveCoreMigrator.bookmarksURL), .bookmarks)
                            return
                        }
                        
                        Migration.braveCoreSyncObjectsMigrator?.exportBookmarks(to: url) { success in
                            if success {
                                completion(showInterstitialPage(url), .bookmarks)
                            } else {
                                completion(showInterstitialPage(BraveCoreMigrator.bookmarksURL), .bookmarks)
                            }
                        }
                    default:
                        completion(false, syncType)
                }
            } else {
                completion(true, syncType)
            }
        })
    }
}
