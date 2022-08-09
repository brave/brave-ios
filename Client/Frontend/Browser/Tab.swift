/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared
import BraveCore
import BraveShared
import SwiftyJSON
import XCGLogger
import Data

private let log = Logger.browserLogger

protocol TabContentScript {
  static func name() -> String
  func scriptMessageHandlerName() -> String?
  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void)
}

protocol TabDelegate {
  func tab(_ tab: Tab, didAddSnackbar bar: SnackBar)
  func tab(_ tab: Tab, didRemoveSnackbar bar: SnackBar)
  /// Triggered when "Find in Page" is selected on selected web text
  func tab(_ tab: Tab, didSelectFindInPageFor selectedText: String)
  /// Triggered when "Search with Brave" is selected on selected web text
  func tab(_ tab: Tab, didSelectSearchWithBraveFor selectedText: String)
  func tab(_ tab: Tab, didCreateWebView webView: WKWebView)
  func tab(_ tab: Tab, willDeleteWebView webView: WKWebView)
  func showRequestRewardsPanel(_ tab: Tab)
  func stopMediaPlayback(_ tab: Tab)
  func showWalletNotification(_ tab: Tab, origin: URLOrigin)
  func updateURLBarWalletButton()
  func isTabVisible(_ tab: Tab) -> Bool
}

@objc
protocol URLChangeDelegate {
  func tab(_ tab: Tab, urlDidChangeTo url: URL)
}

enum TabSecureContentState {
  case localHost
  case secure
  case insecure
  case unknown
}

class Tab: NSObject {
  var id: String?

  let rewardsId: UInt32

  var onScreenshotUpdated: (() -> Void)?
  var rewardsEnabledCallback: ((Bool) -> Void)?

  var alertShownCount: Int = 0
  var blockAllAlerts: Bool = false
  private(set) var type: TabType = .regular

  var redirectURLs = [URL]()

  var isPrivate: Bool {
    return type.isPrivate
  }

  var secureContentState: TabSecureContentState = .unknown

  var walletProvider: BraveWalletEthereumProvider?
  var walletProviderJS: String?
  var isWalletIconVisible: Bool = false {
    didSet {
      tabDelegate?.updateURLBarWalletButton()
    }
  }
  var walletKeyringService: BraveWalletKeyringService? {
    didSet {
      walletKeyringService?.add(self)
    }
  }
  // PageMetadata is derived from the page content itself, and as such lags behind the
  // rest of the tab.
  var pageMetadata: PageMetadata?

  var canonicalURL: URL? {
    if let string = pageMetadata?.siteURL,
      let siteURL = URL(string: string) {
      return siteURL
    }
    return self.url
  }

  /// The URL that should be shared when requested by the user via the share sheet
  ///
  /// If the canonical URL of the page points to a different base domain entirely, this will result in
  /// sharing the canonical URL. This is to ensure pages such as Google's AMP share the correct URL while
  /// also ensuring single page applications which don't update their canonical URLs on navigation share
  /// the current pages URL
  var shareURL: URL? {
    guard let url = url else { return nil }
    if let canonicalURL = canonicalURL, canonicalURL.baseDomain != url.baseDomain {
      return canonicalURL
    }
    return url
  }

  var userActivity: NSUserActivity?

  var webView: BraveWebView?
  var tabDelegate: TabDelegate?
  weak var urlDidChangeDelegate: URLChangeDelegate?  // TODO: generalize this.
  var bars = [SnackBar]()
  var favicons = [Favicon]()
  var lastExecutedTime: Timestamp?
  var sessionData: SessionData?
  fileprivate var lastRequest: URLRequest?
  var restoring: Bool = false
  var pendingScreenshot = false
  
  /// The url set after a successful navigation. This will also set the `url` property.
  ///
  /// - Note: Unlike the `url` property, which may be set during pre-navigation,
  /// the `committedURL` is only assigned when navigation was committed..
  var committedURL: URL? {
    willSet {
      url = newValue
      previousComittedURL = committedURL
    }
  }
  
