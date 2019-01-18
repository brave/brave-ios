// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveShared
import Data
import CoreData

// These override the setting in the prefs
public enum BraveShield {
    case AllOff
    case AdblockAndTp
    case HTTPSE
    case SafeBrowsing
    case FpProtection
    case NoScript
    
    var globalPreference: Bool {
        switch self {
        case .AllOff:
            return false
        case .AdblockAndTp:
            return Preferences.Shields.blockAdsAndTracking.value
        case .HTTPSE:
            return Preferences.Shields.httpsEverywhere.value
        case .SafeBrowsing:
            return Preferences.Shields.blockPhishingAndMalware.value
        case .FpProtection:
            return Preferences.Shields.fingerprintingProtection.value
        case .NoScript:
            return Preferences.Shields.blockScripts.value
        }
    }
}

private class PrivateBrowsingShieldOverride {
    fileprivate static var privateModeOverrides: [String: PrivateBrowsingShieldOverride] = [:]
    
    private var overrides: [BraveShield: Bool] = [:]
    
    init(shield: BraveShield, isOn: Bool) {
        overrides[shield] = isOn
    }
    
    subscript(shield: BraveShield) -> Bool? {
        get { return overrides[shield] }
        set { overrides[shield] = newValue }
    }
}

extension Domain {
    
    /// Remove all private browsing shield overrides
    class func resetPrivateBrowsingShieldOverrides() {
        PrivateBrowsingShieldOverride.privateModeOverrides.removeAll()
    }
    
    class func setBraveShield(forUrl url: URL, shield: BraveShield, isOn: Bool?,
                              context: NSManagedObjectContext = DataController.newBackgroundContext()) {
        
        let domain = Domain.getOrCreateForUrl(url, context: context)
        domain.setBraveShield(shield: shield, isOn: isOn, context: context)
    }
    
    class func getBraveShield(forUrl url: URL, shield: BraveShield,
                              context: NSManagedObjectContext = DataController.newBackgroundContext()) -> Bool? {
        
        let domain = Domain.getOrCreateForUrl(url, context: context)
        return domain.getBraveShield(shield)
    }
    
    func setBraveShield(shield: BraveShield, isOn: Bool?,
                        context: NSManagedObjectContext = DataController.newBackgroundContext()) {
        if PrivateBrowsingManager.shared.isPrivateBrowsing {
            guard let key = url else { return }
            // Remove private mode override if its set to the same value as the Domain's override
            let setting = (isOn == getBraveShield(shield) ? nil : isOn)
            if let on = setting {
                if let override = PrivateBrowsingShieldOverride.privateModeOverrides[key] {
                    override[shield] = on
                } else {
                    PrivateBrowsingShieldOverride.privateModeOverrides[key] = PrivateBrowsingShieldOverride(shield: shield, isOn: on)
                }
            } else {
                PrivateBrowsingShieldOverride.privateModeOverrides[key]?[shield] = nil
            }
            return
        }
        
        let setting = (isOn == shield.globalPreference ? nil : isOn) as NSNumber?
        switch shield {
        case .AllOff: shield_allOff = setting
        case .AdblockAndTp: shield_adblockAndTp = setting
        case .HTTPSE: shield_httpse = setting
        case .SafeBrowsing: shield_safeBrowsing = setting
        case .FpProtection: shield_fpProtection = setting
        case .NoScript: shield_noScript = setting
        }
        DataController.save(context: context)
    }
    
    /// Get whether or not a shield override is set for a given shield.
    func getBraveShield(_ shield: BraveShield) -> Bool? {
        switch shield {
        case .AllOff:
            return self.shield_allOff?.boolValue
        case .AdblockAndTp:
            return self.shield_adblockAndTp?.boolValue
        case .HTTPSE:
            return self.shield_httpse?.boolValue
        case .SafeBrowsing:
            return self.shield_safeBrowsing?.boolValue
        case .FpProtection:
            return self.shield_fpProtection?.boolValue
        case .NoScript:
            return self.shield_noScript?.boolValue
        }
    }
    
    /// Whether or not a given shield should be enabled based on domain exceptions and the users global preference
    func isShieldExpected(_ shield: BraveShield) -> Bool {
        // If we're private browsing we may have private only overrides that the user made during their private
        // session
        if PrivateBrowsingManager.shared.isPrivateBrowsing, let key = url,
            let privateModeOverride = PrivateBrowsingShieldOverride.privateModeOverrides[key]?[shield] {
            return privateModeOverride
        }
        
        switch shield {
        case .AllOff:
            return self.shield_allOff?.boolValue ?? false
        case .AdblockAndTp:
            return self.shield_adblockAndTp?.boolValue ?? Preferences.Shields.blockAdsAndTracking.value
        case .HTTPSE:
            return self.shield_httpse?.boolValue ?? Preferences.Shields.httpsEverywhere.value
        case .SafeBrowsing:
            return self.shield_safeBrowsing?.boolValue ?? Preferences.Shields.blockPhishingAndMalware.value
        case .FpProtection:
            return self.shield_fpProtection?.boolValue ?? Preferences.Shields.fingerprintingProtection.value
        case .NoScript:
            return self.shield_noScript?.boolValue ?? Preferences.Shields.blockScripts.value
        }
    }
}
