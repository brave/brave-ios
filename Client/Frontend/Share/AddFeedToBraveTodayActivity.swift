// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared

class AddFeedToBraveTodayActivity: UIActivity {
    fileprivate let callback: () -> Void
    
    init(callback: @escaping () -> Void) {
        self.callback = callback
    }
    
    override var activityTitle: String? {
        return Strings.BraveToday.addSourceShareTitle
    }
    
    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "settings-brave-today")
    }
    
    override func perform() {
        callback()
        activityDidFinish(true)
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
}
