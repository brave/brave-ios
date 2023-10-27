// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import UIKit
import WebKit
import CryptoKit
@testable import Brave

/// This is a test view controller that loads a web view and allows us to attach a custom navigation delegate
class MockWebViewController: UIViewController {
  let webView: WKWebView
  let scriptFactory: ScriptFactory
  
  private let userScriptManager = UserScriptManager()
  
  init(navigationDelegate: WKNavigationDelegate) {
    let configuration = WKWebViewConfiguration()
    self.webView = WKWebView(frame: CGRect(width: 10, height: 10), configuration: configuration)
    self.scriptFactory = ScriptFactory()
    super.init(nibName: nil, bundle: nil)
    webView.navigationDelegate = navigationDelegate
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Will load some base scripts into this webview
    userScriptManager.loadScripts(into: webView, scripts: [])
    
    self.view.addSubview(webView)
    webView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  func add(scripts: Set<UserScriptType>) {
    for script in scripts.sorted(by: { $0.order < $1.order }) {
      do {
        let userScript = try scriptFactory.makeScript(for: script)
        add(userScript: userScript)
      } catch {
        XCTFail(error.localizedDescription)
      }
    }
  }
  
  func add(userScript: WKUserScript) {
    webView.configuration.userContentController.addUserScript(userScript)
  }
  
  func loadHTMLString(_ htmlString: String) {
    self.webView.loadHTMLString(htmlString, baseURL: URL(string: "https://example.com"))
  }
  
  @discardableResult
  func attachScriptHandler(contentWorld: WKContentWorld, name: String, messageHandler: MockMessageHandler) -> MockMessageHandler {
    webView.configuration.userContentController.addScriptMessageHandler(
      messageHandler,
      contentWorld: contentWorld,
      name: name
    )
    
    return messageHandler
  }
  
  func attachScriptHandler(contentWorld: WKContentWorld, name: String, timeout: TimeInterval = 30) -> MockMessageHandler {
    return attachScriptHandler(
      contentWorld: contentWorld, name: name,
      messageHandler: MockMessageHandler(timeout: timeout) { _ in
        return nil
      }
    )
  }
}

/// This collects messages and outputs them as a stream
class MessageStream<Message>: NSObject, AsyncIteratorProtocol {
  typealias AsyncIterator = MessageStream
  typealias Element = (Message)
  
  private let timeout: TimeInterval
  private var startDate: Date
  
  @MainActor private var messages: [Element] = []
  @MainActor private var stopped = false
  
  init(timeout: TimeInterval = 360) {
    self.timeout = timeout
    self.startDate = Date()
  }
  
  enum LoadError: Error {
    case timedOut
  }
  
  @MainActor func add(message: Message) {
    guard !stopped else { return }
    messages.append(message)
  }
  
  func start() {
    self.startDate = Date()
  }
  
  @MainActor func stop() {
    stopped = true
    messages.removeAll()
  }
  
  @MainActor func next() async throws -> Element? {
    while !stopped {
      guard Date().timeIntervalSince(startDate) < timeout else {
        throw LoadError.timedOut
      }
      
      guard !messages.isEmpty else {
        try await Task.sleep(seconds: 0.5)
        continue
      }
      
      return messages.removeFirst()
    }
    
    return nil
  }
}
