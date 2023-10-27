// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared
import Strings
import BraveShields
import os.log

/// A class that handles `brave://` scheme requests
class BraveSchemeHandler: NSObject, WKURLSchemeHandler {
  static let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "braveScheme")
  static let scheme = "brave"
  
  private static let authQueryKey = "auth"
  private static let authToken = UUID().uuidString
  
  static var authQueryItem: URLQueryItem {
    return URLQueryItem(name: authQueryKey, value: authToken)
  }
  
  /// An enum representation of all the hosts supported by the BraveSchemeHandler
  enum Host: String, CaseIterable {
    case player
    
    /// The way the navigation bar should display this value
    var displayURL: URL? {
      var components = URLComponents()
      components.scheme = BraveSchemeHandler.scheme
      components.host = rawValue
      return components.url
    }
  }
  
  /// A mapping of a path to mime type
  private let mimeTypeMapping: [String: String] = [
    // Brave Player
    "/styles/Player.css": "text/css",
    "/scripts/Player.js": "text/javascript",
    "/images/PlayerBackground.svg": "image/svg+xml",
    "/images/PlayerLogo.svg": "image/svg+xml"
  ]
  
  func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    guard let url = urlSchemeTask.request.url, let host = Self.host(for: url) else {
      Self.log.error("Bad brave scheme request: `\(urlSchemeTask.request.url?.absoluteString ?? "nil")`")
      urlSchemeTask.didFailWithError(InternalPageSchemeHandlerError.badURL)
      return
    }
    
    do {
      if let resource = try resource(for: url) {
        let response = URLResponse(url: url, mimeType: resource.mimeType, expectedContentLength: -1, textEncodingName: nil)
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(resource.data)
        urlSchemeTask.didFinish()
      } else if let data = try host.loadData(for: url) {
        let response = URLResponse(url: url, mimeType: "text/html", expectedContentLength: -1, textEncodingName: "utf-8")
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
      } else {
        Self.log.error("Unauthorized brave scheme request for `\(url.absoluteString)`")
        urlSchemeTask.didFailWithError(InternalPageSchemeHandlerError.notAuthorized)
      }
    } catch {
      Self.log.error("Failed to load brave scheme resource for `\(url.absoluteString)`: \(error)")
      urlSchemeTask.didFailWithError(error)
    }
  }
  
  func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    // Not handled
  }
  
  static func createURL(host: Host, path: String, authenticate: Bool) -> URL? {
    var components = URLComponents()
    components.scheme = scheme
    components.host = host.rawValue
    components.path = path
    if authenticate {
      components.queryItems = [authQueryItem]
    }
    
    return components.url
  }
  
  /// Checks to see if this scheme handler handles this request. This is needed for the navigation delegate
  static func handles(url: URL) -> Bool {
    return host(for: url) != nil
  }
  
  /// Checks to see if this scheme handler handles the given scheme
  static func handlesScheme(for url: URL) -> Bool {
    guard let scheme = url.scheme else { return false }
    return scheme == Self.scheme
  }
  
  /// Will append the authorization token to the url if it is not there but only if the url is a valid request
  ///
  /// - Warning: This will authorize the request. Only use this when restoring urls or when user inputs the url manually
  static func authorizeIfNeeded(requestURL: URL) -> URL {
    guard Self.handles(url: requestURL) else { return requestURL }
    var components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)
    var queryItems = components?.queryItems ?? []
    queryItems.removeAll(where: { $0.name == authQueryKey })
    queryItems.append(authQueryItem)
    components?.queryItems = queryItems
    return components?.url ?? requestURL
  }
  
  /// Remove the authorization token (used for display purposes)
  static func stripAuthorization(from requestURL: URL) -> URL {
    guard var components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) else { return requestURL }
    components.queryItems = components.queryItems?.filter({ $0.name != authQueryKey })
    if components.queryItems?.isEmpty == true {
      components.queryItems = nil
    }
    return components.url ?? requestURL
  }
  
  /// Check to see if the request is authorized for this scheme handler.
  /// This will check:
  /// 1. Invalid host requests
  /// 2. That the request is on the main frame. Embedded frames are not allowed.
  /// 3. The navigation type is allowed
  /// 4. The navigation type has an auth key if its `other`
  ///
  /// - Note: Call this when you know the scheme matches this scheme handler
  static func checkAuthorization(for navigationAction: WKNavigationAction) -> Bool {
    guard let requestURL = navigationAction.request.url else {
      return false
    }
    
    guard BraveSchemeHandler.handles(url: requestURL) else {
      Self.log.error("Blocked invalid host to brave scheme for `\(requestURL.absoluteString)`")
      return false
    }
    guard navigationAction.targetFrame?.isMainFrame == true else {
      Self.log.error("Blocked sub-frame navigation to brave scheme for `\(requestURL.absoluteString)`")
      return false
    }
    
    switch navigationAction.navigationType {
    case .backForward, .reload:
      // We allow these without any auth token
      return true
    case .formResubmitted, .formSubmitted, .linkActivated:
      // We restrict these types of navigations
      Self.log.error("Blocked invalid brave scheme navigation type `\(String(describing: requestURL.absoluteString))` for `\(requestURL.absoluteString)`")
      return false
    case .other:
      if checkAuthorizationToken(for: requestURL) {
        return true
      } else {
        Self.log.error("Missing authorization token for `\(requestURL.absoluteString)`")
        return false
      }
    @unknown default:
      return false
    }
  }
  
  /// Check to see if there is a valid authorization token on the given request.
  ///
  /// - Note: This will not check validity of the host or the scheme
  static func checkAuthorizationToken(for requestURL: URL) -> Bool {
    guard let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) else {
      // If this triggers we need to either add the url validity check outside of this method.
      // You probably just need to add `BraveSchemeHandler.handles` check if this triggers wherever this method is being called
      assertionFailure("Not somethign that should ever trigger as we already check the validity of the url above with the `handles` check.")
      return false
    }
    
    guard components.queryItems?.contains(where: { $0.name == authQueryKey && $0.value == authToken}) == true else {
      return false
    }
    
    return true
  }
  
  /// Load a resource for the given URL.
  /// If the url is not a valid resource url, a nil will be returned
  private func resource(for url: URL) throws -> (data: Data, mimeType: String)? {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    guard let path = components?.path else { return nil }
    guard let mimeType = mimeTypeMapping[path] else { return nil }
    
    guard let resourceURL = Bundle.module.url(forResource: url.lastPathComponent, withExtension: nil) else {
      return nil
    }
    
    let data = try Data(contentsOf: resourceURL)
    return (data, mimeType)
  }
  
  /// Return a host for this url.
  ///
  /// - Note: This will check the validity of the scheme but not check for the auth token.
  static func host(for url: URL) -> Host? {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    guard components?.scheme == scheme else { return nil }
    guard let host = components?.host else { return nil }
    return Host(rawValue: host)
  }
}

extension BraveSchemeHandler.Host {
  /// Load the data for this host
  func loadData(for url: URL) throws -> Data? {
    switch self {
    case .player:
      return try PlayerUtils.loadPlayerData(for: url)
    }
  }
}
