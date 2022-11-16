// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Data
import Shared
import BraveShared
import Storage
import os.log

class PlaylistWebLoader: UIView {
  fileprivate static var pageLoadTimeout = 300.0
  private var pendingHTTPUpgrades = [String: URLRequest]()
  private var pendingRequests = [String: URLRequest]()

  private let tab = Tab(
    configuration: WKWebViewConfiguration().then {
      $0.processPool = WKProcessPool()
      $0.preferences = WKPreferences()
      $0.preferences.javaScriptCanOpenWindowsAutomatically = false
      $0.allowsInlineMediaPlayback = true
      $0.ignoresViewportScaleLimits = true
    }, type: .private
  ).then {
    $0.createWebview()
    $0.webView?.scrollView.layer.masksToBounds = true
  }

  private weak var certStore: CertStore?
  private var handler: ((PlaylistInfo?) -> Void)?

  init() {
    super.init(frame: .zero)
    
    guard let webView = tab.webView else {
      return
    }
    
    self.addSubview(webView)
    webView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    self.removeFromSuperview()
  }

  func load(url: URL, handler: @escaping (PlaylistInfo?) -> Void) {
    self.handler = { [weak self] in
      // Handler cannot be called more than once!
      self?.handler = nil
      handler($0)
    }
    
    guard let webView = tab.webView,
          let browserViewController = self.currentScene?.browserViewController else {
      self.handler?(nil)
      return
    }
    
    self.certStore = browserViewController.profile.certStore
    let KVOs: [KVOConstants] = [
      .estimatedProgress, .loading, .canGoBack,
      .canGoForward, .URL, .title,
      .hasOnlySecureContent, .serverTrust,
    ]

    browserViewController.tab(tab, didCreateWebView: webView)
    KVOs.forEach { webView.removeObserver(browserViewController, forKeyPath: $0.rawValue) }

    // When creating a tab, TabManager automatically adds a uiDelegate
    // This webView is invisible and we don't want any UI being handled.
    webView.uiDelegate = nil
    webView.navigationDelegate = self
    
    tab.replaceContentScript(PlaylistWebLoaderContentHelper(self),
                             name: PlaylistWebLoaderContentHelper.scriptName,
                             forTab: tab)

    webView.frame = superview?.bounds ?? self.bounds
    webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60.0))
  }

  func stop() {
    guard let webView = tab.webView else { return }
    webView.stopLoading()
    DispatchQueue.main.async {
      self.handler?(nil)
      webView.loadHTMLString("<html><body>PlayList</body></html>", baseURL: nil)
    }
  }

  private class PlaylistWebLoaderContentHelper: TabContentScript {
    private weak var webLoader: PlaylistWebLoader?
    private var playlistItems = Set<String>()
    private var isPageLoaded = false
    private var timeout: DispatchWorkItem?

    init(_ webLoader: PlaylistWebLoader) {
      self.webLoader = webLoader
      
      timeout = DispatchWorkItem(block: { [weak self] in
        guard let self = self else { return }
        self.webLoader?.handler?(nil)
        self.webLoader?.tab.webView?.loadHTMLString("<html><body>PlayList</body></html>", baseURL: nil)
        self.webLoader = nil
      })

      if let timeout = timeout {
        DispatchQueue.main.asyncAfter(deadline: .now() + PlaylistWebLoader.pageLoadTimeout, execute: timeout)
      }
    }

    static let scriptName = "PlaylistScript"
    static let scriptId = PlaylistScriptHandler.scriptId
    static let messageHandlerName = PlaylistScriptHandler.messageHandlerName
    static let scriptSandbox = PlaylistScriptHandler.scriptSandbox
    static let userScript: WKUserScript? = nil

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
      if !verifyMessage(message: message) {
        assertionFailure("Missing required security token.")
        return
      }
      
      replyHandler(nil, nil)
      
      let cancelRequest = {
        self.timeout?.cancel()
        self.timeout = nil
        self.webLoader?.handler?(nil)
        self.webLoader?.tab.webView?.loadHTMLString("<html><body>PlayList</body></html>", baseURL: nil)
        self.webLoader = nil
      }

      guard let item = PlaylistInfo.from(message: message),
        item.detected
      else {
        cancelRequest()
        return
      }

      // For now, we ignore base64 video mime-types loaded via the `data:` scheme.
      if item.duration <= 0.0 && !item.detected || item.src.isEmpty || item.src.hasPrefix("data:") || item.src.hasPrefix("blob:") {
        cancelRequest()
        return
      }
        
      DispatchQueue.main.async {
        if !self.playlistItems.contains(item.src) {
          self.playlistItems.insert(item.src)
          
          self.timeout?.cancel()
          self.timeout = nil
          self.webLoader?.handler?(item)
          self.webLoader = nil
        }
        
        // This line MAY cause problems.. because some websites have a loading delay for the source of the media item
        // If the second we receive the src, we reload the page by doing the below HTML,
        // It may not have received all info necessary to play the item such as MetadataInfo
        // For now it works 100% of the time and it is safe to do it. If we come across such a website, that causes problems,
        // we'll need to find a different way of forcing the WebView to STOP loading metadata in the background
        self.webLoader?.tab.webView?.loadHTMLString("<html><body>PlayList</body></html>", baseURL: nil)
        self.webLoader = nil
      }
    }
  }
}

