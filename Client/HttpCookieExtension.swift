// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared

private let log = Logger.browserLogger

extension HTTPCookie {
    
    
    typealias Success = Bool
    class func saveToDisk(_ filename: String = "CookiesData.json", completion: ((Success) -> Void)? = nil) {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        cookieStore.getAllCookies { (cookies) in
            let baseDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: true)
                try data.write(to: URL(fileURLWithPath: "\(baseDir)/\(filename)"))
            } catch {
                log.error("Failed to write cookies to disk with error: \(error)")
                completion?(false)
                return
            }
            completion?(true)
        }
    }
    
    class func loadFromDisk(_ filename: String = "CookiesData.json", completion: ((Success) -> Void)? = nil) {
        let baseDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: "\(baseDir)/\(filename)"), options: Data.ReadingOptions.alwaysMapped)
            if let cookies: [HTTPCookie] = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [HTTPCookie] {
                HTTPCookie.setCookies(cookies) { (success) in
                    completion?(success)
                }
            } else {
                log.error("Failed to write cookies to disk with error: Invalid data type")
                completion?(false)
            }
        } catch {
            log.error("Failed to write cookies to disk with error: \(error)")
            completion?(false)
        }
    }
    
    private class func setCookies(_ cookies: [HTTPCookie], completion: ((Success) -> Void)?) {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        let dispatchGroup = DispatchGroup()
        cookies.forEach({
            dispatchGroup.enter()
            cookieStore.setCookie($0, completionHandler: {dispatchGroup.leave()})
        })
        
        dispatchGroup.notify(queue: .main) {
            completion?(true)
        }
    }
}
