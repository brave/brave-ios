// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared
import os.log

/// This handler receives a list of ids and selectors for a given frame for which it is then able to inject scripts and css rules in order to hide certain elements
///
/// The ids and classes are collected in the `SelectorsPollerScript.js` file.
class CosmeticFiltersScriptHandler: TabContentScript {
  private struct CosmeticFiltersDTO: Decodable {
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
  
  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
    if !verifyMessage(message: message) {
      assertionFailure("Invalid security token. Fix the `RequestBlocking.js` script")
      replyHandler(nil, nil)
      return
    }

    do {
      let data = try JSONSerialization.data(withJSONObject: message.body)
      let dto = try JSONDecoder().decode(CosmeticFiltersDTO.self, from: data)
      
      guard let frameURL = URL(string: dto.data.sourceURL) else {
        replyHandler(nil, nil)
        return
      }
      
      let selectors = AdBlockStats.shared.cachedEngines.flatMap { cachedEngine -> [String] in
        do {
          return try cachedEngine.selectorsForCosmeticRules(
            frameURL: frameURL,
            ids: dto.data.ids,
            classes: dto.data.classes
          )
        } catch {
          Logger.module.error("\(error.localizedDescription)")
          return []
        }
      }
      
      replyHandler(selectors, nil)
    } catch {
      assertionFailure("Invalid type of message. Fix the `RequestBlocking.js` script")
      replyHandler(nil, nil)
    }
  }
}
