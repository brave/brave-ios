/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON
import os.log

struct ReferralData {

  let downloadId: String
  let referralCode: String
  let offerPage: String?

  func isExtendedUrp() -> Bool {
    return offerPage != nil
  }

  init(downloadId: String, code: String, offerPage: String? = nil) {
    self.downloadId = downloadId
    self.referralCode = code

    self.offerPage = offerPage
  }

  init?(json: JSON) {
    guard let downloadId = json["download_id"].string, let code = json["referral_code"].string else {
      Logger.module.error("Failed to unwrap json to Referral struct.")
      UrpLog.log("Failed to unwrap json to Referral struct. \(json)")
      return nil
    }

    self.downloadId = downloadId
    self.referralCode = code
    self.offerPage = json["offer_page_url"].string
  }
}

public struct AdAttributionData {
  
  public let attribution: Bool
  public let organizationId: Int?
  public let conversionType: String?
  public let campaignId: Int
  public let countryOrRegion: String?
  
  init(attribution: Bool, organizationId: Int? = nil, conversionType: String? = nil, campaignId: Int, countryOrRegion: String? = nil) {
    self.attribution = attribution
    self.organizationId = organizationId
    self.conversionType = conversionType
    self.campaignId = campaignId
    self.countryOrRegion = countryOrRegion
  }
}

enum SerializationError: Error {
  case missing(String)
  case invalid(String, Any)
}

extension AdAttributionData {
  init(json: [String: Any]?) throws {
    guard let json = json else {
      throw SerializationError.invalid("Invalid json Dictionary", "")
    }
    
    guard let attribution = json["attribution"] as? Bool else {
      Logger.module.error("Failed to unwrap json to Ad Attribution property.")
      UrpLog.log("Failed to unwrap json to Ad Attribution property. \(json)")
      
      throw SerializationError.missing("Attribution Context")
    }
    
    guard let campaignId = json["campaignId"] as? Int else {
      Logger.module.error("Failed to unwrap json to Campaign Id property.")
      UrpLog.log("Failed to unwrap json to Campaign Id property. \(json)")
      
      throw SerializationError.missing("Campaign Id")
    }
    
    if let conversionType = json["conversionType"] as? String {
      guard conversionType == "Download" || conversionType == "Redownload" else {
        throw SerializationError.invalid("Conversion Type", conversionType)
      }
    }
    
    self.attribution = attribution
    self.organizationId = json["orgId"] as? Int
    self.conversionType = json["conversionType"] as? String
    self.campaignId = campaignId
    self.countryOrRegion = json["countryOrRegion"] as? String
  }
}