  /// The previous url that was set before `comittedURL` was set again
  private(set) var previousComittedURL: URL?
  
  var url: URL? {
    didSet {
      if let _url = url, let internalUrl = InternalURL(_url), internalUrl.isAuthorized {
        url = URL(string: internalUrl.stripAuthorization)
      }
    }
  }
  var lastKnownUrl: URL? {
    // Tab url can be nil when user cold starts the app
    // thus we check session data for last known url
    guard self.url != nil else {
      return self.sessionData?.urls.last
    }
    return self.url
  }
  var mimeType: String?
  var isEditing: Bool = false
  var shouldClassifyLoadsForAds = true
  var playlistItem: PlaylistInfo?
  var playlistItemState: PlaylistItemAddedState = .none

  /// The tabs new tab page controller.
  ///
  /// Should be setup in BVC then assigned here for future use.
  var newTabPageViewController: NewTabPageViewController? {
    willSet {
      if newValue == nil {
        deleteNewTabPageController()
      }
    }
  }

  private func deleteNewTabPageController() {
    guard let controller = newTabPageViewController, controller.parent != nil else { return }
    controller.willMove(toParent: nil)
    controller.removeFromParent()
    controller.view.removeFromSuperview()
  }

  /// When viewing a non-HTML content type in the webview (like a PDF document), this URL will
  /// point to a tempfile containing the content so it can be shared to external applications.
  var temporaryDocument: TemporaryDocument?

  fileprivate var _noImageMode = false

  // Use computed property so @available can be used to guard `noImageMode`.
  var noImageMode: Bool {
    get { return _noImageMode }
    set {
      if newValue == _noImageMode {
        return
      }
      _noImageMode = newValue
      contentBlocker.noImageMode(enabled: _noImageMode)
    }
  }

  // There is no 'available macro' on props, we currently just need to store ownership.
  lazy var contentBlocker = ContentBlockerHelper(tab: self)
  lazy var requestBlockingContentHelper = RequestBlockingContentHelper(tab: self)

  /// The last title shown by this tab. Used by the tab tray to show titles for zombie tabs.
  var lastTitle: String?

  var isDesktopSite: Bool {
    webView?.customUserAgent?.lowercased().contains("mobile") == false
  }
  
  var containsWebPage: Bool {
    if let url = url {
      let isHomeURL = InternalURL(url)?.isAboutHomeURL
      return url.isWebPage() && isHomeURL != true
    }
    
    return false
  }

  /// In-memory dictionary of websites that were explicitly set to use either desktop or mobile user agent.
  /// Key is url's base domain, value is desktop mode on or off.
  /// Each tab has separate list of website overrides.
  private var userAgentOverrides: [String: Bool] = [:]

  var readerModeAvailableOrActive: Bool {
    if let readerMode = self.getContentScript(name: "ReaderMode") as? ReaderMode {
      return readerMode.state != .unavailable
    }
    return false
  }

  fileprivate(set) var screenshot: UIImage?
  var screenshotUUID: UUID? {
    didSet { TabMO.saveScreenshotUUID(screenshotUUID, tabId: id) }
  }
  
  var webStateDebounceTimer: Timer?
  var onPageReadyStateChanged: ((ReadyState.State) -> Void)?

  // If this tab has been opened from another, its parent will point to the tab from which it was opened
  var parent: Tab?

  fileprivate var contentScriptManager = TabContentScriptManager()
  private(set) var userScriptManager: UserScriptManager?

  fileprivate var configuration: WKWebViewConfiguration?

  /// Any time a tab tries to make requests to display a Javascript Alert and we are not the active
  /// tab instance, queue it for later until we become foregrounded.
  fileprivate var alertQueue = [JSAlertInfo]()

