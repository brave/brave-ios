// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveShared
import BraveUI

extension Theme {
    func applyAppearanceProperties() {
        
        // `appearance` modifications only impact UI items not current visible

        // important! for privacy concerns, otherwise UI can bleed through
        UIView.appearance(whenContainedInInstancesOf: [BasePasscodeViewController.self]).backgroundColor = UIColor.braveBackground
        
        UIToolbar.appearance().tintColor = UIColor.braveOrange
        UIToolbar.appearance().backgroundColor = UIColor.braveBackground
        UIToolbar.appearance().barTintColor = UIColor.braveBackground
        
        UINavigationBar.appearance().tintColor = UIColor.braveOrange
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.braveLabel]
        UINavigationBar.appearance().barTintColor = UIColor.braveBackground
        
        UISwitch.appearance().onTintColor = UIColor.braveOrange
        
        // This is a subtle "abuse" of theme colors
        // In order to properly style things, `addressBar` has been utilized to offer contrast to `home`/`header`, as many of the themes utilize similar colors.
        // These used colors have been mapped, primarily for table usage, and to understand how table colors relate to each other.
        // Any change to a single tableView property that currently uses one of these will probably have odd behavior and must be thoroughly tested
        
        /// Used as color a table will use as the base (e.g. background)
        let tablePrimaryColor = UIColor.braveGroupedBackground
        /// Used to augment `tablePrimaryColor` above
        let tableSecondaryColor = UIColor.secondaryBraveGroupedBackground
        
        // Will become the color for whatever in the table is .clear
        // In some cases this is the header, footer, cell, or a combination of them.
        // Be careful adjusting colors here, and make sure impact is well known
        UITableView.appearance().backgroundColor = tablePrimaryColor
        UITableView.appearance().separatorColor = .braveSeparator
        
        UITableViewCell.appearance().tintColor = colors.accent
        UITableViewCell.appearance().backgroundColor = tableSecondaryColor
        
        UIImageView.appearance(whenContainedInInstancesOf: [SettingsViewController.self]).tintColor = UIColor.braveLabel
        UIImageView.appearance(whenContainedInInstancesOf: [BraveRewardsSettingsViewController.self]).tintColor = UIColor.braveLabel

        UIView.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).backgroundColor = tablePrimaryColor
        
        UILabel.appearance(whenContainedInInstancesOf: [UITableView.self]).textColor = .braveLabel
        UILabel.appearance(whenContainedInInstancesOf: [UICollectionReusableView.self]).textColor = .braveLabel
        
        AddEditHeaderView.appearance().backgroundColor = tableSecondaryColor
        UITextField.appearance().textColor = UIColor.braveLabel
        UITextField.appearance().keyboardAppearance = isDark ? .dark : .light
        
        // Sync items
        SyncViewController.SyncView.appearance(whenContainedInInstancesOf: [UINavigationController.self]).backgroundColor = .braveBackground
        SyncDeviceTypeButton.appearance().backgroundColor = .braveBackground
        UIButton.appearance(
            whenContainedInInstancesOf: [SyncViewController.self]).setTitleColor(.braveLabel, for: .normal)
        
        // Search
        UIView.appearance(whenContainedInInstancesOf: [SearchViewController.self]).backgroundColor = .braveBackground
        InsetButton.appearance(whenContainedInInstancesOf: [SearchViewController.self]).backgroundColor = .clear
        
        InsetButton.appearance(whenContainedInInstancesOf: [SearchSuggestionPromptView.self]).setTitleColor(.braveLabel, for: .normal)
        
        // Overrides all views inside of itself
        // According to docs, UIWindow override should be enough, but some labels on iOS 13 are still messed up without UIView override as well
        // (e.g. shields panel)
        UIWindow.appearance().overrideUserInterfaceStyle = isDark ? .dark : .light
        UIView.appearance().overrideUserInterfaceStyle = isDark ? .dark : .light
    }
}
