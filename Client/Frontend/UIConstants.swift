/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// A browser color represents the color of UI in both Private browsing mode and normal mode
struct BrowserColor {
    let normalColor: UIColor
    let PBMColor: UIColor
    init(normal: UIColor, pbm: UIColor) {
        self.normalColor = normal
        self.PBMColor = pbm
    }

    init(normal: Int, pbm: Int) {
        self.normalColor = UIColor(rgb: normal)
        self.PBMColor = UIColor(rgb: pbm)
    }

    func color(isPBM: Bool) -> UIColor {
        return isPBM ? PBMColor : normalColor
    }

    func colorFor(_ theme: Theme) -> UIColor {
        return color(isPBM: theme == .Private)
    }
}

extension UIColor {
    // These are defaults from http://design.firefox.com/photon/visuals/color.html
    struct Defaults {
        static let GreyA = UIColor(rgb: 0xF7F8F9)
        static let GreyB = UIColor(rgb: 0xE7EBEE)
        static let GreyC = UIColor(rgb: 0xDBDFE3)
        static let GreyD = UIColor(rgb: 0xCDD1D5)
        static let GreyE = UIColor(rgb: 0xA7ACB2)
        static let GreyF = UIColor(rgb: 0x999EA2)
        static let GreyG = UIColor(rgb: 0x818589)
        static let GreyH = UIColor(rgb: 0x606467)
        static let GreyI = UIColor(rgb: 0x484B4E)
        static let GreyJ = UIColor(rgb: 0x222326)
        static let Blue = UIColor(rgb: 0x00BCD6)
        static let Purple = UIColor(rgb: 0x7D7BDC)
        static let Green = UIColor(rgb: 0x02B999)
        static let Red = UIColor(rgb: 0xE2052A)
        static let BraveOrange = UIColor(rgb: 0x7D7BDC)
    }

    struct Browser {
        static let Background = BrowserColor(normal: Defaults.GreyB, pbm: Defaults.GreyI)
        static let Text = BrowserColor(normal: .white, pbm: Defaults.GreyD)
        static let URLBarDivider = BrowserColor(normal: .clear, pbm: .clear)
        static let LocationBarBackground = BrowserColor(normal: Defaults.GreyB, pbm: Defaults.GreyI)
        static let Tint = BrowserColor(normal: Defaults.GreyG, pbm: Defaults.GreyF)
    }

    struct URLBar {
        static let Border = BrowserColor(normal: Defaults.GreyD, pbm: Defaults.GreyI)
        static let ActiveBorder = BrowserColor(normal: Defaults.Blue, pbm: Defaults.GreyI)
        static let Tint = BrowserColor(normal: Defaults.Blue, pbm: Defaults.Blue)
    }

    struct TextField {
        static let Background = BrowserColor(normal: .white, pbm: Defaults.GreyJ)
        static let TextAndTint = BrowserColor(normal: Defaults.GreyJ, pbm: .white)
        static let Highlight = BrowserColor(normal: Defaults.Blue.withAlphaComponent(0.15), pbm: Defaults.Purple.withAlphaComponent(0.15))
        static let ReaderModeButtonSelected = BrowserColor(normal: Defaults.Blue, pbm: Defaults.Purple)
        static let ReaderModeButtonUnselected = BrowserColor(normal: Defaults.GreyG, pbm: Defaults.GreyF)
        static let PageOptionsSelected = ReaderModeButtonSelected
        static let PageOptionsUnselected = UIColor.Browser.Tint
        static let Separator = BrowserColor(normal: Defaults.GreyC, pbm: Defaults.GreyI)
    }
    
    struct ToolBar {
        static let ToolBarDivider = BrowserColor(normal: UIColor.black.withAlphaComponent(0.25), pbm: UIColor.black.withAlphaComponent(0.5))
    }

    // The back/forward/refresh/menu button (bottom toolbar)
    struct ToolbarButton {
        static let SelectedTint = BrowserColor(normal: Defaults.Blue, pbm: Defaults.Purple)
        static let DisabledTint = BrowserColor(normal: Defaults.GreyG.withAlphaComponent(0.3), pbm: Defaults.GreyF.withAlphaComponent(0.3))
    }

