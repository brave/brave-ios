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
  
  fileprivate enum Keys: String {
    case connect
    case disconnect
    case signMessage
    case message
    case serializedMessage
    case signatures
    case sendOptions
    case publicKey
    case signature
    case method
    case params
    case code
    case data
  }
  
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
        let (publicKey, error) = await connect(args: body.args)
        replyHandler(publicKey, error)
        if let publicKey = publicKey as? String {
          await emitConnectEvent(publicKey: publicKey)
        }
      case .disconnect:
        provider.disconnect()
        tab.emitSolanaEvent(.disconnect)
        replyHandler("{:}", nil)
      case .signAndSendTransaction:
        let (result, error) = await signAndSendTransaction(args: body.args)
        replyHandler(result, error)
      case .signMessage:
        let (result, error) = await signMessage(args: body.args)
        replyHandler(result, error)
      case .request:
        guard let args = body.args,
              let argDict = MojoBase.Value(jsonString: args)?.dictionaryValue,
              let method = argDict[Keys.method.rawValue]?.stringValue else {
          replyHandler(nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
          return
        }
        let (result, error) = await request(args: body.args)
        replyHandler(result, error)
        if method == Keys.connect.rawValue, let publicKey = result as? String {
          await emitConnectEvent(publicKey: publicKey)
        } else if method == Keys.disconnect.rawValue {
          tab.emitSolanaEvent(.disconnect)
        }
      case .signTransaction:
        let (result, error) = await signTransaction(args: body.args)
        replyHandler(result, error)
      case .signAllTransactions:
        let (result, error) = await signAllTransactions(args: body.args)
        replyHandler(result, error)
      }
    }
  }
  
  /// Given optional args `{onlyIfTrusted: Bool}`, will return the base 58 encoded public key for success or the error dictionary for failures.
  @MainActor func connect(args: String?) async -> (Any?, String?) {
    guard let tab = tab, let provider = tab.walletSolProvider else {
      return (nil, buildErrorJson(status: .internalError, errorMessage: ""))
    }
    var param: [String: MojoBase.Value]?
    if let args = args {
      param = MojoBase.Value(jsonString: args)?.dictionaryValue
    }
    // need to inject `_brave_solana.createPublickey` function
    await tab.userScriptManager?.injectSolanaInternalScript()
    let (status, errorMessage, publicKey) = await provider.connect(param)
    guard status == .success else {
      return (nil, buildErrorJson(status: status, errorMessage: errorMessage))
    }
    await tab.updateSolanaProperties()
    return (publicKey, nil)
  }
  
  /// Given args `{serializedMessage: [Uint8], signatures: [Buffer], sendOptions: [:]}`, will return
  /// dictionary `{publicKey: <base58 encoded string>, signature: <base58 encoded string>}` for success
  /// or an error dictionary for failures.
  @MainActor func signAndSendTransaction(args: String?) async -> (Any?, String?) {
    guard let args = args,
          let arguments = MojoBase.Value(jsonString: args)?.dictionaryValue,
          let serializedMessage = arguments[Keys.serializedMessage.rawValue],
          let signatures = arguments[Keys.signatures.rawValue],
          let provider = tab?.walletSolProvider else {
      return (nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
    }
    // get the send options dictionary
    let sendOptions = arguments[Keys.sendOptions.rawValue]?.dictionaryValue
    let param = createSignTransactionParam(serializedMessage: serializedMessage, signatures: signatures)
    let (status, errorMessage, result) = await provider.signAndSendTransaction(param, sendOptions: sendOptions)
    guard status == .success else {
      return (nil, buildErrorJson(status: status, errorMessage: errorMessage))
    }
    guard let encodedResult = MojoBase.Value(dictionaryValue: result).jsonObject else {
      return (nil, buildErrorJson(status: .internalError, errorMessage: errorMessage))
    }
    return (encodedResult, nil)
  }
  
  /// Given args `{[[UInt8], String]}` (second arg optional), will return
  /// `{publicKey: <base58 encoded String>, signature: <base 58 decoded list>}` for success flow
  /// or an error dictionary for failures
  @MainActor func signMessage(args: String?) async -> (Any?, String?) {
    guard let args = args,
          let argsList = MojoBase.Value(jsonString: args)?.listValue,
          let blobMsg = argsList.first?.numberArray,
          let provider = tab?.walletSolProvider else {
      return (nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
    }
    let displayEncoding = argsList[safe: 1]?.stringValue
    let (status, errorMessage, result) = await provider.signMessage(blobMsg, displayEncoding: displayEncoding)
    guard status == .success,
          let publicKey = result[Keys.publicKey.rawValue]?.stringValue,
          let signature = result[Keys.signature.rawValue]?.stringValue,
          let signatureEncoded = NSData(base58Encoded: signature) as? Data else {
      return (nil, buildErrorJson(status: status, errorMessage: errorMessage))
    }
    let resultDict: [String: Any] = [Keys.publicKey.rawValue: publicKey, Keys.signature.rawValue: signatureEncoded.getBytes()]
    guard let encodedResult = JSONSerialization.jsObject(withNative: resultDict) else {
      return (nil, buildErrorJson(status: .internalError, errorMessage: errorMessage))
    }
    return (encodedResult, nil)
  }
  
  /// Given a request arg `{method: String, params: {}}`, will encode the response as a json object for success
  /// or provide an error dictionary for failures
  @MainActor func request(args: String?) async -> (Any?, String?) {
    guard let args = args,
          var argDict = MojoBase.Value(jsonString: args)?.dictionaryValue,
          let method = argDict[Keys.method.rawValue]?.stringValue,
          let tab = tab,
          let provider = tab.walletSolProvider else {
      return (nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
    }
    if method == Keys.signMessage.rawValue,
       let blobMsg = argDict[Keys.params.rawValue]?.dictionaryValue?[Keys.message.rawValue]?.numberArray {
      /* Convert from [UInt8] to data / blob (Mojo binaryValue). */
      var updatedParamsDict = argDict[Keys.params.rawValue]?.dictionaryValue ?? [:]
      updatedParamsDict[Keys.message.rawValue] = MojoBase.Value(binaryValue: blobMsg)
      argDict[Keys.params.rawValue] = MojoBase.Value(dictionaryValue: updatedParamsDict)
    }
    let (status, errorMessage, result) = await provider.request(argDict)
    guard status == .success else {
      return (nil, buildErrorJson(status: status, errorMessage: errorMessage))
    }
    if method == Keys.connect.rawValue,
       let publicKey = result[Keys.publicKey.rawValue]?.stringValue {
      // need to inject `_brave_solana.createPublickey` function before replying w/ success.
      await tab.userScriptManager?.injectSolanaInternalScript()
      await tab.updateSolanaProperties()
      return (publicKey, nil)
    } else {
      guard let encodedResult = MojoBase.Value(dictionaryValue: result).jsonObject else {
        return (nil, buildErrorJson(status: .internalError, errorMessage: "Internal error"))
      }
      return (encodedResult, nil)
    }
  }
  
  /// Given args `{serializedMessage: Buffer, signatures: {publicKey: String, signature: Buffer}}`,
  /// will encoded the response as a json object for success or provide an error dictionary for failures
  @MainActor func signTransaction(args: String?) async -> (Any?, String?) {
    guard let args = args,
          let arguments = MojoBase.Value(jsonString: args)?.dictionaryValue,
          let serializedMessage = arguments[Keys.serializedMessage.rawValue],
          let signatures = arguments[Keys.signatures.rawValue],
          let provider = tab?.walletSolProvider else {
      return (nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
    }
    let param = createSignTransactionParam(serializedMessage: serializedMessage, signatures: signatures)
    let (status, errorMessage, serializedTx) = await provider.signTransaction(param)
    guard status == .success else {
      return (nil, buildErrorJson(status: status, errorMessage: errorMessage))
    }
    guard let encodedSerializedTx = JSONSerialization.jsObject(withNative: serializedTx) else {
      return (nil, buildErrorJson(status: .internalError, errorMessage: "Internal error"))
    }
    return (encodedSerializedTx, nil)
  }
  
  /// Given args `[{serializedMessage: Buffer, signatures: {publicKey: String, signature: Buffer}}]`,
  /// will encoded the response as a json object for success or provide an error dictionary for failures
  @MainActor func signAllTransactions(args: String?) async -> (Any?, String?) {
    guard let args = args,
          let transactions = MojoBase.Value(jsonString: args)?.listValue,
          let provider = tab?.walletSolProvider else {
      return (nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
    }
    let params: [BraveWallet.SolanaSignTransactionParam] = transactions.compactMap { tx in
      guard let transaction = tx.dictionaryValue,
            let serializedMessage = transaction[Keys.serializedMessage.rawValue],
            let signatures = transaction[Keys.signatures.rawValue] else {
        return nil
      }
      return createSignTransactionParam(serializedMessage: serializedMessage, signatures: signatures)
    }
    guard !params.isEmpty else {
      return (nil, buildErrorJson(status: .invalidParams, errorMessage: "Invalid args"))
    }
    let (status, errorMessage, serializedTxs) = await provider.signAllTransactions(params)
    guard status == .success else {
      return (nil, buildErrorJson(status: status, errorMessage: errorMessage))
    }
    guard let encodedSerializedTxs = JSONSerialization.jsObject(withNative: serializedTxs) else {
      return (nil, buildErrorJson(status: .internalError, errorMessage: "Internal error"))
    }
    return (encodedSerializedTxs, nil)
  }
  
  /// Helper function to build `SolanaSignTransactionParam` given the serializedMessage and signatures from the `solanaWeb3.Transaction`.
  private func createSignTransactionParam(serializedMessage: MojoBase.Value, signatures: MojoBase.Value) -> BraveWallet.SolanaSignTransactionParam {
    // get the serialized message
    let serializedMessageValues = serializedMessage.bufferToList?.map { UInt8($0.intValue) } ?? []
    let encodedSerializedMsg = (Data(serializedMessageValues) as NSData).base58EncodedString()
    // get the signatures array
    let signaturesValues = (signatures.listValue ?? []).compactMap { $0.dictionaryValue }
    let signatures: [BraveWallet.SignaturePubkeyPair] = signaturesValues.map {
      BraveWallet.SignaturePubkeyPair(
        signature: $0[Keys.signature.rawValue]?.bufferToList?.map { NSNumber(value: $0.intValue) },
        publicKey: $0[Keys.publicKey.rawValue]?.stringValue ?? ""
      )
    }
    return .init(encodedSerializedMsg: encodedSerializedMsg, signatures: signatures)
  }
  
  private func buildErrorJson(status: BraveWallet.SolanaProviderError, errorMessage: String) -> String? {
    JSONSerialization.jsObject(withNative: [Keys.code.rawValue: status.rawValue, Keys.message.rawValue: errorMessage])
  }
  
  @MainActor private func emitConnectEvent(publicKey: String) async {
    if let webView = tab?.webView {
      let script = "window.solana.emit('connect', _brave_solana.createPublickey('\(publicKey)'))"
      await webView.evaluateSafeJavaScript(functionName: script, contentWorld: .page, asFunction: false)
    }
  }
}

private extension MojoBase.Value {
  /// Returns the array of numbers given a Buffer as MojoBase.Value.
  /// `Buffer` comes as ["data": [UInt8], "type": "Buffer"].
  var bufferToList: [MojoBase.Value]? {
    dictionaryValue?[SolanaProviderHelper.Keys.data.rawValue]?.listValue
  }
  
  var numberArray: [NSNumber]? {
    listValue?.map { NSNumber(value: $0.intValue) }
  }
}
