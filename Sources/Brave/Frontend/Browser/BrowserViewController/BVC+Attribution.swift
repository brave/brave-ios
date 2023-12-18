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
  
  @MainActor public func handleSearchAdsInstallAttribution(_ urp: UserReferralProgram) async throws {
    do {
      let attributionData = try await urp.adCampaignLookup()
      let refCode = urp.generateReferralCode(attributionData: attributionData)
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
  
  private func performProgramReferralLookup(_ urp: UserReferralProgram, refCode: String?) {
    urp.referralLookup(refCode: refCode) { [weak self] referralCode, offerUrl in
      guard let self = self else { return }
      
      Preferences.URP.referralLookupOutstanding.value = false
      
      guard let url = offerUrl?.asURL else { return }
      self.openReferralLink(url: url)
    }
  }
}
