// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data

final class PrivateBrowsingManager {
    
    var isPrivateBrowsing = false {
        didSet {
            if oldValue != isPrivateBrowsing {
                NotificationCenter.default.post(name: .PrivacyModeChanged, object: nil)
                if !isPrivateBrowsing {
                    Domain.resetPrivateBrowsingShieldOverrides()
                }
            }
        }
    }
    
    static let shared = PrivateBrowsingManager()
    
}
