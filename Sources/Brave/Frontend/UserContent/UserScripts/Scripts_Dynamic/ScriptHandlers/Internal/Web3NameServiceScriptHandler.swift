/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit
import os.log
import BraveWallet

protocol Web3NameServiceScriptHandlerDelegate: AnyObject {
  func web3NameServiceDecisionHandler(_ proceed: Bool, web3Service: Web3Service, originalURL: URL, visitType: VisitType)
}

class Web3NameServiceScriptHandler: TabContentScript {
  weak var delegate: Web3NameServiceScriptHandlerDelegate?
  var originalURL: URL?
  var visitType: VisitType = .unknown
  fileprivate weak var tab: Tab?
  
  required init(tab: Tab) {
    self.tab = tab
  }
  
  static let scriptName = "Web3NameServiceScript"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "\(scriptName)_\(messageUUID)"
  static let scriptSandbox: WKContentWorld = .page
  static let userScript: WKUserScript? = nil
  
  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
    defer { replyHandler(nil, nil) }
    
    guard let params = message.body as? [String: String], let originalURL = originalURL else {
      return
    }
    
    if params["type"] == "Disable",
       let serviceId = params["service_id"],
       let service = Web3Service(rawValue: serviceId) {
      delegate?.web3NameServiceDecisionHandler(false, web3Service: service, originalURL: originalURL, visitType: visitType)
    } else if params["type"] == "Proceed",
              let serviceId = params["service_id"],
              let service = Web3Service(rawValue: serviceId) {
      delegate?.web3NameServiceDecisionHandler(true, web3Service: service, originalURL: originalURL, visitType: visitType)
    } else {
      assertionFailure("Invalid message: \(message.body)")
    }
  }
}
