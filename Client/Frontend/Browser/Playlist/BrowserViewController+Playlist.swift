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
        guard Preferences.Playlist.showToastForAdd.value,
              let selectedTab = tabManager.selectedTab,
              selectedTab.url?.isPlaylistSupportedSiteURL == true else {
            return
        }
        
        if let toast = playlistToast {
            toast.item = info
            return
        }
        
        // Item requires the user to choose whether or not to add it to playlists
        let toast = PlaylistToast(item: info, state: itemState, completion: { [weak self] buttonPressed in
            guard let self = self else { return }
            
            switch itemState {
            // Item requires user action to add it to playlists
            case .pendingUserAction:
                if buttonPressed {
                    // Update playlist with new items..
                    PlaylistItem.addItem(info, cachedData: nil) {
                        PlaylistManager.shared.autoDownload(item: info)
                        
                        log.debug("Playlist Item Added")
                        
                        self.playlistToast = nil
                        self.showPlaylistToast(info: info, itemState: .added)
                        UIImpactFeedbackGenerator(style: .medium).bzzt()
                    }
                } else {
                    self.playlistToast = nil
                }
                
            // Item already exists in playlist, so ask them if they want to view it there
            // Item was added to playlist by the user, so ask them if they want to view it there
            case .added, .existing:
                if buttonPressed {
                    self.openPlaylist()
                    UIImpactFeedbackGenerator(style: .medium).bzzt()
                }
                
                self.playlistToast = nil
            }
        })
        
        playlistToast = toast
        let duration = itemState == .pendingUserAction ? 10 : 5
        show(toast: toast, afterWaiting: .milliseconds(250), duration: .seconds(duration))
    }
    
    func dismissPlaylistToast(animated: Bool) {
        playlistToast?.dismiss(false, animated: animated)
    }
    
    private func openPlaylist() {
        let playlistController = (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController ?? PlaylistViewController()
        playlistController.modalPresentationStyle = .fullScreen
        present(playlistController, animated: true)
    }
    
    func addToPlayListActivity(info: PlaylistInfo?, itemDetected: Bool) {
        addToPlayListActivityItem = (enabled: itemDetected, item: info)
    }
}
