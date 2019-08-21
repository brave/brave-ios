// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

extension Theme {
    func applyAppearanceProperties() {
        
        // `appearance` modifications do not seem to fully reset UI components.
        UINavigationBar.appearance().do {
            $0.tintColor = colors.accent
            $0.backgroundColor = colors.header
        }
        
        (UISwitch.appearance() as UISwitch).do {
            $0.tintColor = colors.accent
            $0.onTintColor = colors.accent
        }
        
        UITableView.appearance().appearanceBackgroundColor = colors.addressBar
        UITableView.appearance().appearanceSeparatorColor = colors.border.withAlphaComponent(colors.transparencies.borderAlpha)
        
        UITableViewCell.appearance().tintColor = colors.accent
        UITableViewCell.appearance().backgroundColor = colors.home

        UILabel.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).appearanceTextColor = colors.tints.home
        
        
    }
}

extension UILabel {
    @objc dynamic var appearanceTextColor: UIColor! {
        get { return self.textColor }
        set {  self.textColor = newValue }
    }
}

extension UITableView {
    @objc dynamic var appearanceBackgroundColor: UIColor? {
        get { return self.backgroundColor }
        set {  self.backgroundColor = newValue }
    }
    
    @objc dynamic var appearanceSeparatorColor: UIColor? {
        get { return self.separatorColor }
        set {  self.separatorColor = newValue }
    }
}