    struct LoadingBar {
        static let Start = BrowserColor(normal: Defaults.Blue, pbm: Defaults.Purple)
        static let End = BrowserColor(normal: Defaults.Blue, pbm: Defaults.Red)
    }

    struct TabTray {
        static let Background = Browser.Background
    }

    struct HomePanel {
        // These values are the same for both private/normal.
        // The homepanel toolbar needed to be able to theme, not anymore.
        // Keep this just in case someone decides they want it to theme again
        static let ToolbarBackground = BrowserColor(normal: Defaults.GreyB, pbm: Defaults.GreyI)
        static let ToolbarHighlight = BrowserColor(normal: Defaults.Blue, pbm: Defaults.Blue)
        static let ToolbarTint = BrowserColor(normal: Defaults.GreyG, pbm: Defaults.GreyF)
    }
}

public struct UIConstants {
    static let AboutHomePage = URL(string: "\(WebServer.sharedInstance.base)/about/home/")!

    static let DefaultPadding: CGFloat = 10
    static let SnackbarButtonHeight: CGFloat = 48
    static let TopToolbarHeight: CGFloat = 56
    static var ToolbarHeight: CGFloat = 46
    static var BottomToolbarHeight: CGFloat {
        get {
            var bottomInset: CGFloat = 0.0
            if #available(iOS 11, *) {
                if let window = UIApplication.shared.keyWindow {
                    bottomInset = window.safeAreaInsets.bottom
                }
            }
            return ToolbarHeight + bottomInset
        }
    }

    static let AppBackgroundColor = UIColor.white
    static let SystemBlueColor = UIColor.Defaults.Blue
    static let ControlTintColor = UIColor.Defaults.Blue
    static let PasscodeDotColor = UIColor.Defaults.GreyF
    static let PrivateModeAssistantToolbarBackgroundColor = UIColor.Defaults.GreyI
    static let PrivateModeTextHighlightColor = UIColor.Defaults.Purple
    static let PrivateModePurple = UIColor.Defaults.Purple

    // Static fonts
    static let DefaultChromeSize: CGFloat = 16
    static let DefaultChromeSmallSize: CGFloat = 11
    static let PasscodeEntryFontSize: CGFloat = 36
    static let DefaultChromeFont: UIFont = UIFont.systemFont(ofSize: DefaultChromeSize, weight: UIFontWeightRegular)
    static let DefaultChromeSmallFontBold = UIFont.boldSystemFont(ofSize: DefaultChromeSmallSize)
    static let PasscodeEntryFont = UIFont.systemFont(ofSize: PasscodeEntryFontSize, weight: UIFontWeightBold)

    static let PanelBackgroundColor = UIColor.white
    static let SeparatorColor = UIColor.Defaults.GreyB
    static let HighlightBlue = UIColor.Defaults.Blue
    static let DestructiveRed = UIColor.Defaults.Red
    static let BorderColor = UIColor.darkGray
    static let BackgroundColor = AppBackgroundColor

    // Used as backgrounds for favicons
    static let DefaultColorStrings = ["2e761a", "399320", "40a624", "57bd35", "70cf5b", "90e07f", "b1eea5", "881606", "aa1b08", "c21f09", "d92215", "ee4b36", "f67964", "ffa792", "025295", "0568ba", "0675d3", "0996f8", "2ea3ff", "61b4ff", "95cdff", "00736f", "01908b", "01a39d", "01bdad", "27d9d2", "58e7e6", "89f4f5", "c84510", "e35b0f", "f77100", "ff9216", "ffad2e", "ffc446", "ffdf81", "911a2e", "b7223b", "cf2743", "ea385e", "fa526e", "ff7a8d", "ffa7b3" ]

    /// JPEG compression quality for persisted screenshots. Must be between 0-1.
    static let ScreenshotQuality: Float = 0.3
    static let ActiveScreenshotQuality: CGFloat = 0.5
}
