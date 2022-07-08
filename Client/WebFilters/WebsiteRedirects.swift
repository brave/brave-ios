// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared

struct WebsiteRedirects {
  private enum Site: CaseIterable {
    case reddit
    case npr
    
    /// This is the host we want to redirect users to. All other parts of the url remain unchanged
    var hostToRedirectTo: String {
      switch self {
      case .reddit: return "old.reddit.com"
      case .npr: return "text.npr.org"
      }
    }
    
    /// What hosts should be redirected. Due to compat reasons not every host may be easily replaced.
    var eligibleHosts: Set<String> {
      switch self {
      case .reddit: return ["reddit.com", "www.reddit.com", "np.reddit.com", "amp.reddit.com", "i.reddit.com"]
      case .npr: return ["www.npr.org", "npr.org"]
      }
    }
    
    /// What hosts should not be redirected. It's either due to web compat reasons or to let user explicitely type a url to not override it.
    /// Reddit is good example, regular reddit.com and new.reddit.com point to the same new user interface.
    /// So we redirect all regular reddit.com link, but the user may explicitely go to new.reddit.com without having to disable the reddit redirect toggle.
    var excludedHosts: Set<String> {
      switch self {
      case .reddit: return ["new.reddit.com"]
      case .npr: return ["account.npr.org"]
      }
    }
    
    var isEnabled: Bool {
      switch self {
      case .reddit: return Preferences.WebsiteRedirects.reddit.value
      case .npr: return Preferences.WebsiteRedirects.npr.value
      }
    }
  }
  
  /// Decides whether a website the user is on should bre redirected to another website.
  /// Returns nil if no redirection should happen.
  static func websiteRedirect(for url: URL) -> URL? {
    guard let host = url.host else { return nil }
    
    let foundMatch = Site.allCases
      .filter { $0.isEnabled }
      .filter { !$0.excludedHosts.contains(host) && host != $0.hostToRedirectTo }
      .first(where: { $0.eligibleHosts.contains(host) })
    
    guard let redirect = foundMatch,
          var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
    
    // For privacy reasons we do not redirect websites if username or password are present.
    if components.user != nil || components.password != nil { return nil }
    
    components.host = redirect.hostToRedirectTo
    return components.url
  }
}
