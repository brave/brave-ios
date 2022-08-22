// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared
import BraveShared
import BraveCore
import BraveVPN

private let log = Logger.browserLogger

class BraveSkusScriptHandler: TabContentScript {
  typealias ReplyHandler = (Any?, String?) -> Void
  
  private weak var tab: Tab?
  
  private let sku: SkusSkusService?
  
  required init(tab: Tab) {
    self.tab = tab
    self.sku = Skus.SkusServiceFactory.get(privateMode: tab.isPrivate)
  }
  
  static func name() -> String { "BraveSkusHelper" }
  
  func scriptMessageHandlerName() -> String? { "braveSkusHelper" }
  
  private enum Method: Int {
    case refreshOrder = 1
    case fetchOrderCredentials = 2
    case prepareCredentialsPresentation = 3
    case credentialsSummary = 4
  }
  
  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
    let allowedHosts = DomainUserScript.braveSkus.associatedDomains
    
    guard let requestHost = message.frameInfo.request.url?.host,
          allowedHosts.contains(requestHost),
          message.frameInfo.isMainFrame else {
      log.error("Brave skus request called from disallowed host")
      return
    }
    
    guard let response = message.body as? [String: Any],
          let methodId = response["method_id"] as? Int,
          let data = response["data"] as? [String: Any] else {
      log.error("Failed to retrieve method id")
      return
    }
    
    switch methodId {
    case Method.refreshOrder.rawValue:
      if let orderId = data["orderId"] as? String {
        handleRefreshOrder(for: orderId, domain: requestHost, replyHandler: replyHandler)
      }
    case Method.fetchOrderCredentials.rawValue:
      if let orderId = data["orderId"] as? String {
        handleFetchOrderCredentials(for: orderId, domain: requestHost, replyHandler: replyHandler)
      }
    case Method.prepareCredentialsPresentation.rawValue:
      if let domain = data["domain"] as? String, let path = data["path"] as? String {
        handlePrepareCredentialsSummary(for: domain, path: path, replyHandler: replyHandler)
      }
    case Method.credentialsSummary.rawValue:
      if let domain = data["domain"] as? String {
        handleCredentialsSummary(for: domain, replyHandler: replyHandler)
      }
    default:
      assertionFailure("Failure, the website called unhandled method with id: \(methodId)")
    }
  }
  
  private func handleRefreshOrder(for orderId: String, domain: String, replyHandler: @escaping ReplyHandler) {
    sku?.refreshOrder(domain, orderId: orderId) { [weak self] completion in
      do {
        guard let data = completion.data(using: .utf8) else { return }
        let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        log.debug("skus refreshOrder")
        self?.callback(methodId: 1, result: json, replyHandler: replyHandler)
      } catch {
        self?.callback(methodId: 1, result: "", replyHandler: replyHandler)
        log.error("refrshOrder: Failed to decode json: \(error)")
      }
    }
  }
  
  private func handleFetchOrderCredentials(for orderId: String, domain: String, replyHandler: @escaping ReplyHandler) {
    sku?.fetchOrderCredentials(domain, orderId: orderId) { [weak self] completion in
      log.debug("skus fetchOrderCredentials")
      self?.callback(methodId: 2, result: completion, replyHandler: replyHandler)
    }
  }
  
  private func handlePrepareCredentialsSummary(for domain: String, path: String, replyHandler: @escaping ReplyHandler) {
    log.debug("skus prepareCredentialsPresentation")
    sku?.prepareCredentialsPresentation(domain, path: path) { [weak self] credential in
      if !credential.isEmpty {
        if let vpnCredential = BraveSkusWebHelper.fetchVPNCredential(credential, domain: domain) {
          Preferences.VPN.skusCredential.value = credential
          Preferences.VPN.skusCredentialDomain.value = domain
          
          BraveVPN.setCustomVPNCredential(vpnCredential.credential, environment: vpnCredential.environment)
        }
      } else {
        //assertionFailure()
      }
      
      //self?.callback(methodId: 3, result: credential, replyHandler: replyHandler)
    }
  }
  
  private func handleCredentialsSummary(for domain: String, replyHandler: @escaping ReplyHandler) {
    sku?.credentialSummary(domain) { [weak self] completion in
      do {
        log.debug("skus credentialSummary")
        
        guard let data = completion.data(using: .utf8) else { return }
        let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        self?.callback(methodId: 4, result: json, replyHandler: replyHandler)
        
        if let expiresDate = (json as? [String: Any])?["expires_at"] as? String,
           let date = BraveSkusWebHelper.milisecondsOptionalDate(from: expiresDate) {
          Preferences.VPN.expirationDate.value = date
        } else {
          //assertionFailure("Failed to parse date")
        }
        
        self?.handlePrepareCredentialsSummary(for: domain, path: "*", replyHandler: replyHandler)
      } catch {
        log.error("refrshOrder: Failed to decode json: \(error)")
      }
    }
  }
  
  private func callback(methodId: Int, result: Any, replyHandler: ReplyHandler) {
    //let args: [Any] = ["\(methodId)", result]
    
    replyHandler(result, nil)
  }
}
