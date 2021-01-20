// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Shared
import Storage
import UIKit
import WebKit
import XCGLogger

private let log = Logger.browserLogger

// MARK: - OpenSearch

public struct OpenSearchReference: Codable {
    let reference: String
    let title: String?

    private enum CodingKeys: String, CodingKey {
        case reference = "href"
        case title = "title"
    }
}

// MARK: - OpenSearch Browser Extension

extension BrowserViewController {
    
    /// Adding Toolbar button over the keyboard for adding Open Search Engine
    /// - Parameter webView: webview triggered open seach engine
    func evaluateWebsiteSupportOpenSearchEngine(_ webView: WKWebView) {
        let script = """
                        var link = document.querySelector("link[type='application/opensearchdescription+xml']")
                        var dict = {
                            href : link.getAttribute("href"),
                            title : link.getAttribute("title")
                        };
                        JSON.stringify(dict)
                     """
        
        webView.evaluateJavaScript(script) { (result, _) in
            guard let htmlStr = result as? String,
                  let data: Data = htmlStr.data(using: .utf8) else { return }
                        
            do {
                let openSearchReference = try JSONDecoder().decode(OpenSearchReference.self, from: data)
                self.updateAddOpenSearchEngine(webView, referenceObject: openSearchReference)
            } catch {
                log.error(error.localizedDescription)
            }
        }
    }
    
    private func updateAddOpenSearchEngine(_ webView: WKWebView, referenceObject: OpenSearchReference) {
        // Add Reference Object as Open Search Engine
        openSearchEngine = referenceObject
        
        // Open Search guidlines requires Title to be same as Short Name but it is not enforced,
        // thus in case of yahoo.com the title is 'Yahoo Search' and Shortname is 'Yahoo'
        // Instead we are checking referenceURL match to determine searchEngine is added or not
        
        let matches = self.profile.searchEngines.orderedEngines.filter {$0.referenceURL == referenceObject.reference}
        
        if !matches.isEmpty {
            self.customSearchEngineButton.state = .disabled
        } else {
            self.customSearchEngineButton.state = .enabled
        }
        
        /*
         This is how we access hidden views in the WKContentView
         Using the public headers we can find the keyboard accessoryView which is not usually available.
         Specific values here are from the WKContentView headers.
         https://github.com/JaviSoto/iOS9-Runtime-Headers/blob/master/Frameworks/WebKit.framework/WKContentView.h
         */
        guard let webContentView = UIView.findSubViewWithFirstResponder(webView) else {
            /*
             In some cases the URL bar can trigger the keyboard notification. In that case the webview isnt the first responder
             and a search button should not be added.
             */
            return
        }
        
        let argumentNextItem: [Any] = ["_n", "extI", "tem"]
        let argumentView: [Any] = ["v", "ie", "w"]
        
        let valueKeyNextItem = argumentNextItem.compactMap { $0 as? String }.joined()
        let valueKeyView = argumentView.compactMap { $0 as? String }.joined()

        guard let input = webContentView.perform(#selector(getter: UIResponder.inputAccessoryView)),
              let inputView = input.takeUnretainedValue() as? UIInputView,
              let nextButton = inputView.value(forKey: valueKeyNextItem) as? UIBarButtonItem,
              let nextButtonView = nextButton.value(forKey: valueKeyView) as? UIView else {
            return
        }
        
        inputView.addSubview(customSearchEngineButton)
        
        customSearchEngineButton.snp.remakeConstraints { make in
            make.leading.equalTo(nextButtonView.snp.trailing).offset(20)
            make.width.equalTo(inputView.snp.height)
            make.top.equalTo(nextButtonView.snp.top)
            make.height.equalTo(inputView.snp.height)
        }
    }

    @objc func addCustomSearchEngineForFocusedElement() {
        guard var referenceURLString = openSearchEngine?.reference,
              let title = openSearchEngine?.title,
              var referenceURL = URL(string: referenceURLString),
              let faviconURLString = self.tabManager.selectedTab?.displayFavicon?.url,
              let iconURL = URL(string: faviconURLString) else {
            let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
            present(alert, animated: true, completion: nil)
            return
        }
                
        guard let scheme = tabManager.selectedTab?.webView?.url?.scheme,
              let host = tabManager.selectedTab?.webView?.url?.host else {
            log.error("Selected Tab doesn't have URL")
            return
        }
        
        while referenceURLString.hasPrefix("/") {
            referenceURLString.remove(at: referenceURLString.startIndex)
        }
        
        let constructedReferenceURLString = "\(scheme)://\(host)/\(referenceURLString)"

        if referenceURL.host == nil, let constructedReferenceURL = URL(string: constructedReferenceURLString) {
            referenceURL = constructedReferenceURL
        }
            
        downloadOpenSearchXML(referenceURL, referenceURL: referenceURLString, title: title, iconURL: iconURL)
    }

    func downloadOpenSearchXML(_ url: URL, referenceURL: String, title: String, iconURL: URL) {
        customSearchEngineButton.state = .loading

        WebImageCacheManager.shared.load(from: iconURL, completion: { (image, _, _, _, _) in
            var searchEngineIcon = #imageLiteral(resourceName: "defaultFavicon")

            if let favIcon = image {
                searchEngineIcon = favIcon
            }
            
            NetworkManager().downloadResource(with: url).uponQueue(.main) { [weak self] response in
                guard let openSearchEngine =
                        OpenSearchParser(pluginMode: true).parse(response.data, referenceURL: referenceURL, image: searchEngineIcon) else {
                    return
                }
                
                self?.addSearchEngine(openSearchEngine)
            }
        })
    }
    
    func addSearchEngine(_ engine: OpenSearchEngine) {
        let alert = ThirdPartySearchAlerts.addThirdPartySearchEngine(engine) { alert in
            do {
                try self.profile.searchEngines.addSearchEngine(engine)
                
                let toast = SimpleToast()
                toast.showAlertWithText(Strings.thirdPartySearchEngineAdded, bottomContainer: self.webViewContainer)
                
                self.customSearchEngineButton.state = .disabled
            } catch {
                let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
                self.present(alert, animated: true) {
                    self.customSearchEngineButton.state = .enabled
                }
            }
        }

        self.present(alert, animated: true, completion: {})
    }
}

// MARK: - KeyboardHelperDelegate

extension BrowserViewController: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        keyboardState = state
        updateViewConstraints()

        UIView.animate(withDuration: state.animationDuration) {
            UIView.setAnimationCurve(state.animationCurve)
            self.alertStackView.layoutIfNeeded()
        }

        guard let webView = tabManager.selectedTab?.webView else { return }

        self.evaluateWebsiteSupportOpenSearchEngine(webView)
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        keyboardState = nil
        updateViewConstraints()
        //If the searchEngineButton exists remove it form the keyboard
        if let buttonGroup = customSearchBarButton?.buttonGroup {
            buttonGroup.barButtonItems = buttonGroup.barButtonItems.filter { $0 != customSearchBarButton }
            customSearchBarButton = nil
        }

        if self.customSearchEngineButton.superview != nil {
            self.customSearchEngineButton.removeFromSuperview()
        }

        UIView.animate(withDuration: state.animationDuration) {
            UIView.setAnimationCurve(state.animationCurve)
            self.alertStackView.layoutIfNeeded()
        }
    }
}
