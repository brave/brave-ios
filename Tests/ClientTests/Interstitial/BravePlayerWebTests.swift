//
//  BravePlayerWebTests.swift
//  
//
//  Created by Jacob on 2023-11-17.
//

import XCTest
import WebKit
import SnapKit
import CryptoKit

@testable import Brave

final class BravePlayerWebTests: XCTestCase {
  @MainActor func testAuthentication() async throws {
    // Given
    let playerURL = PlayerUtils.makeBravePlayerURL(prefix: "youtube", videoID: "123", authenticate: false)!
    let authenticatedPlayerURL = PlayerUtils.makeBravePlayerURL(prefix: "youtube", videoID: "123", authenticate: true)!
    let navigationDelegate = TestAdBlockDelegate()
    let viewController = MockWebViewController(navigationDelegate: navigationDelegate)
    
    // Load the view and add the siteStateListener script
    viewController.loadViewIfNeeded()
    
    // Load the sample htmls page and await the first page load result
    let htmlURL = Bundle.module.url(forResource: "brave-player-tests", withExtension: "html")!
    let htmlString = try! String(contentsOf: htmlURL, encoding: .utf8)
      .replacingOccurrences(of: "%PLAYER_URL%", with: playerURL.absoluteString)
      .replacingOccurrences(of: "%AUTHENTICATED_PLAYER_URL%", with: authenticatedPlayerURL.absoluteString)
    
    viewController.loadHTMLString(htmlString)
    var linksActivated = 0
    
    for try await message in navigationDelegate {
      switch message {
      case let .decidePolicyForNavigationAction(action, _, policy):
        if action.targetFrame?.isMainFrame == true {
          // Main frame navigations includes:
          // 1. Initial page load
          // 2. Link activations
          // 3. JavaScript navigations (i.e. window.location)
          // 4. JavaScript navigations (i.e. window.open).
          if action.request.url == URL(string: "https://example.com/")! {
            guard policy == .allow else {
              XCTFail("Initial navigation should be allowed")
              navigationDelegate.stop()
              return
            }
          } else if action.request.url == playerURL {
            guard policy == .cancel else {
              XCTFail("Link navigation should be blocked")
              navigationDelegate.stop()
              return
            }
            
            // We cover two types of navigations (window.location and link clicks here)
            // Wait for both to be triggered before stopping the stream.
            // Note: While we do block `window.open`, this is not covered as it's blocked by WebKit so the delegate is not actually triggered.
            linksActivated += 1
            if linksActivated >= 2 {
              navigationDelegate.stop()
            }
          } else {
            XCTFail("Sanity check: The only main frame navigations should be the above 3")
            navigationDelegate.stop()
          }
        } else {
          // Sub-Frame navigations should only exist for an embedded brave player iframe.
          XCTAssertEqual(
            action.request.url, authenticatedPlayerURL,
            "Sanity check: The only subframe we should have in html is the authenticated player url."
          )
          
          guard policy == .cancel else {
            XCTFail("Brave Player in sub-frames should be blocked")
            navigationDelegate.stop()
            return
          }
        }
      case .didFailNavigation:
        XCTFail("Navigation failures shouldn't happen")
        navigationDelegate.stop()
      }
    }
  }
}

private class TestAdBlockDelegate: NSObject, WKNavigationDelegate, AsyncSequence {
  typealias AsyncIterator = MessageStream<Message>
  typealias Element = Message
  
  enum Message {
    case decidePolicyForNavigationAction(WKNavigationAction, WKWebpagePreferences, WKNavigationActionPolicy)
    case didFailNavigation(WKNavigation, Error)
  }
  
  private let messageStream = MessageStream<Message>()
  @MainActor private var stopped = false
  
  func makeAsyncIterator() -> MessageStream<Message> {
    messageStream.start()
    return messageStream
  }
  
  @MainActor func stop() {
    stopped = true
    messageStream.stop()
  }
  
  @MainActor
  func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
    guard !stopped else { return .cancel}
    return .allow
  }
  
  @MainActor
  public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
    guard !stopped else { return (.cancel, preferences) }
    
    if let result = await handleAdBlock(for: navigationAction, preferences: preferences) {
      messageStream.add(message: .decidePolicyForNavigationAction(navigationAction, result.1, result.0))
      return result
    }
      
    messageStream.add(message: .decidePolicyForNavigationAction(navigationAction, preferences, .allow))
    return (.allow, preferences)
  }
  
  @MainActor func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    messageStream.add(message: .didFailNavigation(navigation, error))
  }
  
  /// Handle any ad-blocking logic
  /// -Note: We should share this code with the actual BVC so we're testing the same thing
  private func handleAdBlock(for navigationAction: WKNavigationAction, preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences)? {
    guard let requestURL = navigationAction.request.url else {
      return (.cancel, preferences)
    }

    // Handle invalid `brave://` scheme navigations
    if BraveSchemeHandler.handlesScheme(for: requestURL) {
      guard BraveSchemeHandler.checkAuthorization(for: navigationAction) else {
        return (.cancel, preferences)
      }
    }
    
    return nil
  }
}
