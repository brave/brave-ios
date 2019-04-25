// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared

private let log = Logger.browserLogger

class BackgroundMediaPlayback: TabContentScript {
    fileprivate weak var tab: Tab?
    
    init(tab: Tab) {
        self.tab = tab
    }
    
    static func name() -> String {
        return "BackgroundMediaPlayback"
    }
    
    func scriptMessageHandlerName() -> String? {
        return "backgroundMediaPlayback"
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let response = message.body as? String {
            debugPrint(response)
            log.info(response)
        } else {
            log.info(message.description)
        }
    }
}
