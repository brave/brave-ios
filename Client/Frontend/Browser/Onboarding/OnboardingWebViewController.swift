// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

class OnboardingWebViewController: UIViewController, WKNavigationDelegate {
    
    private let toolbar = Toolbar().then {
        $0.snp.makeConstraints {
            $0.height.equalTo(45.0)
        }
    }
    
    private let webView = { () -> WKWebView in
       let configuration: WKWebViewConfiguration = {
            let configuration = WKWebViewConfiguration()
            configuration.processPool = WKProcessPool()
            configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
            return configuration
        }()
        
        return WKWebView(frame: .zero, configuration: configuration)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let stackView = UIStackView().then {
            $0.axis = .vertical
        }
        
        [toolbar, webView].forEach(stackView.addArrangedSubview(_:))
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        webView.navigationDelegate = self
        webView.load(URLRequest(url: URL(string: "https://brave.com/terms-of-use/")!))
        
        toolbar.exitButton.addTarget(self, action: #selector(onExit), for: .touchUpInside)
        toolbar.backButton.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        toolbar.forwardButton.addTarget(self, action: #selector(onForward), for: .touchUpInside)
        toolbar.actionButton.addTarget(self, action: #selector(onAction), for: .touchUpInside)
    }
    
    @objc
    private func onExit() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    private func onBack() {
        if webView.canGoBack {
            webView.goBack()
            updateWebPageDomain()
        }
        
        toolbar.backButton.isEnabled = webView.canGoBack
        toolbar.backButton.tintColor = webView.canGoBack ? UX.buttonEnabledColor : UX.buttonDisabledColor
    }
    
    @objc
    private func onForward() {
        if webView.canGoForward {
            webView.goForward()
            updateWebPageDomain()
        }
        
        toolbar.forwardButton.isEnabled = webView.canGoForward
        toolbar.forwardButton.tintColor = webView.canGoForward ? UX.buttonEnabledColor : UX.buttonDisabledColor
    }
    
    @objc
    private func onAction() {
        print("Access Button Pressed..")
    }
    
    private func updateWebPageDomain() {
        toolbar.urlLabel.text = webView.url?.host
    }
    
    private func updateWebPageSecurity() {
        if let trust = webView.serverTrust {
            toolbar.secureIcon.isHidden = false
            
            var result: SecTrustResultType = .invalid
            SecTrustEvaluate(trust, &result)
            
            if result == .proceed || result == .unspecified {
                toolbar.secureIcon.tintColor = UX.secureWebPageColor
                toolbar.urlLabel.textColor = UX.secureWebPageColor
            } else {
                toolbar.secureIcon.tintColor = UX.insecureWebPageColor
                toolbar.urlLabel.textColor = UX.insecureWebPageColor
            }
        } else {
            toolbar.secureIcon.isHidden = true
            toolbar.urlLabel.textColor = UX.unknownWebPageColor
        }
    }
    
    private func updateBackForwardUI() {
        toolbar.backButton.isEnabled = webView.canGoBack
        toolbar.backButton.tintColor = webView.canGoBack ? UX.buttonEnabledColor : UX.buttonDisabledColor

        toolbar.forwardButton.isEnabled = webView.canGoForward
        toolbar.forwardButton.tintColor = webView.canGoForward ? UX.buttonEnabledColor : UX.buttonDisabledColor
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        updateBackForwardUI()
        decisionHandler(.allow)
    }
    
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        
        self.webView(webView, decidePolicyFor: navigationAction) { action in
            decisionHandler(action, preferences)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        
        updateWebPageDomain()
        updateWebPageSecurity()
        updateBackForwardUI()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
        updateWebPageDomain()
        updateWebPageSecurity()
        updateBackForwardUI()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        updateWebPageSecurity()
        updateBackForwardUI()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateBackForwardUI()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateWebPageSecurity()
        updateBackForwardUI()
    }
}

extension OnboardingWebViewController {
    private struct UX {
        static let buttonEnabledColor = UIColor(rgb: 0x5E6770)
        static let buttonDisabledColor = UIColor(rgb: 0xE0E1E5)
        static let secureWebPageColor = UIColor(rgb: 0x03A402)
        static let insecureWebPageColor = UIColor.red
        static let unknownWebPageColor = UIColor.darkGray
    }
    
    class Toolbar: UIView {
        let exitButton = UIButton().then {
            $0.setImage(#imageLiteral(resourceName: "onboarding_exit").template, for: .normal)
            $0.contentMode = .scaleAspectFit
            $0.tintColor = UX.buttonEnabledColor
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        let backButton = UIButton().then {
            $0.setImage(#imageLiteral(resourceName: "onboarding_back").template, for: .normal)
            $0.contentMode = .scaleAspectFit
            $0.tintColor = UX.buttonDisabledColor
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
            $0.isEnabled = false
        }
        
        let secureIcon = UIImageView().then {
            $0.image = #imageLiteral(resourceName: "onboarding_secure_page_lock").template
            $0.contentMode = .scaleAspectFit
            $0.tintColor = UX.unknownWebPageColor
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
            $0.isHidden = true
        }
        
        let urlLabel = UILabel().then {
            $0.textColor = UX.unknownWebPageColor
            $0.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
            $0.numberOfLines = 0
        }
        
        let forwardButton = UIButton().then {
            $0.setImage(#imageLiteral(resourceName: "onboarding_forward").template, for: .normal)
            $0.contentMode = .scaleAspectFit
            $0.tintColor = UX.buttonDisabledColor
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
            $0.isEnabled = false
        }
        
        let actionButton = UIButton().then {
            $0.setImage(#imageLiteral(resourceName: "onboarding_action_dots").template, for: .normal)
            $0.contentMode = .scaleAspectFit
            $0.tintColor = UX.buttonEnabledColor
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        private let leftStackview = UIStackView().then {
            $0.spacing = 16.0
            $0.isLayoutMarginsRelativeArrangement = true
            $0.layoutMargins = UIEdgeInsets(equalInset: 13.0)
        }
        
        private let middleStackview = UIStackView().then {
            $0.spacing = 4.0
            $0.alignment = .center
            $0.isLayoutMarginsRelativeArrangement = true
            $0.layoutMargins = UIEdgeInsets(equalInset: 13.0)
        }
        
        private let rightStackview = UIStackView().then {
            $0.spacing = 16.0
            $0.isLayoutMarginsRelativeArrangement = true
            $0.layoutMargins = UIEdgeInsets(equalInset: 13.0)
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = .white
            
            addSubview(leftStackview)
            addSubview(middleStackview)
            addSubview(rightStackview)
            
            [exitButton, backButton].forEach(leftStackview.addArrangedSubview(_:))
            [secureIcon, urlLabel].forEach(middleStackview.addArrangedSubview(_:))
            [forwardButton, actionButton].forEach(rightStackview.addArrangedSubview(_:))
            
            middleStackview.snp.makeConstraints {
                $0.centerX.equalTo(self.snp.centerX)
                $0.top.equalTo(self.snp.top)
                $0.bottom.equalTo(self.snp.bottom)
            }
            
            leftStackview.snp.makeConstraints {
                $0.left.equalTo(self.snp.left)
                $0.right.equalTo(middleStackview.snp.left).offset(-20.0)
                $0.top.equalTo(self.snp.top)
                $0.bottom.equalTo(self.snp.bottom)
            }
            
            rightStackview.snp.makeConstraints {
                $0.left.equalTo(middleStackview.snp.right).offset(20.0)
                $0.right.equalTo(self.snp.right)
                $0.top.equalTo(self.snp.top)
                $0.bottom.equalTo(self.snp.bottom)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
