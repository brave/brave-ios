// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

public class ContentBlockerDownloader {
  public static let shared = ContentBlockerDownloader()
  private let session = URLSession(configuration: .ephemeral)
  private let adBlockDataS3URL = URL(string: "https://adblock-data.s3.brave.com")!
  
  public func downloadContentBlockers(
    for filterList: AdblockFilterListCatalogEntry, servicesKey: String
  ) async throws -> String {
    let filterListURL = adBlockDataS3URL
      .appendingPathComponent("ios").appendingPathComponent("\(filterList.uuid)-latest.txt")
    var urlRequest = URLRequest(url: filterListURL)
    urlRequest.addValue(servicesKey, forHTTPHeaderField: "BraveServiceKey")
    let result = try await session.download(for: urlRequest)
    let contents = try String(contentsOf: result.0)
    return contents
  }
}
