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
        // need to inject `_brave_solana.createPublickey` function
        await tab.userScriptManager?.injectSolanaInternalScript()
        let (status, errorMessage, publicKey) = await provider.connect(param)
        guard status == .success else {
          replyHandler(nil, buildErrorJson(status: status, errorMessage: errorMessage))
          return
        }
        await tab.updateSolanaProperties()
        replyHandler(publicKey, nil)
        if let webView = tab.webView {
          let script = "window.solana.emit('connect', _brave_solana.createPublickey('\(publicKey)'))"
          await webView.evaluateSafeJavaScript(functionName: script, contentWorld: .page, asFunction: false)
        }
      case .disconnect:
        provider.disconnect()
        tab.emitSolanaEvent(.disconnect)
        replyHandler("{:}", nil)
      case .signAndSendTransaction:
        guard let args = body.args,
              let arguments = MojoBase.Value(jsonString: args)?.dictionaryValue,
              let serializedMessage = arguments["serializedMessage"],
              let signatures = arguments["signatures"] else {
          replyHandler(nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
          return
        }
        // get the send options dictionary
        let sendOptions = arguments["sendOptions"]?.dictionaryValue
        let param = createSignTransactionParam(serializedMessage: serializedMessage, signatures: signatures)
        let (status, errorMessage, result) = await provider.signAndSendTransaction(param, sendOptions: sendOptions)
        guard status == .success else {
          replyHandler(nil, buildErrorJson(status: status, errorMessage: errorMessage))
          return
        }
        guard let encodedResult = MojoBase.Value(dictionaryValue: result).jsonObject else {
          replyHandler(nil, buildErrorJson(status: .internalError, errorMessage: errorMessage))
          return
        }
        replyHandler(encodedResult, nil)
      case .signMessage:
        guard let args = body.args,
              let argsList = MojoBase.Value(jsonString: args)?.listValue,
              let messageDict = argsList.first?.dictionaryValue else {
          replyHandler(nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
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
              let signature = result["signature"]?.stringValue,
              let signatureDecoded = NSData(base58Encoded: signature) as? Data else {
          replyHandler(nil, buildErrorJson(status: status, errorMessage: errorMessage))
          return
        }
        let resultDict: [String: Any] = ["publicKey": publicKey, "signature": signatureDecoded.getBytes()]
        guard let encodedResult = JSONSerialization.jsObject(withNative: resultDict) else {
          replyHandler(nil, buildErrorJson(status: .internalError, errorMessage: errorMessage))
          return
        }
        replyHandler(encodedResult, nil)
      case .request:
        guard let args = body.args,
              let argDict = MojoBase.Value(jsonString: args)?.dictionaryValue,
              let method = argDict["method"]?.stringValue else {
          replyHandler(nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
          return
        }
        let (status, errorMessage, result) = await provider.request(argDict)
        guard status == .success else {
          replyHandler(nil, buildErrorJson(status: status, errorMessage: errorMessage))
          return
        }
        if method == "connect",
           let publicKey = result["publicKey"]?.stringValue {
          // need to inject `_brave_solana.createPublickey` function before replying w/ success.
          await tab.userScriptManager?.injectSolanaInternalScript()
          await tab.updateSolanaProperties()
          replyHandler(publicKey, nil)
          if let webView = tab.webView {
            let script = "window.solana.emit('connect', _brave_solana.createPublickey('\(publicKey)'))"
            await webView.evaluateSafeJavaScript(functionName: script, contentWorld: .page, asFunction: false)
          }
        } else {
          if method == "disconnect" {
            tab.emitSolanaEvent(.disconnect)
          }
          // TODO: Handle non-connect/disconnect request. Reply with:
          // - connect => { publicKey: solanaWeb3.PublicKey}
          // - disconnect => {}
          // - signTransaction => { publicKey: <base58 encoded string>,
          //                        signature: <base58 encoded string>}
          // - signAndSendTransaction => { publicKey: <base58 encoded string>,
          //                               signature: <base58 encoded string>}
          // - signAllTransactions => { publicKey: <base58 encoded string>,
          //                            signature: <base58 encoded string>[]}
          // - signMessage => { publicKey: <base58 encoded string>,
          //                    signature: <base58 encoded string>}
          guard let encodedResult = MojoBase.Value(dictionaryValue: result).jsonObject else {
            replyHandler(nil, buildErrorJson(status: .internalError, errorMessage: "Internal error"))
            return
          }
          replyHandler(encodedResult, nil)
        }
      case .signTransaction:
        guard let args = body.args,
              let arguments = MojoBase.Value(jsonString: args)?.dictionaryValue,
              let serializedMessage = arguments["serializedMessage"],
              let signatures = arguments["signatures"] else {
          replyHandler(nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
          return
        }
        let param = createSignTransactionParam(serializedMessage: serializedMessage, signatures: signatures)
        let (status, errorMessage, serializedTx) = await provider.signTransaction(param)
        guard status == .success else {
          replyHandler(nil, buildErrorJson(status: status, errorMessage: errorMessage))
          return
        }
        guard let encodedSerializedTx = JSONSerialization.jsObject(withNative: serializedTx) else {
          replyHandler(nil, buildErrorJson(status: .internalError, errorMessage: "Internal error"))
          return
        }
        replyHandler(encodedSerializedTx, nil)
      case .signAllTransactions:
        guard let args = body.args,
              let transactions = MojoBase.Value(jsonString: args)?.listValue else {
          replyHandler(nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
          return
        }
        let params: [BraveWallet.SolanaSignTransactionParam] = transactions.compactMap { tx in
          guard let transaction = tx.dictionaryValue,
                let serializedMessage = transaction["serializedMessage"],
                let signatures = transaction["signatures"] else {
            return nil
          }
          return createSignTransactionParam(serializedMessage: serializedMessage, signatures: signatures)
        }
        guard !params.isEmpty else {
          replyHandler(nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
          return
        }
        let (status, errorMessage, serializedTxs) = await provider.signAllTransactions(params)
        guard status == .success else {
          replyHandler(nil, buildErrorJson(status: status, errorMessage: errorMessage))
          return
        }
        guard let encodedSerializedTxs = JSONSerialization.jsObject(withNative: serializedTxs) else {
          replyHandler(nil, buildErrorJson(status: .internalError, errorMessage: "Internal error"))
          return
        }
        replyHandler(encodedSerializedTxs, nil)
      }
    }
  }
  
  func createSignTransactionParam(serializedMessage: MojoBase.Value, signatures: MojoBase.Value) -> BraveWallet.SolanaSignTransactionParam {
    // get the serialized message
    let serializedMessageValues = (serializedMessage.dictionaryValue?["data"]?.listValue ?? []).map { UInt8($0.intValue) }
    let encodedSerializedMsg = (Data(serializedMessageValues) as NSData).base58EncodedString()
    // get the signatures array
    let signaturesValues = (signatures.listValue ?? []).compactMap { $0.dictionaryValue }
    let signatures: [BraveWallet.SignaturePubkeyPair] = signaturesValues.map {
      BraveWallet.SignaturePubkeyPair(
        signature: ($0["signature"]?.dictionaryValue?["data"]?.listValue ?? []).map { NSNumber(value: $0.intValue) },
        publicKey: $0["publicKey"]?.stringValue ?? ""
      )
    }
    return .init(encodedSerializedMsg: encodedSerializedMsg, signatures: signatures)
  }
  
  private func buildErrorJson(status: BraveWallet.SolanaProviderError, errorMessage: String) -> String? {
    JSONSerialization.jsObject(withNative: ["code": status.rawValue, "message": errorMessage])
  }
}
