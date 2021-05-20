// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data
import Shared
import BraveShared

private let log = Logger.browserLogger

extension BrowserViewController: PlaylistHelperDelegate {
    func showPlaylistAlert(_ alertController: UIAlertController) {
        self.present(alertController, animated: true)
    }
    
    func showPlaylistToast(info: PlaylistInfo, itemState: PlaylistItemAddedState) {
        // Update menu button
        topToolbar.menuButton.addBadge(.playlist, animated: true)
        toolbar?.menuButton.addBadge(.playlist, animated: true)
    }
    
    func dismissPlaylistToast(animated: Bool) {
        // Update menu button
        topToolbar.menuButton.removeBadge(.playlist, animated: true)
        toolbar?.menuButton.removeBadge(.playlist, animated: true)
    }
    
    func openPlaylist() {
        let playlistController = (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController ?? PlaylistViewController()
        playlistController.modalPresentationStyle = .fullScreen
        present(playlistController, animated: true)
    }
    
    func addToPlayListActivity(info: PlaylistInfo?, itemDetected: Bool) {
        if info == nil {
            addToPlayListActivityItem = nil
        } else {
            addToPlayListActivityItem = (enabled: itemDetected, item: info)
        }
    }
    
    func openInPlayListActivity(info: PlaylistInfo?) {
        if info == nil {
            openInPlaylistActivityItem = nil
        } else {
            openInPlaylistActivityItem = (enabled: true, item: info)
        }
    }
    
    func addToPlaylist(item: PlaylistInfo, completion: ((_ didAddItem: Bool) -> Void)?) {
        if PlaylistManager.shared.isDiskSpaceEncumbered() {
            let style: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
            let alert = UIAlertController(
                title: Strings.PlayList.playlistDiskSpaceWarningTitle, message: Strings.PlayList.playlistDiskSpaceWarningMessage, preferredStyle: style)
            
            alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.openInPlaylistActivityItem = (enabled: true, item: item)
                self.addToPlayListActivityItem = nil
                
                PlaylistItem.addItem(item, cachedData: nil) {
                    PlaylistManager.shared.autoDownload(item: item)
                    completion?(true)
                }
            }))
            
            alert.addAction(UIAlertAction(title: Strings.CancelString, style: .cancel, handler: { _ in
                completion?(false)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            openInPlaylistActivityItem = (enabled: true, item: item)
            addToPlayListActivityItem = nil
            
            PlaylistItem.addItem(item, cachedData: nil) {
                PlaylistManager.shared.autoDownload(item: item)
                completion?(true)
            }
        }
    }
    
    func openInPlaylist(item: PlaylistInfo, completion: (() -> Void)?) {
        let playlistController = (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController ?? PlaylistViewController()
        playlistController.modalPresentationStyle = .fullScreen
        present(playlistController, animated: true) {
            completion?()
        }
    }
}
