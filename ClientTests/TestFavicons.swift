/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Storage
@testable import Client
import Shared

class TestFavicons: ProfileTest {

    fileprivate func addSite(_ favicons: Favicons, url: String, s: Bool = true) {
        let expectation = self.expectation(description: "Wait for history")
        let site = Site(url: url, title: "")
        let icon = Favicon(url: url + "/icon.png")
        favicons.addFavicon(icon, forSite: site).upon {
            XCTAssertEqual($0.isSuccess, s, "Icon added \(url)")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 100, handler: nil)
    }

    func testFaviconFetcherParse() {
        let expectation = self.expectation(description: "Wait for Favicons to be fetched")

        let profile = MockProfile()
        // I want a site that also has an iOS app so I can get "apple-touch-icon-precomposed" icons as well
        let url = URL(string: "https://instagram.com")
        FaviconFetcher.getForURL(url!, profile: profile).uponQueue(.main) { result in
            guard let favicons = result.successValue, favicons.count > 0, let url = favicons.first?.url.asURL else {
                XCTFail("Favicons were not found.")
                return expectation.fulfill()
            }
            XCTAssertEqual(favicons.count, 1, "Instagram should have a Favicon.")

            WebImageCacheWithNoPrivacyProtectionManager.shared.load(from: url) { image, _, _, _, _ in
                guard let image = image else {
                    XCTFail("Not a valid URL provided for a favicon.")
                    return expectation.fulfill()
                }
                XCTAssertNotEqual(image.size, .zero)
                expectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 3000, handler: nil)
    }

    func testDefaultFavicons() {
        let icon = FaviconFetcher.getDefaultIconForURL(url: URL(string: "http://www.google.de")!)
        XCTAssertNotNil(icon)
        let craigsListIcon = FaviconFetcher.getDefaultIconForURL(url: URL(string: "http://vancouver.craigslist.ca")!)
        XCTAssertNotNil(craigsListIcon)

    }
}
