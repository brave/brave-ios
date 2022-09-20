/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import BraveShared
import Shared

private let log = Logger.browserLogger

extension TabContentScript {
  static var uniqueID: String {
    UUID().uuidString.replacingOccurrences(of: "-", with: "")
  }
  
  static var messageUUID: String {
    UUID().uuidString.replacingOccurrences(of: "-", with: "")
  }
  
  static func loadUserScript(named: String) -> String? {
    guard let path = Bundle.current.path(forResource: named, ofType: "js"),
          let source: String = try? String(contentsOfFile: path) else {
      log.error("Failed to load script: \(named).js")
      return nil
    }
    return source
  }
  
  static func secureScript(handlerName: String, securityToken: String, script: String) -> String {
    secureScript(handlerNamesMap: ["$<message_handler>": handlerName], securityToken: securityToken, script: script)
  }
  
  static func secureScript(handlerNamesMap: [String: String], securityToken: String, script: String) -> String {
    var script = script
    for (obfuscatedHandlerName, actualHandlerName) in handlerNamesMap {
      script = script.replacingOccurrences(of: obfuscatedHandlerName, with: actualHandlerName)
    }
    
    let messageHandlers: String = {
      if !handlerNamesMap.isEmpty {
        let handlers = "[\(handlerNamesMap.map({"'\($0.value)'"}).joined(separator: ", "))]"
        return """
        \(handlers).forEach(e => {
          if (webkit.messageHandlers[e]) {
            Object_freeze(webkit.messageHandlers[e]);
            Object_freeze(webkit.messageHandlers[e].postMessage);
          }
        });
        """
      }
      return ""
    }()
    
    return """
    (function() {
      const SECURITY_TOKEN = '\(securityToken)';

      const Object_assign = Object.assign;
      const Object_create = Object.create;
      const Object_defineProperties = Object.defineProperties;
      const Object_getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
      const Object_getOwnPropertyDescriptors = Object.getOwnPropertyDescriptors;
      const Object_getOwnPropertyNames = Object.getOwnPropertyNames;
      const Object_getOwnPropertySymbols = Object.getOwnPropertySymbols;
      const Object_getPrototypeOf = Object.getPrototypeOf;

      const Object_freeze = Object.freeze;
      const Object_seal = Object.seal;
      const Object_preventExtensions = Object.preventExtensions;
    
      const Function_prototype_apply = Function.prototype.apply;
      const Function_prototype_call = Function.prototype.call;
    
      \(messageHandlers)
    
      \(script)
    })();
    """
  }
}
