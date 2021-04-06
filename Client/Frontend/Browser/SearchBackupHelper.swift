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
        
        guard let info = SearchBackupMessage.from(message: message) else {
            print("INVALID SCRIPT MESSAGE") //TODO: Log This.
            return
        }
        
        let str = "https://www.google.com/search?q=test&hl=us&gl=us"
        let request = URLRequest(url: URL(string: str)!)
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data else { return }
            
            let str = data.websafeBase64String()!
            
            DispatchQueue.main.async {
                if let error = error {
                    print(error) //TODO: Log Error.
                    
                    // swiftlint:disable:next safe_javascript
                    self.tab?.webView?.evaluateJavaScript("window.brave_ios.resolve('\(info.id)', null, '\(error)');", completionHandler: { _, err in
                        
                        print(err) //TODO: Log Error.
                    })
                } else {
                    // swiftlint:disable:next safe_javascript
                    self.tab?.webView?.evaluateJavaScript("window.brave_ios.resolve('\(info.id)', '\(str)', null);", completionHandler: { _, err in
                        
                        print(err) //TODO: Log Error.
                    })
                }
            }
            
        }.resume()
        
    }

    static var isActivated: Bool {
        return true
    }
    
    private struct SearchBackupMessage: Codable {
        let id: String
        let securitytoken: String
        let data: [String: String]
        
        static func from(message: WKScriptMessage) -> SearchBackupMessage? {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: message.body, options: .fragmentsAllowed)
                return try JSONDecoder().decode(SearchBackupMessage.self, from: jsonData)
            } catch {
                print(error) //TODO: Log Error.
                return nil
            }
        }
    }
}
