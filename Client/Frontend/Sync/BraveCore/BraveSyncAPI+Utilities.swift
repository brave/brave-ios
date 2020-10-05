// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import SwiftKeychainWrapper

extension BraveSyncAPI {
    
    public static let seedByteLength = 32
    private static let isInGroupKey = "BraveSyncAPI.isInGroupKey"
    
    var isInSyncGroup: Bool {
        if let codeWords = UserDefaults.standard.object(forKey: BraveSyncAPI.isInGroupKey) as? Bool {
            return codeWords
        }
        return false
    }
    
    @discardableResult
    func joinSyncGroup(codeWords: String) -> Bool {
        if self.setSyncCode(codeWords) {
            UserDefaults.standard.setValue(true, forKey: BraveSyncAPI.isInGroupKey)
            return true
        }
        return false
    }
    
    func leaveSyncGroup() {
        BraveSyncAPI.shared.resetSync()
        UserDefaults.standard.removeObject(forKey: BraveSyncAPI.isInGroupKey)
    }
}