extension PlaylistWebLoader: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    webView.evaluateSafeJavaScript(functionName: "window.__firefox__.playlistProcessDocumentLoad()",
                                   args: [],
                                   contentWorld: PlaylistWebLoaderContentHelper.scriptSandbox,
                                   asFunction: false)
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    self.handler?(nil)
  }

  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
    guard let url = navigationAction.request.url else {
      return (.cancel, preferences)
    }
    
    if let policy = handleSpecialActions(for: navigationAction) {
      return (policy, preferences)
    }
    
    NavigationActionHelper.configurePageData(for: navigationAction, on: tab)
    
    // Ad-blocking checks
    if let mainDocumentURL = navigationAction.request.mainDocumentURL {
      let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
      let domainForMainFrame = Domain.getOrCreate(forUrl: mainDocumentURL, persistent: !isPrivateBrowsing)
      webView.configuration.preferences.isFraudulentWebsiteWarningEnabled =
        domainForMainFrame.isShieldExpected(.SafeBrowsing, considerAllShieldsOption: true)
      NavigationActionHelper.configureTabScripts(for: navigationAction, on: tab, domain: domainForMainFrame)
    }

    // The next part requires that the request has a valid scheme
    // This is the normal case, opening a http or https url, which we handle by loading them in this WKWebView. We
    // always allow this. Additionally, data URIs are also handled just like normal web pages.
    if ["http", "https", "data", "blob", "file"].contains(url.scheme) {
      NavigationActionHelper.ensureUserAgent(for: navigationAction, on: tab, webView: webView)
      handleHTTPSUpgrades(for: navigationAction)
      let updatedPreferences = setupAdBlock(for: navigationAction, on: tab, preferences: preferences)
      return (.allow, updatedPreferences)
    } else {
      return (.cancel, preferences)
    }
  }

  func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
    let response = navigationResponse.response
    let responseURL = response.url

    if let responseURL = responseURL,
      let internalURL = InternalURL(responseURL),
      internalURL.isSessionRestore {
      tab.shouldClassifyLoadsForAds = false
    }
    
    // We also add subframe urls in case a frame upgraded to https
    if let responseURL = responseURL,
       let domain = tab.currentPageData?.domain(persistent: false),
       let scriptTypes = tab.currentPageData?.makeUserScriptTypes(
        forResponseURL: responseURL,
        isForMainFrame: navigationResponse.isForMainFrame,
        domain: domain
       ) {
      tab.setCustomUserScript(scripts: scriptTypes)
    }

    var request: URLRequest?
    if let url = responseURL {
      request = pendingRequests.removeValue(forKey: url.absoluteString)
    }

    if let url = responseURL, let urlHost = responseURL?.normalizedHost() {
      // If an upgraded https load happens with a host which was upgraded, increase the stats
      if url.scheme == "https", let _ = pendingHTTPUpgrades.removeValue(forKey: urlHost) {
        BraveGlobalShieldStats.shared.httpse += 1
        tab.contentBlocker.stats = tab.contentBlocker.stats.adding(httpsCount: 1)
      }
    }

    // TODO: REFACTOR to support Multiple Windows Better
    if let browserController = webView.currentScene?.browserViewController {
      // Check if this response should be handed off to Passbook.
      if OpenPassBookHelper(request: request, response: response, canShowInWebView: false, forceDownload: false, browserViewController: browserController) != nil {
        return .cancel
      }
    }

    if navigationResponse.isForMainFrame {
      if response.mimeType?.isKindOfHTML == false, request != nil {
        return .cancel
      } else {
        tab.temporaryDocument = nil
      }

      tab.mimeType = response.mimeType
    }

    return .allow
  }

  public func webView(_ webView: WKWebView, respondTo challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    let origin = "\(challenge.protectionSpace.host):\(challenge.protectionSpace.port)"
    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
      let trust = challenge.protectionSpace.serverTrust,
      let cert = SecTrustGetCertificateAtIndex(trust, 0), certStore?.containsCertificate(cert, forOrigin: origin) == true {
      return (.useCredential, URLCredential(trust: trust))
    }

    guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic || challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest || challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM else {
      return (.performDefaultHandling, nil)
    }

    return (.rejectProtectionSpace, nil)
  }
}

