// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveShared
import BraveUI
import Shared

// MARK: - ProductNotification

extension BrowserViewController {
    
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
                    return "Congratulations. You’re pretty special."
                case .newbieExclusive, .casualExclusive, .regularExclusive, .expertExclusive:
                    return "Congratulations. You’re part of an exclusive club."
                case .professionalTier:
                    return "Congratulations. You joined the pros."
                case .primeTier:
                    return "Congratulations. You’ve become a master."
                case .grandTier:
                    return "Congratulations. You’ve become a Grand Master."
                case .legendaryTier:
                    return "Congratulations. You are legendary."
            }
        }
        
        var nextTier: BenchmarkTrackerCountTier? {
            switch self {
                case .specialTier:
                    return .newbieExclusive
                case .newbieExclusive:
                    return .casualExclusive
                case .casualExclusive:
                    return .regularExclusive
                case .regularExclusive:
                    return .expertExclusive
                case .expertExclusive:
                    return .professionalTier
                case .professionalTier:
                    return .primeTier
                case .primeTier:
                    return .grandTier
                case .grandTier:
                    return .legendaryTier
                case .legendaryTier:
                    return nil
            }
        }
    }
    
    @objc func presentEducationalProductNotifications() {
        guard let selectedTab = tabManager.selectedTab, benchmarkNotificationPresented else { return }
        
        var notificationShown = false
        let contentBlockerStats = ContentBlockerHelper(tab: selectedTab).stats

        // Step 1: First Time Block Notification
        if !Preferences.ProductNotificationBenchmarks.firstTimeBlockingShown.value, contentBlockerStats.total > 0 {
            notifyFirstTimeBlock(selectedTab: selectedTab)
            
            Preferences.ProductNotificationBenchmarks.firstTimeBlockingShown.value = true
            notificationShown = true
        }
        
        // Step 3: 20+ Trackers and Ads Blocked
        guard !notificationShown else { return }

        if !selectedTab.notificationTypeList.contains(.videoAdsBlocked),
           contentBlockerStats.total > 20 {
            notifyVideoAdsBlocked(selectedTab: selectedTab)
            
            selectedTab.notificationTypeList.append(.videoAdsBlocked)
            notificationShown = true
        }
        
        // Step 4: Https Upgrade
        guard !notificationShown else { return }

        if !selectedTab.notificationTypeList.contains(.httpsUpgrade),
           contentBlockerStats.httpsCount > 0 {
            notifyHttpsUpgrade(selectedTab: selectedTab)
            
            selectedTab.notificationTypeList.append(.httpsUpgrade)
            notificationShown = true
        }
        
        // Step 5: Share Brave Benchmark Tiers
        guard !notificationShown else { return }

        if !Preferences.ProductNotificationBenchmarks.allTiersShown.value {
            let numOfTrackersAds = BraveGlobalShieldStats.shared.adblock + BraveGlobalShieldStats.shared.trackingProtection
            let allBenchmarkTiers = BenchmarkTrackerCountTier.allCases
            let savedTrackerTierCount = Preferences.ProductNotificationBenchmarks.trackerTierCount.value
            
            for (index, tier) in (allBenchmarkTiers.filter { numOfTrackersAds > $0.rawValue }).enumerated() {
                guard savedTrackerTierCount < numOfTrackersAds else { return }
                
                if let nextTier = allBenchmarkTiers.at(index)?.nextTier {
                    Preferences.ProductNotificationBenchmarks.trackerTierCount.value = nextTier.rawValue
                } else {
                    Preferences.ProductNotificationBenchmarks.allTiersShown.value = true
                }
                    
                notifyTrackerAdsCount(tier.rawValue, selectedTab: selectedTab)
                
                break
            }
        }
    }
    
    private func notifyFirstTimeBlock(selectedTab: Tab) {
        let shareTrackersViewController = ShareTrackersController(tab: selectedTab, trackingType: .trackerAdWarning)
        
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
    
    private func notifyVideoAdsBlocked(selectedTab: Tab) {
        let shareTrackersViewController = ShareTrackersController(tab: selectedTab, trackingType: .videoAdBlock)
        
        shareTrackersViewController.actionHandler = { [weak self] action in
            guard let self = self else { return }
            
            switch action {
                case .dontShowAgainTapped:
                    self.dismissAndAddNoShowList(.videoAdBlock)
                default:
                    break
            }
        }
        
        showBenchmarkNotificationPopover(controller: shareTrackersViewController)
    }
    
    private func notifyHttpsUpgrade(selectedTab: Tab) {
        let shareTrackersViewController = ShareTrackersController(tab: selectedTab, trackingType: .encryptedConnectionWarning)
        
        shareTrackersViewController.actionHandler = { [weak self] action in
            guard let self = self else { return }
            
            switch action {
                case .dontShowAgainTapped:
                    self.dismissAndAddNoShowList(.encryptedConnectionWarning)
                default:
                    break
            }
        }
        
        showBenchmarkNotificationPopover(controller: shareTrackersViewController)
    }
    
    private func notifyTrackerAdsCount(_ count: Int, selectedTab: Tab) {
        let shareTrackersViewController = ShareTrackersController(tab: selectedTab, trackingType: .trackerCountShare(count: count))
        
        shareTrackersViewController.actionHandler = { [weak self] action in
            guard let self = self else { return }
            
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
        // TODO: Show Brave Shields Detail Screen
    }
    
    func dismissAndAddNoShowList(_ type: TrackingType) {
        // TODO: Dismiss and do not show that kind of notification
    }
    
    func shareTrackersAndAdsWithEmail(_ count: Int) {
        // TODO: Share with Email
    }
    
    func shareTrackersAndAdsWithTwitter(_ count: Int) {
        // TODO: Share with Twitter
    }
    
    func shareTrackersAndAdsWithFacebook(_ count: Int) {
        // TODO: Share with Facebook
    }
    
    func shareTrackersAndAdsWithDefault(_ count: Int) {
        // TODO: Share with Default
    }
}
