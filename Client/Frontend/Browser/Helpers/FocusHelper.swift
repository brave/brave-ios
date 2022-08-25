/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit
import Logger

class FocusHelper: TabContentScript {
  fileprivate weak var tab: Tab?

  init(tab: Tab) {
    self.tab = tab
  }

  static func name() -> String {
    return "FocusHelper"
  }

  func scriptMessageHandlerName() -> String? {
    return "focusHelper"
  }

  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
    defer { replyHandler(nil, nil) }

    guard let body = message.body as? [String: AnyObject] else {
      return Log.main.error("FocusHelper.js sent wrong type of message")
    }

    if UserScriptManager.isMessageHandlerTokenMissing(in: body) {
      Log.main.debug("Missing required security token.")
      return
    }

    guard let data = body["data"] as? [String: String] else {
      return Log.main.error("FocusHelper.js sent wrong type of message")
    }

    guard let _ = data["elementType"],
      let eventType = data["eventType"]
    else {
      return Log.main.error("FocusHelper.js sent wrong keys for message")
    }

    switch eventType {
    case "focus":
      tab?.isEditing = true
    case "blur":
      tab?.isEditing = false
    default:
      return Log.main.error("FocusHelper.js sent unhandled eventType")
    }
  }
}
