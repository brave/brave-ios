// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Static
import Shared
import BraveShared
import IntentsUI

// MARK: - ShortcutSettingsViewController

class ShortcutSettingsViewController: TableViewController {
    
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
                            manageShortcutActivity(for: .newTab)
                        }, accessory: .disclosureIndicator, cellClass: MultilineValue1Cell.self)],
                    footer: .title("Use Shortcuts to open a new tab via Siri - Voice Assistant"))
        )
        
        dataSource.sections.append(
            Section(rows: [
                        Row(text: "Open New Private Tab", selection: { [unowned self] in
                            manageShortcutActivity(for: .newPrivateTab)
                        }, accessory: .disclosureIndicator, cellClass: MultilineValue1Cell.self)],
                    footer: .title("Use Shortcuts to open a new private tab via Siri - Voice Assistant"))
        )
        
        dataSource.sections.append(
            Section(rows: [
                        Row(text: "Clear Browser History", selection: { [unowned self] in
                            manageShortcutActivity(for: .clearBrowsingHistory)
                        }, accessory: .disclosureIndicator, cellClass: MultilineValue1Cell.self)],
                    footer: .title("Use Shortcuts to Clear Browsing History & Open a New Tab via Siri - Voice Assistant"))
        )
            
        dataSource.sections.append(
            Section(rows: [
                        Row(text: "Enable VPN", selection: { [unowned self] in
                            manageShortcutActivity(for: .enableBraveVPN)
                        }, accessory: .disclosureIndicator, cellClass: MultilineValue1Cell.self)],
                    footer: .title("Use Shortcuts to enable Brave VPN via Siri - Voice Assistant"))
        )
        
        dataSource.sections.append(
            Section(rows: [
                        Row(text: "Open Brave Today", selection: { [unowned self] in
                            manageShortcutActivity(for: .openBraveToday)
                        }, accessory: .disclosureIndicator, cellClass: MultilineValue1Cell.self)],
                    footer: .title("Use Shortcuts to Open a New Tab & Show Brave Today Feed via Siri - Voice Assistant"))
        )
        
        dataSource.sections.append(
            Section(rows: [
                        Row(text: "Open Playlist", selection: { [unowned self] in
                            manageShortcutActivity(for: .openBraveToday)
                        }, accessory: .disclosureIndicator, cellClass: MultilineValue1Cell.self)],
                    footer: .title("Use Shortcuts to Open Playlist via Siri - Voice Assistant"))
        )
    }
    
    private func manageShortcutActivity(for type: ActivityType) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { [unowned self] (shortcuts, error) in
            DispatchQueue.main.async {
                guard let shortcuts = shortcuts else { return }
                
                guard let shortcut = shortcuts.first(where: { $0.shortcut.userActivity?.activityType == type.identifier }) else {
                    presentAddShorcutActivity(for: type)
                    return
                }
                
                self.presentEditShorcutActivity(for: shortcut)
            }
        }
    }
    
    private func presentAddShorcutActivity(for type: ActivityType) {
        let userActivity = ActivityShortcutManager.shared.createShortcutActivity(type: type)
                        
        let addShorcutViewController = INUIAddVoiceShortcutViewController(shortcut: INShortcut(userActivity: userActivity))
        addShorcutViewController.delegate = self

        present(addShorcutViewController, animated: true, completion: nil)
    }
    
    private func presentEditShorcutActivity(for voiceShortcut: INVoiceShortcut) {
        let addShorcutViewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
        addShorcutViewController.delegate = self

        present(addShorcutViewController, animated: true, completion: nil)
    }
}

extension ShortcutSettingsViewController: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension ShortcutSettingsViewController: INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }

    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
