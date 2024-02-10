// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared
import Preferences
import BraveCore
import os.log

class BraveSearchScriptHandler: TabContentScript {
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
  }
  
  static let scriptName = "BraveSearchScript"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "\(scriptName)_\(messageUUID)"
  static let scriptSandbox: WKContentWorld = .page
  static let userScript: WKUserScript? = {
    guard var script = loadUserScript(named: scriptName) else {
      return nil
    }
    return WKUserScript(source: secureScript(handlerName: messageHandlerName,
                                             securityToken: scriptId,
                                             script: script),
                        injectionTime: .atDocumentStart,
                        forMainFrameOnly: false,
                        in: scriptSandbox)
  }()

  private enum Method: Int {
    case canSetBraveSearchAsDefault = 1
    case setBraveSearchDefault = 2
  }

  private struct MethodModel: Codable {
    enum CodingKeys: String, CodingKey {
      case methodId = "method_id"
    }

    let methodId: Int
  }

  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
    if !verifyMessage(message: message) {
      assertionFailure("Missing required security token.")
      return (nil, nil)
    }
    
    let allowedHosts = DomainUserScript.braveSearchHelper.associatedDomains

    guard let requestHost = message.frameInfo.request.url?.host,
      allowedHosts.contains(requestHost),
      message.frameInfo.isMainFrame
    else {
      Logger.module.error("Backup search request called from disallowed host")
      return (nil, nil)
    }

    guard let data = try? JSONSerialization.data(withJSONObject: message.body, options: []),
      let method = try? JSONDecoder().decode(MethodModel.self, from: data).methodId
    else {
      Logger.module.error("Failed to retrieve method id")
      return (nil, nil)
    }

    switch method {
    case Method.canSetBraveSearchAsDefault.rawValue:
      return await handleCanSetBraveSearchAsDefault()
    case Method.setBraveSearchDefault.rawValue:
      return await handleSetBraveSearchDefault()
    default:
      return (nil, nil)
    }
  }

  @MainActor
  private func handleCanSetBraveSearchAsDefault() async -> (Any?, String?) {
    if tab?.isPrivate == true {
      Logger.module.debug("Private mode detected, skipping setting Brave Search as a default")
      return (false, nil)
    }

    let maximumPromptCount = Preferences.Search.braveSearchDefaultBrowserPromptCount
    if Self.canSetAsDefaultCounter >= maxCountOfDefaultBrowserPromptsPerSession || maximumPromptCount.value >= maxCountOfDefaultBrowserPromptsTotal {
      Logger.module.debug("Maximum number of tries of Brave Search website prompts reached")
      return (false, nil)
    }

    Self.canSetAsDefaultCounter += 1
    maximumPromptCount.value += 1

    let defaultEngine = profile.searchEngines.defaultEngine(forType: .standard).shortName
    let canSetAsDefault = defaultEngine != OpenSearchEngine.EngineNames.brave
    return (canSetAsDefault, nil)
  }

  private func handleSetBraveSearchDefault() async -> (Any?, String?) {
    profile.searchEngines.updateDefaultEngine(OpenSearchEngine.EngineNames.brave, forType: .standard)
    return (nil, nil)
  }
}