  var nightMode: Bool {
    didSet {
      var isNightModeEnabled = false
      
      if let fetchedTabURL = fetchedURL, !fetchedTabURL.isNightModeBlockedURL, nightMode {
        isNightModeEnabled = true
      }
      
      webView?.evaluateSafeJavaScript(
        functionName: "window.__firefox__.NightMode.setEnabled",
        args: [isNightModeEnabled],
        contentWorld: .defaultClient,
        asFunction: true
      ) { _, error in
        if let error = error {
          log.error("Error executing script: \(error)")
        }
      }

      userScriptManager?.isNightModeEnabled = isNightModeEnabled
    }
  }

  init(configuration: WKWebViewConfiguration, type: TabType = .regular) {
    self.configuration = configuration
    rewardsId = UInt32.random(in: 1...UInt32.max)
    nightMode = Preferences.General.nightModeEnabled.value

    super.init()
    self.type = type
  }

  weak var navigationDelegate: WKNavigationDelegate? {
    didSet {
      if let webView = webView {
        webView.navigationDelegate = navigationDelegate
      }
    }
  }

  /// A helper property that handles native to Brave Search communication.
  var braveSearchManager: BraveSearchManager?

  private lazy var refreshControl = UIRefreshControl().then {
    $0.addTarget(self, action: #selector(reload), for: .valueChanged)
  }

  func createWebview() {
    if webView == nil {
      assert(configuration != nil, "Create webview can only be called once")
      configuration!.userContentController = WKUserContentController()
      configuration!.preferences = WKPreferences()
      configuration!.preferences.javaScriptCanOpenWindowsAutomatically = false
      configuration!.preferences.isFraudulentWebsiteWarningEnabled = Preferences.Shields.googleSafeBrowsing.value
      configuration!.allowsInlineMediaPlayback = true
      // Enables Zoom in website by ignoring their javascript based viewport Scale limits.
      configuration!.ignoresViewportScaleLimits = true

      // TODO: Downgrade to 14.5 once api becomes available.
      if #available(iOS 15.0, *) {
        configuration!.upgradeKnownHostsToHTTPS = Preferences.Shields.httpsEverywhere.value
      }

      if configuration!.urlSchemeHandler(forURLScheme: InternalURL.scheme) == nil {
        configuration!.setURLSchemeHandler(InternalSchemeHandler(), forURLScheme: InternalURL.scheme)
      }
      let webView = TabWebView(frame: .zero, configuration: configuration!, isPrivate: isPrivate)
      webView.delegate = self
      configuration = nil

      webView.accessibilityLabel = Strings.webContentAccessibilityLabel
      webView.allowsBackForwardNavigationGestures = true
      webView.allowsLinkPreview = true

      // Turning off masking allows the web content to flow outside of the scrollView's frame
      // which allows the content appear beneath the toolbars in the BrowserViewController
      webView.scrollView.layer.masksToBounds = false
      webView.navigationDelegate = navigationDelegate

      restore(webView, restorationData: self.sessionData?.savedTabData)

      self.webView = webView
      self.webView?.addObserver(self, forKeyPath: KVOConstants.URL.rawValue, options: .new, context: nil)
      self.userScriptManager = UserScriptManager(
        tab: self,
        isCookieBlockingEnabled: Preferences.Privacy.blockAllCookies.value,
        isPaymentRequestEnabled: webView.hasOnlySecureContent,
        isWebCompatibilityMediaSourceAPIEnabled: Preferences.Playlist.webMediaSourceCompatibility.value,
        isMediaBackgroundPlaybackEnabled: Preferences.General.mediaAutoBackgrounding.value,
        isNightModeEnabled: Preferences.General.nightModeEnabled.value,
        isDeAMPEnabled: Preferences.Shields.autoRedirectAMPPages.value,
        walletProviderJS: walletProviderJS
      )
      tabDelegate?.tab(self, didCreateWebView: webView)

      nightMode = Preferences.General.nightModeEnabled.value
    }
  }

  func resetWebView(config: WKWebViewConfiguration) {
    configuration = config
    deleteWebView()
    contentScriptManager.helpers.removeAll()
  }

