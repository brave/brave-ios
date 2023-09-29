/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SafariServices
import Shared
import BraveShared
import CertificateUtilities
import SwiftyJSON
import os.log

enum UrpError {
  case networkError, downloadIdNotFound, ipNotFound, endpointError
}

/// Api endpoints for user referral program.
struct UrpService {
  private struct ParamKeys {
    static let api = "api_key"
    static let referralCode = "referral_code"
    static let platform = "platform"
    static let downLoadId = "download_id"
  }

  private let host: String
  private let adServicesURL: String
  private let apiKey: String
  private let sessionManager: URLSession
  private let certificateEvaluator: PinningCertificateEvaluator

  init?(host: String, apiKey: String, adServicesURL: String) {
    self.host = host
    self.apiKey = apiKey
    self.adServicesURL = adServicesURL

    guard let hostUrl = URL(string: host), let normalizedHost = hostUrl.normalizedHost() else { return nil }

    // Certificate pinning
    certificateEvaluator = PinningCertificateEvaluator(hosts: [normalizedHost])

    sessionManager = URLSession(configuration: .default, delegate: certificateEvaluator, delegateQueue: .main)
  }

  func referralCodeLookup(refCode: String?, completion: @escaping (ReferralData?, UrpError?) -> Void) {
    guard var endPoint = URL(string: host) else {
      completion(nil, .endpointError)
      UrpLog.log("Host not a url: \(host)")
      return
    }

    var params = [UrpService.ParamKeys.api: apiKey]

    var lastPathComponent = "ua"
    if let refCode = refCode {
      params[UrpService.ParamKeys.referralCode] = refCode
      params[UrpService.ParamKeys.platform] = "ios"
      lastPathComponent = "nonua"
    }
    endPoint.append(pathComponents: "promo", "initialize", lastPathComponent)

    sessionManager.urpApiRequest(endPoint: endPoint, params: params) { response in
      switch response {
      case .success(let data):
        if let data = data as? Data {
          Logger.module.debug("Referral code lookup response: \(String(data: data, encoding: .utf8) ?? "nil")")
        }
        
        UrpLog.log("Referral code lookup response: \(data)")

        let json = JSON(data)
        let referral = ReferralData(json: json)
        completion(referral, nil)

      case .failure(let error):
        Logger.module.error("Referral code lookup response: \(error.localizedDescription)")
        UrpLog.log("Referral code lookup response: \(error.localizedDescription)")

        completion(nil, .endpointError)
      }
    }
  }
  
  func adCampaignTokenLookup(adAttributionToken: String, completion: @escaping ((Bool?, Int?)?, Error?) -> Void) {
    guard let endPoint = URL(string: adServicesURL) else {
      completion(nil, nil)
      UrpLog.log("AdServicesURLString can not be resolved: \(adServicesURL)")
      
      return
    }
    
    let attributionDataToken = adAttributionToken.data(using: .utf8)
    
    // Request is created with token fetched from Ad Services
    sessionManager.adServicesAttributionApiRequest(endPoint: endPoint, rawData: attributionDataToken) { response in
      switch response {
      case .success(let data):
        if let data = data as? Data {
          Logger.module.debug("Ad Attribution response: \(String(data: data, encoding: .utf8) ?? "nil")")
        }
        
        UrpLog.log("Ad Attribution responsee: \(data)")

        if let dataResponseJSON = data as? [String: Any] {
          if let attribution = dataResponseJSON["attribution"] as? Bool, 
              let campaignId = dataResponseJSON["campaignId"] as? Int {
            completion((attribution, campaignId), nil)
          }
        }
        
        completion(nil, nil)
      case .failure(let error):
        Logger.module.error("Ad Attribution response: \(error.localizedDescription)")
        UrpLog.log("Ad Attribution response: \(error.localizedDescription)")

        completion(nil, error)
      }
    }
  }

  func checkIfAuthorizedForGrant(with downloadId: String, completion: @escaping (Bool?, UrpError?) -> Void) {
    guard var endPoint = URL(string: host) else {
      completion(nil, .endpointError)
      return
    }
    endPoint.append(pathComponents: "promo", "activity")

    let params = [
      UrpService.ParamKeys.api: apiKey,
      UrpService.ParamKeys.downLoadId: downloadId,
    ]

    sessionManager.urpApiRequest(endPoint: endPoint, params: params) { response in
      switch response {
      case .success(let data):
        if let data = data as? Data {
          Logger.module.debug("Check if authorized for grant response: \(String(data: data, encoding: .utf8) ?? "nil")")
        }
        let json = JSON(data)
        completion(json["finalized"].boolValue, nil)

      case .failure(let error):
        Logger.module.error("Check if authorized for grant response: \(error.localizedDescription)")
        completion(nil, .endpointError)
      }
    }
  }
}

extension URLSession {
  /// All requests to referral api use PUT method, accept and receive json.
  func urpApiRequest(endPoint: URL, params: [String: String], completion: @escaping (Result<Any, Error>) -> Void) {
    request(endPoint, method: .put, parameters: params, encoding: .json) { response in
      completion(response)
    }
  }
  
  // Apple ad service attricution request requires plain text encoding with post method and passing token as rawdata
  func adServicesAttributionApiRequest(endPoint: URL, rawData: Data?, completion: @escaping (Result<Any, Error>) -> Void) {
    request(endPoint, method: .post, rawData: rawData, encoding: .textPlain) { response in
      completion(response)
    }
  }
}
