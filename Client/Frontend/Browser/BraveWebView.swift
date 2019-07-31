// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

class BraveWebView: WKWebView {
    private var observer: NSKeyValueObservation?
    
    private static var nonPersistentDataStore: WKWebsiteDataStore?
    private static func sharedNonPersistentStore() -> WKWebsiteDataStore {
        if let dataStore = nonPersistentDataStore {
            return dataStore
        }
        
        let dataStore = WKWebsiteDataStore.nonPersistent()
        nonPersistentDataStore = dataStore
        return dataStore
    }
    
    init(frame: CGRect, configuration: WKWebViewConfiguration = WKWebViewConfiguration(), isPrivate: Bool = true) {
        if isPrivate {
            configuration.websiteDataStore = BraveWebView.sharedNonPersistentStore()
        } else {
            BraveWebView.nonPersistentDataStore = nil
            configuration.websiteDataStore = WKWebsiteDataStore.default()
        }
        
        super.init(frame: frame, configuration: configuration)
    }
    
    static func removeNonPersistentStore() {
        BraveWebView.nonPersistentDataStore = nil
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func resetScrollView() {
        let scrollViewInfo = ScrollViewInfo(scrollView)
        observer = self.observe(\BraveWebView.isLoading, options: .new, changeHandler: {[weak self] webView, value in
            guard let self = self else { return }
            
            if value.newValue == false && webView.estimatedProgress >= 1.0 {
                scrollViewInfo.restore(to: webView.scrollView)
                self.observer = nil
            }
        })
    }
    
    private class ScrollViewInfo {
        private let zoomScale: CGFloat
        private let contentOffset: CGPoint
        
        init(_ scrollView: UIScrollView) {
            zoomScale = scrollView.zoomScale
            contentOffset = scrollView.contentOffset
        }
        
        func restore(to scrollView: UIScrollView) {
            scrollView.zoomScale = zoomScale
            scrollView.contentOffset = contentOffset
        }
    }
}
