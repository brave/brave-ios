// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Static
import Shared
import BraveShared

// MARK: - PlayListSide

enum PlayListSide: String, CaseIterable, RepresentableOptionType {
    case left
    case right
        
    var displayString: String {
        switch self {
            case .left:
                return Strings.PlayList.playlistSidebarLocationOptionLeft
            case .right:
                return Strings.PlayList.playlistSidebarLocationOptionRight
        }
    }
}

// MARK: - PlayListDownloadType

enum PlayListDownloadType: String, CaseIterable, RepresentableOptionType {
    case on
    case off
    case wifi
        
    var displayString: String {
        switch self {
            case .on:
                return Strings.PlayList.playlistAutoDownloadOptionOn
            case .off:
                return Strings.PlayList.playlistAutoDownloadOptionOff
            case .wifi:
                return Strings.PlayList.playlistAutoDownloadOptionOnlyWifi
        }
    }
}

// MARK: - PlaylistSettingsViewController

class PlaylistSettingsViewController: TableViewController {

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
        
        title = Strings.PlayList.playListSectionTitle
        
        dataSource.sections = [
            Section(
                rows: [
                    .boolRow(title: Strings.PlayList.playlistToastShowSettingsOptionTitle,
                             option: Preferences.Playlist.showToastForAdd)
                ],
                footer: .title(Strings.PlayList.playlistToastShowSettingsOptionFooterText)
            ),
            Section(
                rows: [
                    .boolRow(title: Strings.PlayList.playlistAutoPlaySettingsOptionTitle,
                             option: Preferences.Playlist.firstLoadAutoPlay)
                ],
                footer: .title(Strings.PlayList.playlistAutoPlaySettingsOptionFooterText)
            )
        ]
        
        var autoDownloadSection = Section(rows: [])
        var row = Row(text: Strings.PlayList.playlistAutoDownloadSettingsTitle,
                      detailText: PlayListDownloadType(rawValue: Preferences.Playlist.autoDownloadVideo.value)?.displayString,
                      accessory: .disclosureIndicator,
                      cellClass: MultilineSubtitleCell.self)

        row.selection = { [unowned self] in
            let optionsViewController = OptionSelectionViewController<PlayListDownloadType>(
                options: PlayListDownloadType.allCases,
                selectedOption: PlayListDownloadType(rawValue: Preferences.Playlist.autoDownloadVideo.value),
                optionChanged: { [unowned self] _, option in
                    Preferences.Playlist.autoDownloadVideo.value = option.rawValue

                    self.dataSource.reloadCell(row: row, section: autoDownloadSection, displayText: option.displayString)
                    self.applyTheme(self.theme)
                }
            )
            optionsViewController.title = Strings.PlayList.playlistAutoDownloadSettingsTitle
            optionsViewController.footerText = Strings.PlayList.playlistAutoDownloadFooterSettingsText

            self.navigationController?.pushViewController(optionsViewController, animated: true)
        }
        
        autoDownloadSection.rows.append(row)
        dataSource.sections.append(autoDownloadSection)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            var sideSelectionSection = Section(rows: [])
            var row = Row(text: Strings.PlayList.playlistSidebarLocationTitle,
                          detailText: PlayListSide(rawValue: Preferences.Playlist.listViewSide.value)?.displayString,
                          accessory: .disclosureIndicator,
                          cellClass: MultilineSubtitleCell.self)

            row.selection = { [unowned self] in
                let optionsViewController = OptionSelectionViewController<PlayListSide>(
                    options: PlayListSide.allCases,
                    selectedOption: PlayListSide(rawValue: Preferences.Playlist.listViewSide.value),
                    optionChanged: { [unowned self] _, option in
                        Preferences.Playlist.listViewSide.value = option.rawValue

                        self.dataSource.reloadCell(row: row, section: sideSelectionSection, displayText: option.displayString)
                        self.applyTheme(self.theme)
                    }
                )
                optionsViewController.title = Strings.PlayList.playlistSidebarLocationTitle
                optionsViewController.footerText = Strings.PlayList.playlistSidebarLocationFooterText

                self.navigationController?.pushViewController(optionsViewController, animated: true)
            }
            
            sideSelectionSection.rows.append(row)
            dataSource.sections.append(sideSelectionSection)
        }
        
        dataSource.sections.append(
            Section(rows: [
                Row(text: Strings.PlayList.playlistDeleteCacheAlertTitle, selection: { [unowned self] in
                    let style: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
                    let alert = UIAlertController(
                        title: Strings.PlayList.playlistDeleteCacheAlertTitle,
                        message: Strings.PlayList.playlistDeleteCacheAlertDescription,
                        preferredStyle: style)
                    
                    alert.addAction(UIAlertAction(title: Strings.delete, style: .default, handler: { _ in
                        PlaylistManager.shared.deleteAllItems()
                    }))
                    alert.addAction(UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }, cellClass: ButtonCell.self)],
                    footer: .title(Strings.PlayList.playlistDeleteAllSettingsOptionFooterText))
        )
        
        if !AppConstants.buildChannel.isPublic {
            // TODO: Add debug settings here
        }
    }
}
