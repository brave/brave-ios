// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveShared

class PlayerUtils {
  static let baseURL = URL(string: "about:blank")!
  
  static func playerURL(videoID: String) -> URL? {
    return URL(string: "\(baseURL.absoluteString)?brave-player=\(videoID)")
  }
  
  static func youTubeVideoID(from url: URL) -> String? {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return nil
    }
    if url.scheme == baseURL.scheme, let id = components.queryItems?.first(where: { $0.name == "brave-player" })?.value {
      return id
    }
    let youTubeURLs: Set<String> = ["youtube.com", "m.youtube.com", "youtu.be"]
    if !url.isWebPage(), let baseDomain = url.baseDomain, !youTubeURLs.contains(baseDomain) {
      return nil
    }
    guard let id = components.queryItems?.first(where: { $0.name == "v" })?.value else {
      return nil
    }
    return id
  }
}
