// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
@testable import Client

extension DomainParserTests {
    func testETLD() {
        //Success Expected
        checkETLD(urlString: "https://m.youtube.com", expectedDomain: "youtube.com")
        checkETLD(urlString: "http://www.google.co.in", expectedDomain: "google.co.in")
        
        //UTF Strings
        checkETLD(urlString: "https://點看.點看.com".utf8HostToAscii(), expectedDomain: "xn--c1yn36f.com")
        //Punycoded Strings
        checkETLD(urlString: "https://xn--c1yn36f.xn--c1yn36f.com", expectedDomain: "xn--c1yn36f.com")
        
        //Failurs Expected
//        checkETLD(urlString: "m.youtube.com", expectedDomain: "youtube.com")
        
        //Non Punycoded URLS> Fails because URL() does not support UTF characters. Webkit gives you Punycoded by default.
//        checkETLD(urlString: "https://點看.點看.com", expectedDomain: "點看.com")
    }
    
    func checkETLD(urlString: String, expectedDomain: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(urlString.etldValue(parser: self.domainParser), expectedDomain, file: file, line: line)
    }
}
