// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import BraveCore

class WalletProviderHelper: TabContentScript {
  private static let supportedSingleArgMethods = [
    "net_listening", "net_peerCount",
    "net_version", "eth_chainId",
    "eth_syncing", "eth_coinbase",
    "eth_mining", "eth_hashrate",
    "eth_accounts", "eth_newBlockFilter",
    "eth_newPendingTransactionFilter"
  ]
  
  let tab: Tab
  
  init(tab: Tab) {
    self.tab = tab
  }
  
  static func name() -> String {
    return "walletProvider"
  }
  
  func scriptMessageHandlerName() -> String? {
    return "walletProvider"
  }
  
  static func shouldInjectWalletProvider(_ completion: @escaping (Bool) -> Void) {
    BraveWallet.KeyringServiceFactory.get(privateMode: false)?
      .keyringInfo(BraveWallet.DefaultKeyringId, completion: { keyring in
        completion(keyring.isKeyringCreated)
      })
  }
  
  func userContentController(
    _ userContentController: WKUserContentController,
    didReceiveScriptMessage message: WKScriptMessage,
    replyHandler: @escaping (Any?, String?) -> Void
  ) {
    enum MessageAction: String {
      case request
      case isConnected
      case enable
      case send
      case sendAsync
      case isUnlocked
    }
    
    guard let provider = tab.walletProvider,
          !message.frameInfo.securityOrigin.host.isEmpty, // Fail if there is no last committed URL yet
          message.frameInfo.isMainFrame, // Fail the request came from 3p origin
          JSONSerialization.isValidJSONObject(message.body),
          let body = message.body as? NSDictionary,
          let name = body["name"] as? String,
          let jsonPayload = body["args"] as? String,
          let action = MessageAction(rawValue: name) else {
      return
    }
    
    // The web page has communicated with `window.ethereum`, so we should show the wallet icon
    tab.isWalletIconVisible = true
    
    let securityOrigin = message.frameInfo.securityOrigin
    let origin = "\(securityOrigin.protocol)://\(securityOrigin.host):\(securityOrigin.port)"
    
    func handleResponse(
      id: MojoBase.Value,
      formedResponse: MojoBase.Value,
      reject: Bool,
      firstAllowedAccount: String,
      updateJSProperties: Bool
    ) {
      if reject {
        replyHandler(nil, formedResponse.jsonString)
      } else {
        replyHandler(formedResponse.jsonObject, nil)
      }
      if updateJSProperties {
        tab.updateEthereumProperties()
      }
    }
    
    switch action {
    case .request:
      guard let requestPayload = MojoBase.Value(jsonString: jsonPayload) else {
        replyHandler(nil, "Invalid args")
        return
      }
      provider.request(requestPayload, origin: origin, completion: handleResponse)
    case .isConnected:
      replyHandler(nil, nil)
    case .enable:
      provider.enable(handleResponse)
    case .sendAsync:
      guard let requestPayload = MojoBase.Value(jsonString: jsonPayload) else {
        replyHandler(nil, "Invalid args")
        return
      }
      provider.request(requestPayload, origin: origin, completion: handleResponse)
    case .send:
      struct SendPayload {
        var method: String
        var params: MojoBase.Value?
        init?(payload: String) {
          guard let jsonValue = MojoBase.Value(jsonString: payload)?.dictionaryValue,
                let method = jsonValue["method"]?.stringValue
          else { return nil }
          self.method = method
          self.params = jsonValue["params"] // can be undefined in JS
        }
      }
      guard let sendPayload = SendPayload(payload: jsonPayload) else {
        replyHandler(nil, "Invalid args")
        return
      }
      
      if sendPayload.method.isEmpty {
        if let params = sendPayload.params, params.tag != .null {
          // Same as sendAsync
          provider.request(params, origin: origin, completion: handleResponse)
        } else {
          // Empty method with no params is not valid
          replyHandler(nil, "Invalid args")
        }
        return
      }
      
      if !Self.supportedSingleArgMethods.contains(sendPayload.method),
         (sendPayload.params == nil || sendPayload.params?.tag == .null) {
        // If its not a single arg supported method and there are no parameters then its not a valid
        // call
        replyHandler(nil, "Invalid args")
        return
      }
      
      provider.send(
        sendPayload.method,
        params: sendPayload.params ?? .init(listValue: []),
        origin: origin,
        completion: handleResponse
      )
    case .isUnlocked:
      provider.isLocked { isLocked in
        replyHandler(!isLocked, nil)
      }
    }
  }
}
