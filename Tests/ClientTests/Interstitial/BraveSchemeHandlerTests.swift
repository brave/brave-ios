// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import XCTest
import WebKit
@testable import Brave

final class BraveSchemeHandlerTests: XCTestCase {
  func testAuthorization() throws {
    let requestURL = URL(string: "brave://player/youtube/123")!
    let authorizedURL = BraveSchemeHandler.authorizeIfNeeded(requestURL: requestURL)
    
    XCTAssertFalse(BraveSchemeHandler.checkAuthorizationToken(for: requestURL))
    XCTAssertTrue(BraveSchemeHandler.checkAuthorizationToken(for: authorizedURL))
  }
  
  func testURLs() throws {
    try XCTAssertNotNil(
      BraveSchemeHandler.loadData(for: URL(string: "brave://player/youtube/123")!),
      "This should be a valid brave player URL"
    )
    
    try XCTAssertNil(
      BraveSchemeHandler.loadData(for: URL(string: "brave://player/youtube.ca/123")!),
      "The url should only support a youtube.com path (youtube.ca is invalid)"
    )
    
    try XCTAssertNil(
      BraveSchemeHandler.loadData(for: URL(string: "brave://player/youtube.com")!),
      "The url should have a video id"
    )
    
    try XCTAssertNil(
      BraveSchemeHandler.loadData(for: URL(string: "brave://invalid/youtube/123")!),
      "The url should have a valid host"
    )
    
    try XCTAssertNil(
      BraveSchemeHandler.loadData(for: URL(string: "notbrave://player/youtube/123")!),
      "The url should have a valid scheme"
    )
  }
  
  func testStrippingAuthToken() throws {
    XCTAssertEqual(
      BraveSchemeHandler.stripAuthorization(from: URL(string: "brave://player/youtube/123?auth=234")!),
      URL(string: "brave://player/youtube/123")!,
      "The auth token should have been stripped out without modifying the url"
    )
  }
  
  func testHostDisplayURL() throws {
    XCTAssertEqual(
      BraveSchemeHandler.host(for: URL(string: "brave://player/youtube/123")!)?.displayURL,
      URL(string: "brave://player")!
    )
  }
}

private extension BraveSchemeHandler {
  /// A helper method for the test to return a host and from that host return the page data
  static func loadData(for requestURL: URL) throws -> Data? {
    return try host(
      for: requestURL
    )?.loadData(for: requestURL)
  }
}
