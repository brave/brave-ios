// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import WebKit

class WindowRenderHelper: TabContentScript {
  fileprivate weak var tab: Tab?

  required init(tab: Tab) {
    self.tab = tab
  }

  static let scriptName = "WindowRenderHelper"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "\(scriptName)_\(messageUUID)"
  private static let resizeWindowFunction = "\(scriptName)_\(uniqueID)"
  
  static let userScript: WKUserScript? = {
    guard var script = loadUserScript(named: scriptName) else {
      return nil
    }
    return WKUserScript.create(source: secureScript(handlerNamesMap: ["$<windowRenderHelper>": resizeWindowFunction],
                                                    securityToken: scriptId,
                                                    script: script),
                               injectionTime: .atDocumentStart,
                               forMainFrameOnly: false,
                               in: .defaultClient)
  }()

  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
    // Do nothing with the messages received.
    // For now.. It's useful for debugging though.
  }

  static func executeScript(for tab: Tab) {
    tab.webView?.evaluateSafeJavaScript(functionName: "\(resizeWindowFunction).resizeWindow", contentWorld: .defaultClient)
  }
}
