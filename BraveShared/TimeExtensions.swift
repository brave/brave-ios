// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

extension Int {
    
    /// Return number of minutes in seconds.
    var minutes: TimeInterval {
        return TimeInterval(self * 60)
    }
    
    /// Returns number of hours in seconds.
    var hours: TimeInterval {
        return TimeInterval(self.minutes * 60)
    }
    
    /// Returns number of days in seconds.
    var days: TimeInterval {
        return TimeInterval(self.hours * 24)
    }
    
    /// Returns _very_ approximate number of years in seconds
    /// Only use when duration is not critical
    var years: TimeInterval {
        return TimeInterval(self.days * 365)
    }
}
