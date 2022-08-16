// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import BraveShared
import Shared
import Data

private let log = Logger.browserLogger

protocol PlaylistFolderSharingHelperDelegate: AnyObject {
  func openPlaylistSharingFolder(with id: String)
}

class PlaylistFolderSharingHelper: NSObject, TabContentScript {
  fileprivate weak var tab: Tab?
  public weak var delegate: PlaylistFolderSharingHelperDelegate?

  init(tab: Tab) {
    self.tab = tab
    super.init()
  }

  static func name() -> String {
    return "PlaylistFolderSharingHelper"
  }

  func scriptMessageHandlerName() -> String? {
    return "playlistFolderSharingHelper_\(UserScriptManager.messageHandlerTokenString)"
  }

  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
    defer { replyHandler(nil, nil) }
    
    if let sharingInfo = PlaylistFolderSharingInfo.from(message: message) {
      // This shared playlist folder already exists
      if let sharedFolder = PlaylistFolder.getSharedFolder(folderId: sharingInfo.playlistId) {
        message.webView?.evaluateSafeJavaScript(functionName: "window.brave.playlist.errorHandler",
                                                args: ["Item Already Exists \(sharedFolder.title ?? sharingInfo.playlistId)"],
                                                contentWorld: .page)
      } else {
        delegate?.openPlaylistSharingFolder(with: sharingInfo.playlistId)
      }
      return
    }
  }
}

private struct PlaylistFolderSharingInfo: Codable {
  public let playlistId: String

  public static func from(message: WKScriptMessage) -> PlaylistFolderSharingInfo? {
    if !JSONSerialization.isValidJSONObject(message.body) {
      return nil
    }

    do {
      let data = try JSONSerialization.data(withJSONObject: message.body, options: [.fragmentsAllowed])
      return try JSONDecoder().decode(PlaylistFolderSharingInfo.self, from: data)
    } catch {
      log.error("Error Decoding PlaylistFolderSharingInfo: \(error)")
    }

    return nil
  }
}
