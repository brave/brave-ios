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

extension WKNavigationAction {
  /// Allow local requests only if the request is privileged.
  /// If the request is internal or unprivileged, we should deny it.
  var isInternalUnprivileged: Bool {
    guard let url = request.url else {
      return true
    }

    if let url = InternalURL(url) {
      return !url.isAuthorized
    } else {
      return false
    }
  }
}

extension URL {
  /// Obtain a schemeless absolute string
  fileprivate var schemelessAbsoluteString: String {
    guard let scheme = self.scheme else { return absoluteString }
    return absoluteString.replacingOccurrences(of: "\(scheme)://", with: "")
  }
}

extension BrowserViewController {
  private func tab(for webView: WKWebView) -> Tab? {
    tabManager[webView] ?? (webView as? TabWebView)?.tab
  }
  
  fileprivate func handleExternalURL(_ url: URL,
                                     tab: Tab?,
                                     navigationAction: WKNavigationAction,
                                     openedURLCompletionHandler: ((Bool) -> Void)? = nil) {
    
    let isMainFrame = navigationAction.targetFrame?.isMainFrame == true
    
    // Do not open external links for child tabs automatically
    // The user must tap on the link to open it.
    if tab?.parent != nil && navigationAction.navigationType != .linkActivated {
      return
    }
    
    var alertDetails = String(format: Strings.openExternalAppURLMessage, url.relativeString)
    
    // We do not want certain schemes to be opened externally when called from subframes.
    // And tel / sms dialog should not be shown for non-active tabs #6687
    if ["tel", "sms"].contains(url.scheme) {
      if !isMainFrame || tab?.url?.host != topToolbar.currentURL?.host {
        return
      }
      
      if let displayHost = tab?.url?.withoutWWW.host {
        alertDetails = String(format: Strings.openExternalAppURLHost, displayHost) + "\n\n" + alertDetails
      }
    }
    
    self.view.endEditing(true)
    
    let popup = AlertPopupView(
      imageView: nil,
      title: Strings.openExternalAppURLTitle,
      message: alertDetails,
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

  // Recognize an Apple Maps URL. This will trigger the native app. But only if a search query is present. Otherwise
  // it could just be a visit to a regular page on maps.apple.com.
  fileprivate func isAppleMapsURL(_ url: URL) -> Bool {
    if url.scheme == "http" || url.scheme == "https" {
      if url.host == "maps.apple.com" && url.query != nil {
        return true
      }
    }
    return false
  }

  // Recognize a iTunes Store URL. These all trigger the native apps. Note that appstore.com and phobos.apple.com
  // used to be in this list. I have removed them because they now redirect to itunes.apple.com. If we special case
  // them then iOS will actually first open Safari, which then redirects to the app store. This works but it will
  // leave a 'Back to Safari' button in the status bar, which we do not want.
  fileprivate func isStoreURL(_ url: URL) -> Bool {
    if url.scheme == "http" || url.scheme == "https" {
      if url.host == "itunes.apple.com" {
        return true
      }
    }
    if url.scheme == "itms-appss" || url.scheme == "itmss" {
      return true
    }
    return false
  }

  // This is the place where we decide what to do with a new navigation action. There are a number of special schemes
  // and http(s) urls that need to be handled in a different way. All the logic for that is inside this delegate
  // method.

  fileprivate func isUpholdOAuthAuthorization(_ url: URL) -> Bool {
    return url.scheme == "rewards" && url.host == "uphold"
  }

  public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
    guard let url = navigationAction.request.url else {
      return (.cancel, preferences)
    }

    if InternalURL.isValid(url: url) {
      if navigationAction.navigationType != .backForward, navigationAction.isInternalUnprivileged {
        Logger.module.warning("Denying unprivileged request: \(navigationAction.request)")
        return (.cancel, preferences)
      }

      return (.allow, preferences)
    }

    if url.scheme == "about" {
      return (.allow, preferences)
    }

    if url.isBookmarklet {
      return (.cancel, preferences)
    }

    // Universal links do not work if the request originates from the app, manual handling is required.
    if let mainDocURL = navigationAction.request.mainDocumentURL,
      let universalLink = UniversalLinkManager.universalLinkType(for: mainDocURL, checkPath: true) {
      switch universalLink {
      case .buyVPN:
        presentCorrespondingVPNViewController()
        return (.cancel, preferences)
      }
    }

    // First special case are some schemes that are about Calling. We prompt the user to confirm this action. This
    // gives us the exact same behaviour as Safari.
    let tab = tab(for: webView)
    
    if ["sms", "tel", "facetime", "facetime-audio"].contains(url.scheme) {
      
      // Do not allow opening external URLs from child tabs
      handleExternalURL(url, tab: tab, navigationAction: navigationAction)
      return (.cancel, preferences)
    }

    // Second special case are a set of URLs that look like regular http links, but should be handed over to iOS
    // instead of being loaded in the webview. Note that there is no point in calling canOpenURL() here, because
    // iOS will always say yes. TODO Is this the same as isWhitelisted?

    if isAppleMapsURL(url) {
      // Do not allow opening external URLs from child tabs
      handleExternalURL(url, tab: tab, navigationAction: navigationAction)
      return (.cancel, preferences)
    }

    if isStoreURL(url) {
      // Do not allow opening external URLs from child tabs
      handleExternalURL(url, tab: tab, navigationAction: navigationAction)
      return (.cancel, preferences)
    }

    // Handles custom mailto URL schemes.
    if url.scheme == "mailto" {
      // Do not allow opening external URLs from child tabs
      handleExternalURL(url, tab: tab, navigationAction: navigationAction)
      return (.cancel, preferences)
    }

    let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
    
    // Website redirection logic
    if url.isWebPage(includeDataURIs: false),
       navigationAction.targetFrame?.isMainFrame == true,
       let redirectURL = WebsiteRedirects.redirect(for: url) {
      
      tab?.loadRequest(URLRequest(url: redirectURL))
      return (.cancel, preferences)
    }
    
    // before loading any ad-block scripts
    // await the preparation of the ad-block services
    await LaunchHelper.shared.prepareAdBlockServices(
      adBlockService: self.braveCore.adblockService
    )
    
    if let mainDocumentURL = navigationAction.request.mainDocumentURL {
      if mainDocumentURL != tab?.currentPageData?.mainFrameURL {
        // Clear the current page data if the page changes.
        // Do this before anything else so that we have a clean slate.
        tab?.currentPageData = PageData(mainFrameURL: mainDocumentURL)
      }
      
      let domainForMainFrame = Domain.getOrCreate(forUrl: mainDocumentURL, persistent: !isPrivateBrowsing)
      // Enable safe browsing (frodulent website warnings)
      webView.configuration.preferences.isFraudulentWebsiteWarningEnabled = domainForMainFrame.isShieldExpected(.SafeBrowsing, considerAllShieldsOption: true)
      
      // Debouncing logic
      // Handle debouncing for main frame only and only if the site (etld+1) changes
      // We also only handle `http` and `https` requests
      if url.isWebPage(includeDataURIs: false),
         let currentURL = tab?.webView?.url,
         currentURL.baseDomain != url.baseDomain,
         domainForMainFrame.isShieldExpected(.AdblockAndTp, considerAllShieldsOption: true),
         navigationAction.targetFrame?.isMainFrame == true {
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
        if let redirectURL = redirectChain.last?.url {
          // For now we only allow the `Referer`. The browser will add other headers during navigation.
          var modifiedRequest = URLRequest(url: redirectURL)

          for (headerKey, headerValue) in navigationAction.request.allHTTPHeaderFields ?? [:] {
            guard headerKey == "Referer" else { continue }
            modifiedRequest.setValue(headerValue, forHTTPHeaderField: headerKey)
          }

          tab?.loadRequest(modifiedRequest)
          // Cancel the original request. We don't want it to load as it's tracking us
          return (.cancel, preferences)
        }
      }
      
      // Set some additional user scripts
      if navigationAction.targetFrame?.isMainFrame == true {
        tab?.setScripts(scripts: [
          // Add de-amp script
          // The user script manager will take care to not reload scripts if this value doesn't change
          .deAmp: Preferences.Shields.autoRedirectAMPPages.value,
          
          // Add request blocking script
          // This script will block certian `xhr` and `window.fetch()` requests
          .requestBlocking: url.isWebPage(includeDataURIs: false) &&
                            domainForMainFrame.isShieldExpected(.AdblockAndTp, considerAllShieldsOption: true),
          
          // The tracker protection script
          // This script will track what is blocked and increase stats
          .trackerProtectionStats: url.isWebPage(includeDataURIs: false) &&
                                   domainForMainFrame.isShieldExpected(.AdblockAndTp, considerAllShieldsOption: true)
        ])
      }
      
      // Check if custom user scripts must be added to or removed from the web view.
      if let targetFrame = navigationAction.targetFrame {
        tab?.currentPageData?.addSubframeURL(forRequestURL: url, isForMainFrame: targetFrame.isMainFrame)
        let scriptTypes = tab?.currentPageData?.makeUserScriptTypes(domain: domainForMainFrame) ?? []
        tab?.setCustomUserScript(scripts: scriptTypes)
      }
    }

    // Brave Search logic.

    if navigationAction.targetFrame?.isMainFrame == true,
      BraveSearchManager.isValidURL(url) {

      // Add Brave Search headers if Rewards is enabled
      if !isPrivateBrowsing && rewards.isEnabled && navigationAction.request.allHTTPHeaderFields?["X-Brave-Ads-Enabled"] == nil {
        var modifiedRequest = URLRequest(url: url)
        modifiedRequest.setValue("1", forHTTPHeaderField: "X-Brave-Ads-Enabled")
        tab?.loadRequest(modifiedRequest)
        return (.cancel, preferences)
      }

      // We fetch cookies to determine if backup search was enabled on the website.
      let profile = self.profile
      webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
        tab?.braveSearchManager = BraveSearchManager(profile: profile, url: url, cookies: cookies)
        if let braveSearchManager = tab?.braveSearchManager {
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
                tab?.injectResults()
              }
            }
          }
        }
      }
    } else {
      tab?.braveSearchManager = nil
    }

    // This is the normal case, opening a http or https url, which we handle by loading them in this WKWebView. We
    // always allow this. Additionally, data URIs are also handled just like normal web pages.

    if ["http", "https", "data", "blob", "file"].contains(url.scheme) {
      if navigationAction.targetFrame?.isMainFrame == true {
        tab?.updateUserAgent(webView, newURL: url)
      }

      pendingRequests[url.absoluteString] = navigationAction.request

      // TODO: Downgrade to 14.5 once api becomes available.
      if #unavailable(iOS 15.0) {
        if Preferences.Shields.httpsEverywhere.value,
          url.scheme == "http",
          let urlHost = url.normalizedHost() {
          HttpsEverywhereStats.shared.shouldUpgrade(url) { shouldupgrade in
            DispatchQueue.main.async {
              if shouldupgrade {
                self.pendingHTTPUpgrades[urlHost] = navigationAction.request
              }
            }
          }
        }
      }

      // Adblock logic,
      // Only use main document URL, not the request URL
      // If an iFrame is loaded, shields depending on the main frame, not the iFrame request

      // Weird behavior here with `targetFram` and `sourceFrame`, on refreshing page `sourceFrame` is not nil (it is non-optional)
      //  however, it is still an uninitialized object, making it an unreliable source to compare `isMainFrame` against.
      //  Rather than using `sourceFrame.isMainFrame` or even comparing `sourceFrame == targetFrame`, a simple URL check is used.
      // No adblocking logic is be used on session restore urls. It uses javascript to retrieve the
      // request then the page is reloaded with a proper url and adblocking rules are applied.
      if let mainDocumentURL = navigationAction.request.mainDocumentURL,
        mainDocumentURL.schemelessAbsoluteString == url.schemelessAbsoluteString,
        !(InternalURL(url)?.isSessionRestore ?? false),
        navigationAction.sourceFrame.isMainFrame || navigationAction.targetFrame?.isMainFrame == true {
        // Identify specific block lists that need to be applied to the requesting domain
        let domainForShields = Domain.getOrCreate(forUrl: mainDocumentURL, persistent: !isPrivateBrowsing)
        
        // Load rule lists
        tab?.contentBlocker.ruleListTypes = ContentBlockerManager.shared.compiledRuleTypes(
          for: domainForShields
        )
        
        let isScriptsEnabled = !domainForShields.isShieldExpected(.NoScript, considerAllShieldsOption: true)
        preferences.allowsContentJavaScript = isScriptsEnabled
      }

      // Cookie Blocking code below
      if let tab = tab {
        tab.setScript(script: .cookieBlocking, enabled: Preferences.Privacy.blockAllCookies.value)
      }

      // Reset the block alert bool on new host.
      if let newHost: String = url.host, let oldHost: String = webView.url?.host, newHost != oldHost {
        self.tabManager.selectedTab?.alertShownCount = 0
        self.tabManager.selectedTab?.blockAllAlerts = false
      }

      return (.allow, preferences)
    }

    // Standard schemes are handled in previous if-case.
    // This check handles custom app schemes to open external apps.
    // Our own 'brave' scheme does not require the switch-app prompt.
    if url.scheme?.contains("brave") == false {
      // Do not allow opening external URLs from child tabs
      handleExternalURL(url, tab: tab, navigationAction: navigationAction) { didOpenURL in
        // Do not show error message for JS navigated links or redirect
        // as it's not the result of a user action.
        if !didOpenURL, navigationAction.navigationType == .linkActivated {
          let alert = UIAlertController(title: Strings.unableToOpenURLErrorTitle, message: Strings.unableToOpenURLError, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: nil))
          self.present(alert, animated: true, completion: nil)
        }
      }
    }
    
    return (.cancel, preferences)
  }

  public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
    let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
    let response = navigationResponse.response
    let responseURL = response.url
    let tab = tab(for: webView)
    
    // Check if we upgraded to https and if so we need to update the url of frame evaluations
    if let responseURL = responseURL,
       let domain = tab?.currentPageData?.domain(persistent: !isPrivateBrowsing),
       tab?.currentPageData?.upgradeFrameURL(forResponseURL: responseURL, isForMainFrame: navigationResponse.isForMainFrame) == true {
      let scriptTypes = tab?.currentPageData?.makeUserScriptTypes(domain: domain) ?? []
      tab?.setCustomUserScript(scripts: scriptTypes)
    }

    if let tab = tab,
      let responseURL = responseURL,
      InternalURL(responseURL)?.isSessionRestore == true {
      tab.shouldClassifyLoadsForAds = false
    }

    var request: URLRequest?
    if let url = responseURL {
      request = pendingRequests.removeValue(forKey: url.absoluteString)
    }

    // We can only show this content in the web view if this web view is not pending
    // download via the context menu.
    let canShowInWebView = navigationResponse.canShowMIMEType && (webView != pendingDownloadWebView)
    let forceDownload = webView == pendingDownloadWebView

    if let url = responseURL, let urlHost = responseURL?.normalizedHost() {
      // If an upgraded https load happens with a host which was upgraded, increase the stats
      if url.scheme == "https", let _ = pendingHTTPUpgrades.removeValue(forKey: urlHost) {
        BraveGlobalShieldStats.shared.httpse += 1
        if let stats = tab?.contentBlocker.stats {
          tab?.contentBlocker.stats = stats.adding(httpsCount: 1)
        }
      }
    }

    // Check if this response should be handed off to Passbook.
    if let passbookHelper = OpenPassBookHelper(request: request, response: response, canShowInWebView: canShowInWebView, forceDownload: forceDownload, browserViewController: self) {
      // Open our helper and cancel this response from the webview.
      passbookHelper.open()
      return .cancel
    }

    // Check if this response should be downloaded.
    let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
    if let downloadHelper = DownloadHelper(request: request, response: response, cookieStore: cookieStore, canShowInWebView: canShowInWebView, forceDownload: forceDownload) {
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
      if response.mimeType?.isKindOfHTML == false, let request = request {
        tab.temporaryDocument = TemporaryDocument(preflightResponse: response, request: request, tab: tab)
      } else {
        tab.temporaryDocument = nil
      }

      tab.mimeType = response.mimeType
    }
    
    // Record the navigation visit type for the URL after navigation actions
    // this is done in decidePolicyFor to handle all the cases like redirects etc.
    if let url = responseURL, let tab = tab, !url.isReaderModeURL, !url.isFileURL, url.isWebPage(), !tab.isPrivate {
      recordNavigationInTab(url, visitType: lastEnteredURLVisitType)
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
    guard let tab = tab(for: webView), let url = webView.url, rewards.isEnabled else { return }
    tab.redirectURLs.append(url)
  }
  
  /// Invoked when an error occurs while starting to load data for the main frame.
  public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    // Ignore the "Frame load interrupted" error that is triggered when we cancel a request
    // to open an external application and hand it over to UIApplication.openURL(). The result
    // will be that we switch to the external app, for example the app store, while keeping the
    // original web page in the tab instead of replacing it with an error page.
    let error = error as NSError
    if error.domain == "WebKitErrorDomain" && error.code == 102 {
      return
    }

    if checkIfWebContentProcessHasCrashed(webView, error: error) {
      return
    }

    if error.code == Int(CFNetworkErrors.cfurlErrorCancelled.rawValue) {
      if let tab = tabManager[webView], tab === tabManager.selectedTab {
        updateToolbarCurrentURL(tab.url?.displayURL)
        updateWebViewPageZoom(tab: tab)
      }
      return
    }

    if let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
      ErrorPageHelper(certStore: profile.certStore).loadPage(error, forUrl: url, inWebView: webView)
      // Submitting same errornous URL using toolbar will cause progress bar get stuck
      // Reseting the progress bar in case there is an error is necessary
      topToolbar.hideProgressBar()

      // If the local web server isn't working for some reason (Brave cellular data is
      // disabled in settings, for example), we'll fail to load the session restore URL.
      // We rely on loading that page to get the restore callback to reset the restoring
      // flag, so if we fail to load that page, reset it here.
      if InternalURL(url)?.aboutComponent == "sessionrestore" {
        tabManager.allTabs.filter { $0.webView == webView }.first?.restoring = false
      }
    }
  }
}

extension WKNavigationType: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .linkActivated: return "linkActivated"
    case .formResubmitted: return "formResubmitted"
    case .backForward: return "backForward"
    case .formSubmitted: return "formSubmitted"
    case .other: return "other"
    case .reload: return "reload"
    @unknown default:
      return "Unknown(\(rawValue))"
    }
  }
}