  func clearHistory(config: WKWebViewConfiguration) {
    guard let webView = webView,
      let tabID = id
    else {
      return
    }

    // Remove the tab history from saved tabs
    TabMO.removeHistory(with: tabID)

    /*
         * Clear selector is used on WKWebView backForwardList because backForwardList list is only exposed with a getter
         * and this method Removes all items except the current one in the tab list so when another url is added it will add the list properly
         * This approach is chosen to achieve removing tab history in the event of removing  browser history
         * Best way perform this is to clear the backforward list and in our case there is no drawback to clear the list
         * And alternative would be to reload webpages which will be costly and also can cause unexpected results
         */
    let argument: [Any] = ["_c", "lea", "r"]

    let method = argument.compactMap { $0 as? String }.joined()
    let selector: Selector = NSSelectorFromString(method)

    if webView.backForwardList.responds(to: selector) {
      webView.backForwardList.performSelector(onMainThread: selector, with: nil, waitUntilDone: true)
    }
  }

  func restore(_ webView: WKWebView, restorationData: SavedTab?) {
    // Pulls restored session data from a previous SavedTab to load into the Tab. If it's nil, a session restore
    // has already been triggered via custom URL, so we use the last request to trigger it again; otherwise,
    // we extract the information needed to restore the tabs and create a NSURLRequest with the custom session restore URL
    // to trigger the session restore via custom handlers
    if let sessionData = restorationData {
      restoring = true

      lastTitle = sessionData.title

      var urls = [String]()
      for url in sessionData.history {
        guard let url = URL(string: url) else { continue }
        urls.append(url.absoluteString)
      }

      let currentPage = sessionData.historyIndex
      self.sessionData = nil
      var jsonDict = [String: AnyObject]()
      jsonDict["history"] = urls as AnyObject?
      jsonDict["currentPage"] = currentPage as AnyObject?
      guard let json = JSON(jsonDict).rawString()?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        return
      }

      if let restoreURL = URL(string: "\(InternalURL.baseUrl)/\(SessionRestoreHandler.path)?history=\(json)") {
        let request = PrivilegedRequest(url: restoreURL) as URLRequest
        webView.load(request)
        lastRequest = request
      }
    } else if let request = lastRequest {
      webView.load(request)
    } else {
      log.warning("creating webview with no lastRequest and no session data: \(String(describing: self.url))")
    }

  }

  func deleteWebView() {
    contentScriptManager.uninstall(from: self)

    if let webView = webView {
      webView.removeObserver(self, forKeyPath: KVOConstants.URL.rawValue)
      tabDelegate?.tab(self, willDeleteWebView: webView)
    }
    webView = nil
  }

  deinit {
    deleteWebView()
    deleteNewTabPageController()
    contentScriptManager.helpers.removeAll()
  }

  var loading: Bool {
    return webView?.isLoading ?? false
  }

  var estimatedProgress: Double {
    return webView?.estimatedProgress ?? 0
  }

  var backList: [WKBackForwardListItem]? {
    return webView?.backForwardList.backList
  }

  var forwardList: [WKBackForwardListItem]? {
    return webView?.backForwardList.forwardList
  }

  var historyList: [URL] {
    func listToUrl(_ item: WKBackForwardListItem) -> URL { return item.url }
    var tabs = self.backList?.map(listToUrl) ?? [URL]()
    tabs.append(self.url!)
    return tabs
  }

  var title: String? {
    return webView?.title
  }

  var displayTitle: String {
    if let title = webView?.title, !title.isEmpty {
      return title.contains("localhost") ? "" : title
    }

    // When picking a display title. Tabs with sessionData are pending a restore so show their old title.
    // To prevent flickering of the display title. If a tab is restoring make sure to use its lastTitle.
    if let url = self.url, InternalURL(url)?.isAboutHomeURL ?? false, sessionData == nil, !restoring {
      return Strings.newTabTitle
    }

    // lets double check the sessionData in case this is a non-restored new tab
    if let firstURL = sessionData?.urls.first, sessionData?.urls.count == 1, InternalURL(firstURL)?.isAboutHomeURL ?? false {
      return Strings.newTabTitle
    }

    if let url = self.url, !InternalURL.isValid(url: url), let shownUrl = url.displayURL?.absoluteString {
      return shownUrl
    }

    guard let lastTitle = lastTitle, !lastTitle.isEmpty else {
      // FF uses url?.displayURL?.absoluteString ??  ""
      // but we can grab the title from `TabMO`
      if let title = url?.absoluteString {
        return title
      } else if let tab = TabMO.get(fromId: id) {
        return tab.title ?? tab.url ?? ""
      }
      return ""
    }

    return lastTitle
  }

  var currentInitialURL: URL? {
    return self.webView?.backForwardList.currentItem?.initialURL
  }

  var displayFavicon: Favicon? {
    if let url = url, InternalURL(url)?.isAboutHomeURL == true { return nil }
    return favicons.max { $0.width! < $1.width! }
  }

  var canGoBack: Bool {
    return webView?.canGoBack ?? false
  }

  var canGoForward: Bool {
    return webView?.canGoForward ?? false
  }
  
  /// This property is for fetching the actual URL for the Tab
  /// In private browsing the URL is in memory but this is not the case for normal mode
  /// For Normal  Mode Tab information is fetched using Tab ID from 
  var fetchedURL: URL? {
    if PrivateBrowsingManager.shared.isPrivateBrowsing {
      if let url = url, url.isWebPage() {
        return url
      }
    } else {
      if let tabUrl = url, tabUrl.isWebPage() {
        return tabUrl
      } else if let tabID = id {
        let fetchedTab = TabMO.get(fromId: tabID)
        
        if let urlString = fetchedTab?.url, let url = URL(string: urlString), url.isWebPage() {
          return url
        }
      }
    }
    
    return nil
  }

  func goBack() {
    _ = webView?.goBack()
  }

  func goForward() {
    _ = webView?.goForward()
  }

  func goToBackForwardListItem(_ item: WKBackForwardListItem) {
    _ = webView?.go(to: item)
  }

  @discardableResult func loadRequest(_ request: URLRequest) -> WKNavigation? {
    if let webView = webView {
      lastRequest = request
      if let url = request.url {
        if url.isFileURL, request.isPrivileged {
          return webView.loadFileURL(url, allowingReadAccessTo: url)
        }

        /// Donate Custom Intent Open Website
        if url.isSecureWebPage(), !isPrivate {
          ActivityShortcutManager.shared.donateCustomIntent(for: .openWebsite, with: url.absoluteString)
        }
      }

      return webView.load(request)
    }
    return nil
  }

  func stop() {
    webView?.stopLoading()
  }

  @objc func reload() {
    // Clear the user agent before further navigation.
    // Proper User Agent setting happens in BVC's WKNavigationDelegate.
    // This prevents a bug with back-forward list, going back or forward and reloading the tab
    // loaded wrong user agent.
    webView?.customUserAgent = nil

    defer {
      if let refreshControl = webView?.scrollView.refreshControl,
        refreshControl.isRefreshing {
        refreshControl.endRefreshing()
      }
    }

    // If the current page is an error page, and the reload button is tapped, load the original URL
    if let url = webView?.url, let internalUrl = InternalURL(url), let page = internalUrl.originalURLFromErrorPage {
      webView?.replaceLocation(with: page)
      return
    }

    if let _ = webView?.reloadFromOrigin() {
      nightMode = Preferences.General.nightModeEnabled.value
      log.debug("reloaded zombified tab from origin")
      return
    }

    if let webView = self.webView {
      log.debug("restoring webView from scratch")
      restore(webView, restorationData: sessionData?.savedTabData)
    }
  }

  func updateUserAgent(_ webView: WKWebView, newURL: URL) {
    guard let baseDomain = newURL.baseDomain else { return }

    let desktopMode = userAgentOverrides[baseDomain] ?? UserAgent.shouldUseDesktopMode
    webView.customUserAgent = desktopMode ? UserAgent.desktop : UserAgent.mobile
  }

  func addContentScript(_ helper: TabContentScript, name: String, contentWorld: WKContentWorld) {
    contentScriptManager.addContentScript(helper, name: name, forTab: self, contentWorld: contentWorld)
  }

  func getContentScript(name: String) -> TabContentScript? {
    return contentScriptManager.getContentScript(name)
  }

  func hideContent(_ animated: Bool = false) {
    webView?.isUserInteractionEnabled = false
    if animated {
      UIView.animate(
        withDuration: 0.25,
        animations: { () -> Void in
          self.webView?.alpha = 0.0
        })
    } else {
      webView?.alpha = 0.0
    }
  }

  func showContent(_ animated: Bool = false) {
    webView?.isUserInteractionEnabled = true
    if animated {
      UIView.animate(
        withDuration: 0.25,
        animations: { () -> Void in
          self.webView?.alpha = 1.0
        })
    } else {
      webView?.alpha = 1.0
    }
  }

  func addSnackbar(_ bar: SnackBar) {
    bars.append(bar)
    tabDelegate?.tab(self, didAddSnackbar: bar)
  }

  func removeSnackbar(_ bar: SnackBar) {
    if let index = bars.firstIndex(of: bar) {
      bars.remove(at: index)
      tabDelegate?.tab(self, didRemoveSnackbar: bar)
    }
  }

  func removeAllSnackbars() {
    // Enumerate backwards here because we'll remove items from the list as we go.
    bars.reversed().forEach { removeSnackbar($0) }
  }

  func expireSnackbars() {
    // Enumerate backwards here because we may remove items from the list as we go.
    bars.reversed().filter({ !$0.shouldPersist(self) }).forEach({ removeSnackbar($0) })
  }

  func setScreenshot(_ screenshot: UIImage?, revUUID: Bool = true) {
    self.screenshot = screenshot
    if revUUID {
      self.screenshotUUID = UUID()
    }

    onScreenshotUpdated?()
  }

  /// Switches user agent Desktop -> Mobile or Mobile -> Desktop.
  func switchUserAgent() {
    if let urlString = webView?.url?.baseDomain {
      // The website was changed once already, need to flip the override.
      if let siteOverride = userAgentOverrides[urlString] {
        userAgentOverrides[urlString] = !siteOverride
      } else {
        // First time switch, adding the basedomain to dictionary with flipped value.
        userAgentOverrides[urlString] = !UserAgent.shouldUseDesktopMode
      }
    }

    reload()
  }

  func queueJavascriptAlertPrompt(_ alert: JSAlertInfo) {
    alertQueue.append(alert)
  }

  func dequeueJavascriptAlertPrompt() -> JSAlertInfo? {
    guard !alertQueue.isEmpty else {
      return nil
    }
    return alertQueue.removeFirst()
  }

  func cancelQueuedAlerts() {
    alertQueue.forEach { alert in
      alert.cancel()
    }
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
    guard let webView = object as? BraveWebView, webView == self.webView,
      let path = keyPath, path == KVOConstants.URL.rawValue
    else {
      return assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")")
    }
    guard let url = self.webView?.url else {
      return
    }

    updatePullToRefreshVisibility()

    self.urlDidChangeDelegate?.tab(self, urlDidChangeTo: url)
  }

  func updatePullToRefreshVisibility() {
    guard let url = webView?.url, let webView = webView else { return }
    webView.scrollView.refreshControl = url.isLocalUtility || !Preferences.General.enablePullToRefresh.value ? nil : refreshControl
  }

  func isDescendentOf(_ ancestor: Tab) -> Bool {
    return sequence(first: parent) { $0?.parent }.contains { $0 == ancestor }
  }

  func injectUserScriptWith(fileName: String, type: String = "js", injectionTime: WKUserScriptInjectionTime = .atDocumentEnd, mainFrameOnly: Bool = true, contentWorld: WKContentWorld) {
    guard let webView = self.webView else {
      return
    }
    if let path = Bundle.current.path(forResource: fileName, ofType: type),
      let source = try? String(contentsOfFile: path) {
      let userScript = WKUserScript.create(source: source, injectionTime: injectionTime, forMainFrameOnly: mainFrameOnly, in: contentWorld)
      webView.configuration.userContentController.addUserScript(userScript)
    }
  }

  func observeURLChanges(delegate: URLChangeDelegate) {
    self.urlDidChangeDelegate = delegate
  }

  func removeURLChangeObserver(delegate: URLChangeDelegate) {
    if let existing = self.urlDidChangeDelegate, existing === delegate {
      self.urlDidChangeDelegate = nil
    }
  }

  func stopMediaPlayback() {
    tabDelegate?.stopMediaPlayback(self)
  }
}

