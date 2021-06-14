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
    
    /// Tracks how many in current browsing session the user has been prompted to set Brave Search as a default
    /// while on one of Brave Search websites.
    static var canSetAsDefaultCounter = 0
    /// How many times user is shown the default browser prompt on Brave Search websites.
    private let maxCountOfDefaultBrowserPromptsPerSession = 3
    /// How many times user is shown the default browser prompt in total, this does not reset between app launches.
    private let maxCountOfDefaultBrowserPromptsTotal = 10
    
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
        case canSetBraveSearchAsDefault = 1
        case setBraveSearchDefault = 2
    }
    
    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        var allowedHosts = ["search.brave.com",
                            "search-dev.brave.com",
                            "search-dev-local.brave.com",
                            "search.brave.software",
                            "search.bravesoftware.com"]
        if !AppConstants.buildChannel.isPublic {
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
        case Method.canSetBraveSearchAsDefault.rawValue:
            handleCanSetBraveSearchAsDefault(methodId: method)
        case Method.setBraveSearchDefault.rawValue:
            handleSetBraveSearchDefault(methodId: method)
        default:
            break
        }
    }
    
    private func handleCanSetBraveSearchAsDefault(methodId: Int) {
        
        if PrivateBrowsingManager.shared.isPrivateBrowsing {
            log.debug("Private mode deteceted, not trying to set Brave Search as a default")
            callback(methodId: methodId, result: false)
            return
        }
        
        let maximumPromptCount = Preferences.Search.braveSearchDefaultBrowserPromptCount
        if Self.canSetAsDefaultCounter >= maxCountOfDefaultBrowserPromptsPerSession ||
            maximumPromptCount.value >= maxCountOfDefaultBrowserPromptsTotal {
            log.debug("Maximum number of tries of Brave Search website prompts reached")
            callback(methodId: methodId, result: false)
            return
        }
        
        Self.canSetAsDefaultCounter += 1
        maximumPromptCount.value += 1
        
        let defaultEngine = profile.searchEngines.defaultEngine(forType: .standard).shortName
        let canSetAsDefault = defaultEngine != OpenSearchEngine.EngineNames.brave
        
        callback(methodId: methodId, result: canSetAsDefault)
    }
    
    private func handleSetBraveSearchDefault(methodId: Int) {
        profile.searchEngines.updateDefaultEngine(OpenSearchEngine.EngineNames.brave, forType: .standard)
        callback(methodId: methodId, result: nil)
    }
    
    private func callback(methodId: Int, result: Bool?) {
        let functionName =
            "window.__firefox__.D\(UserScriptManager.messageHandlerTokenString).resolve"
        
        var args = ["'\(methodId)'"]
        if let result = result {
            args.append("\(result)")
        }
        
        self.tab?.webView?.evaluateSafeJavaScript(
            functionName: functionName,
            args: args,
            sandboxed: false,
            escapeArgs: false)
    }
}
