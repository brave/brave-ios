// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

class BraveWebView: WKWebView {
    
    private static let nonPersistentDataStore = ReferenceCountedDataStore()
    
    init(frame: CGRect, configuration: WKWebViewConfiguration = WKWebViewConfiguration(), isPrivate: Bool = true) {
        if isPrivate {
            configuration.websiteDataStore = BraveWebView.nonPersistentDataStore.getDataStore()
        } else {
            BraveWebView.nonPersistentDataStore.killDataStore() //switching to normal mode destroys all data-stores
            configuration.websiteDataStore = WKWebsiteDataStore.default()
        }
        
        super.init(frame: frame, configuration: configuration)
    }
    
    func removePersistentStore() {
        if !self.configuration.websiteDataStore.isPersistent {
            BraveWebView.nonPersistentDataStore.destroyDataStore()
        }
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    
    private class ReferenceCountedDataStore {
        private var refCount = 0
        private var dataStore: WKWebsiteDataStore?
        
        func getDataStore() -> WKWebsiteDataStore {
            defer { refCount += 1}
            
            if let dataStore = self.dataStore {
                return dataStore
            }
            
            let dataStore = WKWebsiteDataStore.nonPersistent()
            self.dataStore = dataStore
            return dataStore
        }
        
        func destroyDataStore() {
            refCount -= 1
            
            if refCount <= 0 {
                dataStore = nil
                refCount = 0
            }
        }
        
        func killDataStore() {
            refCount = 0
            dataStore = nil
        }
    }
}
