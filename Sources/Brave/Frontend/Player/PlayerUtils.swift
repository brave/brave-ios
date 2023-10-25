// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveShared

class PlayerUtils {
  
  static func youTubeVideoID(from url: URL) -> String? {
    let youTubeURLs: Set<String> = ["youtube.com", "m.youtube.com", "youtu.be"]
    if !url.isWebPage(), let baseDomain = url.baseDomain, !youTubeURLs.contains(baseDomain) {
      return nil
    }
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let id = components.queryItems?.first(where: { $0.name == "v" })?.value else {
      return nil
    }
    return id
  }
}
