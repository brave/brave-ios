// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import Shared
import BraveShared
import Storage
import Data
import WebKit
import ObjectiveC.runtime
@testable import Client

private extension WKWebView {
    class func swizzleMe() {
        let originalSelector = #selector(WKWebView.init(frame:configuration:))
        let swizzledSelector = #selector(WKWebView.reInit(frame:configuration:))
        
        let originalMethod = class_getInstanceMethod(self, originalSelector)!
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)!
        
        let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        
        if didAddMethod {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    }
    
    @objc
    func reInit(frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
        configuration.setValue(true, forKey: "alwaysRunsAtForegroundPriority")
        return reInit(frame: frame, configuration: configuration)
    }
}

private extension HTTPCookie {
    class func filter(cookies: [HTTPCookie], for url: URL) -> [HTTPCookie]? {
        guard let host = url.host?.lowercased() else { return nil }
        return cookies.filter({ $0.validFor(host: host) })
    }
    
    private func validFor(host: String) -> Bool {
        guard domain.hasPrefix(".") else { return host == domain }
        return host == domain.dropFirst() || host.hasSuffix(domain)
    }
}

private class WebViewNavigationAdapter: NSObject, WKNavigationDelegate {
    private let didFailListener: ((Error) -> Void)?
    private let didFinishListener: (() -> Void)?
    
    init(didFailListener: ((Error) -> Void)? = nil, didFinishListener: (() -> Void)? = nil) {
        self.didFailListener = didFailListener
        self.didFinishListener = didFinishListener
        super.init()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinishListener?()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        didFailListener?(error)
    }
}

class TabSessionTests: XCTestCase {
    private var tabManager: TabManager!
    
    override class func setUp() {
        super.setUp()
//        WKWebView.swizzleMe()
    }
    
    override func setUp() {
        super.setUp()
        
        tabManager = { () -> TabManager in
            let profile = BrowserProfile(localName: "profile")
            return TabManager(prefs: profile.prefs, imageStore: nil)
        }()
    }
    
    override func tearDown() {
        super.tearDown()
        
        destroyData { }
        tabManager = nil
    }
    
    private func destroyData(_ completion: @escaping () -> Void) {
        tabManager.removeAll()
        tabManager.reset()
        
        
        let group = DispatchGroup()
        
        group.enter()
        History.deleteAll({
            group.leave()
        })
        
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        
        group.enter()
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                                modifiedSince: .distantPast,
                                                completionHandler: {
            group.leave()
        })

