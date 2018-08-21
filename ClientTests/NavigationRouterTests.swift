/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Client
import WebKit

import XCTest

class NavigationRouterTests: XCTestCase {
    
    var appScheme: String {
        let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as! [AnyObject]
        let urlType = urlTypes.first as! [String : AnyObject]
        let urlSchemes = urlType["CFBundleURLSchemes"] as! [String]
        return urlSchemes.first!
    }
    
    func testOpenURLScheme() {
        let url = "http://google.com?a=1&b=2&c=foo%20bar".escape()!
        let appURL = "\(appScheme)://open-url?url=\(url)"
        let navItem = NavigationPath(url: URL(string: appURL)!)!
        XCTAssertEqual(navItem, NavigationPath.url(webURL: URL(string: url.unescape()!)!, isPrivate: false))
        
        let emptyNav = NavigationPath(url: URL(string: "\(appScheme)://open-url?private=true")!)
        XCTAssertEqual(emptyNav, NavigationPath.url(webURL: nil, isPrivate: true))
        
        let badNav = NavigationPath(url: URL(string: "\(appScheme)://open-url?url=blah")!)
        XCTAssertEqual(badNav, NavigationPath.url(webURL: URL(string: "blah"), isPrivate: false))
    }
    
    // Test EVERY deep link
    func testDeepLinks() {
        XCTAssertEqual(NavigationPath(url: URL(string: "\(appScheme)://deep-link?url=/homepanel/bookmarks")!), NavigationPath.deepLink(DeepLink.homePanel(.bookmarks)))
        XCTAssertEqual(NavigationPath(url: URL(string: "\(appScheme)://deep-link?url=/homepanel/topsites")!), NavigationPath.deepLink(DeepLink.homePanel(.topsites)))
        XCTAssertEqual(NavigationPath(url: URL(string: "\(appScheme)://deep-link?url=/homepanel/history")!), NavigationPath.deepLink(DeepLink.homePanel(.history)))
        XCTAssertEqual(NavigationPath(url: URL(string: "\(appScheme)://deep-link?url=/homepanel/badbad")!), nil)
    }

}
