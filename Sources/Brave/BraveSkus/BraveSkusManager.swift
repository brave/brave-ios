// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import Preferences
import BraveCore
import BraveVPN
import os.log

@MainActor
public class BraveSkusManager {
  private let sku: SkusSkusService
  
  public init?(isPrivateMode: Bool) {
    guard let skusService = Skus.SkusServiceFactory.get(privateMode: isPrivateMode) else {
      assert(isPrivateMode, "SkusServiceFactory failed to intialize in regular mode, something is wrong.")
      return nil
    }
    
    self.sku = skusService
  }
  
  public static func refreshSKUCredential(isPrivate: Bool) async {
    guard let _ = Preferences.VPN.skusCredential.value,
          let domain = Preferences.VPN.skusCredentialDomain.value,
          let expirationDate = Preferences.VPN.expirationDate.value else {
      Logger.module.debug("No skus credentials stored in the app.")
      return
    }
    
    guard expirationDate < Date() else {
      Logger.module.debug("Existing sku credential has not expired yet, no need to refresh it.")
      return
    }
    
    guard let manager = BraveSkusManager(isPrivateMode: isPrivate) else {
      return
    }
    
    _ = await manager.credentialSummary(for: domain)
    Logger.module.debug("credentialSummary response")
  }
  
  // MARK: - Handling SKU methods.
  
  func refreshOrder(for orderId: String, domain: String) async -> Any? {
    let response = await sku.refreshOrder(domain, orderId: orderId)
    
    do {
      guard let data = response.data(using: .utf8) else { return nil }
      let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
      Logger.module.debug("refreshOrder json parsed successfully")
      return json
    } catch {
      Logger.module.error("refrshOrder: Failed to decode json: \(error.localizedDescription)")
      return nil
    }
  }
  
  func fetchOrderCredentials(for orderId: String, domain: String) async -> String {
    let credential = await sku.fetchOrderCredentials(domain, orderId: orderId)
    Logger.module.debug("skus fetchOrderCredentials")
    return credential
  }
  
  func prepareCredentialsPresentation(for domain: String, path: String) async -> String {
    Logger.module.debug("skus prepareCredentialsPresentation")
    
    let credential = await sku.prepareCredentialsPresentation(domain, path: path)
    
    if !credential.isEmpty {
      if let vpnCredential = BraveSkusWebHelper.fetchVPNCredential(credential, domain: domain) {
        Preferences.VPN.skusCredential.value = credential
        Preferences.VPN.skusCredentialDomain.value = domain
        Preferences.VPN.expirationDate.value = vpnCredential.expirationDate
        
        BraveVPN.setCustomVPNCredential(vpnCredential)
      }
    } else {
      Logger.module.debug("skus empty credential from prepareCredentialsPresentation call")
    }
    
    return credential
  }
  
  func credentialSummary(for domain: String) async -> Any? {
    let credential = await sku.credentialSummary(domain)
    
    do {
      Logger.module.debug("skus credentialSummary")
      
      guard let data = credential.data(using: .utf8) else {
        return nil
      }
      
      let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
      
      let jsonDecoder = JSONDecoder()
      jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
      let credentialSummaryJson = try jsonDecoder.decode(CredentialSummary.self, from: data)
      
      switch credentialSummaryJson.state {
      case .valid:
        if Preferences.VPN.skusCredential.value == nil {
          Logger.module.debug("The credential does NOT exists, calling prepareCredentialsPresentation")
          _ = await prepareCredentialsPresentation(for: domain, path: "*")
        } else {
          Logger.module.debug("The credential exists, NOT calling prepareCredentialsPresentation")
        }
      case .sessionExpired:
        Logger.module.debug("This credential session has expired")
        Self.keepShowingSessionExpiredState = true
      case .invalid:
        if !credentialSummaryJson.active {
          Logger.module.debug("The credential summary is not active")
        }
        
        if credentialSummaryJson.remainingCredentialCount <= 0 {
          Logger.module.debug("The credential summary does not have any remaining credentials")
        }
      }
      
      return json
    } catch {
      Logger.module.error("refrshOrder: Failed to decode json: \(error.localizedDescription)")
      return nil
    }
  }
  
  private struct CredentialSummary: Codable {
    let expiresAt: Date
    let active: Bool
    let remainingCredentialCount: Int
    // The json for credential summary has additional fields. They are not used in the app at the moment.
    
    enum State {
      case valid
      case invalid
      case sessionExpired
    }
    
    var state: State {
      if active && remainingCredentialCount > 0 { return .valid }
      if active && remainingCredentialCount == 0 { return .sessionExpired }
      return .invalid
    }
    
    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.active = try container.decode(Bool.self, forKey: .active)
      self.remainingCredentialCount = try container.decode(Int.self, forKey: .remainingCredentialCount)
      guard let expiresAt =
              BraveSkusWebHelper.milisecondsOptionalDate(from: try container.decode(String.self, forKey: .expiresAt)) else {
        throw DecodingError.typeMismatch(Data.self, .init(codingPath: [],
                                                            debugDescription: "Failed to decode Data from String"))
      }
      
      self.expiresAt = expiresAt
    }
  }
  
  // MARK: - Session Expired state
  /// An in-memory flag that will show a "session expired" prompt to the user in the current browsing session.
  public static var keepShowingSessionExpiredState = false
  
  public static func sessionExpiredStateAlert(loginCallback: @escaping (UIAlertAction) -> Void) -> UIAlertController {
    let alert = UIAlertController(title: Strings.VPN.sessionExpiredTitle, message: Strings.VPN.sessionExpiredDescription, preferredStyle: .alert)
    
    let loginButton = UIAlertAction(title: Strings.VPN.sessionExpiredLoginButton, style: .default,
                                    handler: loginCallback)
    let dismissButton = UIAlertAction(title: Strings.VPN.sessionExpiredDismissButton, style: .cancel)
    alert.addAction(loginButton)
    alert.addAction(dismissButton)
    
    return alert
  }
}
