// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import WebKit
import BraveCore

private let log = Logger.braveCoreLogger

class AdsMediaReporting: TabContentScript {
  let rewards: BraveRewards
  weak var tab: Tab?

  init(rewards: BraveRewards, tab: Tab) {
    self.rewards = rewards
    self.tab = tab
  }

  static let scriptName = "AdsMediaReporting"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "\(scriptName)_\(messageUUID)"
  static let scriptSandbox: WKContentWorld = .page
  static let userScript: WKUserScript? = {
    guard var script = loadUserScript(named: scriptName) else {
      return nil
    }
    return WKUserScript.create(source: secureScript(handlerName: messageHandlerName,
                                                    securityToken: scriptId,
                                                    script: script),
                               injectionTime: .atDocumentStart,
                               forMainFrameOnly: false,
                               in: scriptSandbox)
  }()

  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
    defer { replyHandler(nil, nil) }
    guard let body = message.body as? [String: AnyObject] else {
      return
    }

    if UserScriptManager.isMessageHandlerTokenMissing(in: body) {
      log.debug("Missing required security token.")
      return
    }

    if let isPlaying = body["data"] as? Bool, rewards.isEnabled {
      guard let tab = tab else { return }
      if isPlaying {
        rewards.reportMediaStarted(tabId: Int(tab.rewardsId))
      } else {
        rewards.reportMediaStopped(tabId: Int(tab.rewardsId))
      }
    }
  }
}
