// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct PrivacyReportsItem: Identifiable {
  var id: String {
    domainOrTracker
  }
  
  let domainOrTracker: String
  let faviconUrl: String?
  let count: Int
  
  init(domainOrTracker: String, faviconUrl: String? = nil, count: Int) {
    self.domainOrTracker = domainOrTracker
    self.faviconUrl = faviconUrl
    self.count = count
  }
}
