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
  case errorBorder = "error-border"
  case errorText = "error-text"
  
  case warningBackground = "warning-background"
  case warningBorder = "warning-border"
  case warningText = "warning-text"
  
  case infoBackground = "info-background"
  case infoBorder = "info-border"
  case infoText = "info-text"
  
  case successBackground = "success-background"
  case successBorder = "success-border"
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
    DesignSystemColor.text02.color
  }
  public static var secondaryBraveLabel: UIColor {
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
  public static var braveInfoLabel: UIColor {
    DesignSystemColor.infoText.color
  }
  public static var braveInfoBorder: UIColor {
    DesignSystemColor.infoBorder.color
  }
  public static var braveInfoBackground: UIColor {
    DesignSystemColor.infoBackground.color
  }
  public static var braveSuccessLabel: UIColor {
    DesignSystemColor.successText.color
  }
}

extension UIColor {
  public static var privateModeBackground: UIColor {
    // Static!
    UIColor(hex: 0x2C2153)
  }
}

/// The Brave Color Palette used in Brave's Design System
///
/// File: `Color Palette.sketch`
/// Version: `9dc5d63`
final public class Colors {
  // MARK: - Neutral
  public static let neutral000 = UIColor(hex: 0xF8F9Fa)
  public static let neutral700 = UIColor(hex: 0x495057)
  // MARK: - Grey
  public static let grey000 = UIColor(hex: 0xF0F2FF)
  public static let grey200 = UIColor(hex: 0xDADCE8)
  public static let grey500 = UIColor(hex: 0xAEB1C2)
  public static let grey600 = UIColor(hex: 0x84889C)
  public static let grey700 = UIColor(hex: 0x5E6175)
  public static let grey800 = UIColor(hex: 0x3B3E4F)
  public static let grey900 = UIColor(hex: 0x1E2029)
  // MARK: - Blurple
  public static let blurple300 = UIColor(hex: 0xA0A5EB)
  public static let blurple400 = UIColor(hex: 0x737ADE)
  // MARK: - Blue
  public static let blue400 = UIColor(hex: 0x5DB5FC)
}

extension UIColor {
  fileprivate convenience init(hex: UInt32) {
    let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
    let b = CGFloat(hex & 0x0000FF) / 255.0
    self.init(displayP3Red: r, green: g, blue: b, alpha: 1.0)
  }
}
