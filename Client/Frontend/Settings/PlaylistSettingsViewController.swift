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
    case left = "left"
    case right = "right"
        
    var displayString: String {
        switch self {
            case .left:
                return Strings.PlayList.playlistSidebarLocationOptionLeft
            case .right:
                return Strings.PlayList.playlistSidebarLocationOptionRight
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
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            var sideSelection = Section(rows: [])

            let themeSubtitle = PlayListSide(rawValue: Preferences.Playlist.listViewSide.value)?.displayString

            var row = Row(text: Strings.PlayList.playlistSidebarLocationTitle,
                          detailText: themeSubtitle,
                          accessory: .disclosureIndicator,
                          cellClass: MultilineSubtitleCell.self)

            row.selection = { [unowned self] in
                let optionsViewController = OptionSelectionViewController<PlayListSide>(
                    options: PlayListSide.allCases,
                    selectedOption: PlayListSide(rawValue: Preferences.Playlist.listViewSide.value),
                    optionChanged: { [unowned self] _, option in
                        Preferences.Playlist.listViewSide.value = option.rawValue

                        self.dataSource.reloadCell(row: row, section: sideSelection, displayText: option.displayString)
                        self.applyTheme(self.theme)
                    }
                )
                optionsViewController.title = Strings.PlayList.playlistSidebarLocationTitle
                optionsViewController.footerText = Strings.PlayList.playlistSidebarLocationFooterText

                self.navigationController?.pushViewController(optionsViewController, animated: true)
            }
            
            sideSelection.rows.append(row)
            
            dataSource.sections.append(sideSelection)
        }
        
        if !AppConstants.buildChannel.isPublic {
            // TODO: Add debug settings here
        }
    }
}
