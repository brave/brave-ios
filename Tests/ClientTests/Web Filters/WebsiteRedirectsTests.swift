// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
@testable import Brave
import Shared
import BraveShared

class WebsiteRedirectsTests: XCTestCase {
  
  override func setUpWithError() throws {
    Preferences.WebsiteRedirects.reddit.value = true
    Preferences.WebsiteRedirects.npr.value = true
  }
  
  override func tearDownWithError() throws {
    Preferences.WebsiteRedirects.reddit.reset()
    Preferences.WebsiteRedirects.npr.reset()
  }
  
  private func url(_ text: String) throws -> URL {
    try XCTUnwrap(URL(string: text))
  }
  
  func testBasicRedirect() throws {
    XCTAssertEqual(WebsiteRedirects.websiteRedirect(
      for: try url("https://reddit.com/r/brave")), try url("https://old.reddit.com/r/brave"))
    
    XCTAssertEqual(WebsiteRedirects.websiteRedirect(
      for: try url("https://npr.org/sample_article")), try url("https://text.npr.org/sample_article"))
    
    XCTAssertNil(WebsiteRedirects.websiteRedirect(for: try url("https://example.com")))
  }
  
  func testExcludedHosts() throws {
    XCTAssertNil(WebsiteRedirects.websiteRedirect(for: try url("https://new.reddit.com/r/brave")))
    XCTAssertNil(WebsiteRedirects.websiteRedirect(for: try url("https://account.npr.org/login")))
  }
  
  func testDisabledOptions() throws {
    XCTAssertEqual(WebsiteRedirects.websiteRedirect(
      for: try url("https://reddit.com/r/brave")), try url("https://old.reddit.com/r/brave"))
    Preferences.WebsiteRedirects.reddit.value = false
    XCTAssertNil(WebsiteRedirects.websiteRedirect(for: try url("https://reddit.com/r/brave")))
    
    XCTAssertEqual(WebsiteRedirects.websiteRedirect(
      for: try url("https://npr.org/sample_article")), try url("https://text.npr.org/sample_article"))
    Preferences.WebsiteRedirects.npr.value = false
    XCTAssertNil(WebsiteRedirects.websiteRedirect(for: try url("https://npr.org/sample_article")))
  }
  
  func testReddit() throws {
    // Real life example
    XCTAssertEqual(WebsiteRedirects.websiteRedirect(
      for:
        try url("https://reddit.com/r/brave_browser/comments/vtb6yr/whatsapp_web_is_not_working_on_brave/if6nce6/")),
                   try url("https://old.reddit.com/r/brave_browser/comments/vtb6yr/whatsapp_web_is_not_working_on_brave/if6nce6/"))
    
    // Supported hosts
    
    XCTAssertEqual(WebsiteRedirects.websiteRedirect(
      for: try url("https://i.reddit.com/r/brave")), try url("https://old.reddit.com/r/brave"))
    
    XCTAssertEqual(WebsiteRedirects.websiteRedirect(
      for: try url("https://amp.reddit.com/r/brave")), try url("https://old.reddit.com/r/brave"))
    
    XCTAssertEqual(WebsiteRedirects.websiteRedirect(
      for: try url("https://np.reddit.com/r/brave")), try url("https://old.reddit.com/r/brave"))
    
    XCTAssertEqual(WebsiteRedirects.websiteRedirect(
      for: try url("https://reddit.com/r/brave")), try url("https://old.reddit.com/r/brave"))
    
    XCTAssertEqual(WebsiteRedirects.websiteRedirect(
      for: try url("https://www.reddit.com/r/brave")), try url("https://old.reddit.com/r/brave"))
  }
  
  func testNpr() throws {
    // Real life example
    XCTAssertEqual(WebsiteRedirects.websiteRedirect(
      for: try url("https://www.npr.org/2022/07/07/1107814440/researchers-can-now-explain-how-climate-change-is-affecting-your-weather")),
                   try url("https://text.npr.org/2022/07/07/1107814440/researchers-can-now-explain-how-climate-change-is-affecting-your-weather"))
  }
}
