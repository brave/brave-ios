// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import WebKit
import BraveCore
import os.log

class BraveSearchResultAdScriptHandler: TabContentScript {
  private struct SearchResultAdResponse: Decodable {  
    struct SearchResultAd: Decodable {
      let creativeInstanceId: String
      let placementId: String
      let creativeSetId: String
      let campaignId: String
      let advertiserId: String
      let landingPage: URL
      let headlineText: String
      let description: String
      let rewardsValue: String
      let conversionUrlPatternValue: String?
      let conversionAdvertiserPublicKeyValue: String?
      let conversionObservationWindowValue: Int?
    }

    let creatives: [SearchResultAd]
  }

  fileprivate weak var tab: Tab?

  init(tab: Tab) {
    self.tab = tab
  }

  static let scriptName = "BraveSearchResultAdScript"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "\(scriptName)_\(messageUUID)"
  static let scriptSandbox: WKContentWorld = .page
  static let userScript: WKUserScript? = {
    guard var script = loadUserScript(named: scriptName) else {
      return nil
    }
    return WKUserScript(source: secureScript(handlerName: messageHandlerName,
                                             securityToken: scriptId,
                                             script: script),
                        injectionTime: .atDocumentEnd,
                        forMainFrameOnly: true,
                        in: scriptSandbox)
  }()

  func userContentController(
    _ userContentController: WKUserContentController,
    didReceiveScriptMessage message: WKScriptMessage, 
    replyHandler: (Any?, String?) -> Void
  ) {
    defer { replyHandler(nil, nil) }

    if !verifyMessage(message: message) {
      assertionFailure("Missing required security token.")
      return
    }

    guard let tab = tab,
          let braveSearchResultAdManager = tab.braveSearchResultAdManager
    else {
      Logger.module.error("Failed to get Brave search result ad handler")
      return
    }

    guard JSONSerialization.isValidJSONObject(message.body),
          let messageData = try? JSONSerialization.data(withJSONObject: message.body, options: []),
          let searchResultAds = try? JSONDecoder().decode(SearchResultAdResponse.self, from: messageData)
    else {
        Logger.module.error("Failed to process Brave search result ads")
        return
    }

    processSearchResultAds(searchResultAds, braveSearchResultAdManager: braveSearchResultAdManager)
  }

  private func processSearchResultAds(
    _ searchResultAds: SearchResultAdResponse,
    braveSearchResultAdManager: BraveSearchResultAdManager
  ) {
    for ad in searchResultAds.creatives {
      guard let rewardsValue = Double(ad.rewardsValue)
        else {
          Logger.module.error("Failed to process Brave search result ads")
          return
      }

      var conversionInfo: BraveAds.ConversionInfo?
      if let conversionUrlPatternValue = ad.conversionUrlPatternValue,
         let conversionObservationWindowValue = ad.conversionObservationWindowValue {
        let timeInterval = TimeInterval(conversionObservationWindowValue * 24 * 60 * 60)
        conversionInfo = .init(
            urlPattern: conversionUrlPatternValue,
            verifiableAdvertiserPublicKeyBase64: ad.conversionAdvertiserPublicKeyValue,
            observationWindow: Date(timeIntervalSince1970: timeInterval)
        )
      }

      let searchResultAdInfo: BraveAds.SearchResultAdInfo = .init(
        type: .searchResultAd,
        placementId: ad.placementId,
        creativeInstanceId: ad.creativeInstanceId,
        creativeSetId: ad.creativeSetId,
        campaignId: ad.campaignId,
        advertiserId: ad.advertiserId,
        targetUrl: ad.landingPage,
        headlineText: ad.headlineText,
        description: ad.description,
        value: rewardsValue,
        conversion: conversionInfo
      )

      braveSearchResultAdManager.triggerSearchResultAdEvent(searchResultAdInfo)
    }
  }
}
