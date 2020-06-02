// Copyright (c) 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import GCDWebServers
import BraveShared

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
                
                return InterstitialPageHandler.responseForType(url: url, threatType: .unwantedSoftware)
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
                "tab_title": Strings.safeBrowsingTabTitle,
                "page_header": Strings.safeBrowsingUnknownPageHeader,
                "error_description": String(format: Strings.safeBrowsingUnknownErrorDescription, "\(host)"),
                "learn_more": Strings.safeBrowsingSharedLearnMore,
                "more_details": Strings.safeBrowsingSharedMoreDetails,
                "back_to_safety": Strings.safeBrowsingSharedBackToSafety,
                "error_detection": String(format: Strings.safeBrowsingUnknownErrorDetection, "\(host)"),
                "visit_unsafe": String(format: Strings.safeBrowsingUnknownVisitUnsafe, "\(host)")
            ]
            return buildResponse(asset: asset, variables: variables)
            
        case .malware:
            let asset = Bundle.main.path(forResource: "Malware", ofType: "html")
            let variables = [
                "tab_title": Strings.safeBrowsingTabTitle,
                "page_header": Strings.safeBrowsingMalwarePageHeader,
                "error_description": String(format: Strings.safeBrowsingMalwareErrorDescription, "\(host)"),
                "learn_more": Strings.safeBrowsingSharedLearnMore,
                "more_details": Strings.safeBrowsingSharedMoreDetails,
                "back_to_safety": Strings.safeBrowsingSharedBackToSafety,
                "error_detection": String(format: Strings.safeBrowsingMalwareErrorDetection, "\(host)"),
                "risk_1": Strings.safeBrowsingMalwareRisks1,
                "visit_unsafe": Strings.safeBrowsingMalwareVisitUnsafe,
                "risk_2": Strings.safeBrowsingMalwareRisks2
            ]
            return buildResponse(asset: asset, variables: variables)
            
        case .socialEngineering:
            let asset = Bundle.main.path(forResource: "Phishing", ofType: "html")
            let variables = [
                "tab_title": Strings.safeBrowsingTabTitle,
                "page_header": Strings.safeBrowsingPhishingPageHeader,
                "error_description": String(format: Strings.safeBrowsingPhishingErrorDescription, "\(host)"),
                "learn_more": Strings.safeBrowsingSharedLearnMore,
                "more_details": Strings.safeBrowsingSharedMoreDetails,
                "back_to_safety": Strings.safeBrowsingSharedBackToSafety,
                "error_detection_1": Strings.safeBrowsingPhishingErrorDetection1,
                "transparency_report": "https://transparencyreport.google.com/safe-browsing/search?url=\(escapedURL)",
                "detected_problem": Strings.safeBrowsingPhishingErrorDetectionProblem,
                "error_detection_2": String(format: Strings.safeBrowsingPhishingErrorDetection2, "\(host)"),
                "report_problem": Strings.safeBrowsingPhishingReportProblem,
                "report_problem_url": "https://safebrowsing.google.com/safebrowsing/report_error/?url=\(escapedURL)",
                "report_problem_text": Strings.safeBrowsingPhishingReportProblemText,
                "risk_1": Strings.safeBrowsingPhishingRisks1,
                "risk_2": Strings.safeBrowsingPhishingVisitUnsafe
            ]
            return buildResponse(asset: asset, variables: variables)
            
        case .unwantedSoftware:
            let asset = Bundle.main.path(forResource: "UnwantedSoftware", ofType: "html")
            let variables = [
                "tab_title": Strings.safeBrowsingTabTitle,
                "page_header": Strings.safeBrowsingUnwantedSoftwarePageHeader,
                "error_description": String(format: Strings.safeBrowsingUnwantedSoftwareErrorDescription, "\(host)"),
                "learn_more": Strings.safeBrowsingSharedLearnMore,
                "more_details": Strings.safeBrowsingSharedMoreDetails,
                "back_to_safety": Strings.safeBrowsingSharedBackToSafety,
                "error_detection": Strings.safeBrowsingUnwantedSoftwareErrorDetection,
                "error_detection_link_text": Strings.safeBrowsingUnwantedSoftwareErrorDetectionLinkText,
                "error_detection_url": "https://transparencyreport.google.com/safe-browsing/search?url=\(escapedURL)",
                "error_description_page": String(format: Strings.safeBrowsingUnwantedSoftwareErrorDetectionPage, "\(host)"),
                "risk_1": Strings.safeBrowsingUnwantedSoftwareRisks1,
                "visit_unsafe": Strings.safeBrowsingUnwantedSoftwareVisitUnsafe,
                "risk_2": Strings.safeBrowsingUnwantedSoftwareRisks2
            ]
            return buildResponse(asset: asset, variables: variables)
            
        case .potentiallyHarmfulApplication:
            let asset = Bundle.main.path(forResource: "HarmfulApplication", ofType: "html")
            let variables = [
                "tab_title": Strings.safeBrowsingTabTitle,
                "page_header": Strings.safeBrowsingHarmfulApplicationPageHeader,
                "error_description": Strings.safeBrowsingHarmfulApplicationErrorDescription,
                "learn_more": Strings.safeBrowsingSharedLearnMore,
                "more_details": Strings.safeBrowsingSharedMoreDetails,
                "back_to_safety": Strings.safeBrowsingSharedBackToSafety,
                "error_detection": Strings.safeBrowsingHarmfulApplicationErrorDetection,
                "error_detection_link_text": Strings.safeBrowsingHarmfulApplicationErrorDetectionLinkText,
                "error_detection_url": "https://transparencyreport.google.com/safe-browsing/search?url=\(escapedURL)",
                "error_description_page": String(format: Strings.safeBrowsingHarmfulApplicationErrorDetectionPage, "\(host)"),
                "risk_1": Strings.safeBrowsingHarmfulApplicationRisks1,
                "visit_unsafe": Strings.safeBrowsingHarmfulApplicationVisitUnsafe,
                "risk_2": Strings.safeBrowsingHarmfulApplicationRisks2
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
