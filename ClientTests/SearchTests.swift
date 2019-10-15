/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import GCDWebServers
@testable import Client
import UIKit

import XCTest

class SearchTests: XCTestCase {
    func testParsing() {
        let parser = OpenSearchParser(pluginMode: true)
        let file = Bundle.main.path(forResource: "google", ofType: "xml", inDirectory: "SearchPlugins/")
        let engine: OpenSearchEngine! = parser.parse(file!, engineID: "google")
        XCTAssertEqual(engine.shortName, "Google")

        // Test regular search queries.
        XCTAssertEqual(engine.searchURLForQuery("foobar")!.absoluteString, "https://www.google.com/search?q=foobar&ie=utf-8&oe=utf-8")

        // Test search suggestion queries.
        XCTAssertEqual(engine.suggestURLForQuery("foobar")!.absoluteString, "https://www.google.com/complete/search?client=firefox&q=foobar")
    }

    func testURIFixup() {
        // Check valid URLs. We can load these after some fixup.
        checkValidURL("http://www.mozilla.org", afterFixup: "http://www.mozilla.org")
        checkValidURL("about:", afterFixup: "about:")
        checkValidURL("about:config", afterFixup: "about:config")
        checkValidURL("about: config", afterFixup: "about:%20config")
        checkValidURL("file:///f/o/o", afterFixup: "file:///f/o/o")
        checkValidURL("ftp://ftp.mozilla.org", afterFixup: "ftp://ftp.mozilla.org")
        checkValidURL("foo.bar", afterFixup: "http://foo.bar")
        checkValidURL(" foo.bar ", afterFixup: "http://foo.bar")
        checkValidURL("1.2.3", afterFixup: "http://1.2.3")

        // Check invalid URLs. These are passed along to the default search engine.
        checkInvalidURL("foobar")
        checkInvalidURL("foo bar")
        checkInvalidURL("mozilla. org")
        checkInvalidURL("123")
        checkInvalidURL("a/b")
        checkInvalidURL("创业咖啡")
        checkInvalidURL("创业咖啡 中国")
        checkInvalidURL("创业咖啡. 中国")
        checkInvalidURL("data:text/html;base64,SGVsbG8gV29ybGQhCg==")
        checkInvalidURL("data://https://www.example.com,fake example.com")
        
        // Check invalid quoted URLs, emails, and quoted domains.
        // These are passed along to the default search engine.
        checkInvalidURL(#""123"#)
        checkInvalidURL(#""123""#)
        checkInvalidURL(#""ftp.mozilla.org"#)
        checkInvalidURL(#""ftp.mozilla.org""#)
        checkInvalidURL(#"https://"ftp.mozilla.org""#)
        checkInvalidURL(#"https://"ftp.mozilla.org"#)
        checkInvalidURL("foo@brave.com")
        checkInvalidURL("\"foo@brave.com")
        checkInvalidURL("\"foo@brave.com\"")
        checkInvalidURL(#""创业咖啡.中国"#)
        checkInvalidURL(#""创业咖啡.中国""#)
    }
    
    func testEmails() {
        let validEmails = [
            "foo@yahoo.com",
            "foo-100@yahoo.com",
            "foo.100@yahoo.com",
            "foo111@foo.com",
            "foo-100@foo.net",
            "foo-100@foo.net",
            "foo.100@foo.com.au",
            "foo@1.com",
            "foo@gmail.com.com",
            "foo+100@gmail.com",
            "foo-100@yahoo-test.com",
            "foo@gmail.com.1a",
            "foo123@gmail.a"
        ]
        
        let invalidEmails = [
            "foo",
            "foo@.com.my",
            "foo123@.com",
            "foo123@.com.com",
            ".foo@foo.com",
            "foo()*@gmail.com",
            "foo@%*.com",
            "foo..2002@gmail.com",
            "foo.@gmail.com",
            "foo@foo@gmail.com",
            #""foo@gmail.com"#,
            #""foo@gmail.com""#
        ]
        
        validEmails.forEach({
            XCTAssertTrue(URIFixup.isValidEmail($0), "\($0) is not a valid email")
        })
        
        invalidEmails.forEach({
            XCTAssertFalse(URIFixup.isValidEmail($0), "\($0) is a valid email")
        })
    }

    fileprivate func checkValidURL(_ beforeFixup: String, afterFixup: String) {
        XCTAssertEqual(URIFixup.getURL(beforeFixup)!.absoluteString, afterFixup)
    }

    fileprivate func checkInvalidURL(_ beforeFixup: String) {
        XCTAssertNil(URIFixup.getURL(beforeFixup))
    }

    func testSuggestClient() {
        let webServerBase = startMockSuggestServer()
        let engine = OpenSearchEngine(engineID: "mock", shortName: "Mock engine", image: UIImage(), searchTemplate: "", suggestTemplate: "\(webServerBase)?q={searchTerms}",
                                      isCustomEngine: false)
        let client = SearchSuggestClient(searchEngine: engine, userAgent: "Fx-testSuggestClient")

        let query1 = self.expectation(description: "foo query")
        client.query("foo", callback: { response, error in
            withExtendedLifetime(client) {
                if error != nil {
                    XCTFail("Error: \(error?.description ?? "nil")")
                }

                XCTAssertEqual(response![0], "foo")
                XCTAssertEqual(response![1], "foo2")
                XCTAssertEqual(response![2], "foo you")

                query1.fulfill()
            }
        })
        waitForExpectations(timeout: 10, handler: nil)

        let query2 = self.expectation(description: "foo bar query")
        client.query("foo bar", callback: { response, error in
            withExtendedLifetime(client) {
                if error != nil {
                    XCTFail("Error: \(error?.description ?? "nil")")
                }

                XCTAssertEqual(response![0], "foo bar soap")
                XCTAssertEqual(response![1], "foo barstool")
                XCTAssertEqual(response![2], "foo bartender")

                query2.fulfill()
            }
        })
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testExtractingOfSearchTermsFromURL() {
        let parser = OpenSearchParser(pluginMode: true)
        var file = Bundle.main.path(forResource: "google", ofType: "xml", inDirectory: "SearchPlugins/")
        let googleEngine: OpenSearchEngine! = parser.parse(file!, engineID: "google")

        // create URL
        let searchTerm = "Foo Bar"
        let encodedSeachTerm = searchTerm.replacingOccurrences(of: " ", with: "+")
        let googleSearchURL = URL(string: "https://www.google.com/search?q=\(encodedSeachTerm)&ie=utf-8&oe=utf-8&gws_rd=cr&ei=I0UyVp_qK4HtUoytjagM")
        let duckDuckGoSearchURL = URL(string: "https://duckduckgo.com/?q=\(encodedSeachTerm)&ia=about")
        let invalidSearchURL = URL(string: "https://www.google.co.uk")

        // check it correctly matches google search term given google config
        XCTAssertEqual(searchTerm, googleEngine.queryForSearchURL(googleSearchURL))

        // check it doesn't match when the URL is not a search URL
        XCTAssertNil(googleEngine.queryForSearchURL(invalidSearchURL))

        // check that it matches given a different configuration
        file = Bundle.main.path(forResource: "duckduckgo", ofType: "xml", inDirectory: "SearchPlugins/")
        let duckDuckGoEngine: OpenSearchEngine! = parser.parse(file!, engineID: "duckduckgo")
        XCTAssertEqual(searchTerm, duckDuckGoEngine.queryForSearchURL(duckDuckGoSearchURL))

        // check it doesn't match search URLs for different configurations
        XCTAssertNil(duckDuckGoEngine.queryForSearchURL(googleSearchURL))

        // check that if you pass in a nil URL that everything works
        XCTAssertNil(duckDuckGoEngine.queryForSearchURL(nil))
    }

    fileprivate func startMockSuggestServer() -> String {
        let webServer: GCDWebServer = GCDWebServer()

        webServer.addHandler(forMethod: "GET", path: "/", request: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse? in
            var suggestions: [String]!
            let query = request.query?["q"] as! String
            switch query {
            case "foo":
                suggestions = ["foo", "foo2", "foo you"]
            case "foo bar":
                suggestions = ["foo bar soap", "foo barstool", "foo bartender"]
            default:
                XCTFail("Unexpected query: \(query)")
            }
            return GCDWebServerDataResponse(jsonObject: [query, suggestions])
        }

        if !webServer.start(withPort: 0, bonjourName: nil) {
            XCTFail("Can't start the GCDWebServer")
        }

        return "http://localhost:\(webServer.port)"
    }
}
