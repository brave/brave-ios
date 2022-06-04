// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import Foundation
import WebKit

@testable import Brave

class DownloadHelperTests: XCTestCase {

  func test_init_whenMIMETypeIsNil_initializeCorrectly() {
    let response = anyResponse(mimeType: nil)

    var sut = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: false)
    XCTAssertNotNil(sut)

    sut = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: false, forceDownload: true)
    XCTAssertNotNil(sut)

    sut = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: false, forceDownload: false)
    XCTAssertNotNil(sut)

    sut = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: true)
    XCTAssertNotNil(sut)
  }

  func test_init_whenMIMETypeIsNotOctetStream_initializeCorrectly() {
    for mimeType in allMIMETypes() {
      if mimeType == MIMEType.octetStream { continue }

      let response = anyResponse(mimeType: mimeType)

      var sut = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: false)
      XCTAssertNil(sut)

      sut = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: false, forceDownload: true)
      XCTAssertNotNil(sut)

      sut = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: false, forceDownload: false)
      XCTAssertNotNil(sut)

      sut = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: true)
      XCTAssertNotNil(sut)
    }
  }

  func test_init_whenMIMETypeIsOctetStream_initializeCorrectly() {
    let response = anyResponse(mimeType: MIMEType.octetStream)

    var sut = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: false)
    XCTAssertNotNil(sut)

    sut = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: false, forceDownload: true)
    XCTAssertNotNil(sut)

    sut = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: true)
    XCTAssertNotNil(sut)

    sut = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: false, forceDownload: false)
    XCTAssertNotNil(sut)
  }

  // MARK: - Helpers

  private func anyRequest() -> URLRequest {
    return URLRequest(url: URL(string: "http://any-url.com")!, cachePolicy: anyCachePolicy(), timeoutInterval: 60.0)
  }

  private func anyResponse(mimeType: String?) -> URLResponse {
    return URLResponse(url: URL(string: "http://any-url.com")!, mimeType: mimeType, expectedContentLength: 10, textEncodingName: nil)
  }

  private func cookieStore() -> WKHTTPCookieStore {
    return WKWebsiteDataStore.`default`().httpCookieStore
  }

  private func anyCachePolicy() -> URLRequest.CachePolicy {
    return .useProtocolCachePolicy
  }

  private func allMIMETypes() -> [String] {
    return [MIMEType.bitmap,
            MIMEType.CSS,
            MIMEType.GIF,
            MIMEType.javaScript,
            MIMEType.JPEG,
            MIMEType.HTML,
            MIMEType.octetStream,
            MIMEType.passbook,
            MIMEType.PDF,
            MIMEType.plainText,
            MIMEType.PNG,
            MIMEType.webP,
            MIMEType.xHTML]
  }
} 

