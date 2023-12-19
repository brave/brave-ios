// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Preferences
import Shared

public class AttributionManager { 
  private let dau: DAU
  private let urp: UserReferralProgram
  
  ///  The default Install Referral Code
  public let organicInstallReferralCode = "BRV001"
  
  public init(dau: DAU, urp: UserReferralProgram) {
    self.dau = dau
    self.urp = urp
  }
  
  public func handleReferralLookup(completion: @escaping (URL) -> Void) {
    if Preferences.URP.referralLookupOutstanding.value == true {
      performProgramReferralLookup(refCode: UserReferralProgram.getReferralCode()) { offerUrl in
        guard let url = offerUrl else { return }
        completion(url)
      }
    } else {
      urp.pingIfEnoughTimePassed()
    }
  }
  
  @MainActor public func handleSearchAdsInstallAttribution() async throws {
    do {
      let attributionData = try await urp.adCampaignLookup()
      let refCode = generateReferralCode(attributionData: attributionData)
      setupReferralCodeAndPingServer(refCode: refCode)
    } catch {
      throw error
    }
  }
  
  public func setupReferralCodeAndPingServer(refCode: String) {
    // Setting up referral code value
    // This value should be set before first DAU ping
    Preferences.URP.referralCode.value = refCode
    Preferences.URP.installAttributionLookupOutstanding.value = false
    
    dau.sendPingToServer()
  }
  
  private func performProgramReferralLookup(refCode: String?, completion: @escaping (URL?) -> Void) {
    urp.referralLookup(refCode: refCode) { referralCode, offerUrl in
      Preferences.URP.referralLookupOutstanding.value = false
      
      completion(offerUrl?.asURL)
    }
  }
  
  private func generateReferralCode(attributionData: AdAttributionData?) -> String {
    // Prefix code "001" with BRV for organic iOS installs
    var referralCode = organicInstallReferralCode
    
    if attributionData?.attribution == true, let campaignId = attributionData?.campaignId {
      // Adding ASA User refcode prefix to indicate
      // Apple Ads Attribution is true
      referralCode = "ASA\(String(campaignId))"
    }
    
    return referralCode
  }
}
