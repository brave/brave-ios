// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Preferences
import Combine
import Shared

public class AttributionManager { 
  public enum FeatureLinkageType {
    case undefined, vpn, playlist
  }
  
  public enum FeatureLinkageError: Error {
    case executionTimeout
  }
  
  private let dau: DAU
  private let urp: UserReferralProgram
  
  ///  The default Install Referral Code
  private let organicInstallReferralCode = "BRV001"
  
  @Published public var adFeatureLinkage: FeatureLinkageType = .undefined

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
  
  @MainActor public func handleAdsReportingFeatureLinkage() async throws -> String {
    // This function should run multiple tasks first adCampaignLookup
    // and adReportsKeywordLookup depending on adCampaignLookup result.
    // There is maximum threshold of 5 sec for all the tasks to be completed
    // or an error will be thrown
    // This is done in order not to delay onboading more than certain periods

    let start = DispatchTime.now() // Start time for time tracking

    do {
      let attributionData = try await urp.adCampaignLookup()

      let elapsedTime = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000
      let remainingTime = 5.0 - elapsedTime

      guard remainingTime > 0 else {
        throw FeatureLinkageError.executionTimeout
      }

      let task2Timeout = DispatchTime.now() + .seconds(Int(remainingTime))
      
      let keywordResult = try await withCheckedThrowingContinuation { continuation in
        Task.detached {
          do {
            let keyword = try await self.urp.adReportsKeywordLookup(attributionData: attributionData)
            continuation.resume(returning: keyword)
          } catch {
            continuation.resume(throwing: error)
          }
        }

        DispatchQueue.global().asyncAfter(deadline: task2Timeout) {
          continuation.resume(throwing: FeatureLinkageError.executionTimeout)
        }
      }

      return keywordResult
    } catch {
      throw error
    }
  }
  
  public func setupReferralCodeAndPingServer(refCode: String? = nil) {
    let refCode = refCode ?? organicInstallReferralCode
    
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
