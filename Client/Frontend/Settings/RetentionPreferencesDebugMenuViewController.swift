// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Static
import Shared
import BraveShared

private let log = Logger.browserLogger

class RetentionPreferencesDebugMenuViewController: TableViewController {    
    private var browserViewController: BrowserViewController?

    init() {
        super.init(style: .insetGrouped)
        
        browserViewController = self.currentScene?.browserViewController
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Retention Preferences"
        
        dataSource.sections = [
            debugFlags,
            retentionFlags
        ]
    }
    
    private func presentDebugFlagAlert() {
        let alert = UIAlertController(
            title: "Value can't be changed!",
            message: "this is debug flag value cant be changed.",
            preferredStyle: UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Sections
    
    private lazy var debugFlags: Section = {
        var shields = Section(
            header: .title("Debug Flags"),
            rows: [
                .boolRow(
                    title: "Skip Onboarding Intro",
                    detailText: "Flag for hide/show entire onboarding sequence",
                    toggleValue: Preferences.DebugFlag.skipOnboardingIntro ?? false,
                    valueChange: { [unowned self] _ in
                        self.presentDebugFlagAlert()
                    },
                    cellReuseId: "SkipOnboardingCell"),
                .boolRow(
                    title: "Skip Education Pop-ups",
                    detailText: "Flag for hide/show education pop-ups. Includes onboarding ad block notifications",
                    toggleValue: Preferences.DebugFlag.skipEduPopups ?? false,
                    valueChange: { [unowned self] _ in
                        self.presentDebugFlagAlert()
                    },
                    cellReuseId: "SkipEduCell"),
                .boolRow(
                    title: "Skip NTP Callouts",
                    detailText: "Flag for hide/show full screen callouts. Includes Default Browser, Rewards, Sync",
                    toggleValue: Preferences.DebugFlag.skipNTPCallouts ?? false,
                    valueChange: { [unowned self] _ in
                        self.presentDebugFlagAlert()
                    },
                    cellReuseId: "SkipNTPCell")
            ],
            footer: .title("These are the debug flags that enables entire features and set to false for Debug scheme in order to provide faster development.")
        )
        return shields
    }()
    
    private lazy var retentionFlags: Section = {
        var shields = Section(
            header: .title("Retention Flags"),
            rows: [
                .boolRow(
                    title: "Retention User",
                    detailText: "Flag showing if the user installed the application after new onboarding is added",
                    toggleValue: Preferences.General.isNewRetentionUser.value ?? false,
                    valueChange: {
                        if $0 {
                            let status = $0
                            Preferences.General.isNewRetentionUser.value = status
                        }
                    },
                    cellReuseId: "RetentionUserCell"),
                .boolRow(
                    title: "Benchmark Notification Presented",
                    detailText: "Boolean which is tracking If a product notification is presented in the actual launch session. This flag is used in order to not to try to present another one over existing popover.",
                    toggleValue: browserViewController?.benchmarkNotificationPresented ?? false,
                    valueChange: { [unowned self] status in
                        self.browserViewController?.benchmarkNotificationPresented = status
                    },
                    cellReuseId: "These are the retention flags determines certain situations where an onboarding element, a callout or an education pop-up will appear.")
            ],
            footer: .title(Strings.shieldsDefaultsFooter)
        )
        return shields
    }()
}
