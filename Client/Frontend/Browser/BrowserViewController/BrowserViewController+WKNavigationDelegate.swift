/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import Data
import BraveShared
import BraveCore
import BraveUI
import BraveWallet
import os.log

extension BrowserViewController: WKNavigationDelegate {
  public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    if tabManager.selectedTab?.webView !== webView {
      return
    }
    toolbarVisibilityViewModel.toolbarState = .expanded

    if let selectedTab = tabManager.selectedTab,
       selectedTab.url?.origin != webView.url?.origin {
      // new site has a different origin, hide wallet icon.
      tabManager.selectedTab?.isWalletIconVisible = false
      // new site, reset connected addresses
      tabManager.selectedTab?.clearSolanaConnectedAccounts()
      // close wallet panel if it's open
      if let popoverController = self.presentedViewController as? PopoverController,
         popoverController.contentController is WalletPanelHostingController {
        self.dismiss(animated: true)
      }
    }

    updateFindInPageVisibility(visible: false)
    displayPageZoom(visible: false)

    // If we are going to navigate to a new page, hide the reader mode button. Unless we
    // are going to a about:reader page. Then we keep it on screen: it will change status
    // (orange color) as soon as the page has loaded.
    if let url = webView.url {
      if !url.isReaderModeURL {
        topToolbar.updateReaderModeState(ReaderModeState.unavailable)
        hideReaderModeBar(animated: false)
      }
    }
  }

  public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
    guard let url = navigationAction.request.url, let tab = tab(for: webView) else {
      return (.cancel, preferences)
    }

    // Handle special urls that require a policy to be returned right away
    if let policy = handleInternalLinks(for: navigationAction)
        ?? handleUniversalLinks(for: navigationAction)
        ?? handleSpecialSchemes(for: navigationAction) {
      return (policy, preferences)
    }
    
    // Website redirection logic
    if url.isWebPage(includeDataURIs: false),
       navigationAction.targetFrame?.isMainFrame == true,
       let redirectURL = WebsiteRedirects.redirect(for: url) {
      tab.loadRequest(URLRequest(url: redirectURL))
      return (.cancel, preferences)
    }
    
    // If we haven't cancelled the request due to the special cases above,
    // we must configure our page data before loading any scripts/ad-block settings
    configurePageData(for: navigationAction, on: tab)
    
    // Logic that requires the main-frame's domain
    if let mainDocumentURL = navigationAction.request.mainDocumentURL {
      let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
      let domainForMainFrame = Domain.getOrCreate(forUrl: mainDocumentURL, persistent: !isPrivateBrowsing)
      
      if let request = makeDebounceRequest(for: navigationAction, on: tab, domain: domainForMainFrame) {
        tab.loadRequest(request)
        return (.cancel, preferences)
      }
      
      configureTabScripts(for: navigationAction, on: tab, domain: domainForMainFrame)
    } else {
      assertionFailure()
    }
    
    handleBraveSearch(for: navigationAction, tab: tab, webView: webView)

    // The next part requires that the request has a valid scheme
    // This is the normal case, opening a http or https url, which we handle by loading them in this WKWebView. We
    // always allow this. Additionally, data URIs are also handled just like normal web pages.
    if ["http", "https", "data", "blob", "file"].contains(url.scheme) {
      // Set the user agent
      if navigationAction.targetFrame?.isMainFrame == true {
        tab.updateUserAgent(webView, newURL: url)
      }
      
      handleHTTPSUpgrades(for: navigationAction)
      let updatedPreferences = setupAdBlock(for: navigationAction, on: tab, preferences: preferences)
      
      // Reset the block alert bool on new host.
      if let newHost: String = url.host, let oldHost: String = webView.url?.host, newHost != oldHost {
        self.tabManager.selectedTab?.alertShownCount = 0
        self.tabManager.selectedTab?.blockAllAlerts = false
      }
      
      return (.allow, updatedPreferences)
    } else {
      return (.cancel, preferences)
    }
  }

  public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
    let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
    let tab = tab(for: webView)
    
    // Check if we upgraded to https and if so we need to update the url of frame evaluations
    if let responseURL = navigationResponse.response.url {
      tab?.currentPageData?.upgradeFrames(forResponseURL: responseURL)
    }
    
    // We also add subframe urls in case a frame upgraded to https
    if let responseURL = navigationResponse.response.url,
       let domain = tab?.currentPageData?.domain(persistent: !isPrivateBrowsing),
       let scriptTypes = tab?.currentPageData?.makeUserScriptTypes(
        forResponseURL: responseURL,
        isForMainFrame: navigationResponse.isForMainFrame,
        domain: domain
       ) {
      tab?.setCustomUserScript(scripts: scriptTypes)
    }

    if let tab = tab,
      let responseURL = navigationResponse.response.url,
      InternalURL(responseURL)?.isSessionRestore == true {
      tab.shouldClassifyLoadsForAds = false
    }

    var request: URLRequest?
    if let responseURL = navigationResponse.response.url {
      request = pendingRequests.removeValue(forKey: responseURL.absoluteString)
    }

    // We can only show this content in the web view if this web view is not pending
    // download via the context menu.
    let canShowInWebView = navigationResponse.canShowMIMEType && (webView != pendingDownloadWebView)
    let forceDownload = webView == pendingDownloadWebView

    if let responseURL = navigationResponse.response.url, let urlHost = responseURL.normalizedHost() {
      // If an upgraded https load happens with a host which was upgraded, increase the stats
      if responseURL.scheme == "https", let _ = pendingHTTPUpgrades.removeValue(forKey: urlHost) {
        BraveGlobalShieldStats.shared.httpse += 1
        if let stats = tab?.contentBlocker.stats {
          tab?.contentBlocker.stats = stats.adding(httpsCount: 1)
        }
      }
    }

    // Check if this response should be handed off to Passbook.
    if let passbookHelper = OpenPassBookHelper(
      request: request, response: navigationResponse.response,
      canShowInWebView: canShowInWebView,
      forceDownload: forceDownload, browserViewController: self
    ) {
      // Open our helper and cancel this response from the webview.
      passbookHelper.open()
      return .cancel
    }

    // Check if this response should be downloaded.
    let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
    if let downloadHelper = DownloadHelper(
      request: request, response: navigationResponse.response,
      cookieStore: cookieStore, canShowInWebView: canShowInWebView,
      forceDownload: forceDownload
    ) {
      // Clear the pending download web view so that subsequent navigations from the same
      // web view don't invoke another download.
      pendingDownloadWebView = nil

      let downloadAlertAction: (HTTPDownload) -> Void = { [weak self] download in
        self?.downloadQueue.enqueue(download)
      }

      // Open our helper and cancel this response from the webview.
      if let downloadAlert = downloadHelper.downloadAlert(from: view, okAction: downloadAlertAction) {
        present(downloadAlert, animated: true, completion: nil)
      }
      return .cancel
    }

    // If the content type is not HTML, create a temporary document so it can be downloaded and
    // shared to external applications later. Otherwise, clear the old temporary document.
    if let tab = tab, navigationResponse.isForMainFrame {
      if navigationResponse.response.mimeType?.isKindOfHTML == false, let request = request {
        tab.temporaryDocument = TemporaryDocument(
          preflightResponse: navigationResponse.response, request: request, tab: tab
        )
      } else {
        tab.temporaryDocument = nil
      }

      tab.mimeType = navigationResponse.response.mimeType
    }
    
    // Record the navigation visit type for the URL after navigation actions
    // this is done in decidePolicyFor to handle all the cases like redirects etc.
    if let responseURL = navigationResponse.response.url, let tab = tab,
       !responseURL.isReaderModeURL, !responseURL.isFileURL, responseURL.isWebPage(), !tab.isPrivate {
      recordNavigationInTab(responseURL, visitType: lastEnteredURLVisitType)
    }
    
    // If none of our helpers are responsible for handling this response,
    // just let the webview handle it as normal.
    return .allow
  }

  public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

    // If this is a certificate challenge, see if the certificate has previously been
    // accepted by the user.
    let origin = "\(challenge.protectionSpace.host):\(challenge.protectionSpace.port)"
    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
      let trust = challenge.protectionSpace.serverTrust,
      let cert = SecTrustGetCertificateAtIndex(trust, 0), profile.certStore.containsCertificate(cert, forOrigin: origin) {
      completionHandler(.useCredential, URLCredential(trust: trust))
      return
    }

    guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
          challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest ||
          challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM,
          let tab = tab(for: webView)
    else {
      completionHandler(.performDefaultHandling, nil)
      return
    }

    // If this is a request to our local web server, use our private credentials.
    if challenge.protectionSpace.host == "localhost" && challenge.protectionSpace.port == Int(WebServer.sharedInstance.server.port) {
      completionHandler(.useCredential, WebServer.sharedInstance.credentials)
      return
    }

    // The challenge may come from a background tab, so ensure it's the one visible.
    tabManager.selectTab(tab)

    let loginsHelper = tab.getContentScript(name: LoginsScriptHandler.scriptName) as? LoginsScriptHandler
    Task { @MainActor in
      do {
        let credentials = try await Authenticator.handleAuthRequest(self, challenge: challenge, loginsHelper: loginsHelper)
        completionHandler(.useCredential, credentials.credentials)
      } catch {
        completionHandler(.rejectProtectionSpace, nil)
      }
    }
  }

  public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    guard let tab = tab(for: webView) else { return }
    // Set the committed url which will also set tab.url
    tab.committedURL = webView.url
    
    // Need to evaluate Night mode script injection after url is set inside the Tab
    tab.nightMode = Preferences.General.nightModeEnabled.value
    tab.clearSolanaConnectedAccounts()

    rewards.reportTabNavigation(tabId: tab.rewardsId)

    if tabManager.selectedTab === tab {
      updateUIForReaderHomeStateForTab(tab)
    }
  }

  public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    if let tab = tabManager[webView] {
      
      // Deciding whether to inject app's IAP receipt for Brave SKUs or not
      if let url = tab.url,
          let braveSkusHelper = BraveSkusWebHelper(for: url),
          let receiptData = braveSkusHelper.receiptData,
          !tab.isPrivate {
        tab.injectSessionStorageItem(key: receiptData.key, value: receiptData.value)
      }

      // Second attempt to inject results to the BraveSearch.
      // This will be called if we got fallback results faster than
      // the page navigation.
      if let braveSearchManager = tab.braveSearchManager {
        // Fallback results are ready before navigation finished,
        // they must be injected here.
        if !braveSearchManager.fallbackQueryResultsPending {
          tab.injectResults()
        }
      } else {
        // If not applicable, null results must be injected regardless.
        // The website waits on us until this is called with either results or null.
        tab.injectResults()
      }

      navigateInTab(tab: tab, to: navigation)
      if let url = tab.url, tab.shouldClassifyLoadsForAds {
        let faviconURL = URL(string: tab.displayFavicon?.url ?? "")
        rewards.reportTabUpdated(
          tab: tab,
          url: url,
          faviconURL: faviconURL,
          isSelected: tabManager.selectedTab == tab,
          isPrivate: PrivateBrowsingManager.shared.isPrivateBrowsing
        )
      }
      tab.updateEthereumProperties()
      Task {
        await tab.updateSolanaProperties()
      }
      tab.reportPageLoad(to: rewards, redirectionURLs: tab.redirectURLs)
      tab.redirectURLs = []
      if webView.url?.isLocal == false {
        // Reset should classify
        tab.shouldClassifyLoadsForAds = true
        // Set rewards inter site url as new page load url.
        rewardsXHRLoadURL = webView.url
      }

      tabsBar.reloadDataAndRestoreSelectedTab()
      
      if tab.walletEthProvider != nil {
        tab.emitEthereumEvent(.connect)
      }
    }

    // Added this method to determine long press menu actions better
    // Since these actions are depending on tabmanager opened WebsiteCount
    updateToolbarUsingTabManager(tabManager)
  }

  public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
    guard
      let tab = tab(for: webView), let url = webView.url, rewards.isEnabled
    else {
      return
    }
    
    tab.redirectURLs.append(url)
  }
}

