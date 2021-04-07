/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import BraveShared
import Combine

private let log = Logger.browserLogger

class SearchBackupHelper: TabContentScript {
    fileprivate weak var tab: Tab?
    
    private var cancellable: AnyCancellable?

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
        
        guard var components = URLComponents(string: "https://www.google.com") else { return }
        components.queryItems = [.init(name: "q", value: info.data.query),
                                 .init(name: "hl", value: info.data.language),
                                 .init(name: "gl", value: info.data.country)]
        
        guard let url = components.url else { return }
        var request = URLRequest(url: url)
        
        if let geoHeader = info.data.geo {
            request.addValue(geoHeader, forHTTPHeaderField: "x-geo")
        }
        
        cancellable = URLSession.shared
            .dataTaskPublisher(for: request)
            .tryMap { output -> String in
                guard let base64Data = output.data.websafeBase64String() else {
                    throw "Failed to get backup search data as base64"
                }
                
                guard let response = output.response as? HTTPURLResponse,
                      response.statusCode >= 200 && response.statusCode < 300 else {
                    throw "Invalid response"
                }
                
                return base64Data
            }
            .eraseToAnyPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    log.error("Error: \(error)")
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] data in
                // swiftlint:disable:next safe_javascript
                self?.tab?.webView?.evaluateJavaScript("window.brave_ios.resolve('\(info.id)', '\(data)', null);", completionHandler: { _, error in
                    if let error = error {
                        log.error("Promise resolve error: \(error)")
                    }
                })
            })
            
            
        
        
//        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//            guard let self = self, let data = data else { return }
//
//            if let error = error {
//                log.error("Search backup network error: \(error)")
//                return
//            }
//
//            guard let str = data.websafeBase64String() else {
//                log.error("Failed to get backup search data as base64")
//                return
//            }
//
//            DispatchQueue.main.async {
//                // TODO: Convert to safe javascript.
//                // swiftlint:disable:next safe_javascript
//                self.tab?.webView?.evaluateJavaScript("window.brave_ios.resolve('\(info.id)', '\(str)', null);", completionHandler: { _, error in
//                    if let error = error {
//                        log.error("Promise resolve error: \(error)")
//                    }
//                })
//            }
//
//        }.resume()
        
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
