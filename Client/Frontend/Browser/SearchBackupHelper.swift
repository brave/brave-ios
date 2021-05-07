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
    
    private enum Method: Int {
        case backupSearch = 1
        case isBraveSearchDefault = 2
        case setBraveSearchDefault = 3
    }
    
    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        var allowedHosts = ["search.brave.com"]
        if !AppConstants.buildChannel.isPublic {
            allowedHosts.append("search-dev.brave.com")
            // TODO: Remove before merge.
            allowedHosts.append("webpiaskownica.000webhostapp.com")
        }
        
        guard let requestHost = message.frameInfo.request.url?.host,
              allowedHosts.contains(requestHost),
              message.frameInfo.isMainFrame else {
            log.error("Backup search request called from disallowed host")
            return
        }
        
        guard let info = SearchBackupMessage.from(message: message) else {
            return
        }
        
        switch info.id {
        case Method.backupSearch.rawValue:
            handleSearchBackup(info)
        case Method.isBraveSearchDefault.rawValue:
            handleIsBraveSearchDefault(info)
        case Method.setBraveSearchDefault.rawValue:
            handleSetBraveSearchDefault(info)
        default:
            break
        }
        
        
    }
    
    private let functionName =
        "window.__firefox__.D\(UserScriptManager.messageHandlerTokenString).resolve"
    
    private func handleSearchBackup(_ info: SearchBackupMessage) {
        guard let data = info.data else {
            assertionFailure("Search backup data is empty.")
            return
        }
        guard var components = URLComponents(string: "https://www.google.com") else { return }
        components.queryItems = [.init(name: "q", value: data.query),
                                 .init(name: "hl", value: data.language),
                                 .init(name: "gl", value: data.country)]
        
        guard let url = components.url else { return }
        var request = URLRequest(url: url)
        
        if let geoHeader = data.geo {
            request.addValue(geoHeader, forHTTPHeaderField: "x-geo")
        }
        
        cancellable = URLSession(configuration: .ephemeral)
            .dataTaskPublisher(for: request)
            .tryMap { output -> String in
                guard let response = output.response as? HTTPURLResponse,
                      let contentType = response.value(forHTTPHeaderField: "Content-Type"),
                      response.statusCode >= 200 && response.statusCode < 300 else {
                    throw "Invalid response"
                }
                
                // For some reason sometimes no matter what headers are set, ISO encoding is returned
                // instead of utf, we check for that to decode it correctly.
                let encoding: String.Encoding =
                    contentType.contains("ISO-8859-1") ? .isoLatin1 : .utf8
                
                guard let stringFromData = String(data: output.data, encoding: encoding) else {
                    throw "Failed to decode string from data"
                }
                
                return stringFromData.javaScriptEscapedString
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
                guard let self = self else { return }
                self.tab?.webView?.evaluateSafeJavaScript(
                    functionName: self.functionName,
                    args: ["'\(info.id)'", data],
                    sandboxed: false,
                    escapeArgs: false) { _, error  in
                    if let error = error {
                        log.error("Promise resolve error: \(error)")
                    }
                }
            })
    }
    
    private func handleIsBraveSearchDefault(_ info: SearchBackupMessage) {
        
    }
    
    private func handleSetBraveSearchDefault(_ info: SearchBackupMessage) {
        
    }
    
    private struct SearchBackupMessage: Codable {
        let id: Int
        let data: MessageData?
        
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
