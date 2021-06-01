/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import BraveShared
import Combine

private let log = Logger.browserLogger

class BraveSearchHelper: TabContentScript {
    private weak var tab: Tab?
    private let profile: Profile
    
    private var cancellable: AnyCancellable?
    
    required init(tab: Tab, profile: Profile) {
        self.tab = tab
        self.profile = profile
    }
    
    static func name() -> String {
        return "BraveSearchHelper"
    }
    
    func scriptMessageHandlerName() -> String? {
        return BraveSearchHelper.name()
    }
    
    private enum Method: Int {
        case isBraveSearchDefault = 1
        case setBraveSearchDefault = 2
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
        
        guard let method = (message.body as? [String: Any])?["method_id"] as? Int else {
            log.error("Failed to retrieve method id")
            return
        }
        
        switch method {
        case Method.isBraveSearchDefault.rawValue:
            handleIsBraveSearchDefault(methodId: method)
        case Method.setBraveSearchDefault.rawValue:
            handleSetBraveSearchDefault(methodId: method)
        default:
            break
        }
    }
    
    private func handleIsBraveSearchDefault(methodId: Int) {
        let isDefault =
            profile.searchEngines.defaultEngine().shortName.lowercased() == "brave"
        
        callback(methodId: methodId, result: isDefault)
    }
    
    private func handleSetBraveSearchDefault(methodId: Int) {
        // Tight coupling, in future version this should be removed.
        // One idea of refactor would be to move `openSearchEngine` to `Tab`
        // Then we would have easier time accessing it.
        guard let bvc =
                (UIApplication.shared.delegate as? AppDelegate)?.browserViewController else {
            callback(methodId: methodId, result: false)
            return
        }
        
        if profile.searchEngines.engineExists(withName: "Brave") {
            let engineType: DefaultEngineType =
                PrivateBrowsingManager.shared.isPrivateBrowsing ? .privateMode : .standard
            
            profile.searchEngines.updateDefaultEngine(OpenSearchEngine.EngineNames.brave, forType: engineType)
            callback(methodId: methodId, result: true)
        } else {
            bvc.addCustomSearchEngineForFocusedElement(setAsDefault: true) { [weak self] completion in
                self?.callback(methodId: methodId, result: completion)
            }
        }
        
        
    }
    
    private func callback(methodId: Int, result: Bool) {
        let functionName =
            "window.__firefox__.D\(UserScriptManager.messageHandlerTokenString).resolve"
        
        self.tab?.webView?.evaluateSafeJavaScript(
            functionName: functionName,
            args: ["'\(methodId)'", "\(result)"],
            sandboxed: false,
            escapeArgs: false)
    }
}
