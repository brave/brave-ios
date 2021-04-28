// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import BraveRewards
import XCGLogger

private let log = Logger.browserLogger

protocol BraveRewardsManagerDelegate: AnyObject {
    func updateRewardsButtonState()
}

class BraveRewardsManager: NSObject {
    
    let rewards: BraveRewards
    let legacyWallet: BraveLedger?
    let deviceCheckClient: DeviceCheckClient?
    
    var promotionFetchTimer: Timer?
    
    weak var delegate: BraveRewardsManagerDelegate?
    
    override init() {
        
        
        let configuration: BraveRewardsConfiguration
        if AppConstants.buildChannel.isPublic {
            configuration = .production
        } else {
            if let override = Preferences.Rewards.EnvironmentOverride(rawValue: Preferences.Rewards.environmentOverride.value), override != .none {
                switch override {
                case .dev:
                    configuration = .default
                case .staging:
                    configuration = .staging
                case .prod:
                    configuration = .production
                default:
                    configuration = .staging
                }
            } else {
                configuration = AppConstants.buildChannel == .debug ? .staging : .production
            }
        }

        configuration.buildChannel = BraveAdsBuildChannel().then {
          $0.name = AppConstants.buildChannel.rawValue
          $0.isRelease = AppConstants.buildChannel == .release
        }
        
        Self.migrateAdsConfirmations(for: configuration)
        legacyWallet = Self.legacyWallet(for: configuration)
        
        if let wallet = legacyWallet {
            // Legacy ledger is disabled by default
            wallet.isAutoContributeEnabled = false
            // Ensure we remove any pending contributions or recurring tips from the legacy wallet
            wallet.removeAllPendingContributions { _ in }
            wallet.listRecurringTips { publishers in
                publishers.forEach {
                    wallet.removeRecurringTip(publisherId: $0.id)
                }
            }
        }
        rewards = BraveRewards(configuration: configuration)
        if !BraveRewards.isAvailable {
            // Disable rewards services in case previous user already enabled
            // rewards in previous build
            rewards.isAdsEnabled = false
        } else {
            if rewards.isEnabled && !Preferences.Rewards.rewardsToggledOnce.value {
                Preferences.Rewards.rewardsToggledOnce.value = true
            }
        }
        deviceCheckClient = DeviceCheckClient(environment: configuration.environment)
        
        super.init()
        
        rewards.delegate = self
        
        // Only start ledger service automatically if ads is enabled
        if rewards.isAdsEnabled {
            rewards.startLedgerService(nil)
        }
    }
    
    private static func migrateAdsConfirmations(for configruation: BraveRewardsConfiguration) {
        // To ensure after a user launches 1.21 that their ads confirmations, viewed count and
        // estimated payout remain correct.
        //
        // This hack is unfortunately neccessary due to a missed migration path when moving
        // confirmations from ledger to ads, we must extract `confirmations.json` out of ledger's
        // state file and save it as a new file under the ads directory.
        let base = URL(fileURLWithPath: configruation.stateStoragePath)
        let ledgerStateContainer = base.appendingPathComponent("ledger/random_state.plist")
        let adsConfirmations = base.appendingPathComponent("ads/confirmations.json")
        let fm = FileManager.default
        
        if !fm.fileExists(atPath: ledgerStateContainer.path) ||
            fm.fileExists(atPath: adsConfirmations.path) {
            // Nothing to migrate or already migrated
            return
        }
        
        do {
            let contents = NSDictionary(contentsOfFile: ledgerStateContainer.path)
            guard let confirmations = contents?["confirmations.json"] as? String else {
                log.debug("No confirmations found to migrate in ledger's state container")
                return
            }
            try confirmations.write(toFile: adsConfirmations.path, atomically: true, encoding: .utf8)
        } catch {
            log.error("Failed to migrate confirmations.json to ads folder: \(error)")
        }
    }
    
