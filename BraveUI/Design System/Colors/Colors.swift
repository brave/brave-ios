// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit

enum DesignSystemColor: String {
  case background01
  case background02
  case background03
  case background04
  
  case text01
  case text02
  case text03
  
  case interactive01
  case interactive02
  case interactive03
  case interactive04
  case interactive05
  case interactive06
  case interactive07
  case interactive08
  
  case focusBorder = "focus-border"
  case disabled
  
  case divider01
  
  case errorBackground = "error-background"
  case errorIcon = "error-icon"
  case errorText = "error-text"
  
  case warningBackground = "warning-background"
  case warningIcon = "warning-icon"
  case warningText = "warning-text"
  
  case infoBackground = "info-background"
  case infoIcon = "info-icon"
  case infoText = "info-text"
  
  case successBackground = "success-background"
  case successIcon = "success-icon"
  case successText = "success-text"
  
  var color: UIColor {
    return UIColor(named: rawValue, in: Bundle(for: Brave.self), compatibleWith: nil)!
  }
}

final private class Brave { }

extension UIColor {
  public static var braveBackground: UIColor {
    DesignSystemColor.background02.color
  }
  public static var secondaryBraveBackground: UIColor {
    DesignSystemColor.background01.color
  }
  public static var tertiaryBraveBackground: UIColor {
    DesignSystemColor.background03.color
  }
  public static var braveGroupedBackground: UIColor {
    DesignSystemColor.background04.color
  }
  public static var secondaryBraveGroupedBackground: UIColor {
    DesignSystemColor.background02.color
  }
  public static var tertiaryBraveGroupedBackground: UIColor {
    DesignSystemColor.background04.color
  }
  public static var braveLabel: UIColor {
    DesignSystemColor.text01.color
  }
  public static var secondaryBraveLabel: UIColor {
    DesignSystemColor.text02.color
  }
  public static var tertiaryBraveLabel: UIColor {
    DesignSystemColor.text03.color
  }
  public static var braveOrange: UIColor {
    DesignSystemColor.interactive02.color
  }
  public static var braveBlurple: UIColor {
    DesignSystemColor.interactive05.color
  }
  public static var braveSeparator: UIColor {
    DesignSystemColor.divider01.color
  }
  public static var braveErrorLabel: UIColor {
    DesignSystemColor.errorText.color
  }
}

/// The Brave Color Palette used in Brave's Design System
///
/// File: `Color Palette.sketch`
/// Version: `9dc5d63`
final public class Colors {
  // MARK: - Neutral
  public static let neutral000 = UIColor(hex: 0xF8F9Fa)
  public static let neutral100 = UIColor(hex: 0xF1F3F5)
  public static let neutral300 = UIColor(hex: 0xDEE2E6)
  public static let neutral700 = UIColor(hex: 0x495057)
  // MARK: - Grey
  public static let grey000 = UIColor(hex: 0xF0F2FF)
  public static let grey100 = UIColor(hex: 0xE6E8F5)
  public static let grey200 = UIColor(hex: 0xDADCE8)
  public static let grey300 = UIColor(hex: 0xCED0DB)
  public static let grey400 = UIColor(hex: 0xC2C4CF)
  public static let grey500 = UIColor(hex: 0xAEB1C2)
  public static let grey600 = UIColor(hex: 0x84889C)
  public static let grey700 = UIColor(hex: 0x5E6175)
  public static let grey800 = UIColor(hex: 0x3B3E4F)
  public static let grey900 = UIColor(hex: 0x1E2029)
  // MARK: - Red
  public static let red600 = UIColor(hex: 0xBD1531)
  // MARK: - Magenta
  public static let magenta600 = UIColor(hex: 0xA3278F)
  // MARK: - Purple
  public static let purple500 = UIColor(hex: 0x845EF7)
  public static let purple600 = UIColor(hex: 0x6845D1)
  // MARK: - Blurple
  public static let blurple100 = UIColor(hex: 0xF0F1FF)
  public static let blurple200 = UIColor(hex: 0xD0D2F7)
  public static let blurple300 = UIColor(hex: 0xA0A5EB)
  public static let blurple400 = UIColor(hex: 0x737ADE)
  public static let blurple500 = UIColor(hex: 0x4C54D2)
  public static let blurple900 = UIColor(hex: 0x0B0E38)
  // MARK: - Blue
  public static let blue400 = UIColor(hex: 0x5DB5FC)
  // MARK: - Orange
  public static let orange400 = UIColor(hex: 0xFF7654)
  public static let orange500 = UIColor(hex: 0xFB542B)
}

extension UIColor {
  fileprivate convenience init(hex: UInt32) {
    let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
    let b = CGFloat(hex & 0x0000FF) / 255.0
    self.init(displayP3Red: r, green: g, blue: b, alpha: 1.0)
  }
}
