// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

extension URL {
  /// Recognize an Apple Maps URL. This will trigger the native app. But only if a search query is present. Otherwise
  /// it could just be a visit to a regular page on maps.apple.com.
  var isAppleMapsURL: Bool {
    guard scheme == "http" || scheme == "https" else { return false }
    return host == "maps.apple.com" && query != nil
  }

  /// Recognize a iTunes Store URL. These all trigger the native apps. Note that appstore.com and phobos.apple.com
  /// used to be in this list. I have removed them because they now redirect to itunes.apple.com. If we special case
  /// them then iOS will actually first open Safari, which then redirects to the app store. This works but it will
  /// leave a 'Back to Safari' button in the status bar, which we do not want.
  var isStoreURL: Bool {
    guard scheme == "http" || scheme == "https" else {
      return scheme == "itms-appss" || scheme == "itmss"
    }
    
    return host == "itunes.apple.com"
  }

  /// This is the place where we decide what to do with a new navigation action. There are a number of special schemes
  /// and http(s) urls that need to be handled in a different way. All the logic for that is inside this delegate
  /// method.
  var isUpholdOAuthAuthorization: Bool {
    return scheme == "rewards" && host == "uphold"
  }
}
