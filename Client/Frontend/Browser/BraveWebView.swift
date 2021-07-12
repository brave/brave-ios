// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

class BraveWebView: WKWebView {
    
    /// Stores last position when the webview was touched on.
    private(set) var lastHitPoint = CGPoint(x: 0, y: 0)
    
    private static var nonPersistentDataStore: WKWebsiteDataStore?
    static func sharedNonPersistentStore() -> WKWebsiteDataStore {
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
            configuration.websiteDataStore = WKWebsiteDataStore.default()
        }
        
        super.init(frame: frame, configuration: configuration)
        
        customUserAgent = UserAgent.userAgentForDesktopMode
    }
    
    static func removeNonPersistentStore() {
        BraveWebView.nonPersistentDataStore = nil
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        lastHitPoint = point
        return super.hitTest(point, with: event)
    }
}

extension WKWebView {
    var isPlayingAudio: Bool {
        struct Private {
            static var hasChecked = false
            static var canCheckPlayingAudio = false
        }
        
        if !Private.hasChecked {
            Private.hasChecked = true
            Private.canCheckPlayingAudio = responds(to: Selector(("_isPlayingAudio")))
        }
        
        if Private.canCheckPlayingAudio {
            if let isPlayingAudio = value(forKey: "_isPlayingAudio") as? Bool {
                return isPlayingAudio
            }
        }
        return false
    }
}
