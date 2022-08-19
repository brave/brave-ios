// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

extension String {
  static let numberFormatter = NumberFormatter().then {
    $0.numberStyle = .decimal
    $0.locale = Locale.current
  }
  
  var normalizedDecimals: String {
    return self.replacingOccurrences(of: String.numberFormatter.decimalSeparator, with: ".")
  }
}
