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
    var args: String?
    
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
        var param: [String: MojoBase.Value]?
        if let args = body.args {
          param = MojoBase.Value(jsonString: args)?.dictionaryValue
        }
        let (status, errorMessage, publicKey) = await provider.connect(param)
        guard status == .success else {
          replyHandler(nil, errorMessage)
          return
        }
        // need to inject `_brave_solana.createPublickey` function before replying w/ success.
        await tab.userScriptManager?.injectSolanaInternalScript()
        replyHandler(publicKey, nil)
        tab.updateSolanaProperties()
        if let webView = tab.webView {
          let script = "window.solana.emit('connect', _brave_solana.createPublickey('\(publicKey)'))"
          await webView.evaluateSafeJavaScript(functionName: script, contentWorld: .page, asFunction: false)
        }
      case .disconnect:
        provider.disconnect()
        tab.emitSolanaEvent(.disconnect)
        replyHandler("", nil)
      case .signAndSendTransaction:
        guard let args = body.args,
              let transaction = MojoBase.Value(jsonString: args)?.dictionaryValue,
              let param = signTransactionParam(from: transaction),
              let sendOptions = MojoBase.Value(jsonString: args)?.dictionaryValue else {
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
        guard let args = body.args,
              let argsList = MojoBase.Value(jsonString: args)?.listValue,
              let messageDict = argsList.first?.dictionaryValue else {
          replyHandler(nil, "Invalid args")
          return
        }
        let blobMsg: [NSNumber] =  messageDict.keys
          .sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending })
          .compactMap { messageDict[$0]?.intValue }
          .map { NSNumber(value: $0) }
        let displayEncoding = argsList[safe: 1]?.stringValue
        let (status, errorMessage, result) = await provider.signMessage(blobMsg, displayEncoding: displayEncoding)
        guard status == .success,
              let publicKey = result["publicKey"]?.stringValue,
              let signature = result["signature"]?.stringValue else {
          replyHandler(nil, errorMessage)
          return
        }
        // TODO: signature string needs decoded from base58
        let resultDict = ["publicKey": publicKey, "signature": signature]
        guard let encodedResult = try? JSONSerialization.data(withJSONObject: resultDict, options: .fragmentsAllowed),
              let encodedString = String(data: encodedResult, encoding: .utf8) else {
          replyHandler(nil, "Internal error")
          return
        }
        replyHandler(encodedString, nil)
      case .request:
        guard let args = body.args,
              let argDict = MojoBase.Value(jsonString: args)?.dictionaryValue,
              let method = argDict["method"]?.stringValue else {
          replyHandler(nil, "Invalid args")
          return
        }
        let (status, errorMessage, result) = await provider.request(argDict)
        guard status == .success else {
          replyHandler(nil, errorMessage)
          return
        }
        if method == "connect",
           let publicKey = result["publicKey"]?.stringValue {
          // need to inject `_brave_solana.createPublickey` function before replying w/ success.
          await tab.userScriptManager?.injectSolanaInternalScript()
          replyHandler(publicKey, nil)
          tab.updateSolanaProperties()
          if let webView = tab.webView {
            let script = "window.solana.emit('connect', _brave_solana.createPublickey('\(publicKey)'))"
            await webView.evaluateSafeJavaScript(functionName: script, contentWorld: .page, asFunction: false)
          }
        } else {
          if method == "disconnect" {
            tab.emitSolanaEvent(.disconnect)
          }
          // TODO: Handle non-connect/disconnect request
          replyHandler("{:}", nil)
        }
      case .signTransaction:
        let param = BraveWallet.SolanaSignTransactionParam(encodedSerializedMsg: "", signatures: [])
        let (status, errorMessage, serializedTx) = await provider.signTransaction(param)
        guard status == .success else {
          replyHandler(nil, errorMessage)
          return
        }
        // TODO: Use/reply `window._brave_solana.createTransaction`
        replyHandler("", nil)
      case .signAllTransactions:
        let params: [BraveWallet.SolanaSignTransactionParam] = []
        let (status, errorMessage, serializedTxs) = await provider.signAllTransactions(params)
        guard status == .success else {
          replyHandler(nil, errorMessage)
          return
        }
        // TODO: Use/reply `window._brave_solana.createTransaction` for each `serializedTxs` element
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
}
