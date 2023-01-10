import WebKit
import Shared
import BraveShared

// WKNavigationDelegates must implement NSObjectProtocol
class TabManagerNavDelegate: NSObject, WKNavigationDelegate {
  private var delegates = WeakList<WKNavigationDelegate>()
  weak var tabManager: TabManager?

  func insert(_ delegate: WKNavigationDelegate) {
    delegates.insert(delegate)
  }

  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    for delegate in delegates {
      delegate.webView?(webView, didCommit: navigation)
    }
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    for delegate in delegates {
      delegate.webView?(webView, didFail: navigation, withError: error)
    }
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    for delegate in delegates {
      delegate.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
    }
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    for delegate in delegates {
      delegate.webView?(webView, didFinish: navigation)
    }
  }

  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    for delegate in delegates {
      delegate.webViewWebContentProcessDidTerminate?(webView)
    }
  }

  func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    let authenticatingDelegates = delegates.filter { wv in
      return wv.responds(to: #selector(webView(_:didReceive:completionHandler:)))
    }

    guard let firstAuthenticatingDelegate = authenticatingDelegates.first else {
      return completionHandler(.performDefaultHandling, nil)
    }

    firstAuthenticatingDelegate.webView?(webView, didReceive: challenge) { (disposition, credential) in
      completionHandler(disposition, credential)
    }
  }

  func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
    for delegate in delegates {
      delegate.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
    }
  }

  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    for delegate in delegates {
      delegate.webView?(webView, didStartProvisionalNavigation: navigation)
    }
  }

  private func defaultAllowPolicy() -> WKNavigationActionPolicy {
    let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
    if isPrivateBrowsing || !Preferences.General.followUniversalLinks.value {
      // Stop Brave from opening universal links by using the private enum value
      // `_WKNavigationActionPolicyAllowWithoutTryingAppLink` which is defined here:
      // https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKNavigationDelegatePrivate.h#L62
      let allowDecision = WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2) ?? .allow
      return allowDecision
    }
    return .allow
  }
  
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
    var res = defaultAllowPolicy()
    var pref = preferences
    
    for delegate in delegates {
      typealias WKNavigationActionSignature = (WKNavigationDelegate) -> ((WKWebView, WKNavigationAction, WKWebpagePreferences, @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) -> Void)?
      if delegate.responds(to: #selector(WKNavigationDelegate.webView(_:decidePolicyFor:preferences:decisionHandler:) as WKNavigationActionSignature)) {
        let (policy, preferences) = await delegate.webView!(webView, decidePolicyFor: navigationAction, preferences: preferences)
        if policy == .cancel {
          res = policy
        }
        
        pref = preferences
      }
    }
    
    return (res, pref)
  }
  
  func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
    var res = WKNavigationResponsePolicy.allow
    for delegate in delegates {
      typealias WKNavigationResponseSignature = (WKNavigationDelegate) -> ((WKWebView, WKNavigationResponse, @escaping (WKNavigationResponsePolicy) -> Void) -> Void)?
      if delegate.responds(to: #selector(WKNavigationDelegate.webView(_:decidePolicyFor:decisionHandler:) as WKNavigationResponseSignature)) {
        let policy = await delegate.webView!(webView, decidePolicyFor: navigationResponse)
        if policy == .cancel {
          res = policy
        }
      }
    }

    if res == .allow {
      // TabManager.subscript.getter required MAIN-THREAD!
      
      await Task { @MainActor in
        let tab = tabManager?[webView]
        tab?.mimeType = navigationResponse.response.mimeType
      }.value
    }
    
    return res
  }
}
