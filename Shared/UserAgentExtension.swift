// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

extension UserAgent {
    // Application names are used for default behaviour while custom UA's for user intiated toggle.
    public static func mobileUAApplicationName() -> String? {
        let mobileUA = mobileUserAgent()
        // Extract the WebKit version and use it as the Safari version.
        let mobileRegex = try? NSRegularExpression(pattern: "FxiOS(.*)$", options: [])
        guard let match = mobileRegex?.firstMatch(in: mobileUA, options: [], range: NSRange(location: 0, length: mobileUA.count)) else {
            return nil     // Fall back to Safari's.
        }
        return (mobileUA as NSString).substring(with: match.range)
    }
    
    public static func desktopUAApplicationName() -> String? {
        let desktopUA = desktopUserAgent()
        // Extract the WebKit version and use it as the Safari version.
        let mobileRegex = try? NSRegularExpression(pattern: "Safari(.*)$", options: [])
        guard let match = mobileRegex?.firstMatch(in: desktopUA, options: [], range: NSRange(location: 0, length: desktopUA.count)) else {
            return nil     // Fall back to Safari's.
        }
        return (desktopUA as NSString).substring(with: match.range)
    }
    
    // Check if mobile UA
    public static func isDesktopUA(uaString: String) -> Bool {
        return !uaString.lowercased().contains("mobile")
    }
    
}
