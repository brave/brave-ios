// Copyright 2021 The Brave Authors. All rights reserved.
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
  private weak var tab: Tab?
  
  private let sku: SkusSkusService?
  
  required init(tab: Tab) {
    self.tab = tab
    self.sku = Skus.SkusServiceFactory.get(privateMode: tab.isPrivate)
  }
  
  static func name() -> String { "BraveSkusHelper" }
  
  func scriptMessageHandlerName() -> String? { BraveSkusScriptHandler.name() }
  
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
        handleRefreshOrder(for: orderId)
      }
    case Method.fetchOrderCredentials.rawValue:
      if let orderId = data["orderId"] as? String {
        handleFetchOrderCredentials(for: orderId)
      }
    case Method.prepareCredentialsPresentation.rawValue:
      if let domain = data["domain"] as? String, let path = data["path"] as? String {
        handlePrepareCredentialsSummary(for: domain, path: path)
      }
    case Method.credentialsSummary.rawValue:
      if let domain = data["domain"] as? String {
        handleCredentialsSummary(for: domain)
      }
    default:
      assertionFailure("Failure, the website called unhandled method with id: \(methodId)")
    }
  }
  
  private func handleRefreshOrder(for orderId: String) {
    sku?.refreshOrder(orderId) { [weak self] completion in
      do {
        guard let data = completion.data(using: .utf8) else { return }
        let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        log.debug("skus refreshOrder")
        self?.callback(methodId: 1, result: json)
      } catch {
        log.error("refrshOrder: Failed to decode json: \(error)")
      }
    }
  }
  
  private func handleFetchOrderCredentials(for orderId: String) {
    sku?.fetchOrderCredentials(orderId) { [weak self] completion in
      log.debug("skus fetchOrderCredentials")
      self?.callback(methodId: 2, result: completion)
    }
  }
  
  private func handlePrepareCredentialsSummary(for domain: String, path: String) {
    sku?.prepareCredentialsPresentation(domain, path: path) { [weak self] credential in
      if !credential.isEmpty {
        BraveVPN.setSkusCredential(credential)
      }
      
      self?.callback(methodId: 3, result: credential)
    }
  }
  
  private func handleCredentialsSummary(for domain: String) {
    sku?.credentialSummary(domain) { [weak self] completion in
      do {
        log.debug("skus credentialSummary")
        
        guard let data = completion.data(using: .utf8) else { return }
        let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        self?.callback(methodId: 4, result: json)
        
        if let expiresDate = (json as? [String: Any])?["expires_at"] as? String {
          let formatter = DateFormatter()
          formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
          if let date = formatter.date(from: expiresDate) {
            Preferences.VPN.expirationDate.value = date
          } else {
            assertionFailure("Failed to parse date: \(expiresDate)")
          }
        }
        
        self?.handlePrepareCredentialsSummary(for: domain, path: "*")
      } catch {
        log.error("refrshOrder: Failed to decode json: \(error)")
      }
    }
  }
  
  private func callback(methodId: Int, result: Any) {
    let functionName =
    "window.__firefox__.BSKU\(UserScriptManager.messageHandlerTokenString).resolve"
    
    let args: [Any] = ["\(methodId)", result]
    
    self.tab?.webView?.evaluateSafeJavaScript(
      functionName: functionName,
      args: args,
      contentWorld: .page)
  }
}