    private static func legacyWallet(for config: BraveRewardsConfiguration) -> BraveLedger? {
        let fm = FileManager.default
        let stateStorage = URL(fileURLWithPath: config.stateStoragePath)
        let legacyLedger = stateStorage.appendingPathComponent("legacy_ledger")

        // Check if we've already migrated the users wallet to the `legacy_rewards` folder
        if fm.fileExists(atPath: legacyLedger.path) {
            BraveLedger.environment = config.environment
            return BraveLedger(stateStoragePath: legacyLedger.path)
        }
        
        // We've already performed an attempt at migration, if there wasn't a legacy folder, then
        // we have no legacy wallet.
        if Preferences.Rewards.migratedLegacyWallet.value {
            return nil
        }
        
        // Ledger exists in the state storage under `ledger` folder, if that folder doesn't exist
        // then the user hasn't actually launched the app before and doesn't need to migrate
        let ledgerFolder = stateStorage.appendingPathComponent("ledger")
        if !fm.fileExists(atPath: ledgerFolder.path) {
            // No wallet, therefore no legacy folder needed
            Preferences.Rewards.migratedLegacyWallet.value = true
            return nil
        }
        
        do {
            // Copy the current `ledger` directory into the new legacy state storage path
            try fm.copyItem(at: ledgerFolder, to: legacyLedger)
            // Remove the old Rewards DB so that it starts fresh
            try fm.removeItem(atPath: ledgerFolder.appendingPathComponent("Rewards.db").path)
            // And remove the sqlite journal file if it exists
            let journalPath = ledgerFolder.appendingPathComponent("Rewards.db-journal").path
            if fm.fileExists(atPath: journalPath) {
                try fm.removeItem(atPath: journalPath)
            }
            
            Preferences.Rewards.migratedLegacyWallet.value = true
            BraveLedger.environment = config.environment
            return BraveLedger(stateStoragePath: legacyLedger.path)
        } catch {
            log.error("Failed to migrate legacy wallet into a new folder: \(error)")
            return nil
        }
    }
    
    func setupLedger() {
        guard let ledger = rewards.ledger else { return }
        // Update defaults
        ledger.minimumVisitDuration = 8
        ledger.minimumNumberOfVisits = 1
        ledger.allowUnverifiedPublishers = false
        ledger.allowVideoContributions = true
        ledger.contributionAmount = Double.greatestFiniteMagnitude
        
        // Create ledger observer
        let rewardsObserver = LedgerObserver(ledger: ledger)
        ledger.add(rewardsObserver)
        
        rewardsObserver.walletInitalized = { [weak self] result in
            guard let self = self, let client = self.deviceCheckClient else { return }
            if result == .walletCreated {
                ledger.setupDeviceCheckEnrollment(client) { }
                self.delegate?.updateRewardsButtonState()
            }
        }
        rewardsObserver.promotionsAdded = { [weak self] promotions in
            self?.claimPendingPromotions()
        }
        
        // TO KYLE: not needed?
        // rewardsObserver.fetchedPanelPublisher = { [weak self] publisher, tabId in
        //    guard let self = self, self.isViewLoaded,
        //          let tab = self.tabManager.selectedTab,
        //          tab.rewardsId == tabId else { return }
        //    self.publisher = publisher
        //}
        
        promotionFetchTimer = Timer.scheduledTimer(
            withTimeInterval: 1.hours,
            repeats: true,
            block: { [weak self, weak ledger] _ in
                guard let self = self, let ledger = ledger else { return }
                if self.rewards.isEnabled {
                    ledger.fetchPromotions(nil)
                }
            }
        )
    }
    
    private func claimPendingPromotions() {
        guard let ledger = rewards.ledger else { return }
        ledger.pendingPromotions.forEach { promo in
            if promo.status == .active {
                ledger.claimPromotion(promo) { success in
                    log.info("[BraveRewards] Auto-Claim Promotion - \(success) for \(promo.approximateValue)")
                }
            }
        }
    }
}

extension BraveRewardsManager: BraveRewardsDelegate {
    func faviconURL(fromPageURL pageURL: URL, completion: @escaping (URL?) -> Void) {
        // Currently unused, may be removed in the future
    }
    
    func logMessage(withFilename file: String, lineNumber: Int32, verbosity: Int32, message: String) {
        if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }
        log.logln(verbosity.loggerLevel, fileName: file, lineNumber: Int(lineNumber), closure: { message })
    }
    
    func ledgerServiceDidStart(_ ledger: BraveLedger) {
        setupLedger()
    }
}

private extension Int32 {
    var loggerLevel: XCGLogger.Level {
        switch self {
        case 0: return .error
        case 1: return .info
        case 2..<7: return .debug
        default: return .verbose
        }
    }
}