private extension BrowserViewController {
  func tab(for webView: WKWebView) -> Tab? {
    tabManager[webView] ?? (webView as? TabWebView)?.tab
  }
  
  /// Website redirection logic
  func handleWebsiteRedirection(for navigationAction: WKNavigationAction) -> URLRequest? {
    guard
      let url = navigationAction.request.url,
      url.isWebPage(includeDataURIs: false),
      navigationAction.targetFrame?.isMainFrame == true,
      let redirectURL = WebsiteRedirects.redirect(for: url)
    else {
      return nil
    }
    
    return URLRequest(url: redirectURL)
  }
  
  /// Brave Search logic.
  func handleBraveSearch(for navigationAction: WKNavigationAction, tab: Tab, webView: WKWebView) {
    guard
      let url = navigationAction.request.url,
      navigationAction.targetFrame?.isMainFrame == true,
      BraveSearchManager.isValidURL(url)
    else {
      tab.braveSearchManager = nil
      return
    }
    
    // We fetch cookies to determine if backup search was enabled on the website.
    let profile = self.profile
    
    webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
      tab.braveSearchManager = BraveSearchManager(profile: profile, url: url, cookies: cookies)
      if let braveSearchManager = tab.braveSearchManager {
        braveSearchManager.fallbackQueryResultsPending = true
        braveSearchManager.shouldUseFallback { backupQuery in
          guard let query = backupQuery else {
            braveSearchManager.fallbackQueryResultsPending = false
            return
          }
          
          if query.found {
            braveSearchManager.fallbackQueryResultsPending = false
          } else {
            braveSearchManager.backupSearch(with: query) { completion in
              braveSearchManager.fallbackQueryResultsPending = false
              tab.injectResults()
            }
          }
        }
      }
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
    
  /// Handle debouncing redirects
  func makeDebounceRequest(for navigationAction: WKNavigationAction, on tab: Tab, domain: Domain) -> URLRequest? {
    // Handle debouncing for main frame only and only if the site (etld+1) changes
    // We also only handle `http` and `https` requests
    guard
      let url = navigationAction.request.url,
      url.isWebPage(includeDataURIs: false),
      let currentURL = tab.webView?.url,
      currentURL.baseDomain != url.baseDomain,
      domain.isShieldExpected(.AdblockAndTp, considerAllShieldsOption: true),
      navigationAction.targetFrame?.isMainFrame == true
    else {
      return nil
    }
    
    // Lets get the redirect chain.
    // Then we simply get all elements up until the user allows us to redirect
    // (i.e. appropriate settings are enabled for that redirect rule)
    let redirectChain = DebouncingResourceDownloader.shared
      .redirectChain(for: url)
      .contiguousUntil { _, rule in
        return rule.preferences.allSatisfy { pref in
          switch pref {
          case .deAmpEnabled:
            return Preferences.Shields.autoRedirectAMPPages.value
          }
        }
      }
    
    // Once we check the redirect chain only need the last (final) url from our redirect chain
    guard let redirectURL = redirectChain.last?.url else { return nil }
    // For now we only allow the `Referer`. The browser will add other headers during navigation.
    var modifiedRequest = URLRequest(url: redirectURL)

    for (headerKey, headerValue) in navigationAction.request.allHTTPHeaderFields ?? [:] {
      guard headerKey == "Referer" else { continue }
      modifiedRequest.setValue(headerValue, forHTTPHeaderField: headerKey)
    }

    return modifiedRequest
  }
  
  /// Universal links do not work if the request originates from the app, manual handling is required.
  func handleUniversalLinks(for navigationAction: WKNavigationAction) -> WKNavigationActionPolicy? {
    guard
      let mainDocURL = navigationAction.request.mainDocumentURL,
      let universalLink = UniversalLinkManager.universalLinkType(for: mainDocURL, checkPath: true)
    else {
      return nil
    }
      
    switch universalLink {
    case .buyVPN:
      presentCorrespondingVPNViewController()
      return .cancel
    }
  }
  
  /// Handle internal URLs
  func handleInternalLinks(for navigationAction: WKNavigationAction) -> WKNavigationActionPolicy? {
    guard let url = navigationAction.request.url else { return nil }
    guard InternalURL.isValid(url: url) else { return nil }
    
    if navigationAction.navigationType != .backForward, navigationAction.isInternalUnprivileged {
      return .cancel
    }
    
    return .allow
  }
  
  /// Handle special urls that need custom handling such as those with `about`, `mailto` and `phone` schemas
  func handleSpecialSchemes(for navigationAction: WKNavigationAction) -> WKNavigationActionPolicy? {
    guard let url = navigationAction.request.url else { return nil }
    guard url.scheme != "about" else { return .allow }
    guard !url.isBookmarklet else { return .cancel }
    
    // First special case are some schemes that are about calling and email. We prompt the user to confirm this action. This
    // gives us the exact same behaviour as Safari.
    guard !["sms", "tel", "facetime", "facetime-audio", "mailto"].contains(url.scheme) else {
      handleExternalURL(url)
      return .cancel
    }
    
    // Second special case are a set of URLs that look like regular http links, but should be handed over to iOS
    // instead of being loaded in the webview. Note that there is no point in calling canOpenURL() here, because
    // iOS will always say yes. TODO Is this the same as isWhitelisted?
    guard !url.isAppleMapsURL && !url.isStoreURL else {
      handleExternalURL(url)
      return .cancel
    }
    
    // Standard schemes are handled in previous if-case.
    // This check handles custom app schemes to open external apps.
    // Our own 'brave' scheme does not require the switch-app prompt.
    guard url.scheme?.contains("brave") != true else {
      handleExternalURL(url) { didOpenURL in
        // Do not show error message for JS navigated links or redirect
        // as it's not the result of a user action.
        if !didOpenURL, navigationAction.navigationType == .linkActivated {
          let alert = UIAlertController(title: Strings.unableToOpenURLErrorTitle, message: Strings.unableToOpenURLError, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: nil))
          self.present(alert, animated: true, completion: nil)
        }
      }
      
      return .cancel
    }
    
    return nil
  }
  