extension Tab: TabWebViewDelegate {
  /// Triggered when "Find in Page" is selected on selected text
  fileprivate func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageFor selectedText: String) {
    tabDelegate?.tab(self, didSelectFindInPageFor: selectedText)
  }

  /// Triggered when "Search with Brave" is selected on selected text
  fileprivate func tabWebView(_ tabWebView: TabWebView, didSelectSearchWithBraveFor selectedText: String) {
    tabDelegate?.tab(self, didSelectSearchWithBraveFor: selectedText)
  }
}

private class TabContentScriptManager: NSObject, WKScriptMessageHandlerWithReply {
  fileprivate var helpers = [String: TabContentScript]()

  func uninstall(from tab: Tab) {
    helpers.forEach {
      if let name = $0.value.scriptMessageHandlerName() {
        tab.webView?.configuration.userContentController.removeScriptMessageHandler(forName: name)
      }
    }
  }

  @objc func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
    for helper in helpers.values {
      if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
        if scriptMessageHandlerName == message.name {
          helper.userContentController(userContentController, didReceiveScriptMessage: message, replyHandler: replyHandler)
          return
        }
      }
    }
  }

  func addContentScript(_ helper: TabContentScript, name: String, forTab tab: Tab, contentWorld: WKContentWorld) {
    if let _ = helpers[name] {
      assertionFailure("Duplicate helper added: \(name)")
    }

    helpers[name] = helper

    // If this helper handles script messages, then get the handler name and register it. The Tab
    // receives all messages and then dispatches them to the right TabHelper.
    if let scriptMessageHandlerName = helper.scriptMessageHandlerName() {
      if #available(iOS 14.3, *) {
        tab.webView?.configuration.userContentController.addScriptMessageHandler(self, contentWorld: contentWorld, name: scriptMessageHandlerName)
      } else {
        tab.webView?.configuration.userContentController.addScriptMessageHandler(self, contentWorld: .page, name: scriptMessageHandlerName)
      }
    }
  }

  func getContentScript(_ name: String) -> TabContentScript? {
    return helpers[name]
  }
}

