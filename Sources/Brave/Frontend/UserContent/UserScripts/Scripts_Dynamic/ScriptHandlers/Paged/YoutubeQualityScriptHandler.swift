// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

class YoutubeQualityScriptHandler: NSObject, TabContentScript {
  private weak var tab: Tab?
  private var url: URL?
  private var urlObserver: NSObjectProtocol?
  
  init(tab: Tab) {
    self.tab = tab
    self.url = tab.url
    super.init()
    
    urlObserver = tab.webView?.observe(
      \.url, options: [.new],
       changeHandler: { [weak self] object, change in
         guard let self = self, let url = change.newValue else { return }
         if self.url?.withoutFragment != url?.withoutFragment {
           self.url = url
           
           object.evaluateSafeJavaScript(functionName: "window.__firefox__.\(Self.refreshQuality)",
                                         contentWorld: Self.scriptSandbox,
                                         asFunction: true)
         }
       })
  }
  
  private static let refreshQuality = "refresh_youtube_quality_\(uniqueID)"
  private static let setQuality = "set_youtube_quality_\(uniqueID)"
  
  // TODO: Put this behind a preference
  private static let defaultQuality = "hd720"
  
  static let scriptName = "YoutubeQualityScript"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "\(scriptName)_\(messageUUID)"
  static let scriptSandbox: WKContentWorld = .page
  static let userScript: WKUserScript? = {
    guard var script = loadUserScript(named: scriptName) else {
      return nil
    }
    
    return WKUserScript(source: secureScript(handlerNamesMap: ["$<message_handler>": messageHandlerName,
                                                               "$<current_quality_value>": defaultQuality,
                                                               "$<refresh_youtube_quality>": refreshQuality,
                                                               "$<set_youtube_quality>": setQuality],
                                             securityToken: scriptId,
                                             script: script),
                        injectionTime: .atDocumentStart,
                        forMainFrameOnly: true,
                        in: scriptSandbox)
  }()
  
  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
    defer { replyHandler(nil, nil) }
    
    if !verifyMessage(message: message) {
      assertionFailure("Missing required security token.")
      return
    }
  }
}
