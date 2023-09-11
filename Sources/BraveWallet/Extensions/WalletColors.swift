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
  // Light/Container/Background rgba(255, 255, 255, 1)
  // Dark/Container/Background rgba(25, 27, 34, 1)
  static let containerBackground = UIColor(dynamicProvider: { traits in
    if traits.userInterfaceStyle == .light {
      return UIColor.white
    } else {
      return UIColor(
        red: 25 / 255,
        green: 27 / 255,
        blue: 34 / 255,
        alpha: 1
      )
    }
  })
  
  // Light/Container/Highlight rgba(240, 241, 244, 1)
  // Dark/Container/Highlight rgba(13, 14, 18, 1)
  static let containerHighlight = UIColor(dynamicProvider: { traits in
    if traits.userInterfaceStyle == .light {
      return UIColor(
        red: 240 / 255,
        green: 241 / 255,
        blue: 244 / 255,
        alpha: 1
      )
    } else {
      return UIColor(
        red: 13 / 255,
        green: 14 / 255,
        blue: 18 / 255,
        alpha: 1
      )
    }
  })

  static let passwordWeakRed = UIColor(rgb: 0xd40033)
  static let passwordMediumYellow = UIColor(rgb: 0xbd9600)
  static let passwordStrongGreen = UIColor(rgb: 0x31803e)
}
