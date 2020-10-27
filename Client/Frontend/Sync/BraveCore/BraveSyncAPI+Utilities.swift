// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import BraveShared

extension BraveSyncAPI {
    
    public static let seedByteLength = 32
    private static let isInGroupKey = "BraveSyncAPI.isInGroupKey"
    
    var isInSyncGroup: Bool {
        return Preferences.Chromium.syncEnabled.value
    }
    
    @discardableResult
    func joinSyncGroup(codeWords: String) -> Bool {
        if self.setSyncCode(codeWords) {
            Preferences.Chromium.syncEnabled.value = true
            return true
        }
        return false
    }
    
    func removeDeviceFromSyncGroup(deviceGuid: String) {
        BraveSyncAPI.shared.removeDevice(deviceGuid)
    }
    
    func leaveSyncGroup() {
        BraveSyncAPI.shared.resetSync()
        Preferences.Chromium.syncEnabled.value = false
    }
}