  /// Ensure that the page data loaded is valid and contains the current frame info.
  ///
  /// - Note: You should call this as early as possible unless the request is being cancelled
  func configurePageData(for navigationAction: WKNavigationAction, on tab: Tab) {
    // first we check if our page data is still valid or if it needs to be reset
    if let mainDocumentURL = navigationAction.request.mainDocumentURL {
      if mainDocumentURL != tab.currentPageData?.mainFrameURL {
        // Clear the current page data if the page changes.
        // Do this before anything else so that we have a clean slate.
        tab.currentPageData = PageData(mainFrameURL: mainDocumentURL)
      }
    }
    
    guard let url = navigationAction.request.url else {
      return
    }
    
    if let targetFrame = navigationAction.targetFrame {
      // Add the frame info so that we can execute scripts later on
      tab.currentPageData?.framesInfo[url] = targetFrame
    }
  }
  
  /// Configure the tab with the appropriate scripts for this navigation action
  ///
  /// - Warning: Ensure you call configurePageData before calling this.
  func configureTabScripts(for navigationAction: WKNavigationAction, on tab: Tab, domain: Domain) {
    guard
      let url = navigationAction.request.url,
      let targetFrame = navigationAction.targetFrame
    else { return }
    
    // Check if custom user scripts must be added to or removed from the web view.
    if let scriptTypes = tab.currentPageData?.makeUserScriptTypes(
        forRequestURL: url,
        isForMainFrame: targetFrame.isMainFrame,
        domain: domain
       ) {
      tab.setCustomUserScript(scripts: scriptTypes)
    }
    
    // Set some additional user scripts that are set only on the main frame
    if targetFrame.isMainFrame {
      tab.setScripts(scripts: [
        // Add de-amp script
        // The user script manager will take care to not reload scripts if this value doesn't change
        .deAmp: Preferences.Shields.autoRedirectAMPPages.value,
        
        // Add request blocking script
        // This script will block certian `xhr` and `window.fetch()` requests
        .requestBlocking: url.isWebPage(includeDataURIs: false) &&
        domain.isShieldExpected(.AdblockAndTp, considerAllShieldsOption: true)
      ])
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
      let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
      // Identify specific block lists that need to be applied to the requesting domain
      let domainForShields = Domain.getOrCreate(forUrl: mainDocumentURL, persistent: !isPrivateBrowsing)
      
      // Load rule lists
      tab.contentBlocker.ruleListTypes = ContentBlockerManager.shared.compiledRuleTypes(
        for: domainForShields
      )
      
      let isScriptsEnabled = !domainForShields.isShieldExpected(.NoScript, considerAllShieldsOption: true)
      preferences.allowsContentJavaScript = isScriptsEnabled
    }

    // Cookie Blocking code below
    tab.setScript(script: .cookieBlocking, enabled: Preferences.Privacy.blockAllCookies.value)
    return preferences
  }

  func handleExternalURL(_ url: URL, openedURLCompletionHandler: ((Bool) -> Void)? = nil) {
    self.view.endEditing(true)
    let popup = AlertPopupView(
      imageView: nil,
      title: Strings.openExternalAppURLTitle,
      message: String(format: Strings.openExternalAppURLMessage, url.relativeString),
      titleWeight: .semibold,
      titleSize: 21
    )
    popup.addButton(title: Strings.openExternalAppURLDontAllow, fontSize: 16) { () -> PopupViewDismissType in
      return .flyDown
    }
    popup.addButton(title: Strings.openExternalAppURLAllow, type: .primary, fontSize: 16) { () -> PopupViewDismissType in
      UIApplication.shared.open(url, options: [:], completionHandler: openedURLCompletionHandler)
      return .flyDown
    }
    popup.showWithType(showType: .flyUp)
  }
}