private protocol TabWebViewDelegate: AnyObject {
  /// Triggered when "Find in Page" is selected on selected text
  func tabWebView(_ tabWebView: TabWebView, didSelectFindInPageFor selectedText: String)
  /// Triggered when "Search with Brave" is selected on selected text
  func tabWebView(_ tabWebView: TabWebView, didSelectSearchWithBraveFor selectedText: String)
}

class TabWebView: BraveWebView, MenuHelperInterface {
  fileprivate weak var delegate: TabWebViewDelegate?

  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == MenuHelper.selectorForcePaste {
      // If paste is allowed, show force paste as well
      return super.canPerformAction(#selector(paste(_:)), withSender: sender)
    }
    return super.canPerformAction(action, withSender: sender) || action == MenuHelper.selectorFindInPage
  }
  
  @objc func menuHelperForcePaste() {
    if let string = UIPasteboard.general.string {
      evaluateSafeJavaScript(
        functionName: "window.__firefox__.forcePaste",
        args: [string, UserScriptManager.messageHandlerTokenString],
        contentWorld: .defaultClient
      ) { _, _ in }
    }
  }

  @objc func menuHelperFindInPage() {
    getCurrentSelectedText { [weak self] selectedText in
      guard let self = self else { return }
      guard let selectedText = selectedText else {
        assertionFailure("Impossible to trigger this without selected text")
        return
      }

      self.delegate?.tabWebView(self, didSelectFindInPageFor: selectedText)
    }
  }

