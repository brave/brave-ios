// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
@testable import Brave

class CleanURLServiceTests: XCTestCase {
  private let service = CleanURLService()
  
  override func setUpWithError() throws {
    let resourceURL = Bundle.module.url(forResource: "clean-urls", withExtension: "json")
    let data = try Data(contentsOf: resourceURL!)
    try service.setup(withRulesJSON: data)
  }
  
  func testIncludes() {
    // Given
    // A url
    let url = URL(
      string: "https://dev-pages.bravesoftware.com/clean-urls/?brave_testing1=foo&brave_testing2=bar&brave_testing3=keep&&;b&d&utm_content=removethis&e=&f=g&=end"
    )!
    
    // When
    // Cleaned
    let cleanedURL = service.cleanup(url: url)
    
    // Then
    // Tracking parameters should be removed
    XCTAssertEqual(
      cleanedURL,
      URL(string: "https://dev-pages.bravesoftware.com/clean-urls/?brave_testing3=keep&&;b&d&e=&f=g&=end")!
    )
  }
  
  func testExcemptions() {
    // Given
    // A url
    let url = URL(
      string: "https://dev-pages.bravesoftware.com/clean-urls/exempted?brave_testing1=foo&brave_testing2=bar&brave_testing3=keep&&;b&d&utm_content=removethis&e=&f=g&=end"
    )!
    
    // When
    // Cleaned
    let cleanedURL = service.cleanup(url: url)
    
    // Then
    // Tracking parameters should be removed from the general 
    XCTAssertEqual(
      cleanedURL,
      URL(string: "https://dev-pages.bravesoftware.com/clean-urls/exempted?brave_testing1=foo&brave_testing2=bar&brave_testing3=keep&&;b&d&e=&f=g&=end")!
    )
  }
  
  func testTwitter() {
    // Given
    // A url
    let url = URL(
      string: "https://subpage.twitter.com/post/?utm_content=removethis&e=&t=g&=end"
    )!
    
    // When
    // Cleaned
    let cleanedURL = service.cleanup(url: url)
    
    // Then
    // Tracking parameters should be removed from the general
    XCTAssertEqual(
      cleanedURL,
      URL(string: "https://subpage.twitter.com/post/?e=&=end")!
    )
  }
}
