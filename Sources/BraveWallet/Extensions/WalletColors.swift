// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveUI
import DesignSystem

extension UIColor {

  static var walletGreen: UIColor {
    UIColor(rgb: 0x2ac194)
  }

  static var walletRed: UIColor {
    UIColor(rgb: 0xee6374)
  }
}

enum WalletV2Design {
  static let passwordWeakRed = UIColor(rgb: 0xd40033)
  static let passwordMediumYellow = UIColor(rgb: 0xbd9600)
  static let passwordStrongGreen = UIColor(rgb: 0x31803e)
}
