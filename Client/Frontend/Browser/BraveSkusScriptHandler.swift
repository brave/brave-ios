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

class BraveSkusScriptHandler: TabContentScript {
    private weak var tab: Tab?
    
    required init(tab: Tab) {
        self.tab = tab
    }
    
    static func name() -> String { "BraveSkusHelper" }
    
    func scriptMessageHandlerName() -> String? { BraveSkusScriptHandler.name() }
    
    private enum Method: Int {
        case refreshOrder = 1
        case fetchOrderCredentials = 2
        case prepareCredentialsPresentation = 3
        case credentialsSummary = 4
    }
    
    private struct MethodModel: Codable {
        enum CodingKeys: String, CodingKey {
            case methodId = "method_id"
            case data
        }
        
        let methodId: Int
        // FIXME: Perhaps make it Any for more flexibility
        let data: String
    }
    
    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        let allowedHosts = DomainUserScript.braveSkus.associatedDomains
        
        guard let requestHost = message.frameInfo.request.url?.host,
              allowedHosts.contains(requestHost),
              message.frameInfo.isMainFrame else {
            log.error("Brave skus request called from disallowed host")
            return
        }
        
        guard let response = try? JSONSerialization.data(withJSONObject: message.body, options: []),
              let model = try? JSONDecoder().decode(MethodModel.self, from: response) else {
            log.error("Failed to retrieve method id")
            return
        }
        
        switch model.methodId {
        case Method.refreshOrder.rawValue:
            handleRefreshOrder(for: model.data)
        case Method.fetchOrderCredentials.rawValue:
            handleFetchOrderCredentials(for: model.data)
        case Method.prepareCredentialsPresentation.rawValue:
            handlePrepareCredentialsSummary(for: model.data)
        case Method.credentialsSummary.rawValue:
            handleCredentialsSummary(for: model.data)
        default:
            break
        }
    }
    
    private func handleRefreshOrder(for orderId: String) {
        guard let sku = Skus.SkusServiceFactory.get(privateMode: PrivateBrowsingManager.shared.isPrivateBrowsing) else {
            return
        }
        
        sku.refreshOrder(orderId) { [weak self] completion in
            self?.callback(methodId: 1, result: completion)
        }
    }
    
    private func handleFetchOrderCredentials(for orderId: String) {
        guard let sku = Skus.SkusServiceFactory.get(privateMode: PrivateBrowsingManager.shared.isPrivateBrowsing) else {
            return
        }
        
        sku.fetchOrderCredentials(orderId) { [weak self] completion in
            self?.callback(methodId: 2, result: completion)
        }
    }
    
    private func handlePrepareCredentialsSummary(for domain: String) {
        guard let sku = Skus.SkusServiceFactory.get(privateMode: PrivateBrowsingManager.shared.isPrivateBrowsing) else {
            return
        }
        
        sku.prepareCredentialsPresentation(domain, path: "") { [weak self] completion in
            self?.callback(methodId: 3, result: completion)
        }
    }
    
    private func handleCredentialsSummary(for domain: String) {
        guard let sku = Skus.SkusServiceFactory.get(privateMode: PrivateBrowsingManager.shared.isPrivateBrowsing) else {
            return
        }
        
        sku.credentialSummary(domain) { [weak self] completion in
            self?.callback(methodId: 4, result: completion)
        }
    }
    
    private func callback(methodId: Int, result: String) {
        let functionName =
            "window.__firefox__.BSKU\(UserScriptManager.messageHandlerTokenString).resolve"
        
        let args: [Any] = [methodId, result]
        
        self.tab?.webView?.evaluateSafeJavaScript(
            functionName: functionName,
            args: args,
            contentWorld: .page)
    }
}
