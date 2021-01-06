// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveShared
import BraveUI
import Shared

// MARK: - ProductNotification

extension BrowserViewController {
    
    // MARK: Internal
    
    @objc func presentEducationalProductNotifications() {
        guard let selectedTab = tabManager.selectedTab, !benchmarkNotificationPresented else { return }
        
        let todayInSeconds = Date().timeIntervalSince1970
        let checkDate = Preferences.ProductNotificationBenchmarks.ongoingEducationCheckDate.value
        let isProductNotificationsValid = todayInSeconds <= checkDate
        
        var notificationShown = false
        let contentBlockerStats = selectedTab.contentBlocker.stats
        
        if !isProductNotificationsValid { return }

        // Step 1: First Time Block Notification
        if !Preferences.ProductNotificationBenchmarks.firstTimeBlockingShown.value,
           contentBlockerStats.total > 0 {
            
            notifyFirstTimeBlock(theme: Theme.of(selectedTab))
            
            Preferences.ProductNotificationBenchmarks.firstTimeBlockingShown.value = true
            Preferences.ProductNotificationBenchmarks.ongoingEducationCheckDate.value = Date().timeIntervalSince1970 + 7.days
            
            notificationShown = true
        }
        
        // Step 2: Load a video on a streaming site
        if notificationShown { return }

        if !Preferences.ProductNotificationBenchmarks.videoAdBlockShown.value,
           selectedTab.url?.isMediaSiteURL == true {
            
            notifyVideoAdsBlocked(theme: Theme.of(selectedTab))
            notificationShown = true
        }
        
        // Step 3: 20+ Trackers and Ads Blocked
        if notificationShown { return }

        if !Preferences.ProductNotificationBenchmarks.privacyProtectionBlockShown.value,
           contentBlockerStats.total > benchmarkNumberOfTrackers {
            
            notifyPrivacyProtectBlock(theme: Theme.of(selectedTab))
            notificationShown = true
        }
        
        // Step 4: Https Upgrade
        if notificationShown { return }

        if !Preferences.ProductNotificationBenchmarks.httpsUpgradeShown.value,
           contentBlockerStats.httpsCount > 0 {
            
            notifyHttpsUpgrade(theme: Theme.of(selectedTab))
            notificationShown = true
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
}
