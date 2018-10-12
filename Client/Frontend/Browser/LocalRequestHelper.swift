/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class LocalRequestHelper: TabContentScript {
    func scriptMessageHandlerName() -> String? {
        return "localRequestHelper"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let params = message.body as? [String: String], message.frameInfo.request.url?.isLocal ?? false else {
            return
        }

        if params["type"] == "load",
           let urlString = params["url"],
           let url = URL(string: urlString) {
            _ = message.webView?.load(PrivilegedRequest(url: url) as URLRequest)
        } else if params["type"] == "reload" {
            _ = message.webView?.reload()
        } else {
            assertionFailure("Invalid message: \(message.body)")
        }
    }

    class func name() -> String {
        return "LocalRequestHelper"
    }
}
