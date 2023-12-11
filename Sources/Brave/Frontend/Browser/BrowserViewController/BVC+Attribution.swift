// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Preferences
import Growth
import Shared

extension BrowserViewController {
  public func handleReferralLookup(_ urp: UserReferralProgram) {
    if Preferences.URP.referralLookupOutstanding.value == true {
      performProgramReferralLookup(urp, refCode: UserReferralProgram.getReferralCode())
    } else {
      urp.pingIfEnoughTimePassed()
    }
  }
  
  public func handleSearchAdsInstallAttribution(_ urp: UserReferralProgram) {
    urp.adCampaignLookup() { [weak self] response, error in
      guard let self = self else { return }
      
      let refCode = self.generateReferralCode(attributionData: response, fetchError: error)
      self.setupReferralCodeAndPingServer(refCode: refCode)
    }
  }
  
  private func generateReferralCode(attributionData: AdAttributionData?, fetchError: Error?) -> String {
    // Prefix code "001" with BRV for organic iOS installs
    var referralCode = DAU.organicInstallReferralCode
    
    if fetchError == nil, attributionData?.attribution == true, let campaignId = attributionData?.campaignId {
      // Adding ASA User refcode prefix to indicate
      // Apple Ads Attribution is true
      referralCode = "ASA\(String(campaignId))"
    }
    
    return referralCode
  }
  
  public func setupReferralCodeAndPingServer(refCode: String) {
    // Setting up referral code value
    // This value should be set before first DAU ping
    Preferences.URP.referralCode.value = refCode
    Preferences.URP.installAttributionLookupOutstanding.value = false
    
    dau.sendPingToServer()
  }
  
  private func performProgramReferralLookup(_ urp: UserReferralProgram, refCode: String?) {
    urp.referralLookup(refCode: refCode) { [weak self] referralCode, offerUrl in
      guard let self = self else { return }
      
      Preferences.URP.referralLookupOutstanding.value = false
      
      guard let url = offerUrl?.asURL else { return }
      self.openReferralLink(url: url)
    }
  }
}
