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
    
    // First handle some special actions that require a policy to be returned right away
    if let policy = self.handleSpecialActions(for: navigationAction, tab: tab) {
      return (policy, preferences)
    }
    
    // Next handle some website redirects such as from new reddit to old reddit
    if let redirectRequest = NavigationActionHelper.makeWebsiteRedirectRequest(for: navigationAction) {
      tab.loadRequest(redirectRequest)
      return (.cancel, preferences)
    }
    
    // If we haven't cancelled the request due to the special cases above,
    // we must configure our page data before loading any scripts/ad-block settings
    NavigationActionHelper.configurePageData(for: navigationAction, on: tab)
    
    // Logic that requires the main-frame's domain
    if let mainDocumentURL = navigationAction.request.mainDocumentURL {
      let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
      let domainForMainFrame = Domain.getOrCreate(forUrl: mainDocumentURL, persistent: !isPrivateBrowsing)
      
      if let redirectRequest = NavigationActionHelper.makeDebounceRequest(for: navigationAction, on: tab, domain: domainForMainFrame) {
        tab.loadRequest(redirectRequest)
        return (.cancel, preferences)
      }
      
      NavigationActionHelper.configureTabScripts(for: navigationAction, on: tab, domain: domainForMainFrame)
    } else {
      assertionFailure()
    }
    
    if let redirectRequest = NavigationActionHelper.handleBraveSearch(
      for: navigationAction, tab: tab, webView: webView,
      profile: profile, rewards: rewards
    ) {
      tab.loadRequest(redirectRequest)
      return (.cancel, preferences)
    }
    
    // The next part requires that the request has a valid scheme
    // This is the normal case, opening a http or https url, which we handle by loading them in this WKWebView. We
    // always allow this. Additionally, data URIs are also handled just like normal web pages.
    if ["http", "https", "data", "blob", "file"].contains(url.scheme) {
      NavigationActionHelper.ensureUserAgent(for: navigationAction, on: tab, webView: webView)
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

  public func webView(_ webView: WKWebView, respondTo challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    // If this is a certificate challenge, see if the certificate has previously been
    // accepted by the user.
    let origin = "\(challenge.protectionSpace.host):\(challenge.protectionSpace.port)"
    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
      let trust = challenge.protectionSpace.serverTrust,
      let cert = SecTrustGetCertificateAtIndex(trust, 0), profile.certStore.containsCertificate(cert, forOrigin: origin) {
      return (.useCredential, URLCredential(trust: trust))
    }

    guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
          challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest ||
          challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM,
          let tab = tab(for: webView)
    else {
      return (.performDefaultHandling, nil)
    }

    // If this is a request to our local web server, use our private credentials.
    if challenge.protectionSpace.host == "localhost" && challenge.protectionSpace.port == Int(WebServer.sharedInstance.server.port) {
      return (.useCredential, WebServer.sharedInstance.credentials)
    }

    // The challenge may come from a background tab, so ensure it's the one visible.
    tabManager.selectTab(tab)

    let loginsHelper = tab.getContentScript(name: LoginsScriptHandler.scriptName) as? LoginsScriptHandler
    
    do {
      let credentials = try await Authenticator.handleAuthRequest(self, challenge: challenge, loginsHelper: loginsHelper)
      return (.useCredential, credentials.credentials)
    } catch {
      return (.rejectProtectionSpace, nil)
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
  
  func handleSpecialActions(for navigationAction: WKNavigationAction, tab: Tab) -> WKNavigationActionPolicy? {
    switch NavigationActionHelper.handleSpecialActions(for: navigationAction) {
    case .braveScheme(let url):
      handleExternalURL(url, tab: tab, navigationAction: navigationAction) { didOpenURL in
        // Do not show error message for JS navigated links or redirect
        // as it's not the result of a user action.
        if !didOpenURL, navigationAction.navigationType == .linkActivated {
          let alert = UIAlertController(title: Strings.unableToOpenURLErrorTitle, message: Strings.unableToOpenURLError, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: nil))
          self.present(alert, animated: true, completion: nil)
        }
      }
      
      return .cancel
    case .aboutScheme:
      return .allow
    case .bookmarklet:
      return .cancel
    case .appleMapsURL(let url), .storeURL(let url), .externalAppScheme(let url):
      handleExternalURL(url, tab: tab, navigationAction: navigationAction)
      return .cancel
    case .internalLink(let isPrivileged):
      if !isPrivileged && navigationAction.navigationType != .backForward {
        return .cancel
      } else {
        return .allow
      }
    case .buyVPN:
      presentCorrespondingVPNViewController()
      return .cancel
    case .none:
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
    
    return preferences
  }

  func handleExternalURL(_ url: URL,
                         tab: Tab?,
                         navigationAction: WKNavigationAction,
                         openedURLCompletionHandler: ((Bool) -> Void)? = nil) {
       let isMainFrame = navigationAction.targetFrame?.isMainFrame == true

       // Do not open external links for child tabs automatically
       // The user must tap on the link to open it.
       if tab?.parent != nil && navigationAction.navigationType != .linkActivated {
         return
       }

       // We do not want certain schemes to be opened externally when called from subframes.
       if ["tel", "sms"].contains(url.scheme) && !isMainFrame {
         return
       }

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
