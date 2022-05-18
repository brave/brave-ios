// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest

@testable import Client

class DownloadQueueTests: XCTestCase {

  func test_downloadDidCompleteWithError_whenErrorIsEmpty_doNothing() {
    let (sut, delegate) = makeSUT()
    let download = Download()
    sut.downloads = [download]

    sut.download(download, didCompleteWithError: nil)

    XCTAssertEqual(delegate.receivedMessages, [])
  }

  func test_downloadDidCompleteWithError_whenDownloadsAreEmpty_doNothing() {
    let (sut, delegate) = makeSUT()
    let download = Download()
    sut.downloads = []

    let error = NSError(domain: "download.error", code: 0)
    sut.download(download, didCompleteWithError: error)

    XCTAssertEqual(delegate.receivedMessages, [])
  }

  func test_downloadDidCompleteWithError_whenItHasMoreThanOneDownload_doNothing() {
    let (sut, delegate) = makeSUT()
    let download1 = Download()
    let download2 = Download()
    sut.downloads = [download1, download2]

    let error = NSError(domain: "download.error", code: 0)
    sut.download(download1, didCompleteWithError: error)

    XCTAssertEqual(delegate.receivedMessages, [])
  }

  func test_downloadDidCompleteWithError_sendsCorrectMessage() {
    let (sut, delegate) = makeSUT()
    let download = Download()
    sut.downloads = [download]

    let error = NSError(domain: "download.error", code: 0)
    sut.download(download, didCompleteWithError: error)

    XCTAssertEqual(delegate.receivedMessages, [.didCompleteWithError(error: .downloadError)])
  }

  func test_downloadDidDownloadBytes_sendsCorrectMessage() {
    let (sut, delegate) = makeSUT()
    let download = Download()

    sut.download(download, didDownloadBytes: 1000)
    sut.download(download, didDownloadBytes: 1000)
    sut.download(download, didDownloadBytes: 1000)

    XCTAssertEqual(delegate.receivedMessages, [.didDownloadCombinedBytes(bytes: 1000),
                                               .didDownloadCombinedBytes(bytes: 2000),
                                               .didDownloadCombinedBytes(bytes: 3000)])
  }
}

// MARK: - Tests Helpers

private func makeSUT() -> (sut: DownloadQueue, delegate: DownloadQueueDelegateSpy) {
  let delegate = DownloadQueueDelegateSpy()
  let sut = DownloadQueue()
  sut.delegate = delegate

  return (sut, delegate)
}

private class DownloadQueueDelegateSpy: DownloadQueueDelegate {
  enum DownloadQueueError: Error {
      case downloadError
  }

  enum Message: Equatable {
      case didCompleteWithError(error: DownloadQueueError?)
      case didDownloadCombinedBytes(bytes: Int64)
      case didFinishDownloadingTo(location: URL)
  }

  var receivedMessages: [Message] = []

  func downloadQueue(_ downloadQueue: DownloadQueue, didStartDownload download: Download) {}

  func downloadQueue(_ downloadQueue: DownloadQueue, didDownloadCombinedBytes combinedBytesDownloaded: Int64, combinedTotalBytesExpected: Int64?) {
      receivedMessages.append(.didDownloadCombinedBytes(bytes: combinedBytesDownloaded))
  }

  func downloadQueue(_ downloadQueue: DownloadQueue, download: Download, didFinishDownloadingTo location: URL) {
      receivedMessages.append(.didFinishDownloadingTo(location: location))
  }

  func downloadQueue(_ downloadQueue: DownloadQueue, didCompleteWithError error: Error?) {
      receivedMessages.append(.didCompleteWithError(error: error != nil ? .downloadError : nil))
  }
}
