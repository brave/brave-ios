/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import AdjustSdk

private let AdjustIntegrationErrorDomain = "org.mozilla.ios.Firefox.AdjustIntegrationErrorDomain"

private let AdjustAttributionFileName = "AdjustAttribution.json"

private let AdjustAppTokenKey = "AdjustAppToken"
private let AdjustEnvironmentKey = "AdjustEnvironment"

private let AdjustSandboxEnvironment = "sandbox"
private let AdjustProductionEnvironment = "production"

private enum AdjustEnvironment: String {
    case Sandbox = "sandbox"
    case Production = "production"
}

private struct AdjustSettings {
    var appToken: String
    var environment: AdjustEnvironment
}

/// Simple (singleton) object to contain all code related to Adjust. The idea is to capture all logic
/// here so that we have one single place where we can see what Adjust is doing. Ideally you only call
/// functions in this object from other parts of the application.

class AdjustIntegration: NSObject {
    let profile: Profile
    
    init(profile: Profile) {
        self.profile = profile

        super.init()

        // Move the "AdjustAttribution.json" file from the documents directory to the caches directory.
        migratePathComponentInDocumentsDirectory(AdjustAttributionFileName, to: .cachesDirectory)
    }

    /// Return an ADJConfig object if Adjust has been enabled. It is determined from the values in
    /// the Info.plist file if Adjust should be enabled, and if so, what its application token and
    /// environment are. If those keys are either missing or empty in the Info.plist then it is
    /// assumed that Adjust is not enabled for this build.

    fileprivate func getConfig() -> ADJConfig? {
        guard let settings = getSettings() else {
            return nil
        }

        let config = ADJConfig(appToken: settings.appToken, environment: settings.environment.rawValue)
        if settings.environment == .Sandbox {
            config?.logLevel = ADJLogLevelDebug
        }
        config?.delegate = self
        return config
    }

    /// Returns the Adjust settings from our Info.plist. If the settings are missing or invalid, such as an unknown
    /// environment, then it will return nil.

    fileprivate func getSettings() -> AdjustSettings? {
        let bundle = Bundle.main
        guard let adjustAppToken = bundle.object(forInfoDictionaryKey: AdjustAppTokenKey) as? String,
                let adjustEnvironment = bundle.object(forInfoDictionaryKey: AdjustEnvironmentKey) as? String else {
            return nil
        }
        guard !adjustAppToken.isEmpty && !adjustEnvironment.isEmpty else {
            return nil
        }
        guard let environment = AdjustEnvironment(rawValue: adjustEnvironment) else {
            Logger.browserLogger.error("Adjust - Invalid environment provided: \(adjustEnvironment)")
            return nil
        }
        return AdjustSettings(appToken: adjustAppToken, environment: environment)
    }

    /// Returns true if the attribution file is present.

    fileprivate func hasAttribution() throws -> Bool {
        return FileManager.default.fileExists(atPath: try getAttributionPath())
    }

    /// Save an `ADJAttribution` instance to a JSON file. Throws an error if the file could not be written. The file
    /// written is a JSON file with a single dictionary in it. We add one extra item to it that contains the current
    /// timestamp in seconds since the UNIX epoch.

    fileprivate func saveAttribution(_ attribution: ADJAttribution) throws {
        if let attributionDictionary = attribution.dictionary() {
            let dictionary = NSMutableDictionary(dictionary: attributionDictionary)
            dictionary["_timestamp"] = NSNumber(value: Int64(Date().timeIntervalSince1970) as Int64)
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [JSONSerialization.WritingOptions.prettyPrinted])
            try data.write(to: URL(fileURLWithPath: try getAttributionPath()), options: [])
        }
    }

    /// Return the path to the `AdjustAttribution.json` file. Throws an `NSError` if we could not build the path.

    fileprivate func getAttributionPath() throws -> String {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw NSError(domain: AdjustIntegrationErrorDomain, code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not build \(AdjustAttributionFileName) path"])
        }
        
        return url.appendingPathComponent(AdjustAttributionFileName).path
    }

    /// Return true if Adjust should be enabled. If the user has disabled the Send Anonymous Usage Data then we immediately
    /// return false. Otherwise we only do one ping, which means we only enable it if we have not seen the attributiond
    /// data yet.
    
    fileprivate func shouldEnable() throws -> Bool {
        if profile.prefs.boolForKey(AppConstants.PrefSendUsageData) ?? true {
            return true
        }
        return try hasAttribution() == false
    }
    
    /// Return true if retention (session) tracking should be enabled. This follows the Send Anonymous Usage Data
    /// setting.
    
    fileprivate func shouldTrackRetention() -> Bool {
        return profile.prefs.boolForKey(AppConstants.PrefSendUsageData) ?? true
    }
}

