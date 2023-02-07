/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import BraveShared
import Intents
import BraveWidgetsModels

// Used by the App to navigate to different views.
// To open a URL use /open-url or to open a blank tab use /open-url with no params
public enum DeepLink: Equatable {
  public init?(urlString: String) {
    // Currently unused for now
    return nil
  }
}

// The root navigation for the Router. Look at the tests to see a complete URL
public enum NavigationPath: Equatable {
  case url(webURL: URL?, isPrivate: Bool)
  case deepLink(DeepLink)
  case text(String)
  case widgetShortcutURL(WidgetShortcut)

  public init?(url: URL) {
    let urlString = url.absoluteString
    if url.scheme == "http" || url.scheme == "https" {
      self = .url(webURL: url, isPrivate: PrivateBrowsingManager.shared.isPrivateBrowsing)
      return
    }

    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return nil
    }

    guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject],
      let urlSchemes = urlTypes.first?["CFBundleURLSchemes"] as? [String]
    else {
      assertionFailure()
      return nil
    }

    guard let scheme = components.scheme, urlSchemes.contains(scheme) else {
      return nil
    }

    if urlString.starts(with: "\(scheme)://deep-link"), let deepURL = components.valueForQuery("url"), let link = DeepLink(urlString: deepURL) {
      self = .deepLink(link)
    } else if urlString.starts(with: "\(scheme)://open-url") {
      let urlText = components.valueForQuery("url")
      let url = URIFixup.getURL(urlText ?? "") ?? urlText?.asURL
      let forcedPrivate = Preferences.Privacy.privateBrowsingOnly.value || PrivateBrowsingManager.shared.isPrivateBrowsing
      let isPrivate = Bool(components.valueForQuery("private") ?? "") ?? forcedPrivate
      self = .url(webURL: url, isPrivate: isPrivate)
    } else if urlString.starts(with: "\(scheme)://open-text") {
      let text = components.valueForQuery("text")
      self = .text(text ?? "")
    } else if urlString.starts(with: "\(scheme)://search") {
      let text = components.valueForQuery("q")
      self = .text(text ?? "")
    } else if urlString.starts(with: "\(scheme)://shortcut"),
      let valueString = components.valueForQuery("path"),
      let value = WidgetShortcut.RawValue(valueString),
      let path = WidgetShortcut(rawValue: value) {
      self = .widgetShortcutURL(path)
    } else {
      return nil
    }
  }

  static func handle(nav: NavigationPath, with bvc: BrowserViewController) {
    switch nav {
    case .deepLink(let link): NavigationPath.handleDeepLink(link, with: bvc)
    case .url(let url, let isPrivate): NavigationPath.handleURL(url: url, isPrivate: isPrivate, with: bvc)
    case .text(let text): NavigationPath.handleText(text: text, with: bvc)
    case .widgetShortcutURL(let path): NavigationPath.handleWidgetShortcut(path, with: bvc)
    }
  }

  private static func handleDeepLink(_ link: DeepLink, with bvc: BrowserViewController) {
    // Handle any deep links we add
  }

  private static func handleURL(url: URL?, isPrivate: Bool, with bvc: BrowserViewController) {
    if let newURL = url {
      bvc.switchToTabForURLOrOpen(newURL, isPrivate: isPrivate, isPrivileged: false, isExternal: true)
      bvc.popToBVC()
    } else {
      bvc.openBlankNewTab(attemptLocationFieldFocus: false, isPrivate: isPrivate)
    }
  }

  private static func handleText(text: String, with bvc: BrowserViewController) {
    bvc.openBlankNewTab(
      attemptLocationFieldFocus: true,
      isPrivate: PrivateBrowsingManager.shared.isPrivateBrowsing,
      searchFor: text)
  }

  private static func handleWidgetShortcut(_ path: WidgetShortcut, with bvc: BrowserViewController) {
    switch path {
    case .unknown, .search:
      // Search
      if let url = bvc.tabManager.selectedTab?.url, InternalURL(url)?.isAboutHomeURL == true {
        bvc.focusURLBar()
      } else {
        bvc.openBlankNewTab(attemptLocationFieldFocus: true, isPrivate: PrivateBrowsingManager.shared.isPrivateBrowsing)
      }
    case .newTab:
      bvc.openBlankNewTab(attemptLocationFieldFocus: false, isPrivate: PrivateBrowsingManager.shared.isPrivateBrowsing)
    case .newPrivateTab:
      bvc.openBlankNewTab(attemptLocationFieldFocus: false, isPrivate: true)
    case .bookmarks:
      bvc.navigationHelper.openBookmarks()
    case .history:
      bvc.navigationHelper.openHistory()
    case .downloads:
      bvc.navigationHelper.openDownloads() { success in
        if !success {
          bvc.displayOpenDownloadsError()
        }
      }
    case .playlist:
      bvc.navigationHelper.openPlaylist()
    case .wallet:
      bvc.navigationHelper.openWallet()
    case .scanQRCode:
      bvc.scanQRCode()
    @unknown default:
      assertionFailure()
      break
    }
  }
}
