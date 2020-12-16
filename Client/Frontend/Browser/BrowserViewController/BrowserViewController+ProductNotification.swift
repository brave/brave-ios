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
        case newbieExclusive = 5000
        case casualExclusive = 10000
        case regularExclusive = 25000
        case expertExclusive = 75000
        case professionalTier = 100000
        case primeTier = 250000
        case grandTier = 500000
        case legendaryTier = 1000000
        
        var title: String {
            switch self {
                case .specialTier:
                    return Strings.ShieldEducation.benchmarkSpecialTierTitle
                case .newbieExclusive, .casualExclusive, .regularExclusive, .expertExclusive:
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
    
    @objc func presentEducationalProductNotifications() {
        guard let selectedTab = tabManager.selectedTab, !benchmarkNotificationPresented else { return }
        
        let todayInSeconds = Date().timeIntervalSince1970
        let checkDate = Preferences.ProductNotificationBenchmarks.ongoingEducationCheckDate.value
        let isProductNotificationsValid = todayInSeconds <= checkDate
        
        var notificationShown = false
        let contentBlockerStats = selectedTab.contentBlocker.stats

        // Step 1: First Time Block Notification
        if isProductNotificationsValid,
           !Preferences.ProductNotificationBenchmarks.firstTimeBlockingShown.value,
           contentBlockerStats.total > 0 {
            
            notifyFirstTimeBlock(theme: Theme.of(selectedTab))
            
            Preferences.ProductNotificationBenchmarks.firstTimeBlockingShown.value = true
            Preferences.ProductNotificationBenchmarks.ongoingEducationCheckDate.value = Date().timeIntervalSince1970 + 7.days
            
            notificationShown = true
        }
        
        // Step 2: Load a video on a streaming site
        guard !notificationShown else { return }

        let isVideoStreamingSite = (selectedTab.canonicalURL?.absoluteString.contains("youtube") == true
                                        || selectedTab.canonicalURL?.absoluteString.contains("vimeo") == true)
            
        if isProductNotificationsValid,
           !Preferences.ProductNotificationBenchmarks.videoAdBlockShown.value,
           isVideoStreamingSite {
            
            notifyVideoAdsBlocked(theme: Theme.of(selectedTab))
            notificationShown = true
        }
        
        // Step 3: 20+ Trackers and Ads Blocked
        guard !notificationShown else { return }

        if isProductNotificationsValid,
           !Preferences.ProductNotificationBenchmarks.privacyProtectionBlockShown.value,
           contentBlockerStats.total > benchmarkNumberOfTrackers {
            
            notifyPrivacyProtectBlock(theme: Theme.of(selectedTab))
            notificationShown = true
        }
        
        // Step 4: Https Upgrade
        guard !notificationShown else { return }

        if isProductNotificationsValid,
           !Preferences.ProductNotificationBenchmarks.httpsUpgradeShown.value,
           contentBlockerStats.httpsCount > 0 {
            
            notifyHttpsUpgrade(theme: Theme.of(selectedTab))
            notificationShown = true
        }
        
        // Step 5: Share Brave Benchmark Tiers
        guard !notificationShown else { return }

        if !Preferences.ProductNotificationBenchmarks.allTiersShown.value {
            let numOfTrackerAds = BraveGlobalShieldStats.shared.adblock + BraveGlobalShieldStats.shared.trackingProtection
            let existingTierList = BenchmarkTrackerCountTier.allCases.filter({ numOfTrackerAds > $0.rawValue })
            
            for tier in existingTierList {
                if Preferences.ProductNotificationBenchmarks.trackerTierCount.value < numOfTrackerAds {
                    if let nextTier = tier.nextTier {
                        Preferences.ProductNotificationBenchmarks.trackerTierCount.value = nextTier.rawValue
                    } else {
                        Preferences.ProductNotificationBenchmarks.allTiersShown.value = true
                    }
                        
                    notifyTrackerAdsCount(tier.rawValue, theme: Theme.of(selectedTab))
                    break
                }
            }
        }
    }
    
    private func notifyFirstTimeBlock(theme: Theme) {
        let shareTrackersViewController = ShareTrackersController(theme: theme, trackingType: .trackerAdWarning)
        
        shareTrackersViewController.actionHandler = { [weak self] action in
            guard let self = self else { return }
            
            switch action {
                case .takeALookTapped:
                    self.showShieldsScreen()
                default:
                    break
            }
        }
        
        showBenchmarkNotificationPopover(controller: shareTrackersViewController)
    }
    
    private func notifyVideoAdsBlocked(theme: Theme) {
        let shareTrackersViewController = ShareTrackersController(theme: theme, trackingType: .videoAdBlock)
        
        shareTrackersViewController.actionHandler = { [weak self] action in
            guard let self = self else { return }
            
            self.benchmarkNotificationPresented = false

            switch action {
                case .dontShowAgainTapped:
                    self.dismissAndAddNoShowList(.videoAdBlock)
                default:
                    break
            }
        }
        
        showBenchmarkNotificationPopover(controller: shareTrackersViewController)
    }
    
    private func notifyPrivacyProtectBlock(theme: Theme) {
        let shareTrackersViewController = ShareTrackersController(theme: theme, trackingType: .trackerAdCountBlock(count: benchmarkNumberOfTrackers))
        
        shareTrackersViewController.actionHandler = { [weak self] action in
            guard let self = self else { return }
            
            self.benchmarkNotificationPresented = false

            switch action {
                case .dontShowAgainTapped:
                    self.dismissAndAddNoShowList(.trackerAdCountBlock(count: self.benchmarkNumberOfTrackers))
                default:
                    break
            }
        }
        
        showBenchmarkNotificationPopover(controller: shareTrackersViewController)
    }
    
    private func notifyHttpsUpgrade(theme: Theme) {
        let shareTrackersViewController = ShareTrackersController(theme: theme, trackingType: .encryptedConnectionWarning)
        
        shareTrackersViewController.actionHandler = { [weak self] action in
            guard let self = self else { return }
            
            self.benchmarkNotificationPresented = false

            switch action {
                case .dontShowAgainTapped:
                    self.dismissAndAddNoShowList(.encryptedConnectionWarning)
                default:
                    break
            }
        }
        
        showBenchmarkNotificationPopover(controller: shareTrackersViewController)
    }
    
    private func notifyTrackerAdsCount(_ count: Int, theme: Theme) {
        let shareTrackersViewController = ShareTrackersController(theme: theme, trackingType: .trackerCountShare(count: count))
        
        shareTrackersViewController.actionHandler = { [weak self] action in
            guard let self = self else { return }
            
            self.benchmarkNotificationPresented = false
            
            switch action {
                case .shareEmailTapped:
                    self.shareTrackersAndAdsWithEmail(count)
                case .shareTwitterTapped:
                    self.shareTrackersAndAdsWithTwitter(count)
                case .shareFacebookTapped:
                    self.shareTrackersAndAdsWithFacebook(count)
                case .shareMoreTapped:
                    self.shareTrackersAndAdsWithDefault(count)
                default:
                    break
            }
        }
        
        showBenchmarkNotificationPopover(controller: shareTrackersViewController)
    }
    
    private func showBenchmarkNotificationPopover(controller: (UIViewController & PopoverContentComponent)) {
        let popover = PopoverController(contentController: controller, contentSizeBehavior: .autoLayout)
        popover.addsConvenientDismissalMargins = false
        popover.present(from: topToolbar.locationView.shieldsButton, on: self)
        benchmarkNotificationPresented = true
        
        popover.popoverDidDismiss = { [weak self] _ in
            guard let self = self else { return }
            
            self.benchmarkNotificationPresented = false
        }
    }
    
    // MARK: Actions
    
    func showShieldsScreen() {
        benchmarkNotificationPresented = false

        dismiss(animated: true) {
            self.presentBraveShieldsViewController()
        }
    }
    
    func dismissAndAddNoShowList(_ type: TrackingType) {
        benchmarkNotificationPresented = false
        
        dismiss(animated: true) {
            switch type {
                case .videoAdBlock:
                    Preferences.ProductNotificationBenchmarks.videoAdBlockShown.value = true
                case .trackerAdCountBlock(count: _):
                    Preferences.ProductNotificationBenchmarks.privacyProtectionBlockShown.value = true
                case .encryptedConnectionWarning:
                    Preferences.ProductNotificationBenchmarks.httpsUpgradeShown.value = true
                default:
                    break
            }
        }
    }
    
    func shareTrackersAndAdsWithEmail(_ count: Int) {
        benchmarkNotificationPresented = false

        dismiss(animated: true) {
            // TODO: Share with Email
        }
    }
    
    func shareTrackersAndAdsWithTwitter(_ count: Int) {
        benchmarkNotificationPresented = false

        dismiss(animated: true) {
            // TODO: Share with Twitter
        }
    }
    
    func shareTrackersAndAdsWithFacebook(_ count: Int) {
        benchmarkNotificationPresented = false

        dismiss(animated: true) {
            // TODO: Share with Facebook
        }
    }
    
    func shareTrackersAndAdsWithDefault(_ count: Int) {
        benchmarkNotificationPresented = false

        dismiss(animated: true) {
            // TODO: Share with Default
        }
    }
}
