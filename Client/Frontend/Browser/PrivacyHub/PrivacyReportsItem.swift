// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data

struct PrivacyReportsItem: Identifiable {
  var id: String {
    domainOrTracker
  }
  
  let domainOrTracker: String
  let faviconUrl: String?
  let count: Int
  let source: BlockedResource.Source?
  
  init(domainOrTracker: String, faviconUrl: String? = nil, count: Int, source: BlockedResource.Source? = nil) {
    self.domainOrTracker = domainOrTracker
    self.faviconUrl = faviconUrl
    self.count = count
    self.source = source
  }
}
