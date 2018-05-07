/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit
import Shared
import CoreData
import SwiftKeychainWrapper
import SwiftyJSON
import Storage

/*
 module.exports.categories = {
 BOOKMARKS: '0',
 HISTORY_SITES: '1',
 PREFERENCES: '2'
 }
 
 module.exports.actions = {
 CREATE: 0,
 UPDATE: 1,
 DELETE: 2
 }
 */

let NotificationSyncReady = "NotificationSyncReady"

// TODO: Make capitals - pluralize - call 'categories' not 'type'
public enum SyncRecordType : String {
    case bookmark = "BOOKMARKS"
    case history = "HISTORY_SITES"
    case prefs = "PREFERENCES"
    
    // Please note, this is not a general fetch record string, sync Devices are part of the Preferences
    case devices = "DEVICES"
    //
    
    
    // These are 'static', and do not change, would make actually lazy/static, but not allow for enums
    var fetchedModelType: SyncRecord.Type? {
        let map: [SyncRecordType : SyncRecord.Type] = [.bookmark : SyncBookmark.self, .prefs : SyncDevice.self]
        return map[self]
    }
    
    var coredataModelType: Syncable.Type? {
        let map: [SyncRecordType : Syncable.Type] = [.bookmark : BookmarkMO.self, .prefs : Device.self]
        return map[self]
    }
    
    var syncFetchMethod: String {
        return self == .devices ? "fetch-sync-devices" : "fetch-sync-records"
    }
}

public enum SyncObjectDataType : String {
    case Bookmark = "bookmark"
    case Prefs = "preference" // Remove
    
    // Device is considered part of preferences, this is to just be used internally for tracking a constant.
    //  At some point if Sync migrates to further abstracting Device to its own record type, this will be super close
    //  to just working out of the box
    case Device = "device"
}

enum SyncActions: Int {
    case create = 0
    case update = 1
    case delete = 2
    
}

// TODO: Add rest of Sync.swift implementation from Brave 1.x