private extension PlaylistWebLoader {
  func handleSpecialActions(for navigationAction: WKNavigationAction) -> WKNavigationActionPolicy? {
    switch NavigationActionHelper.handleSpecialActions(for: navigationAction) {
    case .aboutScheme, .bookmarklet, .buyVPN, .appleMapsURL, .storeURL, .externalAppScheme:
      return .cancel
    case .internalLink(let isPrivileged):
      if !isPrivileged && navigationAction.navigationType != .backForward {
        return .cancel
      } else {
        return nil
      }
    case .none, .braveScheme:
      return nil
    }
  }
  
  // TODO: Downgrade to 14.5 once api becomes available.
  /// Special handling for iOS below versio 15+
  func handleHTTPSUpgrades(for navigationAction: WKNavigationAction) {
    guard let url = navigationAction.request.url else { return }
    pendingRequests[url.absoluteString] = navigationAction.request
    
    if #unavailable(iOS 15.0) {
      guard Preferences.Shields.httpsEverywhere.value,
            url.scheme == "http",
            let urlHost = url.normalizedHost() else {
        return
      }
      
      HttpsEverywhereStats.shared.shouldUpgrade(url) { shouldupgrade in
        DispatchQueue.main.async {
          if shouldupgrade {
            self.pendingHTTPUpgrades[urlHost] = navigationAction.request
          }
        }
      }
    }
  }
  
  /// Setup Adblock preferences on the tab
  func setupAdBlock(for navigationAction: WKNavigationAction, on tab: Tab, preferences: WKWebpagePreferences) -> WKWebpagePreferences {
    // Only use main document URL, not the request URL
    //   If an iFrame is loaded, shields depending on the main frame, not the iFrame request
    // Weird behavior here with `targetFram` and `sourceFrame`, on refreshing page `sourceFrame` is not nil (it is non-optional)
    //   however, it is still an uninitialized object, making it an unreliable source to compare `isMainFrame` against.
    //   Rather than using `sourceFrame.isMainFrame` or even comparing `sourceFrame == targetFrame`, a simple URL check is used.
    // No adblocking logic is be used on session restore urls. It uses javascript to retrieve the
    //   request then the page is reloaded with a proper url and adblocking rules are applied.
    if let url = navigationAction.request.url,
       let mainDocumentURL = navigationAction.request.mainDocumentURL,
       mainDocumentURL.schemelessAbsoluteString == url.schemelessAbsoluteString,
       !(InternalURL(url)?.isSessionRestore ?? false),
       navigationAction.sourceFrame.isMainFrame || navigationAction.targetFrame?.isMainFrame == true {
      // Identify specific block lists that need to be applied to the requesting domain
      let domainForShields = Domain.getOrCreate(forUrl: mainDocumentURL, persistent: false)

      // Force adblocking on
      domainForShields.shield_allOff = 0
      domainForShields.shield_adblockAndTp = true
      
      // Load block lists
      let enabledRuleTypes = ContentBlockerManager.shared.compiledRuleTypes(for: domainForShields)
      tab.contentBlocker.ruleListTypes = enabledRuleTypes

      let isScriptsEnabled = !domainForShields.isShieldExpected(.NoScript, considerAllShieldsOption: true)
      preferences.allowsContentJavaScript = isScriptsEnabled
    }
    
    return preferences
  }
}