  @objc func menuHelperSearchWithBrave() {
    getCurrentSelectedText { [weak self] selectedText in
      guard let self = self else { return }
      guard let selectedText = selectedText else {
        assertionFailure("Impossible to trigger this without selected text")
        return
      }

      self.delegate?.tabWebView(self, didSelectSearchWithBraveFor: selectedText)
    }
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    // The find-in-page selection menu only appears if the webview is the first responder.
    becomeFirstResponder()

    return super.hitTest(point, with: event)
  }

  // rdar://33283179 Apple bug where `serverTrust` is not defined as KVO when it should be
  override func value(forUndefinedKey key: String) -> Any? {
    if key == #keyPath(WKWebView.serverTrust) {
      return serverTrust
    }

    return super.value(forUndefinedKey: key)
  }

  private func getCurrentSelectedText(callback: @escaping (String?) -> Void) {
    evaluateSafeJavaScript(functionName: "getSelection().toString", contentWorld: .defaultClient) { result, _ in
      let selectedText = result as? String
      callback(selectedText)
    }
  }
}

///
// Temporary fix for Bug 1390871 - NSInvalidArgumentException: -[WKContentView menuHelperFindInPage]: unrecognized selector
//
// This class only exists to contain the swizzledMenuHelperFindInPage. This class is actually never
// instantiated. It only serves as a placeholder for the method. When the method is called, self is
// actually pointing to a WKContentView. Which is not public, but that is fine, we only need to know
// that it is a UIView subclass to access its superview.
//

