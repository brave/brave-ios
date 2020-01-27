/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest

import Shared
import Storage
import WebKit
@testable import Client

class ClientTests: XCTestCase {

    // Simple test to make sure the WKWebView UA matches the expected FxiOS pattern.
    func testUserAgent() {
        let compare: (String) -> Bool = { ua in
            let range = ua.range(of: "^Mozilla/5\\.0 \\(.+\\) AppleWebKit/[0-9\\.]+ \\(KHTML, like Gecko\\) FxiOS/[0-9\\.]+ Mobile/[A-Za-z0-9]+ Safari/[0-9\\.]+$", options: .regularExpression)
            return range != nil
        }

        XCTAssertTrue(compare(UserAgent.defaultUserAgent()), "User agent computes correctly.")
        XCTAssertTrue(compare(UserAgent.cachedUserAgent(checkiOSVersion: true)!), "User agent is cached correctly.")

        let expectation = self.expectation(description: "Found Firefox user agent")

        let webView = WKWebView()
        webView.evaluateJavaScript("navigator.userAgent") { result, error in
            let userAgent = result as! String
            if compare(userAgent) {
                expectation.fulfill()
            } else {
                XCTFail("User agent did not match expected pattern! \(userAgent)")
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testDesktopUserAgent() {
        let compare: (String) -> Bool = { ua in
            let range = ua.range(of: "^Mozilla/5\\.0 \\(Macintosh; Intel Mac OS X [0-9_]+\\) AppleWebKit/[0-9\\.]+ \\(KHTML, like Gecko\\) Safari/[0-9\\.]+$", options: .regularExpression)
            return range != nil
        }

        XCTAssertTrue(compare(UserAgent.desktopUserAgent()), "Desktop user agent computes correctly.")
    }

    /// Our local server should only accept whitelisted hosts (localhost and 127.0.0.1).
    /// All other localhost equivalents should return 403.
    func testDisallowLocalhostAliases() {
        // Allowed local hosts. The first two are equivalent since iOS forwards an
        // empty host to localhost.
        [ "localhost",
            "",
            "127.0.0.1",
            ].forEach { XCTAssert(hostIsValid($0), "\($0) host should be valid.") }

        // Disallowed local hosts. WKWebView will direct them to our server, but the server
        // should reject them.
        [ "[::1]",
            "2130706433",
            "0",
            "127.00.00.01",
            "017700000001",
            "0x7f.0x0.0x0.0x1"
            ].forEach { XCTAssertFalse(hostIsValid($0), "\($0) host should not be valid.") }
    }
    
    func testDownloadsFolder() {
        let path = try? FileManager.default.downloadsPath()
        XCTAssertNotNil(path)
        
        XCTAssert(FileManager.default.fileExists(atPath: path!.path))
        
        // Let's pretend user deletes downloads folder via files.app
        XCTAssertNoThrow(try FileManager.default.removeItem(at: path!))
        
        XCTAssertFalse(FileManager.default.fileExists(atPath: path!.path))
        
        // Calling downloads path should recreate the deleted folder
        XCTAssertNoThrow(try FileManager.default.downloadsPath())
        
        XCTAssert(FileManager.default.fileExists(atPath: path!.path))
    }

    fileprivate func hostIsValid(_ host: String) -> Bool {
        let expectation = self.expectation(description: "Validate host for \(host)")
        var request = URLRequest(url: URL(string: "http://\(host):6571/about/license")!)
        var response: HTTPURLResponse?
        
        let username = WebServer.sharedInstance.credentials.user ?? ""
        let password = WebServer.sharedInstance.credentials.password ?? ""
        
        let credentials = "\(username):\(password)".data(using: .utf8)?.base64EncodedString() ?? ""

        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")

        URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: .main).dataTask(with: request) { data, resp, error in
            response = resp as? HTTPURLResponse
            expectation.fulfill()
        }.resume()

        waitForExpectations(timeout: 100, handler: nil)
        return response?.statusCode == 200
    }
}
