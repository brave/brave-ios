// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
@testable import BraveShared
import SwiftyJSON

class CustomHeaderDataTest: XCTestCase {
    
    //Valid Json from server.
    var expectedJSON = "[{\"domains\":[\"coinbase.com\",\"api.coinbase.com\"],\"headers\":{\"X-Brave-Partner\":\"coinbase\"},\"cookieNames\":[],\"expiration\":31536000000},{\"domains\":[\"marketwatch.com\",\"barrons.com\"],\"headers\":{\"X-Brave-Partner\":\"dowjones\"},\"cookieNames\":[],\"expiration\":31536000000},{\"domains\":[\"townsquareblogs.com\",\"tasteofcountry.com\",\"ultimateclassicrock.com\",\"xxlmag.com\",\"popcrush.com\"],\"headers\":{\"X-Brave-Partner\":\"townsquare\"},\"cookieNames\":[],\"expiration\":31536000000},{\"domains\":[\"cheddar.com\"],\"headers\":{\"X-Brave-Partner\":\"cheddar\"},\"cookieNames\":[],\"expiration\":31536000000}]"
    
    //Invalid partner key
    var maliciousJSON = "[{\"domains\":[\"coinbase.com\",\"api.coinbase.com\"],\"headers\":{\"Not-X-Brave-Partner\":\"coinbase\"},\"cookieNames\":[],\"expiration\":31536000000},{\"domains\":[\"marketwatch.com\",\"barrons.com\"],\"headers\":{\"Not-X-Brave-Partner\":\"dowjones\"},\"cookieNames\":[],\"expiration\":31536000000},{\"domains\":[\"townsquareblogs.com\",\"tasteofcountry.com\",\"ultimateclassicrock.com\",\"xxlmag.com\",\"popcrush.com\"],\"headers\":{\"Not-X-Brave-Partner\":\"townsquare\"},\"cookieNames\":[],\"expiration\":31536000000},{\"domains\":[\"cheddar.com\"],\"headers\":{\"Not-X-Brave-Partner\":\"cheddar\"},\"cookieNames\":[],\"expiration\":31536000000}]"
    
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let expectedHeaders = getCustomHeader(for: expectedJSON)
        let maliciousHeaders = getCustomHeader(for: maliciousJSON)
        //Tests for non empty array of headers from valid json
        XCTAssertTrue(!expectedHeaders.isEmpty)
        //Tests the non empty array for the correct key
        XCTAssertTrue(expectedHeaders.filter({$0.headerField != CustomHeaderData.bravePartnerKey}).isEmpty)
        //Test for empty array of headers from malicious json
        XCTAssertTrue(maliciousHeaders.isEmpty)
    }
    
    func getCustomHeader(for jsonString: String) -> [CustomHeaderData] {
        let json = JSON(parseJSON: jsonString)
        return CustomHeaderData.customHeaders(from: json)
    }
}

