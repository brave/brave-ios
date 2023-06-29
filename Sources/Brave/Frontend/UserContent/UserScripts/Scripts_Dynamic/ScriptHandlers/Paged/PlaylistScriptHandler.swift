// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import AVKit
import Data
import Preferences
import Shared
import os.log

enum PlaylistItemAddedState {
  case none
  case newItem
  case existingItem
}

protocol PlaylistScriptHandlerDelegate: NSObject {
  func updatePlaylistURLBar(tab: Tab?, state: PlaylistItemAddedState, item: PlaylistInfo?)
  func showPlaylistPopover(tab: Tab?)
  func showPlaylistToast(tab: Tab?, state: PlaylistItemAddedState, item: PlaylistInfo?)
  func showPlaylistAlert(tab: Tab?, state: PlaylistItemAddedState, item: PlaylistInfo?)
  func showPlaylistOnboarding(tab: Tab?)
}

class PlaylistScriptHandler: NSObject, TabContentScript {
  fileprivate weak var tab: Tab?
  public weak var delegate: PlaylistScriptHandlerDelegate?
  private var url: URL?
  private var urlObserver: NSObjectProtocol?
  private var asset: AVURLAsset?
  private static let queue = DispatchQueue(label: "com.playlisthelper.queue", qos: .userInitiated)

  init(tab: Tab) {
    self.tab = tab
    self.url = tab.url
    super.init()
  }

  deinit {
    
  }
  
  static let playlistLongPressed = "playlistLongPressed_\(uniqueID)"
  static let playlistProcessDocumentLoad = "playlistProcessDocumentLoad_\(uniqueID)"
  static let mediaCurrentTimeFromTag = "mediaCurrentTimeFromTag_\(uniqueID)"
  static let stopMediaPlayback = "stopMediaPlayback_\(uniqueID)"

  static let scriptName = "PlaylistScript"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "\(scriptName)_\(messageUUID)"
  static let scriptSandbox: WKContentWorld = .defaultClient
  static let userScript: WKUserScript? = nil

  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
    defer { replyHandler(nil, nil) }
  }

  private class func processPlaylistInfo(handler: PlaylistScriptHandler, item: PlaylistInfo?) {
    
  }
}

extension PlaylistScriptHandler: UIGestureRecognizerDelegate {
  @objc
  func onLongPressedWebView(_ gestureRecognizer: UILongPressGestureRecognizer) {
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    if otherGestureRecognizer.isKind(of: UILongPressGestureRecognizer.self) {
      return true
    }
    return false
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return false
  }
}

extension PlaylistScriptHandler {
  static func getCurrentTime(webView: WKWebView, nodeTag: String, completion: @escaping (Double) -> Void) {
    guard UUID(uuidString: nodeTag) != nil else {
      Logger.module.error("Unsanitized NodeTag.")
      return
    }
    
    webView.evaluateSafeJavaScript(functionName: "window.__firefox__.\(mediaCurrentTimeFromTag)",
                                   args: [nodeTag, Self.scriptId],
                                   contentWorld: Self.scriptSandbox,
                                   asFunction: true) { value, error in

      if let error = error {
        Logger.module.error("Error Retrieving Playlist Page Media Current Time: \(error.localizedDescription)")
      }

      DispatchQueue.main.async {
        if let value = value as? Double {
          completion(value)
        } else {
          completion(0.0)
        }
      }
    }
  }

  static func stopPlayback(tab: Tab?) {
  }
}

extension PlaylistScriptHandler {
  static func updatePlaylistTab(tab: Tab, item: PlaylistInfo?) {

  }
}

extension PlaylistScriptHandler {
  struct ReadyState: Codable {
    let state: String
    
    static func from(message: WKScriptMessage) -> ReadyState? {
      if !JSONSerialization.isValidJSONObject(message.body) {
        return nil
      }

      guard let data = try? JSONSerialization.data(withJSONObject: message.body, options: [.fragmentsAllowed]) else {
        return nil
      }
      
      return try? JSONDecoder().decode(ReadyState.self, from: data)
    }
  }
}
