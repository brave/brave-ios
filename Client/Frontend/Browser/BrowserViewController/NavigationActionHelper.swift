// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared
import Data
import BraveShared

/// A class that halps with handling some special navigation actions
class NavigationActionHelper {
  /// An object representing a special action type that needs special handling
  enum SpecialActionType {
    /// Navigations containing the `about` scheme
    case aboutScheme
    /// Bookmarklet. That is a url beginning with `javascript:` but not `javascript:/`
    case bookmarklet
    /// A navigation action directed to the apple maps app
    case appleMapsURL(URL)
    /// A navigation action directed to the apple store app
    case storeURL(URL)
    /// A navigation schema directed to external apps such as `sms`, `tel`, `mailto`
    case externalAppScheme(URL)
    /// Similar to the external App Scheme this one is the `brave` scheme which needs special processing
    case braveScheme(URL)
    /// Internal links such as `localhost`. Some are priviliged while the rest are not.
    case internalLink(isPrivileged: Bool)
    /// A buy vpn link which needs the usage of internal components
    case buyVPN
  }
  
  /// Takes in a navigation action and returns an a value if this action is directed to a type of navigation that needs to be handled specially.
  ///
  /// This includes things like the mail app, telephone links, internal brave links, bookmarks and localhost links
  static func handleSpecialActions(for navigationAction: WKNavigationAction) -> SpecialActionType? {
    guard let url = navigationAction.request.url else { return nil }
    
    if let internalURL = InternalURL(url) {
      return .internalLink(isPrivileged: internalURL.isAuthorized)
    }
    
    guard url.scheme != "about" else { return .aboutScheme }
    guard !url.isBookmarklet else { return .bookmarklet }
    
    // First special case are some schemes that are about calling and email. We prompt the user to confirm this action. This
    // gives us the exact same behaviour as Safari.
    guard !["sms", "tel", "facetime", "facetime-audio", "mailto"].contains(url.scheme) else {
      return .externalAppScheme(url)
    }
    
    // Second special case are a set of URLs that look like regular http links, but should be handed over to iOS
    // instead of being loaded in the webview. Note that there is no point in calling canOpenURL() here, because
    // iOS will always say yes. TODO Is this the same as isWhitelisted?
    guard !url.isAppleMapsURL else {
      return .appleMapsURL(url)
    }
    guard !url.isStoreURL else {
      return .storeURL(url)
    }
    
    // Standard schemes are handled in previous if-case.
    // This check handles custom app schemes to open external apps.
    // Our own 'brave' scheme does not require the switch-app prompt.
    guard url.scheme?.contains("brave") != true else {
      return .braveScheme(url)
    }
    
    // Universal links do not work if the request originates from the app, manual handling is required.
    if let mainDocURL = navigationAction.request.mainDocumentURL,
      let universalLink = UniversalLinkManager.universalLinkType(for: mainDocURL, checkPath: true) {
      switch universalLink {
      case .buyVPN:
        return .buyVPN
      }
    }
    
    return nil
  }
  
  /// Logic that handles brave searches such as those to `search.brave.com`
  static func handleBraveSearch(for navigationAction: WKNavigationAction, tab: Tab, webView: WKWebView, profile: Profile, rewards: BraveRewards) -> URLRequest? {
    guard
      let url = navigationAction.request.url,
      navigationAction.targetFrame?.isMainFrame == true,
      BraveSearchManager.isValidURL(url)
    else {
      tab.braveSearchManager = nil
      return nil
    }
    
    // Add Brave Search headers if Rewards is enabled
    let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
    if !isPrivateBrowsing && rewards.isEnabled && navigationAction.request.allHTTPHeaderFields?["X-Brave-Ads-Enabled"] == nil {
      var modifiedRequest = URLRequest(url: url)
      modifiedRequest.setValue("1", forHTTPHeaderField: "X-Brave-Ads-Enabled")
      return modifiedRequest
    }
    
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
    
    return nil
  }
  
  /// Ensure that the page data loaded is valid and contains the current frame info.
  ///
  /// - Note: You should call this as early as possible unless the request is being cancelled
  static func configurePageData(for navigationAction: WKNavigationAction, on tab: Tab) {
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
  static func configureTabScripts(for navigationAction: WKNavigationAction, on tab: Tab, domain: Domain) {
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
        // Cookie Blocking code below
        .cookieBlocking: Preferences.Privacy.blockAllCookies.value,
        // Add request blocking script
        // This script will block certian `xhr` and `window.fetch()` requests
        .requestBlocking: url.isWebPage(includeDataURIs: false) &&
          domain.isShieldExpected(.AdblockAndTp, considerAllShieldsOption: true)
      ])
    }
  }
  
  /// Handle debouncing redirects and return a URLRequest if a redirect is meant to happen
  static func makeDebounceRequest(for navigationAction: WKNavigationAction, on tab: Tab, domain: Domain) -> URLRequest? {
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
  
  /// Handle special website redirects for things like new twitter to old twitter.
  static func makeWebsiteRedirectRequest(for navigationAction: WKNavigationAction) -> URLRequest? {
    // Handle website redirects
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
  
  /// Ensure that the user agent is set on all main frame navigations
  static func ensureUserAgent(for navigationAction: WKNavigationAction, on tab: Tab, webView: WKWebView) {
    guard
      let url = navigationAction.request.url,
      navigationAction.targetFrame?.isMainFrame == true
    else {
      return
    }
    
    tab.updateUserAgent(webView, newURL: url)
  }
}
