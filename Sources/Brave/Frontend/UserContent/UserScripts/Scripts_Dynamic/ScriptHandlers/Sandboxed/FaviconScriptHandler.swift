// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared
import BraveCore
import Favicon
import os.log

class FaviconScriptHandler: NSObject, TabContentScript {
  private weak var tab: Tab?
  
  init(tab: Tab) {
    self.tab = tab
    super.init()
  }
  
  static let scriptName = "FaviconScript"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "\(scriptName)_\(messageUUID)"
  static let scriptSandbox: WKContentWorld = .defaultClient
  static let userScript: WKUserScript? = {
    guard var script = loadUserScript(named: scriptName) else {
      return nil
    }
    
    return WKUserScript(source: secureScript(handlerName: messageHandlerName,
                                             securityToken: scriptId,
                                             script: script),
                        injectionTime: .atDocumentEnd,
                        forMainFrameOnly: true,
                        in: scriptSandbox)
  }()

  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
    defer { replyHandler(nil, nil) }
    guard let tab = tab else { return }
    tab.favicon = Favicon.default
    
    guard let webView = message.webView,
          let url = webView.url,
          !InternalURL.isValid(url: url),
          !(InternalURL(url)?.isSessionRestore ?? false) else { return }
    
    let isPrivate = tab.isPrivate
    tab.favicon = FaviconFetcher.getIconFromCache(for: url) ?? Favicon.default
    
    tab.faviconDriver?.webView(webView, scriptMessage: message) { [weak tab] iconUrl, icon in
      let tab = tab
      if let icon = icon {
        if let iconUrl = iconUrl {
          Logger.module.debug("Fetched Favicon: \(iconUrl.absoluteString), for page: \(url.absoluteString)")
        } else {
          Logger.module.debug("Fetched Favicon for page: \(url.absoluteString)")
        }
        
        Task { @MainActor in
          let favicon = await Favicon.renderImage(icon, backgroundColor: .clear, shouldScale: true)
          FaviconFetcher.updateCache(favicon, for: url, persistent: !isPrivate)  // We can only cache favicons for non-private tabs
          
          guard let tab = tab else { return }
          tab.favicon = favicon
          TabEvent.post(.didLoadFavicon(favicon), for: tab)
        }
      } else {
        if let iconUrl = iconUrl {
          Logger.module.error("Failed fetching Favicon: \(iconUrl.absoluteString), for page: \(url.absoluteString)")
        } else {
          Logger.module.error("Website: \(url.absoluteString), has no Favicon")
        }
        
        Task { @MainActor in
          let favicon = try await FaviconFetcher.monogramIcon(url: url, persistent: !isPrivate)
          FaviconFetcher.updateCache(favicon, for: url, persistent: true)
          
          guard let tab = tab else { return }
          tab.favicon = favicon
          TabEvent.post(.didLoadFavicon(nil), for: tab)
        }
      }
    }
  }
}
