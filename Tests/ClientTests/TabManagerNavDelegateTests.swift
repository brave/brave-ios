// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import WebKit

@testable import Brave

class TabManagerNavDelegateTests: XCTestCase {
    let navigation = WKNavigation()

    func test_webViewDidCommit_sendsCorrectMessage() {
        let sut = TabManagerNavDelegate()
        let delegate1 = WKNavigationDelegateSpy()
        let delegate2 = WKNavigationDelegateSpy()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webView(anyWebView(), didCommit: navigation)

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidCommit])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidCommit])
    }

    func test_webViewDidFail_sendsCorrectMessage() {
        let sut = TabManagerNavDelegate()
        let delegate1 = WKNavigationDelegateSpy()
        let delegate2 = WKNavigationDelegateSpy()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webView(anyWebView(), didFail: navigation, withError: anyError())

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidFail])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidFail])
    }

    func test_webViewDidFailProvisionalNavigation_sendsCorrectMessage() {
        let sut = TabManagerNavDelegate()
        let delegate1 = WKNavigationDelegateSpy()
        let delegate2 = WKNavigationDelegateSpy()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webView(anyWebView(), didFailProvisionalNavigation: navigation, withError: anyError())

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidFailProvisionalNavigation])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidFailProvisionalNavigation])
    }

    func test_webViewDidFinish_sendsCorrectMessage() {
        let sut = TabManagerNavDelegate()
        let delegate1 = WKNavigationDelegateSpy()
        let delegate2 = WKNavigationDelegateSpy()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webView(anyWebView(), didFinish: navigation)

        XCTAssertEqual(delegate1.receivedMessages, [.webViewDidFinish])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewDidFinish])
    }

    func test_webViewWebContentProcessDidTerminate_sendsCorrectMessage() {
        let sut = TabManagerNavDelegate()
        let delegate1 = WKNavigationDelegateSpy()
        let delegate2 = WKNavigationDelegateSpy()

        sut.insert(delegate1)
        sut.insert(delegate2)
        sut.webViewWebContentProcessDidTerminate(anyWebView())

        XCTAssertEqual(delegate1.receivedMessages, [.webViewWebContentProcessDidTerminate])
        XCTAssertEqual(delegate2.receivedMessages, [.webViewWebContentProcessDidTerminate])
    }
}

// MARK: - Helpers

private func anyWebView() -> WKWebView {
    return WKWebView(frame: CGRect(width: 100, height: 100))
}

private func anyError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

private class WKNavigationDelegateSpy: WKNavigationDelegate {
    enum Message {
        case webViewDidCommit
        case webViewDidFail
        case webViewDidFailProvisionalNavigation
        case webViewDidFinish
        case webViewWebContentProcessDidTerminate
        case webViewDidReceiveServerRedirectForProvisionalNavigation
        case webViewDidStartProvisionalNavigation
        case webViewDecidePolicyWithActionPolicy
        case webViewDecidePolicyWithResponsePolicy
    }

    var receivedMessages = [Message]()

    func isEqual(_ object: Any?) -> Bool {
        return true
    }

    var hash: Int = 1

    var superclass: AnyClass?

    func `self`() -> Self {
        return self
    }

    func perform(_ aSelector: Selector!) -> Unmanaged<AnyObject>! {
        return .none
    }

    func perform(_ aSelector: Selector!, with object: Any!) -> Unmanaged<AnyObject>! {
        return .none
    }

    func perform(_ aSelector: Selector!, with object1: Any!, with object2: Any!) -> Unmanaged<AnyObject>! {
        return .none
    }

    func isProxy() -> Bool {
        return true
    }

    func isKind(of aClass: AnyClass) -> Bool {
        return true
    }

    func isMember(of aClass: AnyClass) -> Bool {
        return true
    }

    func conforms(to aProtocol: Protocol) -> Bool {
        return true
    }

    func responds(to aSelector: Selector!) -> Bool {
        return true
    }

    var description: String = ""

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        receivedMessages.append(.webViewDidCommit)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        receivedMessages.append(.webViewDidFail)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        receivedMessages.append(.webViewDidFailProvisionalNavigation)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        receivedMessages.append(.webViewDidFinish)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        receivedMessages.append(.webViewWebContentProcessDidTerminate)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        receivedMessages.append(.webViewDidReceiveServerRedirectForProvisionalNavigation)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        receivedMessages.append(.webViewDidStartProvisionalNavigation)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        receivedMessages.append(.webViewDecidePolicyWithActionPolicy)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        receivedMessages.append(.webViewDecidePolicyWithResponsePolicy)
    }
}
