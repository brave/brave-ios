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
        //check if the search engine has already been added.
        //self.openSearchLinkDict = dict
        // Open Search guidlines requires Title to be same as Short Name but it is not enforced,
        // thus in case of yahoo.com the title is 'Yahoo Search' and Shortname is 'Yahoo'
        // This results in mismatch. Adding title field in engine.
        
        let matches = self.profile.searchEngines.orderedEngines.filter {$0.referenceURL == referenceObject.reference}
        
        if !matches.isEmpty {
            customSearchEngineButton.tintColor = .gray
            customSearchEngineButton.isUserInteractionEnabled = false
        } else {
            customSearchEngineButton.tintColor = .blue
            customSearchEngineButton.isUserInteractionEnabled = true
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
        
        guard let input = webContentView.perform(#selector(getter: UIResponder.inputAccessoryView)),
              let inputView = input.takeUnretainedValue() as? UIInputView,
              let nextButton = inputView.value(forKey: "_nextItem") as? UIBarButtonItem,
              let nextButtonView = nextButton.value(forKey: "view") as? UIView else {
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
        guard let webView = tabManager.selectedTab?.webView else {
            return
        }
        webView.evaluateJavaScript("__firefox__.searchQueryForField()") { (result, _) in
            guard let searchQuery = result as? String, let favicon = self.tabManager.selectedTab!.displayFavicon else {
                //Javascript responded with an incorrectly formatted message. Show an error.
                let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
                self.present(alert, animated: true, completion: nil)
                return
            }
            self.addSearchEngine(searchQuery, favicon: favicon)
            self.customSearchEngineButton.tintColor = UIColor.Photon.grey50
            self.customSearchEngineButton.isUserInteractionEnabled = false
        }
    }

    func addSearchEngine(_ searchQuery: String, favicon: Favicon) {
        guard searchQuery != "",
            let iconURL = URL(string: favicon.url),
            let url = URL(string: searchQuery.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!),
            let shortName = url.domainURL.host else {
                let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
                self.present(alert, animated: true, completion: nil)
                return
        }

        let alert = ThirdPartySearchAlerts.addThirdPartySearchEngine { alert in
            self.customSearchEngineButton.tintColor = UIColor.Photon.grey50
            self.customSearchEngineButton.isUserInteractionEnabled = false
            
            WebImageCacheManager.shared.load(from: iconURL, completion: { (image, _, _, _, _) in
                guard let image = image else {
                    let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                self.profile.searchEngines.addSearchEngine(OpenSearchEngine(engineID: nil, shortName: shortName, image: image, searchTemplate: searchQuery, suggestTemplate: nil, isCustomEngine: true))
                let Toast = SimpleToast()
                Toast.showAlertWithText(Strings.thirdPartySearchEngineAdded, bottomContainer: self.webViewContainer)
            })
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
