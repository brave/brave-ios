// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Static
import BraveShared
import Shared

class NewTabPageTableViewController: TableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = Strings.NewTabPageSettingsTitle
        tableView.accessibilityIdentifier = "NewTabPageSettings.tableView"
        dataSource.sections = [section]
        
        // Sponsored switch is only enabled if the background images is enabled also.
        self.sponsoredSwitch?.isEnabled = Preferences.NewTabPage.backgroundImages.value
    }
    
    private lazy var section: Section = {
        return Section(
            rows: [
                BoolRow(title: Strings.NewTabPageSettingsBackgroundImages, option: Preferences.NewTabPage.backgroundImages, onValueChange: {
                    newValue in
                    // Since overriding, does not auto-adjust this setting.
                    Preferences.NewTabPage.backgroundImages.value = newValue
                    
                    // If turning off normal background images, turn of sponsored images as well.
                    Preferences.NewTabPage.backgroundSponsoredImages.value = newValue
                    
                    if !newValue {
                        // Updating the underlying preference does not dynamically update the visuals unfortuantely.
                        // Updating manually. Only update if disabling.
                        self.sponsoredSwitch?.isOn = newValue
                    }
                    
                    // Need to update every time.
                    self.sponsoredSwitch?.isEnabled = newValue
                }),
                BoolRow(title: Strings.NewTabPageSettingsSponsoredImages, option: Preferences.NewTabPage.backgroundSponsoredImages)
            ]
        )
    }()
    
    private var sponsoredSwitch: UISwitch? {
        // A bit of a weird work around, but enables accessing and adjusting the sponsored image switch directly.
        return self.section.rows.last?.accessory.view as? SwitchAccessoryView
    }
}
