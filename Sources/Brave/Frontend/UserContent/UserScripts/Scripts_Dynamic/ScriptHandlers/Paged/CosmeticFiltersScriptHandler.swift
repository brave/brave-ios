// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared
import Data
import os.log

/// This handler receives a list of ids and selectors for a given frame for which it is then able to inject scripts and css rules in order to hide certain elements
///
/// The ids and classes are collected in the `SelectorsPollerScript.js` file.
class CosmeticFiltersScriptHandler: TabContentScript {
  struct CosmeticFiltersDTO: Decodable {
    struct CosmeticFiltersDTOData: Decodable, Hashable {
      let sourceURL: String
      let ids: [String]
      let classes: [String]
    }
    
    let securityToken: String
    let data: CosmeticFiltersDTOData
  }
  
  static let scriptName = "SelectorsPollerScript"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "\(scriptName)_\(messageUUID)"
  static let scriptSandbox: WKContentWorld = .defaultClient  
  static let userScript: WKUserScript? = nil
  
  private weak var tab: Tab?
  
  init(tab: Tab) {
    self.tab = tab
  }
  
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
    if !verifyMessage(message: message) {
      assertionFailure("Invalid security token. Fix the `RequestBlocking.js` script")
      return (nil, nil)
    }

    do {
      let data = try JSONSerialization.data(withJSONObject: message.body)
      let dto = try JSONDecoder().decode(CosmeticFiltersDTO.self, from: data)
      
      guard let frameURL = URL(string: dto.data.sourceURL) else {
        return (nil, nil)
      }
      
      return await Task { @MainActor in
        let domain = Domain.getOrCreate(forUrl: frameURL, persistent: self.tab?.isPrivate == true ? false : true)
        let cachedEngines = await AdBlockStats.shared.cachedEngines(for: domain)
        
        let selectorArrays = await cachedEngines.asyncConcurrentCompactMap { cachedEngine -> (selectors: Set<String>, isAlwaysAggressive: Bool)? in
          do {
            guard let selectors = try await cachedEngine.selectorsForCosmeticRules(
              frameURL: frameURL,
              ids: dto.data.ids,
              classes: dto.data.classes
            ) else {
              return nil
            }
            
            return (selectors, cachedEngine.isAlwaysAggressive)
          } catch {
            Logger.module.error("\(error.localizedDescription)")
            return nil
          }
        }
        
        var standardSelectors: Set<String> = []
        var aggressiveSelectors: Set<String> = []
        for tuple in selectorArrays {
          if tuple.isAlwaysAggressive {
            aggressiveSelectors = aggressiveSelectors.union(tuple.selectors)
          } else {
            standardSelectors = standardSelectors.union(tuple.selectors)
          }
        }
        
        return ([
          "aggressiveSelectors": Array(aggressiveSelectors),
          "standardSelectors": Array(standardSelectors)
        ], nil)
      }.value
    } catch {
      assertionFailure("Invalid type of message. Fix the `RequestBlocking.js` script")
      return (nil, nil)
    }
  }
}
