// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

extension String {
  static let numberFormatterWithCurrentLocale = NumberFormatter().then {
    $0.numberStyle = .decimal
    $0.locale = Locale.current
  }
  
  static let numberFormatterUsLocale = NumberFormatter().then {
    $0.numberStyle = .decimal
    $0.locale = .init(identifier: "en_US")
  }
  
  var normalizedDecimals: String {
    guard String.numberFormatterUsLocale.locale != String.numberFormatterWithCurrentLocale.locale else { return self }
    guard let number = String.numberFormatterWithCurrentLocale.number(from: self) else { return self }
    return  String.numberFormatterUsLocale.string(from: number) ?? self
  }
}