extension AdjustIntegration: AdjustDelegate {
    /// This is called as part of `UIApplication.didFinishLaunchingWithOptions()`. We always initialize the
    /// Adjust SDK. We always let it send the initial attribution ping. Session tracking is only enabled if
    /// the Send Anonymous Usage Data setting is turned on.

    func triggerApplicationDidFinishLaunchingWithOptions(_ launchOptions: [AnyHashable: Any]?) {
        do {
            if let config = getConfig() {
                // Always initialize Adjust - otherwise we cannot enable/disable it later. Their SDK must be
                // initialized through appDidFinishLaunching otherwise it will be in a bad state.
                Adjust.appDidLaunch(config)

                // Disable it right now if we have the attribution and if the user has disabled session tracking. If
                // we do not have attribution yet then we wait until it comes in and at that point make the decision
                // to disable Adjust again.
                if try hasAttribution() {
                    if !shouldTrackRetention() {
                        Logger.browserLogger.info("Adjust - Disabling because sending of usage data is not allowed")
                        Adjust.setEnabled(false)
                    }
                }
            } else {
                Logger.browserLogger.info("Adjust - Skipping because no or invalid config found")
            }
        } catch let error {
            Logger.browserLogger.error("Adjust - Disabling because we failed to configure: \(error)")
            Adjust.setEnabled(false)
        }
    }

    /// This is called when Adjust has figured out the attribution. It will call us with a summary
    /// of all the things it knows. Like the campaign ID. We simply save this to a local file so
    /// that we know we have done a single attribution ping to Adjust.
    ///
    /// Here we also disable Adjust based on the Send Anonymous Usage Data setting.

    func adjustAttributionChanged(_ attribution: ADJAttribution!) {
        do {
            Logger.browserLogger.info("Adjust - Saving attribution info to disk")
            try saveAttribution(attribution)
        } catch let error {
            Logger.browserLogger.error("Adjust - Failed to save attribution: \(error)")
        }
        // Keep Adjust enabled only if the user has allowed this
        if shouldTrackRetention() {
            Logger.browserLogger.info("Adjust - Enabling because user allows anonymous usage data collection")
            Adjust.setEnabled(true)
        } else {
            Logger.browserLogger.info("Adjust - Disabling because user does not allow anonymous usage data collection")
            Adjust.setEnabled(false)
        }
    }

    /// This is called from the Settings screen. The settings screen will remember the choice in the
    /// profile and then use this method to disable or enable Adjust.
    
    static func setEnabled(_ enabled: Bool) {
        Adjust.setEnabled(enabled)
    }
    
    /// Store the deeplink url from Adjust SDK. Per Adjust documentation, any interstitial view launched could interfere
    /// with launching the deeplink. We let the interstial view decide what to do with deeplink.
    /// Ref: https://github.com/adjust/ios_sdk#deferred-deep-linking-scenario
    
    func adjustDeeplinkResponse(_ deeplink: URL?) -> Bool {
        profile.prefs.setString("\(String(describing: deeplink))", forKey: "AdjustDeeplinkKey")
        return true
    }

    private func migratePathComponentInDocumentsDirectory(_ pathComponent: String, to destinationSearchPath: FileManager.SearchPathDirectory) {
        guard let oldPath = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(pathComponent).path, FileManager.default.fileExists(atPath: oldPath) else {
            return
        }

        print("Migrating \(pathComponent) from ~/Documents to \(destinationSearchPath)")
        guard let newPath = try? FileManager.default.url(for: destinationSearchPath, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(pathComponent).path else {
            print("Unable to get destination path \(destinationSearchPath) to move \(pathComponent)")
            return
        }

        do {
            try FileManager.default.moveItem(atPath: oldPath, toPath: newPath)

            print("Migrated \(pathComponent) to \(destinationSearchPath) successfully")
        } catch let error as NSError {
            print("Unable to move \(pathComponent) to \(destinationSearchPath): \(error.localizedDescription)")
        }
    }
}
