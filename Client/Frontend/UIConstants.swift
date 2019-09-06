/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import BraveShared

extension UIColor {
    // These are defaults from http://design.firefox.com/photon/visuals/color.html
    struct Defaults {
        static let MobileGreyF = UIColor(rgb: 0x636369)
        static let iOSHighlightBlue = UIColor(rgb: 0xccdded) // This color should exactly match the ios text highlight
        static let Purple60A30 = UIColor(rgba: 0x8000d74c)
        static let MobilePrivatePurple = UIColor(rgb: 0xcf68ff)
        static let PaleBlue = UIColor(rgb: 0xB0D5FB)
        static let LightBeige = UIColor(rgb: 0xf0e6dc)
    }
}

public struct UIConstants {
    static let AboutHomePage = URL(string: "\(WebServer.sharedInstance.base)/about/home/")!

    static let DefaultPadding: CGFloat = 10
    static let SnackbarButtonHeight: CGFloat = 48
    static let TopToolbarHeight: CGFloat = 44
    static var ToolbarHeight: CGFloat = 44
    static var BottomToolbarHeight: CGFloat {
        get {
            let bottomInset: CGFloat = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0
            return ToolbarHeight + bottomInset
        }
    }

    static let AppBackgroundColor = UIColor.Photon.Grey10
    static let SystemBlueColor = UIColor.Photon.Blue40
    static let PrivateModeAssistantToolbarBackgroundColor = UIColor.Photon.Grey50
    static let PrivateModeTextHighlightColor = UIColor.Photon.Purple60
    static let PrivateModePurple = UIColor.Defaults.MobilePrivatePurple

    // Static fonts
    static let DefaultChromeSize: CGFloat = 16
    static let DefaultChromeSmallSize: CGFloat = 11
    static let PasscodeEntryFontSize: CGFloat = 36
    static let DefaultChromeFont: UIFont = UIFont.systemFont(ofSize: DefaultChromeSize, weight: UIFont.Weight.regular)
    static let DefaultChromeSmallFontBold = UIFont.boldSystemFont(ofSize: DefaultChromeSmallSize)
    static let PasscodeEntryFont = UIFont.systemFont(ofSize: PasscodeEntryFontSize, weight: UIFont.Weight.bold)

    static let PanelBackgroundColor = UIColor.white
    static let SeparatorColor = UIColor.Photon.Grey30
    static let HighlightBlue = UIColor.Photon.Blue50
    static let DestructiveRed = UIColor.Photon.Red50
    static let BorderColor = UIColor.Photon.Grey60
    static let BackgroundColor = AppBackgroundColor

    // Used as backgrounds for favicons
    static let DefaultColorStrings = ["2e761a", "399320", "40a624", "57bd35", "70cf5b", "90e07f", "b1eea5", "881606", "aa1b08", "c21f09", "d92215", "ee4b36", "f67964", "ffa792", "025295", "0568ba", "0675d3", "0996f8", "2ea3ff", "61b4ff", "95cdff", "00736f", "01908b", "01a39d", "01bdad", "27d9d2", "58e7e6", "89f4f5", "c84510", "e35b0f", "f77100", "ff9216", "ffad2e", "ffc446", "ffdf81", "911a2e", "b7223b", "cf2743", "ea385e", "fa526e", "ff7a8d", "ffa7b3" ]

    /// JPEG compression quality for persisted screenshots. Must be between 0-1.
    static let ScreenshotQuality: Float = 0.3
    static let ActiveScreenshotQuality: CGFloat = 0.5
  
    // Passcode dot gray
    static let PasscodeDotColor = BraveUX.GreyG
  
    // Brave Orange
    static let ControlTintColor = BraveUX.BraveOrange
  
    // settings
    static let TableViewHeaderBackgroundColor = BraveUX.GreyA
    static let TableViewHeaderTextColor = BraveUX.GreyH
    static let TableViewRowTextColor = BraveUX.GreyJ
    static let TableViewDisabledRowTextColor = BraveUX.GreyE
    static let TableViewSeparatorColor = BraveUX.GreyC
    static let TableViewHeaderFooterHeight = CGFloat(44)
}
