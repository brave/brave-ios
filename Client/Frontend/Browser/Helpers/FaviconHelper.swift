/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

private let log = Logger.browserLogger

class FaviconHelper: TabContentScript {
  fileprivate weak var tab: Tab?

  init(tab: Tab) {
    self.tab = tab
  }

  static func name() -> String {
    return "FaviconUrlsHandler"
  }

  func scriptMessageHandlerName() -> String? {
    return "FaviconUrlsHandler"
  }

  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
    defer { replyHandler(nil, nil) }
    
    guard let webView = message.webView,
            let url = webView.url else { return }
    
    if !InternalURL.isValid(url: url),
       !(InternalURL(url)?.isSessionRestore ?? false) {
      tab?.driver.webView(webView, onFaviconURLsUpdated: message)
    }
  }
}
