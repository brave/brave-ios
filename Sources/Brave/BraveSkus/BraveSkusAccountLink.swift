// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import os.log
import Preferences
import AIChat

private extension BraveStoreProduct {
  var localStorageKey: String {
    switch self {
    case .vpnMonthly, .vpnYearly: return "braveVpn.receipt"
    case .leoMonthly, .leoYearly: return "braveLeo.receipt"
    }
  }
}

class BraveSkusAccountLink {
  private enum Environment: String, CaseIterable {
    case development
    case staging
    case production
    
    var host: String {
      switch self {
      case .development: return "account.brave.softwware"
      case .staging: return "account.bravesoftware.com"
      case .production: return "account.brave.com"
      }
    }
  }
  
  @MainActor
  @discardableResult static func injectLocalStorage(webView: WKWebView, product: BraveStoreProduct) async -> Bool {
    guard let url = webView.url else {
      return false
    }
    
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let scheme = components.scheme,
          let host = components.host else {
      return false
    }

    if scheme != "https" || !Environment.allCases.map({ $0.host }).contains(host) {
      return false
    }
    
    do {
      let storageKey = product.localStorageKey
      let receipt = try BraveSkusSDK.receipt(for: product)
      try await webView.evaluateSafeJavaScriptThrowing(functionName: "localStorage.setItem", args: [storageKey, receipt], contentWorld: .defaultClient)
      
      if let orderId = Preferences.VPN.originalTransactionId.value {
        try await webView.evaluateSafeJavaScriptThrowing(functionName: "localStorage.setItem", args: ["braveLeo.orderId", orderId], contentWorld: .defaultClient)
      }
      
      
      // Brave-Leo requires Order-ID to be injected into LocalStorage.
      if let orderId = Preferences.AIChat.subscriptionOrderId.value {
        try await webView.evaluateSafeJavaScriptThrowing(functionName: "localStorage.setItem", args: ["braveLeo.orderId", orderId], contentWorld: .defaultClient)
      }
      
      return true
    } catch {
      Logger.module.error("Error Injecting SkusSDK receipt into LocalStorage: \(error)")
    }
    return false
  }
}