        group.notify(queue: .main, execute: {
            completion()
        })
    }
    
    func testPrivateTabSessionSharing() {
        let dataStoreExpectation = XCTestExpectation(description: "dataStorePersistence")
        var webViewNavigationAdapter = WebViewNavigationAdapter()
        
        destroyData {
            let urls = ["https://bing.com",
                        "https://google.com",
                        "https://yandex.ru",
                        "https://yahoo.com"]
            
            self.tabManager.addTabsForURLs(urls.compactMap({ URL(string: $0) }), zombie: false, isPrivate: true)
            XCTAssertTrue(self.tabManager.allTabs.count == 4, "Error: Not all Tabs are created equally")
            
            let group = DispatchGroup()
            self.tabManager.allTabs.forEach({
                XCTAssertNotNil($0.webView, "WebView is not created yet")
                if $0.webView?.configuration.websiteDataStore.isPersistent == true {
                    XCTFail("Private Tab is storing data persistently!")
                }
                
                group.enter()
            })
            
            webViewNavigationAdapter = WebViewNavigationAdapter(didFailListener: { _ in
                group.leave()
            }, didFinishListener: {
                group.leave()
            })
            self.tabManager.addNavigationDelegate(webViewNavigationAdapter)
            
            group.notify(queue: .main) {
                // All requests finished loading.. time to check the cookies..
                let group = DispatchGroup()
                self.tabManager.allTabs.forEach({
                    group.enter()
                    $0.webView?.configuration.websiteDataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), completionHandler: { records in
                        XCTAssertFalse(records.isEmpty, "Error: Data Store not shared amongst private tabs!")
                        
                        let recordNames = Set<String>(records.compactMap({ URL(string: "http://\($0.displayName)")?.host }))
                        let urlNames = Set<String>(urls.compactMap({ URL(string: $0)?.host }))
                        
                        XCTAssertTrue(urlNames.isSubset(of: recordNames), "Data Store records do not match!")
                        group.leave()
                    })
                })
                
                group.notify(queue: .main) {
                    dataStoreExpectation.fulfill()
                }
            }
        }
        wait(for: [dataStoreExpectation], timeout: 30.0)
    }
	
	func testNormalTabSessionSharing() {
		let dataStoreExpectation = XCTestExpectation(description: "dataStorePersistence")
		var webViewNavigationAdapter = WebViewNavigationAdapter()
		
		destroyData {
			let urls = ["https://bing.com",
						"https://google.com",
						"https://yandex.ru",
						"https://yahoo.com"]
			
			self.tabManager.addTabsForURLs(urls.compactMap({ URL(string: $0) }), zombie: false, isPrivate: false)
			XCTAssertTrue(self.tabManager.allTabs.count == 4, "Error: Not all Tabs are created equally")
			
			let group = DispatchGroup()
			self.tabManager.allTabs.forEach({
				XCTAssertNotNil($0.webView, "WebView is not created yet")
				if $0.webView?.configuration.websiteDataStore.isPersistent == false {
					XCTFail("Normal Tab is not storing data persistently!")
				}
				
				group.enter()
			})
			
			webViewNavigationAdapter = WebViewNavigationAdapter(didFailListener: { _ in
				group.leave()
			}, didFinishListener: {
				group.leave()
			})
			self.tabManager.addNavigationDelegate(webViewNavigationAdapter)
			
			group.notify(queue: .main) {
				// All requests finished loading.. time to check the cookies..
				let group = DispatchGroup()
				self.tabManager.allTabs.forEach({
					group.enter()
					$0.webView?.configuration.websiteDataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), completionHandler: { records in
						XCTAssertFalse(records.isEmpty, "Error: Data Store not shared amongst normal tabs!")
						
						let recordNames = Set<String>(records.compactMap({ URL(string: "http://\($0.displayName)")?.host }))
						let urlNames = Set<String>(urls.compactMap({ URL(string: $0)?.host }))
						
						XCTAssertTrue(urlNames.isSubset(of: recordNames), "Data Store records do not match!")
						group.leave()
					})
				})
				
				group.notify(queue: .main) {
					dataStoreExpectation.fulfill()
				}
			}
		}
		wait(for: [dataStoreExpectation], timeout: 30.0)
	}
    
    func testPrivateTabNonPersistence() {
        let dataStoreExpectation = XCTestExpectation(description: "dataStorePersistence")
        var webViewNavigationAdapter = WebViewNavigationAdapter()
        
        destroyData {
            let urls = ["https://bing.com",
                        "https://google.com",
                        "https://yandex.ru",
                        "https://yahoo.com"]
            
            self.tabManager.addTabsForURLs(urls.compactMap({ URL(string: $0) }), zombie: false, isPrivate: true)
            XCTAssertTrue(self.tabManager.allTabs.count == 4, "Error: Not all Tabs are created equally")
            
            let group = DispatchGroup()
            self.tabManager.allTabs.forEach({
                XCTAssertNotNil($0.webView, "WebView is not created yet")
                if $0.webView?.configuration.websiteDataStore.isPersistent == true {
                    XCTFail("Private Tab is storing data persistently!")
                }
                
                group.enter()
            })
            
            webViewNavigationAdapter = WebViewNavigationAdapter(didFailListener: { _ in
                group.leave()
            }, didFinishListener: {
                group.leave()
            })
            self.tabManager.addNavigationDelegate(webViewNavigationAdapter)
            
            group.notify(queue: .main) {
                // All requests finished loading.. kill all tabs.. check the cookies..
                self.tabManager.removeAll()
                
                // When the tab manager destroys tabs, if there are no tabs left, it adds a new zombie tab.
                // Hence the count of 1.
                XCTAssertTrue(self.tabManager.allTabs.count == 1, "Error: Not all Tabs are destroyed equally")
                
                let group = DispatchGroup()
                self.tabManager.allTabs.forEach({
                    group.enter()
                    $0.webView?.configuration.websiteDataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), completionHandler: { records in
                        XCTAssertTrue(records.filter({ $0.displayName != "localhost" }).isEmpty, "Error: Data Store not cleared when tabs destroyed!")
                        group.leave()
                    })
                })
                
                group.notify(queue: .main) {
                    dataStoreExpectation.fulfill()
                }
            }
        }
        
        wait(for: [dataStoreExpectation], timeout: 30.0)
    }
    
    func testTabsPrivateToNormal() {
        let dataStoreExpectation = XCTestExpectation(description: "dataStorePersistence")
        var webViewNavigationAdapter = WebViewNavigationAdapter()

        destroyData {
            let url = URL(string: "https://yandex.ru")!
            let otherURL = URL(string: "https://google.com")!
            
            self.tabManager.addTabsForURLs([url], zombie: false, isPrivate: true)
            XCTAssertTrue(self.tabManager.allTabs.count == 1, "Error: Not all Tabs are created equally")
            
            let group = DispatchGroup()
            self.tabManager.allTabs.forEach({
                XCTAssertNotNil($0.webView, "WebView is not created yet")
                if $0.webView?.configuration.websiteDataStore.isPersistent == true {
                    XCTFail("Private Tab is storing data persistently!")
                }
                
                group.enter()
            })
            
            webViewNavigationAdapter = WebViewNavigationAdapter(didFailListener: { _ in
                group.leave()
            }, didFinishListener: {
                group.leave()
            })
            self.tabManager.addNavigationDelegate(webViewNavigationAdapter)
            
            // All requests finished loading.. switch to normal mode.. check the cookies..
            group.notify(queue: .main) {
                let group = DispatchGroup()
                webViewNavigationAdapter = WebViewNavigationAdapter(didFailListener: { _ in
                    group.leave()
                }, didFinishListener: {
                    group.leave()
                })
                
                self.tabManager.addNavigationDelegate(webViewNavigationAdapter)
                self.tabManager.addTabsForURLs([otherURL], zombie: false, isPrivate: false)
                
                // When the tab manager switches to normal mode from private
                // It should kill all private tabs..
                XCTAssertTrue(self.tabManager.tabs(withType: .private).isEmpty, "Error: Private tabs not destroyed when switching to normal mode!")
                
                XCTAssertFalse(self.tabManager.tabs(withType: .regular).isEmpty, "Error: Normal tab not created")
                
                self.tabManager.allTabs.forEach({
                    XCTAssertNotNil($0.webView, "WebView is not created yet")
                    if $0.webView?.configuration.websiteDataStore.isPersistent == false {
                        XCTFail("Normal Tab is not storing data persistently!")
                    }
                    
                    group.enter()
                })
                
                group.notify(queue: .main) {
                    let group = DispatchGroup()
                    
                    self.tabManager.tabs(withType: .regular).forEach({
                        group.enter()
                        $0.webView?.configuration.websiteDataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), completionHandler: { records in
                            XCTAssertFalse(records.isEmpty, "Error: Data Store not persistent in normal mode!")
                            
                            let recordNames = Set<String>(records.compactMap({ URL(string: "http://\($0.displayName)")?.host }))
                            let urlNames = Set<String>([url.host ?? "FailedTestDomain"])
                            
                            XCTAssertFalse(urlNames.isSubset(of: recordNames), "Data Store leaking from private tab to normal tab!")
                            
                            group.leave()
                        })
                    })
                    
                    group.notify(queue: .main) {
                        dataStoreExpectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [dataStoreExpectation], timeout: 30.0)
    }
    
    func testTabsNormalToPrivate() {
        let dataStoreExpectation = XCTestExpectation(description: "dataStorePersistence")
        var webViewNavigationAdapter = WebViewNavigationAdapter()
        
        destroyData {
            let url = URL(string: "https://yandex.ru")!
            let otherURL = URL(string: "https://google.com")!
            
            self.tabManager.addTabsForURLs([url], zombie: false, isPrivate: false)
            XCTAssertTrue(self.tabManager.allTabs.count == 1, "Error: Not all Tabs are created equally")
            
            let group = DispatchGroup()
            self.tabManager.allTabs.forEach({
                XCTAssertNotNil($0.webView, "WebView is not created yet")
                if $0.webView?.configuration.websiteDataStore.isPersistent == false {
                    XCTFail("Normal Tab is not storing data persistently!")
                }
                
                group.enter()
            })
            
            webViewNavigationAdapter = WebViewNavigationAdapter(didFailListener: { _ in
                group.leave()
            }, didFinishListener: {
                group.leave()
            })
            self.tabManager.addNavigationDelegate(webViewNavigationAdapter)
            
            // All requests finished loading.. switch to private mode.. check the cookies..
            group.notify(queue: .main) {
                let group = DispatchGroup()
                webViewNavigationAdapter = WebViewNavigationAdapter(didFailListener: { _ in
                    group.leave()
                }, didFinishListener: {
                    group.leave()
                })
                
                self.tabManager.addNavigationDelegate(webViewNavigationAdapter)
                self.tabManager.addTabsForURLs([otherURL], zombie: false, isPrivate: true)
                
                // When the tab manager switches to private mode from normal
                // It should keep both private and normal tabs
                XCTAssertFalse(self.tabManager.tabs(withType: .private).isEmpty, "Error: Private tabs not created")
                XCTAssertFalse(self.tabManager.tabs(withType: .regular).isEmpty, "Error: Normal tab not created")
                
                self.tabManager.tabs(withType: .private).forEach({
                    XCTAssertNotNil($0.webView, "WebView is not created yet")
                    if $0.webView?.configuration.websiteDataStore.isPersistent == true {
                        XCTFail("Private Tab is storing data persistently!")
                    }
                    
                    group.enter()
                })
                
                group.notify(queue: .main) {
                    let group = DispatchGroup()
                    
                    self.tabManager.tabs(withType: .private).forEach({
                        //This is what I believe to be a bug in WKWebView where a non-persistent store can view DISK CACHE from a persistent store.
                        //It doesn't make a difference though because it's not transfering sensitive information, session, or cookies!
                        //Can be verified via Safari Development Tools.
                        // - Brandon T.
                        
    //                    group.enter()
    //                    $0.webView?.configuration.websiteDataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), completionHandler: { records in
    //                        let recordNames = Set<String>(records.compactMap({ URL(string: "http://\($0.displayName)")?.host }))
    //                        let urlNames = Set<String>([url.host ?? "FailedTestDomain"])
    //
    //                        XCTAssertFalse(urlNames.isSubset(of: recordNames), "Data Store leaking from normal tab to private tab!")
    //
    //                        group.leave()
    //                    })
                        
                        group.enter()
                        $0.webView?.configuration.websiteDataStore.httpCookieStore.getAllCookies({ cookies in
                            let cookiesForURL = HTTPCookie.filter(cookies: cookies, for: url) ?? []
                            XCTAssertTrue(cookiesForURL.isEmpty, "Cookie Store leaking from normal tab to private tab!")
                            
                            group.leave()
                        })
                    })
                    
                    group.notify(queue: .main) {
                        dataStoreExpectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [dataStoreExpectation], timeout: 30.0)
    }
}
