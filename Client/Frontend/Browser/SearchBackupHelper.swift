/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import BraveShared
import Combine

class SearchBackupHelper: TabContentScript {
    fileprivate weak var tab: Tab?

    required init(tab: Tab) {
        self.tab = tab
    }

    static func name() -> String {
        return "SearchBackup"
    }

    func scriptMessageHandlerName() -> String? {
        return SearchBackupHelper.name()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // 🙀 😭 🏃‍♀️💨
        print("bxx search backup")
        
        let str = "https://www.google.com/search?q=test&hl=us&gl=us"
        let request = URLRequest(url: URL(string: str)!)
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data else { return }
            
            let str = data.websafeBase64String()!
            
            DispatchQueue.main.async {
                // swiftlint:disable:next safe_javascript
                self.tab?.webView?.evaluateJavaScript("searchBackupCallback('\(str)')") { _, _ in
                    
                }
            }
            
        }.resume()
        
    }

    static var isActivated: Bool {
        return true
    }
}
