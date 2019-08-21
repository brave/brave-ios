// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

extension Theme {
    func applyAppearanceProperties() {
        
        // `appearance` modifications only impact UI items not current visible
        
        let bars = [UINavigationBar.appearance(), UIToolbar.appearance()]
        bars.forEach {
            $0.tintColor = colors.accent
            $0.backgroundColor = colors.footer
        }
        
        UISwitch.appearance().tintColor = colors.accent
        UISwitch.appearance().onTintColor = colors.accent
        
        // Will become the color for whatever in the table is .clear
        // In some cases this is the header, footer, cell, or a combination of them.
        // Be careful adjusting colors here, and make sure impact is well known
        UITableView.appearance().appearanceBackgroundColor = colors.addressBar
        UITableView.appearance().appearanceSeparatorColor = colors.border.withAlphaComponent(colors.transparencies.borderAlpha)
        
        UITableViewCell.appearance().tintColor = colors.accent
        UITableViewCell.appearance().backgroundColor = colors.home

        UIView.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).appearanceBackgroundColor = colors.addressBar
        
        UILabel.appearance(whenContainedInInstancesOf: [UITableView.self]).appearanceTextColor = colors.tints.home
    }
}

extension UILabel {
    @objc dynamic var appearanceTextColor: UIColor! {
        get { return self.textColor }
        set {  self.textColor = newValue }
    }
}

extension UITableView {
    @objc dynamic var appearanceSeparatorColor: UIColor? {
        get { return self.separatorColor }
        set {  self.separatorColor = newValue }
    }
}

extension UIView {
    @objc dynamic var appearanceBackgroundColor: UIColor? {
        get { return self.backgroundColor }
        set {  self.backgroundColor = newValue }
    }
}

