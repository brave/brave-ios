// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared

class ReaderModeHandler: InternalSchemeResponse {
    static let path = "reader-mode"
    static let readerModeStyleHash = "sha256-L2W8+0446ay9/L1oMrgucknQXag570zwgQrHwE68qbQ="
    private let readerModeCache: ReaderModeCache = DiskReaderModeCache.sharedInstance
    private let profile: Profile
    
    init(profile: Profile) {
        self.profile = profile
    }

    func response(forRequest request: URLRequest) -> (URLResponse, Data)? {
        guard let _url = request.url,
              let url = InternalURL(_url),
              let queryURL = url.extractedUrlParam else { return nil }
        
        if url.url.lastPathComponent == "page-exists" {
            let statusCode = readerModeCache.contains(_url) ? 200 : 400
            if let response = HTTPURLResponse(url: url.url,
                                              statusCode: statusCode,
                                              httpVersion: "HTTP/1.1",
                                              headerFields: ["Content-Type": "text/html; charset=UTF-8"]) {
                return (response, Data())
            }
            return nil
        }
        
        // From here on, handle 'url=' query param
        if !queryURL.isWebPage() {
            if let response = HTTPURLResponse(url: url.url,
                                              statusCode: 500,
                                              httpVersion: "HTTP/1.1",
                                              headerFields: ["Content-Type": "text/html; charset=UTF-8"]) {
                return (response, Data())
            }
            return nil
        }
        
        // Must generate a unique nonce, every single time as per Content-Policy spec.
        let nonce = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        guard let response = HTTPURLResponse(url: url.url,
                                             statusCode: 200,
                                             httpVersion: "HTTP/1.1",
                                             headerFields: ["Content-Type": "text/html; charset=UTF-8",
                                                            "Content-Security-Policy": "default-src 'none'; img-src *; style-src internal://local '\(ReaderModeHandler.readerModeStyleHash)'; font-src internal://local; script-src 'nonce-\(nonce)'"]) else {
            return nil
        }
        
        guard let readerModePath = Bundle.main.path(forResource: "Reader", ofType: "html"),
              var html = try? String(contentsOfFile: readerModePath) else {
            assert(false)
            return nil
        }
        
        // Apply all security BEFORE modifying contents of the page
        html = html.replacingOccurrences(of: "%READER-TITLE-NONCE%", with: nonce)
        
        // Generate Reader-Mode Response
        do {
            let readabilityResult = try readerModeCache.get(queryURL)
            // We have this page in our cache, so we can display it. Just grab the correct style from the
            // profile and then generate HTML from the Readability results.
            var readerModeStyle = DefaultReaderModeStyle
            if let dict = profile.prefs.dictionaryForKey(ReaderModeProfileKeyStyle) {
                if let style = ReaderModeStyle(dict: dict) {
                    readerModeStyle = style
                }
            }
            
            // Apply all content changes AFTER security modifications
            if let htmlData = applyContentModifications(html: html, style: readerModeStyle, readability: readabilityResult).data(using: .utf8) {
                return (response, htmlData)
            }
            
            return nil
        } catch {
            // This page has not been converted to reader mode yet. This happens when you for example add an
            // item via the app extension and the application has not yet had a change to readerize that
            // page in the background.
            //
            // What we do is simply queue the page in the ReadabilityService and then show our loading
            // screen, which will periodically call page-exists to see if the readerized content has
            // become available.
            ReadabilityService.sharedInstance.process(queryURL, cache: readerModeCache)
            if let readerViewLoadingPath = Bundle.main.path(forResource: "ReaderViewLoading", ofType: "html") {
                do {
                    let readerViewLoading = try NSMutableString(contentsOfFile: readerViewLoadingPath, encoding: String.Encoding.utf8.rawValue)
                    readerViewLoading.replaceOccurrences(of: "%ORIGINAL-URL%", with: queryURL.absoluteString,
                        options: .literal, range: NSRange(location: 0, length: readerViewLoading.length))
                    readerViewLoading.replaceOccurrences(of: "%LOADING-TEXT%", with: Strings.readerModeLoadingContentDisplayText,
                        options: .literal, range: NSRange(location: 0, length: readerViewLoading.length))
                    readerViewLoading.replaceOccurrences(of: "%LOADING-FAILED-TEXT%", with: Strings.readerModePageCantShowDisplayText,
                        options: .literal, range: NSRange(location: 0, length: readerViewLoading.length))
                    readerViewLoading.replaceOccurrences(of: "%LOAD-ORIGINAL-TEXT%", with: Strings.readerModeLoadOriginalLinkText,
                        options: .literal, range: NSRange(location: 0, length: readerViewLoading.length))
                    
                    if let htmlData = (readerViewLoading as String).data(using: .utf8) {
                        return (InternalSchemeHandler.response(forUrl: url.url), htmlData)
                    }
                } catch _ {
                }
            }
        }
        
        return nil
    }
    
    private func simplifyDomain(_ domain: String) -> String {
        let domainPrefixesToSimplify = ["www.", "mobile.", "m.", "blog."]
        return domainPrefixesToSimplify.first { domain.hasPrefix($0) }.map {
            String($0.suffix(from: $0.index($0.startIndex, offsetBy: $0.count)))
        } ?? domain
    }
    
    private func applyContentModifications(html: String, style: ReaderModeStyle, readability: ReadabilityResult) -> String {
        // NEVER Apply security code here.
        return html.replacingOccurrences(of: "%READER-STYLE%", with: style.encode())
            .replacingOccurrences(of: "%READER-DOMAIN%", with: simplifyDomain(readability.domain))
            .replacingOccurrences(of: "%READER-URL%", with: readability.url)
            .replacingOccurrences(of: "%READER-TITLE%", with: readability.title)
            .replacingOccurrences(of: "%READER-CREDITS%", with: readability.credits)
            .replacingOccurrences(of: "%READER-CONTENT%", with: readability.content.escapeHTML)
            .replacingOccurrences(of: "%READER-MESSAGE%", with: "")
    }
}

private extension String {
    /// Encode HTMLStrings
    /// Also used for Strings which are not sanitized for displaying
    /// - Returns: Encoded String
    var escapeHTML: String {
       return self
        .replacingOccurrences(of: "\"", with: "\\\"", options: .literal)
        .replacingOccurrences(of: "'", with: "\\\'", options: .literal)
        .replacingOccurrences(of: "\n", with: "\\n", options: .literal)
    }
}
