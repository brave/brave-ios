// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared
import BraveShared
import BraveCore

private let log = Logger.browserLogger

class BraveServicesScriptHandler: TabContentScript {
    private weak var tab: Tab?
    private let profile: Profile
    private weak var rewards: BraveRewards?
    
    /// Tracks how many in current browsing session the user has been prompted to set Brave Search as a default
    /// while on one of Brave Search websites.
    private static var canSetAsDefaultCounter = 0
    /// How many times user should be shown the default browser prompt on Brave Search websites.
    private let maxCountOfDefaultBrowserPromptsPerSession = 3
    /// How many times user is shown the default browser prompt in total, this does not reset between app launches.
    private let maxCountOfDefaultBrowserPromptsTotal = 10
    
    required init(tab: Tab, profile: Profile, rewards: BraveRewards) {
        self.tab = tab
        self.profile = profile
        self.rewards = rewards
        
        tab.rewardsEnabledCallback = { [weak self] success in
            self?.callback(methodId: Method.braveRequestAdsEnabled.rawValue, result: success)
        }
    }
    
    static func name() -> String { "BraveServicesHelper" }
    
    func scriptMessageHandlerName() -> String? { BraveServicesScriptHandler.name() }
    
    private enum Method: Int {
        case canSetBraveSearchAsDefault = 1
        case setBraveSearchDefault = 2
        case braveRequestAdsEnabled = 3
    }
    
    private struct MethodModel: Codable {
        enum CodingKeys: String, CodingKey {
            case methodId = "method_id"
        }
        
        let methodId: Int
    }
    
    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        let allowedBaseDomains = ["brave.com",
                                  "brave.software",
                                  "bravesoftware.com",
                                  // TODO: REMOVE
                                  "iccub.github.io"]
        
        guard let requestHost = message.frameInfo.request.url?.baseDomain,
              allowedBaseDomains.contains(requestHost),
              message.frameInfo.isMainFrame else {
            log.error("Backup search request called from disallowed host")
            return
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: message.body, options: []),
              let method = try? JSONDecoder().decode(MethodModel.self, from: data).methodId else {
            log.error("Failed to retrieve method id")
            return
        }
        
        switch method {
        case Method.canSetBraveSearchAsDefault.rawValue:
            handleCanSetBraveSearchAsDefault(methodId: method)
        case Method.setBraveSearchDefault.rawValue:
            handleSetBraveSearchDefault(methodId: method)
        case Method.braveRequestAdsEnabled.rawValue:
            handleBraveRequestAdsEnabled(methodId: method)
        default:
            break
        }
    }
    
    private func handleCanSetBraveSearchAsDefault(methodId: Int) {
        
        if PrivateBrowsingManager.shared.isPrivateBrowsing {
            log.debug("Private mode detected, skipping setting Brave Search as a default")
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
    
    private func handleBraveRequestAdsEnabled(methodId: Int) {
        
        if PrivateBrowsingManager.shared.isPrivateBrowsing {
            callback(methodId: methodId, result: false)
            return
        }
        
        guard let rewards = rewards else {
            callback(methodId: methodId, result: false)
            return
        }
        
        if rewards.isEnabled {
            callback(methodId: methodId, result: true)
            return
        }
        
        // If rewards are disabled we show a Rewards panel,
        // The `callback` will be called from other place.
        if let tab = tab {
            tab.tabDelegate?.showRequestRewardsPanel(tab)
        }
    }
    
    private func callback(methodId: Int, result: Bool?) {
        let functionName =
            "window.__firefox__.BSH\(UserScriptManager.messageHandlerTokenString).resolve"
        
        var args: [Any] = [methodId]
        if let result = result {
            args.append(result)
        }
        
        self.tab?.webView?.evaluateSafeJavaScript(
            functionName: functionName,
            args: args,
            sandboxed: false)
    }
}
