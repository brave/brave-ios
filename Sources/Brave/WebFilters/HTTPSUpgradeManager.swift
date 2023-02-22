// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import BraveShared

class HTTPSUpgradeDomainManager {
  private var upgradedRequests: [URL: URLRequest]
  private var httpURLs: Set<URL>
  private var failedURLs: Set<URL>
  
  init() {
    self.upgradedRequests = [:]
    self.httpURLs = []
    self.failedURLs = []
  }
  
  func clearDataIfNeeded(for request: URLRequest, isForMainFrame: Bool) {
    // We only clear on main frame requests
    guard isForMainFrame else {
      return
    }
    
    // Attempt to pull basic data from the request
    guard let url = request.url else {
      clearData()
      return
    }
    
    // If the scheme is already https, we might have already upgraded this request
    // So we will need to check if we need to keep the . Otherwise just clear the requests
    guard url.scheme == "https"  else {
      clearData()
      return
    }
    
    // Look for a previous upgraded request for this main frame
    // (but only the one for this frame) and make sure to keep it
    if let previousRequest = upgradedRequests[url], let previousURL = previousRequest.url {
      upgradedRequests = [url: previousRequest]
      httpURLs = [previousURL]
    } else {
      clearData()
    }
  }
  
  private func clearData() {
    upgradedRequests = [:]
    httpURLs = []
  }
  
  func upgradedURL(for request: URLRequest, isForMainFrame: Bool) -> URL? {
    guard Preferences.Shields.httpsEverywhere.value == true else {
      upgradedRequests = [:]
      return nil
    }
    // TODO: @JS Check blacklist we should fetch
    
    // Attempt to pull basic data from the request
    guard let url = request.url else { return nil }
    guard url.scheme == "http" else { return nil }
    
    // Attempt to make a new url
    var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
    urlComponents?.scheme = "https"
    guard let httpsURL = urlComponents?.url else { return nil }
    guard !failedURLs.contains(httpsURL) else { return nil }
    httpURLs.insert(url)
    
    if isForMainFrame {
      // We only handle main frames, All other frames are not upgraded.
      // But iOS may upgrade them itself so we store the httpURL so we can check if the response was upgraded
      upgradedRequests[httpsURL] = request
      return httpsURL
    } else {
      return nil
    }
  }
  
  func didUpgrade(response: URLResponse) -> Bool {
    // Attempt to pull basic data from the response
    guard let url = response.url else { return false }
    guard url.scheme == "https" else { return false }
    
    // Attempt to make the original request
    var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
    urlComponents?.scheme = "http"
    guard let httpURL = urlComponents?.url else { return false }
    return httpURLs.contains(httpURL)
  }
  
  func addFailedURL(url: URL) {
    failedURLs.insert(url)
  }
  
  func originalRequest(for response: URLResponse) -> URLRequest? {
    guard let url = response.url else { return nil }
    guard response.url?.scheme == "https" else { return nil }
    return upgradedRequests[url]
  }
}

actor HTTPSUpgradeManager {
  private var upgradeStorageManagers: [String: HTTPSUpgradeDomainManager]
  
  init() {
    upgradeStorageManagers = [:]
  }
  
  func storageManager(forMainFrameURL mainFrameURL: URL) -> HTTPSUpgradeDomainManager? {
    guard let etld1 = mainFrameURL.baseDomain else { return nil }
    
    if let storage = upgradeStorageManagers[etld1] {
      return storage
    } else {
      let storage = HTTPSUpgradeDomainManager()
      upgradeStorageManagers[etld1] = storage
      return storage
    }
  }
}
