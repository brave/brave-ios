// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

public extension AdblockService {
  func getShieldsPath() async -> String? {
    return await withCheckedContinuation { continuation in
      if let path = shieldsInstallPath {
        continuation.resume(returning: path)
        return
      }
      
      shieldsComponentReady = { path in
        continuation.resume(returning: path)
        self.shieldsComponentReady = nil
      }
    }
  }
}
