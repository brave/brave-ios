// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import WebKit
import os.log
import JavaScriptCore

struct ReadyState: Codable {
  let state: State
  
  enum State: String, Codable {
    // Page State
    case loading
    case interactive
    case complete
    case loaded
    
    // History State
    case pushstate
    case replacestate
    case popstate
  }
  
  public static func from(message: WKScriptMessage) -> ReadyState? {
    if !JSONSerialization.isValidJSONObject(message.body) {
      return nil
    }

    do {
      let data = try JSONSerialization.data(withJSONObject: message.body, options: [])
      return try JSONDecoder().decode(ReadyState.self, from: data)
    } catch {
      Logger.module.error("Error Decoding ReadyState: \(error.localizedDescription)")
    }

    return nil
  }
  
  private enum CodingKeys: String, CodingKey {
    case state
  }
}

class ReadyStateScriptHandler: TabContentScript {
  private weak var tab: Tab?
  private var debounceTimer: Timer?
  private let ctx = JSContext.plus

  required init(tab: Tab) {
    self.tab = tab
  }
  
  static let scriptName = "ReadyStateScript"
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
  
  var ranOnce = false
  var value: JSValue?
  
  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
    
    defer { replyHandler(nil, nil) }
    
    if !verifyMessage(message: message) {
      assertionFailure("Missing required security token.")
      return
    }

    guard let readyState = ReadyState.from(message: message) else {
      Logger.module.error("Invalid Ready State")
      return
    }
    
    tab?.onPageReadyStateChanged?(readyState.state)
    
    func loadUserScript(named: String) -> String? {
      guard let path = Bundle.module.path(forResource: named, ofType: "js"),
            let source: String = try? String(contentsOfFile: path) else {
        Logger.module.error("Failed to load script: \(named).js")
        assertionFailure("Failed to Load Script: \(named).js")
        return nil
      }
      return source
    }
    
    guard !ranOnce else { return }
    ranOnce = true
    
    DispatchQueue.main.asyncAfter(deadline: .now()) {
      guard let script = loadUserScript(named: "ytdl") else {
        return
      }
        
      guard let ctx = self.ctx else {
        return
      }
        
      ctx.evaluateScript(script)
      
      let fn = """
      var info = Exported.ytdl.getInfo('https://www.youtube.com/watch?v=aqz-KE-bpKQ', { "lang": "en" });
      info.then((e) => {
        console.log(e);
      })
      .catch((e) => {
        console.log(e);
      });
      """
      
      self.value = ctx.evaluateScript(fn)
      print(self.value)
    }

    
//    let success: @convention(c) (JSContextRef?, JSObjectRef?, JSObjectRef?, Int, UnsafePointer<JSValueRef?>?, UnsafeMutablePointer<JSValueRef?>?) -> JSValueRef? = { (context, function, thisObject, argumentCount, arguments, exception) -> JSValueRef? in
//      guard let context = JSContext(jsGlobalContextRef: context) else { return nil }
//      
//      if argumentCount > 0, let arguments = arguments {
//        let buffer = UnsafeBufferPointer(start: arguments, count: argumentCount)
//        let args = Array(buffer)
//        
//        print(args)
//      }
//      return nil
//    }
//    
//    let failure: @convention(c) (JSContextRef?, JSObjectRef?, JSObjectRef?, Int, UnsafePointer<JSValueRef?>?, UnsafeMutablePointer<JSValueRef?>?) -> JSValueRef? = { (context, function, thisObject, argumentCount, arguments, exception) -> JSValueRef? in
//      guard let context = JSContext(jsGlobalContextRef: context) else { return nil }
//      
//      if argumentCount > 0, let arguments = arguments {
//        let buffer = UnsafeBufferPointer(start: arguments, count: argumentCount)
//        let args = Array(buffer)
//        
//        print(args)
//      }
//      return nil
//    }
//    
//    
//    
//    value?.invokeMethod("then", withArguments: [
//      JSContext.bind(ctx: ctx, thisObject: nil, name: "resolve", callback: success),
//      JSContext.bind(ctx: ctx, thisObject: nil, name: "reject", callback: failure)
//    ])
  }
}
