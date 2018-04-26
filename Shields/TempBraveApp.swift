// TEMP

import UIKit
import Shared

let kPrefKeyNoScriptOn = "noscript_on"
let kPrefKeyFingerprintProtection = "fingerprintprotection_on"
let kPrefKeyPrivateBrowsingAlwaysOn = "privateBrowsingAlwaysOn"
let kPrefKeyBrowserLock = "browserLock"
let kPrefKeySetBrowserLock = "setBrowserLockPin"
let kPrefKeyPopupForBrowserLock = "popupForBrowserLock"

class NSUserDefaultsPrefs {
    
    func boolForKey(_ key: String) -> Bool? {
        return nil
    }
    
    func intForKey(_ key: String) -> Int32? {
        return nil
    }
    
    func setInt(_ i: Int32, forKey key: String) {
    }
    
}

class BraveApp {
    class func getPrefs() -> NSUserDefaultsPrefs? {
        return nil;
    }
    
    class func showErrorAlert(title: String, error: String) {
        
    }
}

func stripGenericSubdomainPrefixFromUrl(_ url: String) -> String {
    return url // url.regexReplacePattern("^(m\\.|www\\.|mobile\\.)", with:"");
}

// Firefox has uses urls of the form  http://localhost:6571/errors/error.html?url=http%3A//news.google.ca/ to populate the browser history, and load+redirect using GCDWebServer
func stripLocalhostWebServer(_ url: String?) -> String {
    guard let url = url else { return "" }
    #if !TEST // TODO fix up the fact lots of code isn't available in the test suite, this is just an additional check, so for testing the rest of the code will work fine
//    if !url.startsWith(WebServer.sharedInstance.base) {
//        return url
//    }
    #endif
    // I think the ones prefixed with the following are the only ones of concern. There is also about/sessionrestore urls, not sure if we need to look at those
    let token = "?url="
    let range = url.range(of: token)
    if let range = range {
        return url.substring(from: range.upperBound).removingPercentEncoding ?? ""
    } else {
        return url
    }
}
