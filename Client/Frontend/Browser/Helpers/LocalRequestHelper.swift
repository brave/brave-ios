/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

private let log = Logger.browserLogger

class LocalRequestHelper: TabContentScript {
  static let scriptName = "LocalRequestHelper"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "\(scriptName)_\(messageUUID)"
  static let userScript: WKUserScript? = {
    guard var script = loadUserScript(named: scriptName) else {
      return nil
    }
    return WKUserScript.create(source: secureScript(handlerName: messageHandlerName,
                                                    securityToken: scriptId,
                                                    script: script),
                               injectionTime: .atDocumentStart,
                               forMainFrameOnly: false,
                               in: .page)
  }()

  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
    defer { replyHandler(nil, nil) }
    guard let requestUrl = message.frameInfo.request.url,
      let internalUrl = InternalURL(requestUrl),
      let params = message.body as? [String: String]
    else { return }

    if UserScriptManager.isMessageHandlerTokenMissing(in: params) {
      log.debug("Missing required security token.")
      return
    }

    if params["type"] == "reload" {
      // If this is triggered by session restore pages, the url to reload is a nested url argument.
      if let _url = internalUrl.extractedUrlParam, let nested = InternalURL(_url), let url = nested.extractedUrlParam {
        message.webView?.replaceLocation(with: url)
      } else {
        _ = message.webView?.reload()
      }
    } else {
      assertionFailure("Invalid message: \(message.body)")
    }
  }
}
