// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

class InterstitialPageHandler: TabContentScript {
    
    private weak var tab: Tab?
    private var url: URL?
    
    init(tab: Tab) {
        self.tab = tab
    }
    
    func showSafeBrowsingPage(url: URL, for webView: WKWebView, threatType: ThreatType, completion: @escaping (WKNavigationActionPolicy) -> Void) {
        let pages: [ThreatType: String] = [
            .unspecified: "MITM",
            .malware: "Malware",
            .socialEngineering: "Phishing",
            .unwantedSoftware: "HarmfulApplication",
            .potentiallyHarmfulApplication: "HarmfulApplication"
        ]
        
        completion(.cancel)
        self.url = url
        
        var components = URLComponents(string: WebServer.sharedInstance.base + "/interstitial/\(pages[threatType]!).html")!
        components.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]
        webView.load(PrivilegedRequest(url: components.url!) as URLRequest)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        guard let message = message.body as? String else { return }
        
        if message == "go_back" {
            tab?.goBack()
        } else if message == "proceed_unsafe" {
            tab?.webView?.load(InterstitialRequest(url: url!) as URLRequest)
        } else {
            
        }
    }
    
    class func name() -> String {
        return "InterstitialPageHandler"
    }

    func scriptMessageHandlerName() -> String? {
        return "InterstitialPageHandler"
    }
}

extension InterstitialPageHandler {
    static func register(_ webServer: WebServer) {
        webServer.registerMainBundleResource("404.html", module: "interstitial")
        webServer.registerMainBundleResource("Fake.html", module: "interstitial")
        webServer.registerMainBundleResource("HarmfulApplication.html", module: "interstitial")
        webServer.registerMainBundleResource("Malware.html", module: "interstitial")
        webServer.registerMainBundleResource("MITM.html", module: "interstitial")
        webServer.registerMainBundleResource("NetworkFailure.html", module: "interstitial")
        webServer.registerMainBundleResource("Phishing.html", module: "interstitial")
    }
}

private class InterstitialRequest: NSMutableURLRequest {
    fileprivate static let REQUEST_KEY_INTERSTITIAL = "interstitial"
    
    override init(url URL: URL, cachePolicy: NSURLRequest.CachePolicy, timeoutInterval: TimeInterval) {
        super.init(url: URL, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        setInterstitial()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setInterstitial()
    }

    fileprivate func setInterstitial() {
        URLProtocol.setProperty(true, forKey: InterstitialRequest.REQUEST_KEY_INTERSTITIAL, in: self)
    }
}

extension URLRequest {
    var isInterstitial: Bool {
        return URLProtocol.property(forKey: InterstitialRequest.REQUEST_KEY_INTERSTITIAL, in: self) != nil
    }
}
