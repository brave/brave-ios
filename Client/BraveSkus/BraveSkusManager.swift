// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import BraveCore
import BraveVPN
import os.log

public class BraveSkusManager {
  private let sku: SkusSkusService
  private let considerCachedCredentials: Bool
  
  public init?(isPrivateMode: Bool, considerCachedCredentials: Bool) {
    guard let skusService = Skus.SkusServiceFactory.get(privateMode: isPrivateMode) else {
      assertionFailure("Failed to create SkusService")
      return nil
    }
    
    self.sku = skusService
    self.considerCachedCredentials = considerCachedCredentials
  }
  
  public static func refreshSKUCredential(isPrivate: Bool) {
    guard let _ = Preferences.VPN.skusCredential.value,
          let domain = Preferences.VPN.skusCredentialDomain.value,
          let expirationDate = Preferences.VPN.skusCredentialExpirationDate.value else {
      Logger.module.debug("No skus credentials stored in the app.")
      return
    }
    
    guard expirationDate < Date() else {
      Logger.module.debug("Existing sku credential has not expired yet, no need to refresh it.")
      return
    }
    
    guard let manager = BraveSkusManager(isPrivateMode: isPrivate, considerCachedCredentials: true) else {
      assertionFailure()
      return
    }
    
    Logger.module.debug("Refreshing sku credential")
    
    manager.credentialSummary(for: domain) { completion in
      Logger.module.debug("credentialSummary response")
    }
  }
  
  // MARK: - Handling SKU methods.
  
  func refreshOrder(for orderId: String, domain: String, resultJSON: @escaping (Any?) -> Void) {
    sku.refreshOrder(domain, orderId: orderId) { completion in
      do {
        guard let data = completion.data(using: .utf8) else { return }
        let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        Logger.module.debug("refreshOrder json parsed successfully")
        resultJSON(json)
      } catch {
        resultJSON(nil)
        Logger.module.error("refrshOrder: Failed to decode json: \(error.localizedDescription)")
      }
    }
  }
  
  func fetchOrderCredentials(for orderId: String, domain: String, resultCredential: @escaping (String) -> Void) {
    sku.fetchOrderCredentials(domain, orderId: orderId) { completion in
      Logger.module.debug("skus fetchOrderCredentials")
      resultCredential(completion)
    }
  }
  
  func prepareCredentialsPresentation(for domain: String, path: String,
                                      resultCredential: ((String) -> Void)?) {
    Logger.module.debug("skus prepareCredentialsPresentation")
    sku.prepareCredentialsPresentation(domain, path: path) { credential in
      if !credential.isEmpty {
        if let vpnCredential = BraveSkusWebHelper.fetchVPNCredential(credential, domain: domain) {
          Preferences.VPN.skusCredential.value = credential
          Preferences.VPN.skusCredentialDomain.value = domain
          Preferences.VPN.skusCredentialExpirationDate.value = vpnCredential.expirationDate
          
          BraveVPN.setCustomVPNCredential(vpnCredential)
        }
      } else {
        Logger.module.debug("skus empty credential from prepareCredentialsPresentation call")
      }
      
      resultCredential?(credential)
    }
  }
  
  func credentialSummary(for domain: String, resultJSON: @escaping (Any?) -> Void) {
    sku.credentialSummary(domain) { [weak self] completion in
      do {
        Logger.module.debug("skus credentialSummary")
        
        guard let data = completion.data(using: .utf8) else { return }
        let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        
        resultJSON(json)
        
        if let expiresDate = (json as? [String: Any])?["expires_at"] as? String,
           let date = BraveSkusWebHelper.milisecondsOptionalDate(from: expiresDate) {
          Preferences.VPN.expirationDate.value = date
          
          // The credential has not expired yet, we can proceed with preparing it.
          if date > Date() {
            self?.prepareCredentialsPresentation(for: domain, path: "*", resultCredential: nil)
          }
        } else {
          assertionFailure("Failed to parse date")
        }
        
      } catch {
        Logger.module.error("refrshOrder: Failed to decode json: \(error.localizedDescription)")
      }
    }
  }
}
