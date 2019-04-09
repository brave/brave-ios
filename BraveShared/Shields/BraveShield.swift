// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

// These override the setting in the prefs
public enum BraveShield {
    case AllOff
    case AdblockAndTp
    case HTTPSE
    case SafeBrowsing
    case FpProtection
    case NoScript
    
    public var globalPreference: Bool {
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

public class PrivateBrowsingShieldOverride {
    public static var privateModeOverrides: [String: PrivateBrowsingShieldOverride] = [:]
    
    public var overrides: [BraveShield: Bool] = [:]
    
    public init(shield: BraveShield, isOn: Bool) {
        overrides[shield] = isOn
    }
    
    public subscript(shield: BraveShield) -> Bool? {
        get { return overrides[shield] }
        set { overrides[shield] = newValue }
    }
}
