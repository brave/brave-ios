// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public struct Scheme {
  public enum SchemeType {
    case url, query
  }

  private let type: SchemeType
  private let urlOrQuery: String

  init?(item: NSSecureCoding) {
    if let text = item as? String {
      urlOrQuery = text
      type = .query
    } else if let url = (item as? URL)?.absoluteString.firstURL?.absoluteString {
      urlOrQuery = url
      type = .url
    } else {
      return nil
    }
  }

  var schemeUrl: URL? {
    var components = URLComponents()
    let queryItem: URLQueryItem

    components.scheme = Bundle.main.infoDictionary?["BRAVE_URL_SCHEME"] as? String ?? "brave"

    switch type {
    case .url:
      components.host = "open-url"
      queryItem = URLQueryItem(name: "url", value: urlOrQuery)
    case .query:
      components.host = "search"
      queryItem = URLQueryItem(name: "q", value: urlOrQuery)
    }

    components.queryItems = [queryItem]
    return components.url
  }
}