public class TabWebViewMenuHelper: UIView {
  @objc public func swizzledMenuHelperFindInPage() {
    if let tabWebView = superview?.superview as? TabWebView {
      tabWebView.evaluateSafeJavaScript(functionName: "getSelection().toString", contentWorld: .defaultClient) { result, _ in
        let selectedText = result as? String ?? ""
        tabWebView.delegate?.tabWebView(tabWebView, didSelectFindInPageFor: selectedText)
      }
    }
  }
}

// MARK: - Brave Search

extension Tab {
  /// Call the api on the Brave Search website and passes the fallback results to it.
  /// Important: This method is also called when there is no fallback results
  /// or when the fallback call should not happen at all.
  /// The website expects the iOS device to always call this method(blocks on it).
  func injectResults() {
    DispatchQueue.main.async {
      // If the backup search results happen before the Brave Search loads
      // The method we pass data to is undefined.
      // For such case we do not call that method or remove the search backup manager.
      // swiftlint:disable:next safe_javascript
      self.webView?.evaluateJavaScript("window.onFetchedBackupResults === undefined") {
        result, error in

        if let error = error {
          log.error("onFetchedBackupResults existence check error: \(error)")
        }

        guard let methodUndefined = result as? Bool else {
          log.error("onFetchedBackupResults existence check, failed to unwrap bool result value")
          return
        }

        if methodUndefined {
          log.info("Search Backup results are ready but the page has not been loaded yet")
          return
        }

        var queryResult = "null"

        if let url = self.webView?.url,
          BraveSearchManager.isValidURL(url),
          let result = self.braveSearchManager?.fallbackQueryResult {
          queryResult = result
        }

        self.webView?.evaluateSafeJavaScript(
          functionName: "window.onFetchedBackupResults",
          args: [queryResult],
          contentWorld: .page,
          escapeArgs: false)

        // Cleanup
        self.braveSearchManager = nil
      }
    }
  }
}

// MARK: - Brave SKU
extension Tab {
  func injectSessionStorageItem(key: String, value: String) {
    self.webView?.evaluateSafeJavaScript(functionName: "sessionStorage.setItem",
                                         args: [key, value],
                                         contentWorld: .page)
  }
}
