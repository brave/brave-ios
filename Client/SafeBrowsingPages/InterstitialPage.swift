// Copyright (c) 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import GCDWebServers

private let log = Logger.browserLogger

class InterstitialPageHandler: TabContentScript {
    
    private weak var tab: Tab?
    private var url: URL?
    
    init(tab: Tab) {
        self.tab = tab
    }
    
    func showSafeBrowsingPage(url: URL, for webView: WKWebView, threatType: ThreatType, completion: @escaping (WKNavigationActionPolicy) -> Void) {
        completion(.cancel)
        self.url = url
        
        let pages: [ThreatType: String] = [
            .unspecified: "MITM",
            .malware: "Malware",
            .socialEngineering: "Phishing",
            .unwantedSoftware: "UnwantedSoftware",
            .potentiallyHarmfulApplication: "HarmfulApplication"
        ]
        
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
        let registerHandler = { (type: ThreatType, page: String) in
            webServer.registerHandlerForMethod("GET", module: "interstitial", resource: page, handler: { (request) -> GCDWebServerResponse? in
                guard let url = request?.url.originalURLFromErrorURL else {
                    return GCDWebServerResponse(statusCode: 404)
                }
                
                return InterstitialPageHandler.responseForType(url: url, threatType: type)
            })
        }
        
        webServer.registerMainBundleResource("404.html", module: "interstitial")
        webServer.registerMainBundleResource("Fake.html", module: "interstitial")
        webServer.registerMainBundleResource("NetworkFailure.html", module: "interstitial")
        
        registerHandler(.unspecified, "MITM.html")
        registerHandler(.malware, "Malware.html")
        registerHandler(.socialEngineering, "Phishing.html")
        registerHandler(.unwantedSoftware, "UnwantedSoftware.html")
        registerHandler(.potentiallyHarmfulApplication, "HarmfulApplication.html")
    }
    
    private static func responseForType(url: URL, threatType: ThreatType) -> GCDWebServerResponse? {
        let host = url.host ?? url.absoluteString
        let escapedURL = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .URLAllowed) ?? url.absoluteString
        
        switch threatType {
        case .unspecified:
            let asset = Bundle.main.path(forResource: "MITM", ofType: "html")
            let variables = [
                "tab_title": "SafeBrowsing",
                "page_header": "Your connection is not private",
                "error_description": "Attackers might be trying to steal your information from \(host) (for example, passwords, messages, or credit cards). ",
                "learn_more": "Learn more",
                "more_details": "More details",
                "back_to_safety": "Back to safety",
                "error_detection": "This server could not prove that it is \(host); its security certificate is not trusted by your device's operating system. This may be caused by a misconfiguration or an attacker trying to intercept your connection.",
                "visit_unsafe": "Proceed to \(host) (unsafe)"
            ]
            return buildResponse(asset: asset, variables: variables)
            
        case .malware:
            let asset = Bundle.main.path(forResource: "Malware", ofType: "html")
            let variables = [
                "tab_title": "Safe Browsing",
                "page_header": "The site ahead contains malware",
                "error_description": "Attackers currently on \(host) might attempt to install dangerous programs on your Mac that steal or delete your information (for example, photos, passwords, messages, and credit cards).",
                "learn_more": "Learn more",
                "more_details": "More details",
                "back_to_safety": "Back to safety",
                "error_detection": "Google Safe Browsing recently detected malware on \(host).\nWebsites that are normally safe are sometimes infected with malware.",
                "risk_1": "If you understand the risks to your security, you may",
                "visit_unsafe": "visit this unsafe site",
                "risk_2": "before the dangerous programs have been removed."
            ]
            return buildResponse(asset: asset, variables: variables)
            
        case .socialEngineering:
            let asset = Bundle.main.path(forResource: "Phishing", ofType: "html")
            let variables = [
                "tab_title": "Safe Browsing",
                "page_header": "Deceptive site ahead",
                "error_description": "Attackers on \(host) may trick you into doing something dangerous like installing software or revealing your personal information (for example, passwords, phone numbers, or credit cards).",
                "learn_more": "Learn more",
                "more_details": "More details",
                "back_to_safety": "Back to safety",
                "error_detection_1": "Google Safe Browsing recently",
                "transparency_report": "https://transparencyreport.google.com/safe-browsing/search?url=\(escapedURL)",
                "detected_problem": "detected phishing",
                "error_detection_2": "on \(host).\nPhishing sites pretend to be other websites to trick you.",
                "report_problem": "You can",
                "report_problem_url": "https://safebrowsing.google.com/safebrowsing/report_error/?url=\(escapedURL)",
                "report_problem_text": "report a detection problem",
                "risk_1": "or, if you understand the risks to your security,",
                "risk_2": "visit this unsafe site"
            ]
            return buildResponse(asset: asset, variables: variables)
            
        case .unwantedSoftware:
            let asset = Bundle.main.path(forResource: "UnwantedSoftware", ofType: "html")
            let variables = [
                "tab_title": "Safe Browsing",
                "page_header": "Harmful site ahead",
                "error_description": "Attackers on \(host) might attempt to trick you into installing programs that harm your browsing experience (for example, by changing your homepage or showing extra ads on sites you visit).",
                "learn_more": "Learn more",
                "more_details": "More details",
                "back_to_safety": "Back to safety",
                "error_detection": "Google Safe Browsing recently detected phishing on \(host).\nPhishing sites pretend to be other websites to trick you.",
                "report_problem": "You can",
                "report_problem_url": "https://safebrowsing.google.com/safebrowsing/report_error/?url=\(escapedURL)",
                "report_problem_text": "report a detection problem",
                "risk_1": "or, if you understand the risks to your security,",
                "risk_2": "visit this unsafe site"
            ]
            return buildResponse(asset: asset, variables: variables)
            
        case .potentiallyHarmfulApplication:
            let asset = Bundle.main.path(forResource: "HarmfulApplication", ofType: "html")
            let variables = [
                "tab_title": "Safe Browsing",
                "page_header": "Harmful site ahead",
                "error_description": "Attackers on \(host) might attempt to trick you into installing programs that harm your browsing experience (for example, by changing your homepage or showing extra ads on sites you visit).",
                "learn_more": "Learn more",
                "more_details": "More details",
                "back_to_safety": "Back to safety",
                "error_detection": "Google Safe Browsing recently detected phishing on \(host).\nPhishing sites pretend to be other websites to trick you.",
                "report_problem": "You can",
                "report_problem_url": "https://safebrowsing.google.com/safebrowsing/report_error/?url=\(escapedURL)",
                "report_problem_text": "report a detection problem",
                "risk_1": "or, if you understand the risks to your security,",
                "risk_2": "visit this unsafe site"
            ]
            return buildResponse(asset: asset, variables: variables)
        }
    }
    
    private static func buildResponse(asset: String?, variables: [String: String]) -> GCDWebServerResponse? {
        guard let unwrappedAsset = asset else {
            log.error("Asset is nil")
            return GCDWebServerResponse(statusCode: 404)
        }
        
        let response = GCDWebServerDataResponse(htmlTemplate: unwrappedAsset, variables: variables)
        response?.setValue("no cache", forAdditionalHeader: "Pragma")
        response?.setValue("no-cache,must-revalidate", forAdditionalHeader: "Cache-Control")
        response?.setValue(Date().description, forAdditionalHeader: "Expires")
        return response
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
