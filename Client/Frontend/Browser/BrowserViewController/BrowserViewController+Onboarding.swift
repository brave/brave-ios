// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveShared
import BraveUI
import Shared
import BraveCore

// MARK: - Onboarding

extension BrowserViewController {

    func presentOnboardingIntro() {
        if Preferences.DebugFlag.skipOnboardingIntro == true { return }
        
        // 1. Existing user.
        // 2. User already completed onboarding.
        if Preferences.General.basicOnboardingCompleted.value == OnboardingState.completed.rawValue {
            return
        }
        
        // 1. User is brand new
        // 2. User hasn't completed onboarding
        if Preferences.General.basicOnboardingCompleted.value != OnboardingState.completed.rawValue {
            let onboardingController = WelcomeViewController(profile: profile,
                                                             rewards: rewards)
            onboardingController.modalPresentationStyle = .fullScreen
            onboardingController.onAdsWebsiteSelected = { [weak self] url in
                guard let self = self else { return }
                
                if let url = url {
                    let isPrivate = PrivateBrowsingManager.shared.isPrivateBrowsing
                    self.topToolbar.leaveOverlayMode()
                    let tab = self.tabManager.addTab(PrivilegedRequest(url: url) as URLRequest,
                                                     afterTab: self.tabManager.selectedTab,
                                                     isPrivate: isPrivate)
                    self.tabManager.selectTab(tab)
                } else {
                    self.openBlankNewTab(attemptLocationFieldFocus: true, isPrivate: PrivateBrowsingManager.shared.isPrivateBrowsing)
                }
            }
            
            present(onboardingController, animated: false)
            isfullScreenCalloutPresented = true
            shouldShowNTPEducation = true
            return
        }
    }
    
    func notifyTrackersBlocked(domain: String, trackers: [String: [String]]) {
        let controller = WelcomeBraveBlockedAdsController().then {
            var trackers = trackers
            let first = trackers.popFirst()
            let tracker = first?.key
            let trackerCount = ((first?.value.count ?? 0) - 1) + trackers.reduce(0, { res, values in
                res + values.value.count
            })
            
            $0.setData(domain: domain, trackerBlocked: tracker ?? "", trackerCount: trackerCount)
        }
        
        let popover = PopoverController(contentController: controller)
        popover.present(from: topToolbar.locationView.shieldsButton, on: self)
        
        let pulseAnimation = RadialPulsingAnimation(ringCount: 3)
        pulseAnimation.present(icon: topToolbar.locationView.shieldsButton.imageView?.image,
                               from: topToolbar.locationView.shieldsButton,
                               on: popover,
                               browser: self)
        
        popover.popoverDidDismiss = { _ in
            pulseAnimation.removeFromSuperview()
        }
    }
    
    /// New Tab Page Education screen should load after onboarding is finished and user is on locale JP
    /// - Returns: A tuple which shows NTP Edication is enabled and URL to be loaed
    fileprivate func showNTPEducation() -> (isEnabled: Bool, url: URL?) {
        guard let url = BraveUX.ntpTutorialPageURL else {
            return (false, nil)
        }

        return (Locale.current.regionCode == "JP", url)
    }
}

// MARK: OnboardingControllerDelegate

extension BrowserViewController {
    private func presentEducationNTPIfNeeded() {
        // NTP Education Load after onboarding screen
        if shouldShowNTPEducation,
           showNTPEducation().isEnabled,
           let url = showNTPEducation().url {
            tabManager.selectedTab?.loadRequest(PrivilegedRequest(url: url) as URLRequest)
        }
    }
    
    func dismissOnboarding(_ controller: OnboardingRewardsAgreementViewController,
                           state: OnboardingRewardsState) {
        Preferences.General.basicOnboardingCompleted.value = OnboardingState.completed.rawValue
        
        // Present NTP Education If Locale is JP and onboading is finished or skipped
        // Present private browsing prompt if necessary when onboarding has been skipped
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            self.presentEducationNTPIfNeeded()
        }
    }
    
    // 60 days until the next time the user sees the onboarding..
    static let onboardingDaysInterval = TimeInterval(60.days)
}
