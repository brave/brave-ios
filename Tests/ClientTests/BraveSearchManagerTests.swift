// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

import XCTest
import Preferences
@testable import Brave

class BraveSearchManagerTests: XCTestCase {
  var profile: Profile!
  let url = URL(string: "https://search.brave.com?q=test")!
  let domain = "search.brave.com"
  var cookies: [HTTPCookie]!
  
  override func setUp() {
    super.setUp()
    profile = MockProfile()
    Preferences.General.forceBraveSearchFallbackMixing.reset()
  }
  
  private func createCookie(value: String) -> HTTPCookie {
    let properties: [HTTPCookiePropertyKey: Any] = [
      .name: "fallback",
      .value: value,
      .domain: domain,
      .path: "/",
      .expires: Date().addingTimeInterval(3600)
    ]
    
    return HTTPCookie(properties: properties)!
  }
  
  func testFallbackState1() {
    // App: ON, site: OFF -> ON
    Preferences.General.forceBraveSearchFallbackMixing.value = true
    cookies = [
      createCookie(value: "0")
    ]
    
    let searchManager = BraveSearchManager(profile: profile, url: url, cookies: cookies)
    XCTAssertNotNil(searchManager)
  }
  
  func testFallbackState2() {
    // App: OFF, site: ON -> ON
    Preferences.General.forceBraveSearchFallbackMixing.value = false
    cookies = [
      createCookie(value: "1")
    ]
    
    let searchManager = BraveSearchManager(profile: profile, url: url, cookies: cookies)
    XCTAssertNotNil(searchManager)
  }
  
  func testFallbackState3() {
    // App: OFF, site: OFF -> OFF
    Preferences.General.forceBraveSearchFallbackMixing.value = false
    cookies = [
      createCookie(value: "0")
    ]
    
    let searchManager = BraveSearchManager(profile: profile, url: url, cookies: cookies)
    XCTAssertNil(searchManager)
  }
  
  func testFallbackState4() {
    // App: ON, site: ON -> ON
    Preferences.General.forceBraveSearchFallbackMixing.value = true
    cookies = [
      createCookie(value: "1")
    ]
    
    let searchManager = BraveSearchManager(profile: profile, url: url, cookies: cookies)
    XCTAssertNotNil(searchManager)
  }
  
  func testFallbackStateNoCookie() {
    Preferences.General.forceBraveSearchFallbackMixing.value = true
    // No cookie -> OFF
    let searchManager = BraveSearchManager(profile: profile, url: url, cookies: [])
    XCTAssertNotNil(searchManager)
  }
}
