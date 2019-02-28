/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Data
import Deferred
import BraveShared
import WebKit

// A base protocol for something that can be cleared.
protocol Clearable {
    func clear() -> Success
    var label: String { get }
}

class ClearableError: MaybeErrorType {
    fileprivate let msg: String
    init(msg: String) {
        self.msg = msg
    }
    
    var description: String { return msg }
}

struct ClearableErrorType: MaybeErrorType {
    let err: Error
    
    init(err: Error) {
        self.err = err
    }
    
    var description: String {
        return "Couldn't clear: \(err)."
    }
}

// Remove all cookies stored by the site. This includes localStorage, sessionStorage, and WebSQL/IndexedDB.
class CookiesClearable: Clearable {
    
    var label: String {
        return Strings.Cookies
    }
    
    func clear() -> Success {
        UserDefaults.standard.synchronize()
        let result = Deferred<Maybe<()>>()
        // need event loop to run to autorelease UIWebViews fully
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Clearing cookies clears both cookies and cache.
            let localStorageClearables: Set<String> = [WKWebsiteDataTypeCookies,
                                                       WKWebsiteDataTypeSessionStorage,
                                                       WKWebsiteDataTypeLocalStorage,
                                                       WKWebsiteDataTypeWebSQLDatabases,
                                                       WKWebsiteDataTypeIndexedDBDatabases,
                                                       WKWebsiteDataTypeDiskCache,
                                                       WKWebsiteDataTypeServiceWorkerRegistrations,
                                                       WKWebsiteDataTypeOfflineWebApplicationCache,
                                                       WKWebsiteDataTypeMemoryCache,
                                                       WKWebsiteDataTypeFetchCache]
            WKWebsiteDataStore.default().removeData(ofTypes: localStorageClearables, modifiedSince: Date(timeIntervalSinceReferenceDate: 0)) {
                UserDefaults.standard.synchronize()
                result.fill(Maybe<()>(success: ()))
            }
        }
        return result
    }
}

// Clear the web cache. Note, this has to close all open tabs in order to ensure the data
// cached in them isn't flushed to disk.
class CacheClearable: Clearable {
    
    var label: String {
        return Strings.Cache
    }
    
    func clear() -> Success {
        let result = Deferred<Maybe<()>>()
        // need event loop to run to autorelease UIWebViews fully
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let localStorageClearables: Set<String> = [WKWebsiteDataTypeDiskCache,
                                                       WKWebsiteDataTypeServiceWorkerRegistrations,
                                                       WKWebsiteDataTypeOfflineWebApplicationCache,
                                                       WKWebsiteDataTypeMemoryCache,
                                                       WKWebsiteDataTypeFetchCache]
            WKWebsiteDataStore.default().removeData(ofTypes: localStorageClearables, modifiedSince: Date(timeIntervalSinceReferenceDate: 0)) {
                ImageCache.shared.clear()
                result.fill(Maybe<()>(success: ()))
            }
        }
        
        return result
    }
}

// Clears our browsing history, including favicons and thumbnails.
class HistoryClearable: Clearable {
    init() {
    }
    
    var label: String {
        return Strings.Browsing_History
    }
    
    func clear() -> Success {
        let result = Success()
        History.deleteAll {
            NotificationCenter.default.post(name: .PrivateDataClearedHistory, object: nil)
            result.fill(Maybe<()>(success: ()))
        }
        return result
    }
}

// Clear all stored passwords. This will clear SQLite storage and the system shared credential storage.
class PasswordsClearable: Clearable {
    let profile: Profile
    init(profile: Profile) {
        self.profile = profile
    }
    
    var label: String {
        return Strings.Saved_Logins
    }
    
    func clear() -> Success {
        // Clear our storage
        return profile.logins.removeAll() >>== { res in
            let storage = URLCredentialStorage.shared
            let credentials = storage.allCredentials
            for (space, credentials) in credentials {
                for (_, credential) in credentials {
                    storage.remove(credential, for: space)
                }
            }
            return succeed()
        }
    }
}
