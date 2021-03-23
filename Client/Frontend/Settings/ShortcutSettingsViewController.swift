// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Static
import Shared
import BraveShared

// MARK: - PlaylistSettingsViewController

class ShorcutSettingsViewController: TableViewController {

    let theme: Theme
    
    // MARK: Lifecycle
    
    init(_ theme: Theme) {
        self.theme = theme
        
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Siri Shorcuts"
        
        dataSource.sections.append(
            Section(rows: [
                        Row(text: "Open New Tab", selection: { [unowned self] in
                            print("Setup Shorcut")
                        }, accessory: .disclosureIndicator, cellClass: MultilineValue1Cell.self)],
                    footer: .title("Use Shorcuts to open a new tab via Siri - Virtual Assistant"))
        )
        
        dataSource.sections.append(
            Section(rows: [
                        Row(text: "Open New Private Tab", selection: { [unowned self] in
                            print("Setup Shorcut")
                        }, accessory: .disclosureIndicator, cellClass: MultilineValue1Cell.self)],
                    footer: .title("Use Shorcuts to open a new private tab via Siri - Virtual Assistant"))
        )
    }
}
