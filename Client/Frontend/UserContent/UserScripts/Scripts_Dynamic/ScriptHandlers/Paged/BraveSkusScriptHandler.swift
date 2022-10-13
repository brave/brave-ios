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
import os.log

class BraveSkusScriptHandler: TabContentScript {
  typealias ReplyHandler = (Any?, String?) -> Void
  
  private weak var tab: Tab?
  private let sku: SkusSkusService?
  
  required init(tab: Tab) {
    self.tab = tab
    self.sku = Skus.SkusServiceFactory.get(privateMode: tab.isPrivate)
  }
    
  static let scriptName = "BraveSkusScript"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "\(scriptName)_\(messageUUID)"
  static let scriptSandbox: WKContentWorld = .page
  static let userScript: WKUserScript? = {
    guard var script = loadUserScript(named: scriptName) else {
      return nil
    }
    return WKUserScript.create(source: secureScript(handlerName: messageHandlerName,
                                                    securityToken: scriptId,
                                                    script: script),
                               injectionTime: .atDocumentStart,
                               forMainFrameOnly: true,
                               in: scriptSandbox)
  }()
  
  private enum Method: Int {
    case refreshOrder = 1
    case fetchOrderCredentials = 2
    case prepareCredentialsPresentation = 3
    case credentialsSummary = 4
  }
  
  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
    if !verifyMessage(message: message) {
      assertionFailure("Missing required security token.")
      return
    }
    
    let allowedHosts = DomainUserScript.braveSkus.associatedDomains
    
    guard let requestHost = message.frameInfo.request.url?.host,
          allowedHosts.contains(requestHost),
          message.frameInfo.isMainFrame else {
      Logger.module.error("Brave skus request called from disallowed host")
      return
    }
    
    guard let response = message.body as? [String: Any],
          let methodId = response["method_id"] as? Int,
          let data = response["data"] as? [String: Any] else {
      Logger.module.error("Failed to retrieve method id")
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
    sku?.refreshOrder(domain, orderId: orderId) { completion in
      do {
        guard let data = completion.data(using: .utf8) else { return }
        let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        Logger.module.debug("skus refreshOrder")
        replyHandler(json, nil)
      } catch {
        replyHandler("", nil)
        Logger.module.error("refrshOrder: Failed to decode json: \(error.localizedDescription)")
      }
    }
  }
  
  private func handleFetchOrderCredentials(for orderId: String, domain: String, replyHandler: @escaping ReplyHandler) {
    sku?.fetchOrderCredentials(domain, orderId: orderId) { completion in
      Logger.module.debug("skus fetchOrderCredentials")
      replyHandler(completion, nil)
    }
  }
  
  /// If no reply handler is passed, this function will not send the callback back to the website.
  /// Reason is this method may be called from within another web handler, and the callback can be called only once or it crashes.
  private func handlePrepareCredentialsSummary(for domain: String, path: String, replyHandler: ReplyHandler?) {
    Logger.module.debug("skus prepareCredentialsPresentation")
    sku?.prepareCredentialsPresentation(domain, path: path) { credential in
      if !credential.isEmpty {
        if let vpnCredential = BraveSkusWebHelper.fetchVPNCredential(credential, domain: domain) {
          Preferences.VPN.skusCredential.value = credential
          Preferences.VPN.skusCredentialDomain.value = domain
          
          BraveVPN.setCustomVPNCredential(vpnCredential.credential, environment: vpnCredential.environment)
        }
      } else {
        Logger.module.debug("skus empty credential from prepareCredentialsPresentation call")
      }
      
      replyHandler?(credential, nil)
    }
  }
  
  private func handleCredentialsSummary(for domain: String, replyHandler: @escaping ReplyHandler) {
    sku?.credentialSummary(domain) { [weak self] completion in
      do {
        Logger.module.debug("skus credentialSummary")
        
        guard let data = completion.data(using: .utf8) else { return }
        let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        
        replyHandler(json, nil)
        
        if let expiresDate = (json as? [String: Any])?["expires_at"] as? String,
           let date = BraveSkusWebHelper.milisecondsOptionalDate(from: expiresDate) {
          Preferences.VPN.expirationDate.value = date
        } else {
          assertionFailure("Failed to parse date")
        }
        
        self?.handlePrepareCredentialsSummary(for: domain, path: "*", replyHandler: nil)
      } catch {
        Logger.module.error("refrshOrder: Failed to decode json: \(error.localizedDescription)")
      }
    }
  }
}
