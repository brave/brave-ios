/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import BraveShared

private let log = Logger.browserLogger

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

    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        guard let info = SearchBackupMessage.from(message: message) else {
            return
        }
        
        let str = "https://www.google.com/search?q=test&hl=us&gl=us"
        let request = URLRequest(url: URL(string: str)!)
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data else { return }
            
            if let error = error {
                log.error("Search backup network error: \(error)")
                return
            }
            
            guard let str = data.websafeBase64String() else {
                log.error("Failed to get backup search data as base64")
                return
            }
            
            DispatchQueue.main.async {
                // TODO: Convert to safe javascript.
                // swiftlint:disable:next safe_javascript
                self.tab?.webView?.evaluateJavaScript("window.brave_ios.resolve('\(info.id)', '\(str)', null);", completionHandler: { _, error in
                    log.error("promise resolve error: \(String(describing: error))")
                })
            }
            
        }.resume()
        
    }

    static var isActivated: Bool {
        return true
    }
    
    private struct SearchBackupMessage: Codable {
        let id: String
        let securitytoken: String
        let data: MessageData
        
        struct MessageData: Codable {
            let query: String
            let language: String
            let country: String
            let geo: String?
        }
        
        static func from(message: WKScriptMessage) -> SearchBackupMessage? {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: message.body, options: .fragmentsAllowed)
                return try JSONDecoder().decode(SearchBackupMessage.self, from: jsonData)
            } catch {
                log.error("Failed to decode message parameters: \(error)")
                return nil
            }
        }
    }
}
