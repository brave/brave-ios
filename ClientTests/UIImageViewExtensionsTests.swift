/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
import Storage
import SDWebImage
import GCDWebServers
import Shared

@testable import Client

class UIImageViewExtensionsTests: XCTestCase {

    override func setUp() {
        SDWebImageDownloader.shared().urlCredential = WebServer.sharedInstance.credentials
    }

    func testsetIcon() {
        let url = URL(string: "http://mozilla.com")
        let imageView = UIImageView()

        let goodIcon = FaviconFetcher.getDefaultFavicon(url!)
        let correctColor = FaviconFetcher.getDefaultColor(url!)
        imageView.setIcon(nil, forURL: url)
        XCTAssertEqual(imageView.image!, goodIcon, "The correct default favicon should be applied")
        XCTAssertEqual(imageView.backgroundColor, correctColor, "The correct default color should be applied")

        imageView.setIcon(nil, forURL: URL(string: "http://mozilla.com/blahblah"))
        XCTAssertEqual(imageView.image!, goodIcon, "The same icon should be applied to all urls with the same domain")

        imageView.setIcon(nil, forURL: URL(string: "b"))
        XCTAssertEqual(imageView.image, FaviconFetcher.defaultFavicon, "The default favicon should be applied when no information is given about the icon")
    }

    func testAsyncSetIcon() {
        let originalImage = UIImage(named: "fxLogo")!

        WebServer.sharedInstance.registerHandlerForMethod("GET", module: "favicon", resource: "icon") { (request) -> GCDWebServerResponse! in
            return GCDWebServerDataResponse(data: UIImagePNGRepresentation(originalImage)!, contentType: "image/png")
        }

        let favImageView = UIImageView()
        favImageView.setIcon(Favicon(url: "http://localhost:6571/favicon/icon"), forURL: URL(string: "http://localhost:6571"))

        let expect = expectation(description: "UIImageView async load")
        let time = Int64(2 * Double(NSEC_PER_SEC))
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(time) / Double(NSEC_PER_SEC)) {
            XCTAssert(originalImage.isStrictlyEqual(to: favImageView.image!), "The correct favicon should be applied to the UIImageView")
            expect.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testAsyncSetIconFail() {
        let favImageView = UIImageView()

        let gFavURL = URL(string: "https://www.nofavicon.com/noicon.ico")
        let gURL = URL(string: "http://nofavicon.com")
        let correctImage = FaviconFetcher.getDefaultFavicon(gURL!)

        favImageView.setIcon(Favicon(url: gFavURL!.absoluteString), forURL: gURL)

        let expect = expectation(description: "UIImageView async load")
        let time = Int64(2 * Double(NSEC_PER_SEC))
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(time) / Double(NSEC_PER_SEC)) {
           XCTAssert(correctImage.isStrictlyEqual(to: favImageView.image!), "The correct default favicon should be applied to the UIImageView")
            expect.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testDefaultIcons() {
        let favImageView = UIImageView()

        let gFavURL = URL(string: "https://www.facebook.com/fav") //This will be fetched from tippy top sites
        let gURL = URL(string: "http://www.facebook.com")!
        let defaultItem = FaviconFetcher.defaultIcons[gURL.baseDomain!]!
        let correctImage = UIImage(contentsOfFile: defaultItem.url)!

        favImageView.setIcon(Favicon(url: gFavURL!.absoluteString), forURL: gURL)

        let expect = expectation(description: "UIImageView async load")
        let time = Int64(2 * Double(NSEC_PER_SEC))
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(time) / Double(NSEC_PER_SEC)) {
            XCTAssertEqual(favImageView.backgroundColor, defaultItem.color)
            XCTAssert(correctImage.isStrictlyEqual(to: favImageView.image!), "The correct default favicon should be applied to the UIImageView")
            expect.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
