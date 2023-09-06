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
    
    Task { @MainActor in
      // Assign default favicon
      tab.favicon = Favicon.default
      
      guard let webView = message.webView,
            let url = webView.url else {
        return
      }
      
      // The WebView has a valid URL
      // Attempt to fetch the favicon from cache
      let isPrivate = tab.isPrivate
      tab.favicon = FaviconFetcher.getIconFromCache(for: url) ?? Favicon.default
      
      // If this is an internal page, we don't fetch favicons for such pages from Brave-Core
      guard !InternalURL.isValid(url: url),
            !(InternalURL(url)?.isSessionRestore ?? false) else {
        return
      }
      
      // Update the favicon for this tab, from Brave-Core
      tab.faviconDriver?.webView(webView, scriptMessage: message) { [weak tab] iconUrl, icon in
        FaviconScriptHandler.updateFavicon(tab: tab,
                                           url: url,
                                           isPrivate: isPrivate,
                                           icon: icon,
                                           iconUrl: iconUrl)
      }
    }
  }
  
  private static func updateFavicon(tab: Tab?, url: URL, isPrivate: Bool, icon: UIImage?, iconUrl: URL?) {
    guard let icon = icon else {
      Logger.module.error("Failed fetching Favicon: \(iconUrl?.absoluteString ?? "nil"), for page: \(url.absoluteString)")
      
      // Remove icon from the cache because the website removed possibly removed their icon
      FaviconFetcher.updateCache(nil, for: url, persistent: !isPrivate)
      
      guard let tab = tab else { return }
      tab.favicon = Favicon.default
      TabEvent.post(.didLoadFavicon(Favicon.default), for: tab)
      return
    }
    
    Logger.module.debug("Fetched Favicon: \(iconUrl?.absoluteString ?? "nil"), for page: \(url.absoluteString)")
    
    // If the icon is too small, we don't want to cache it.
    // It's better to show monogram or bundled icons.
    if icon.size.width < CGFloat(FaviconLoader.Sizes.desiredMedium.rawValue) ||
       icon.size.height < CGFloat(FaviconLoader.Sizes.desiredMedium.rawValue) {
      return
    }
    
    Task { @MainActor in
      // Fetch the icon from the database directly
      var favicon = try? await FaviconRenderer.loadIcon(for: url, persistent: !isPrivate)
      
      // If the icon couldn't be fetched, or the icon is a monogram, then render the one returned to us
      if favicon == nil || favicon?.isMonogramImage == true {
        favicon = await Favicon.renderImage(icon, backgroundColor: .clear, shouldScale: true)
      }
      
      guard let tab = tab, let favicon = favicon else { return }
      FaviconFetcher.updateCache(favicon, for: url, persistent: !isPrivate)
      
      tab.favicon = favicon
      TabEvent.post(.didLoadFavicon(favicon), for: tab)
    }
  }
}
