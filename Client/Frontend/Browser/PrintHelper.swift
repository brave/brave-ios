/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

private let log = Logger.browserLogger

class PrintHelper: TabContentScript {
    fileprivate weak var tab: Tab?

    class func name() -> String {
        return "PrintHelper"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "printHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let body = message.body as? [String: AnyObject] else {
            return
        }
        
        if UserScriptManager.isMessageHandlerTokenMissing(in: body) {
            log.debug("Missing required security token.")
            return
        }
        
        if let tab = tab, let webView = tab.webView {
            let printController = UIPrintInteractionController.shared
            printController.printFormatter = webView.viewPrintFormatter()
            printController.present(animated: true, completionHandler: nil)
        }
    }
}
