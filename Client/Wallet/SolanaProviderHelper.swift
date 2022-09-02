// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import BraveCore
import BraveShared
import struct Shared.Logger

private let log = Logger.browserLogger

class SolanaProviderHelper: TabContentScript {
  
  private weak var tab: Tab?
  
  init(tab: Tab) {
    self.tab = tab
  }
  
  static func name() -> String {
    return "walletSolanaProvider"
  }
  
  func scriptMessageHandlerName() -> String? {
    return "walletSolanaProvider_\(UserScriptManager.messageHandlerTokenString)"
  }
  
  static func shouldInjectWalletProvider(_ completion: @escaping (Bool) -> Void) {
    BraveWallet.KeyringServiceFactory.get(privateMode: false)?
      .keyringInfo(BraveWallet.SolanaKeyringId, completion: { keyring in
        completion(keyring.isKeyringCreated)
      })
  }
  
  private struct MessageBody: Decodable {
    enum Method: String, Decodable {
      case connect
      case disconnect
      case signAndSendTransaction
      case signMessage
      case request
      case signTransaction
      case signAllTransactions
    }
    var securityToken: String
    var method: Method
    var args: String
    
    private enum CodingKeys: String, CodingKey {
      case securityToken = "securitytoken"
      case method
      case args
    }
  }
  
  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
    Task { @MainActor in
      guard let tab = tab,
            !tab.isPrivate,
            let provider = tab.walletSolProvider,
            !message.frameInfo.securityOrigin.host.isEmpty, // Fail if there is no last committed URL yet
            message.frameInfo.isMainFrame, // Fail the request came from 3p origin
            JSONSerialization.isValidJSONObject(message.body),
            let messageData = try? JSONSerialization.data(withJSONObject: message.body, options: []),
            let body = try? JSONDecoder().decode(MessageBody.self, from: messageData),
            body.securityToken == UserScriptManager.securityTokenString
      else {
        log.error("Failed to handle solana provider communication")
        return
      }
      
      if message.webView?.url?.isLocal == false,
         message.webView?.hasOnlySecureContent == false { // prevent communication in mixed-content scenarios
        log.error("Failed solana provider communication security test")
        return
      }
      
      if !Preferences.Wallet.allowSolProviderAccess.value {
        log.error("Solana provider access is disabled")
        return
      }
      
      // The web page has communicated with `window.solana`, so we should show the wallet icon
      tab.isWalletIconVisible = true
      
      switch body.method {
      case .connect:
        let param = MojoBase.Value(jsonString: body.args)?.dictionaryValue
        let (status, errorMessage, publicKey) = await provider.connect(param)
        guard status == .success else {
          replyHandler(nil, errorMessage)
          return
        }
        let createdPublicKey = await self.createPublicKey(publicKey)
        replyHandler(createdPublicKey, nil)
        tab.emitSolanaEvent(.connect)
      case .disconnect:
        provider.disconnect()
        tab.emitSolanaEvent(.disconnect)
        replyHandler("", nil)
      case .signAndSendTransaction:
        guard let transaction = MojoBase.Value(jsonString: body.args)?.dictionaryValue,
              let param = signTransactionParam(from: transaction),
              let sendOptions = MojoBase.Value(jsonString: body.args)?.dictionaryValue else {
          replyHandler(nil, "Invalid args")
          return
        }
        let (status, errorMessage, result) = await provider.signAndSendTransaction(param, sendOptions: sendOptions)
        guard status == .success else {
          replyHandler(nil, errorMessage)
          return
        }
        // TODO: Use/reply `result`
        replyHandler("", nil)
      case .signMessage:
        guard let blobMsg = MojoBase.Value(jsonString: body.args)?.binaryValue else {
          replyHandler(nil, "Invalid args")
          return
        }
        let displayEncoding: String? = MojoBase.Value(jsonString: body.args)?.stringValue
        let (status, errorMessage, result) = await provider.signMessage(blobMsg, displayEncoding: displayEncoding)
        guard status == .success,
              let publicKey = result["publicKey"]?.stringValue,
              let signature = result["signature"] else {
          replyHandler(nil, errorMessage)
          return
        }
        let createdPublicKey = await self.createPublicKey(publicKey)
        // TODO: Use/reply `signature`, `createdPublicKey`
        replyHandler("", nil)
      case .request:
        guard let requestPayload = MojoBase.Value(jsonString: body.args)?.dictionaryValue,
              let method = requestPayload["method"]?.stringValue else {
          replyHandler(nil, "Invalid args")
          return
        }
        let (status, errorMessage, result) = await provider.request(requestPayload)
        guard status == .success else {
          replyHandler(nil, errorMessage)
          return
        }
        if method == "connect",
           let publicKey = result["publicKey"]?.stringValue {
          let createdPublicKey = await self.createPublicKey(publicKey)
          replyHandler(createdPublicKey, nil)
        } else {
          // TODO: Handle non-connect request
          replyHandler("", nil)
        }
      case .signTransaction:
        let param = BraveWallet.SolanaSignTransactionParam(encodedSerializedMsg: "", signatures: [])
        let (status, errorMessage, serializedTx) = await provider.signTransaction(param)
        guard status == .success else {
          replyHandler(nil, errorMessage)
          return
        }
        let createdTransaction = await self.createTransaction(serializedTx)
        // TODO: Use/reply `createdTransaction`
        replyHandler("", nil)
      case .signAllTransactions:
        let params: [BraveWallet.SolanaSignTransactionParam] = []
        let (status, errorMessage, serializedTxs) = await provider.signAllTransactions(params)
        guard status == .success else {
          replyHandler(nil, errorMessage)
          return
        }
        let createdTransactions: [String] = await withTaskGroup(of: [String?].self) { @MainActor group -> [String?] in
          for serializedTx in serializedTxs {
            group.addTask { @MainActor in
              return [await self.createTransaction(serializedTx)]
            }
          }
          return await group.reduce([String](), { $0 + $1 })
        }.compactMap { $0 }
        // TODO: Use/reply `createdTransactions`
        replyHandler("", nil)
      }
    }
  }
  
  private func serializedMessage(from transaction: [String: MojoBase.Value]) -> String? {
    // TODO: GetSerializedMessage from transaction
    return nil
  }
  
  private func signatures(from transaction: [String: MojoBase.Value]) -> [BraveWallet.SignaturePubkeyPair] {
    // TODO: GetSignatures from transaction
    return []
  }
  
  private func signTransactionParam(from transaction: [String: MojoBase.Value]) -> BraveWallet.SolanaSignTransactionParam? {
    guard let serializedMessage = serializedMessage(from: transaction) else {
      return nil
    }
    let signatures = signatures(from: transaction)
    return .init(encodedSerializedMsg: serializedMessage, signatures: signatures)
  }
  
  @MainActor private func createPublicKey(_ publicKey: String) async -> String? {
    guard let webView = tab?.webView,
          let userScriptManager = tab?.userScriptManager else {
      return nil
    }
    await userScriptManager.injectSolanaInternalScript()
    let (value, _) = await webView.evaluateSafeJavaScript(
      functionName: "_brave_solana.createPublickey",
      args: [publicKey],
      contentWorld: .page
    )
    guard let dict = value as? [String: Any],
          let createdPublicKey = dict["publicKey"],
          let data = try? JSONSerialization.data(withJSONObject: createdPublicKey, options: [.fragmentsAllowed]) else {
      return nil // `createPublicKey` function failed, or failed to convert to JS data
    }
    let JSEncodedPublicKey = String(data: data, encoding: .utf8) ?? "{}"
    return JSEncodedPublicKey
  }
  
  @MainActor private func createTransaction(_ serializedTx: [NSNumber]) async -> String? {
    guard let webView = tab?.webView,
          let userScriptManager = tab?.userScriptManager else {
      return nil
    }
    await userScriptManager.injectSolanaInternalScript()
    let (value, _) = await webView.evaluateSafeJavaScript(
      functionName: "_brave_solana.createTransaction",
      args: [serializedTx],
      contentWorld: .page
    )
    return value as? String
  }
}
