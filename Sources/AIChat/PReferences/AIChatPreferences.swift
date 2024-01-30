// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Preferences

extension Preferences {
  public enum AIChat {
    public static let hasSeenIntro = Option<Bool>(key: "aichat.intro.hasBeenSeen", default: false)
  }
}
