// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveShared
import BraveUI
import Shared

// MARK: - ProductNotification

extension BrowserViewController {
    
    // MARK: BenchmarkTrackerCountTier
        
    enum BenchmarkTrackerCountTier: Int, Equatable, CaseIterable {
        case specialTier = 1000
        case newbieExclusiveTier = 5000
        case casualExclusiveTier = 10_000
        case regularExclusiveTier = 25_000
        case expertExclusiveTier = 75_000
        case professionalTier = 100_000
        case primeTier = 250_000
        case grandTier = 500_000
        case legendaryTier = 1_000_000

        var title: String {
            switch self {
                case .specialTier:
                    return Strings.ShieldEducation.benchmarkSpecialTierTitle
                case .newbieExclusiveTier, .casualExclusiveTier, .regularExclusiveTier, .expertExclusiveTier:
                    return Strings.ShieldEducation.benchmarkExclusiveTierTitle
                case .professionalTier:
                    return Strings.ShieldEducation.benchmarkProfessionalTierTitle
                case .primeTier:
                    return Strings.ShieldEducation.benchmarkPrimeTierTitle
                case .grandTier:
                    return Strings.ShieldEducation.benchmarkGrandTierTitle
                case .legendaryTier:
                    return Strings.ShieldEducation.benchmarkLegendaryTierTitle
            }
        }

        var nextTier: BenchmarkTrackerCountTier? {
            guard let indexOfSelf = Self.allCases.firstIndex(where: { self == $0 }) else {
                return nil
            }

            return Self.allCases[safe: indexOfSelf + 1]
        }
    }
    
    // MARK: Internal
    
    @objc func updateShieldNotifications() {
        // Adding slight delay here for 2 reasons
        // First the content Blocker stats will be updated in current tab
        // after receiving notification from Global Stats
        // Second the popover notification will be shown after page loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            
            self.presentEducationalProductNotifications()
        }
    }
    
    private func presentEducationalProductNotifications() {
        guard let selectedTab = tabManager.selectedTab,
              !benchmarkNotificationPresented,
              !topToolbar.inOverlayMode else {
            return
        }
        
        let contentBlockerStats = selectedTab.contentBlocker.stats
        
        // Step 1: First Time Block Notification
        if !Preferences.ProductNotificationBenchmarks.firstTimeBlockingShown.value,
           contentBlockerStats.total > 0 {
            
            notifyFirstTimeBlock(theme: Theme.of(selectedTab))
            Preferences.ProductNotificationBenchmarks.firstTimeBlockingShown.value = true
            
            return
        }

        // Step 2: Load a video on a streaming site
        if !Preferences.ProductNotificationBenchmarks.videoAdBlockShown.value,
           selectedTab.url?.isVideoSteamingSiteURL == true {

            notifyVideoAdsBlocked(theme: Theme.of(selectedTab))
            Preferences.ProductNotificationBenchmarks.videoAdBlockShown.value = true

            return
        }
        
        // Step 3: Pre-determined # of Trackers and Ads Blocked
        if !Preferences.ProductNotificationBenchmarks.privacyProtectionBlockShown.value,
           contentBlockerStats.total > benchmarkNumberOfTrackers {
            
            notifyPrivacyProtectBlock(theme: Theme.of(selectedTab))
            Preferences.ProductNotificationBenchmarks.privacyProtectionBlockShown.value = true

            return
        }
        
        // Step 4: Https Upgrade
        if !Preferences.ProductNotificationBenchmarks.httpsUpgradeShown.value,
           contentBlockerStats.httpsCount > 0 {

            notifyHttpsUpgrade(theme: Theme.of(selectedTab))
            Preferences.ProductNotificationBenchmarks.httpsUpgradeShown.value = true

            return
        }
        
        // Benchmark Tier Pop-Over only exist in JP locale
        if Locale.current.regionCode == "JP" {
            // Step 5: Share Brave Benchmark Tiers
            let numOfTrackerAds = BraveGlobalShieldStats.shared.adblock + BraveGlobalShieldStats.shared.trackingProtection
            let existingTierList = BenchmarkTrackerCountTier.allCases.filter({ numOfTrackerAds < $0.rawValue })
            
            if !existingTierList.isEmpty {
                for tier in existingTierList where Preferences.ProductNotificationBenchmarks.trackerTierCount.value < numOfTrackerAds {
                    if let nextTier = tier.nextTier {
                        Preferences.ProductNotificationBenchmarks.trackerTierCount.value = nextTier.rawValue
                    }
                    
                    self.notifyTrackerAdsCount(tier.rawValue, theme: Theme.of(selectedTab))
                    break
                }
            }
        }
    }
    
    private func notifyFirstTimeBlock(theme: Theme) {
        let shareTrackersViewController = ShareTrackersController(theme: theme, trackingType: .trackerAdWarning)
        
        shareTrackersViewController.actionHandler = { [weak self] action in
            guard let self = self, action == .takeALookTapped else { return }
            
            self.showShieldsScreen()
        }
        
        showBenchmarkNotificationPopover(controller: shareTrackersViewController)
    }
    
    private func notifyVideoAdsBlocked(theme: Theme) {
        let shareTrackersViewController = ShareTrackersController(theme: theme, trackingType: .videoAdBlock)
        
        dismiss(animated: true)
        showBenchmarkNotificationPopover(controller: shareTrackersViewController)
    }
    
    private func notifyPrivacyProtectBlock(theme: Theme) {
        let shareTrackersViewController = ShareTrackersController(theme: theme, trackingType: .trackerAdCountBlock(count: benchmarkNumberOfTrackers))
        dismiss(animated: true)
        showBenchmarkNotificationPopover(controller: shareTrackersViewController)
    }
    
    private func notifyHttpsUpgrade(theme: Theme) {
        let shareTrackersViewController = ShareTrackersController(theme: theme, trackingType: .encryptedConnectionWarning)
        dismiss(animated: true)
        showBenchmarkNotificationPopover(controller: shareTrackersViewController)
    }
    
    private func notifyTrackerAdsCount(_ count: Int, theme: Theme) {
        let shareTrackersViewController = ShareTrackersController(theme: theme, trackingType: .trackerCountShare(count: count))
        dismiss(animated: true)

        shareTrackersViewController.actionHandler = { [weak self] action in
            guard let self = self, action == .shareTheNewsTapped else { return }

            self.showShareScreen(with: theme)
        }

        showBenchmarkNotificationPopover(controller: shareTrackersViewController)
    }
    
    private func showBenchmarkNotificationPopover(controller: (UIViewController & PopoverContentComponent)) {
        benchmarkNotificationPresented = true

        let popover = PopoverController(contentController: controller, contentSizeBehavior: .autoLayout)
        popover.addsConvenientDismissalMargins = false
        popover.present(from: self.topToolbar.locationView.shieldsButton, on: self)
    }
    
    // MARK: Actions
    
    func showShieldsScreen() {
        dismiss(animated: true) {
            self.presentBraveShieldsViewController()
        }
    }
    
    func showShareScreen(with theme: Theme) {
        dismiss(animated: true) {
            let globalShieldsActivityController =
                ShieldsActivityItemSourceProvider.shared.setupGlobalShieldsActivityController(theme: theme)
            globalShieldsActivityController.popoverPresentationController?.sourceView = self.view
    
            self.present(globalShieldsActivityController, animated: true, completion: nil)
        }
    }
}
