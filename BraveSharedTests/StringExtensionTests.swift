// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import BraveShared

class StringExtensionTests: XCTestCase {

    func testFirstURL() {
        let urlString = "https://brave.com"
        let url = URL(string: urlString)!
        XCTAssertEqual(urlString, url.absoluteString)
        
        let prefixedString = "Prefixed Text then the URL: \(urlString)"
        XCTAssertEqual(url, prefixedString.firstURL)
        
        let postfixedString = "\(urlString) The url is before this text"
        XCTAssertEqual(url, postfixedString.firstURL)
        
        let stringWithMultipleURLs = "\(urlString) This one has more than one url https://duckduckgo.com"
        XCTAssertEqual(url, stringWithMultipleURLs.firstURL)
        
        let stringWithNoURLs = "This one is just text"
        XCTAssertNil(stringWithNoURLs.firstURL)
        
        let schemelessURL = "brave.com"
        XCTAssertNotNil(schemelessURL.firstURL)
    }
}
