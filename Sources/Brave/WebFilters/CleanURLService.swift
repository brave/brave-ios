// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

/// A helper class that helps us clean urls for "clean copy" feature
class CleanURLService {
  public static let shared = CleanURLService()
  
  private lazy var urlSanitizerService = URLSanitizerServiceFactory.get(privateMode: false)
  private lazy var privateURLSanitizerService = URLSanitizerServiceFactory.get(privateMode: true)
  
  /// Initialize this instance with a network manager
  init() {}
  
  /// Cleanup the url using brave-core's `URLSanitizerService`.
  ///
  /// - Note: If nothing is cleaned, the original URL is returned
  func cleanup(url: URL, isPrivateMode: Bool) -> URL {
    if isPrivateMode {
      return privateURLSanitizerService?.sanitizeURL(url) ?? url
    } else {
      return urlSanitizerService?.sanitizeURL(url) ?? url
    }
  }
}
