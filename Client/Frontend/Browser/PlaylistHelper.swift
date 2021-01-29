// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Data
import BraveShared
import Shared

private let log = Logger.browserLogger

class PlaylistHelper: TabContentScript {
    fileprivate weak var tab: Tab?
    
    init(tab: Tab) {
        self.tab = tab
    }
    
    static func name() -> String {
        return "PlaylistHelper"
    }
    
    func scriptMessageHandlerName() -> String? {
        return "playlistHelper"
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        guard let item = PlaylistInfo.from(message: message) else { return }
        
        log.debug("FOUND VIDEO ITEM ON PAGE: \(message.body)")
        
//        if Playlist.shared.itemExists(item: item) {
//            //Update playlist existing items..
//            if !item.src.isEmpty {
//                Playlist.shared.updateItem(mediaSrc: item.src, item: item) {
//                    log.debug("Playlist Item Updated")
//                }
//            }
//        } else {
//            //Update playlist with new items..
//            Playlist.shared.addItem(item: item, cachedData: nil) {
//                log.debug("Playlist Item Added")
//            }
//        }
    }
}
