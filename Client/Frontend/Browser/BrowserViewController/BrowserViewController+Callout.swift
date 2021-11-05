// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveShared
import BraveCore
import BraveUI
import Shared
import SwiftKeychainWrapper
import SwiftUI

// MARK: - Callouts

extension BrowserViewController {
    
    func presentPassCodeMigration() {
        if KeychainWrapper.sharedAppContainerKeychain.authenticationInfo() != nil {
            let controller = UIHostingController(rootView: PasscodeMigrationContainerView())
            controller.rootView.dismiss = { [unowned controller] enableBrowserLock in
                KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(nil)
                Preferences.Privacy.lockWithPasscode.value = enableBrowserLock
                controller.dismiss(animated: true)
            }
            controller.modalPresentationStyle = .overFullScreen
            // No animation to ensure we don't leak the users tabs
            present(controller, animated: false)
        }
    }
    
    func presentVPNAlertCallout() {
        if Preferences.DebugFlag.skipNTPCallouts == true, isfullScreenCalloutPresented { return }

        if !FullScreenCalloutManager.shouldShowDefaultBrowserCallout(calloutType: .vpn) {
            return
        }
        
        let onboardingNotCompleted =
            Preferences.General.basicOnboardingCompleted.value != OnboardingState.completed.rawValue

        let showedPopup = Preferences.VPN.popupShowed

        if onboardingNotCompleted
            || showedPopup.value
            || !VPNProductInfo.isComplete {
            return
        }
        
        let popup = EnableVPNPopupViewController().then {
            $0.isModalInPresentation = true
            $0.modalPresentationStyle = .overFullScreen
        }
        
        popup.enableVPNTapped = { [weak self] in
            self?.presentCorrespondingVPNViewController()
        }
        
        present(popup, animated: false)
        isfullScreenCalloutPresented = true
        showedPopup.value = true
    }
    
    func presentDefaultBrowserScreenCallout() {
        if Preferences.DebugFlag.skipNTPCallouts == true, isfullScreenCalloutPresented { return }

        if !FullScreenCalloutManager.shouldShowDefaultBrowserCallout(calloutType: .defaultBrowser) {
            return
        }
                
        let onboardingController = WelcomeViewController(
            profile: nil,
            rewards: nil,
            state: WelcomeViewCalloutState.defaultBrowserWarning(
                title: "Make Brave your default browser",
                details: "With Brave as default, every link you click opens with Brave's privacy protections.",
                primaryButtonTitle: "Set as default",
                secondaryButtonTitle: "Skip this",
                primaryAction: {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    
                    Preferences.General.defaultBrowserCalloutDismissed.value = true
                    UIApplication.shared.open(settingsUrl)
                }, secondaryAction: { [weak self] in
                    self?.dismiss(animated: false)
                })
        )

        onboardingController.modalPresentationStyle = .fullScreen
        present(onboardingController, animated: false)
        isfullScreenCalloutPresented = true
    }
    
    func presentBraveRewardsScreenCallout() {
        if Preferences.DebugFlag.skipNTPCallouts == true, isfullScreenCalloutPresented { return }

        if !FullScreenCalloutManager.shouldShowDefaultBrowserCallout(calloutType: .rewards) {
            return
        }
                
        if BraveRewards.isAvailable, !Preferences.Rewards.rewardsToggledOnce.value {
            let controller = OnboardingRewardsAgreementViewController(profile: profile, rewards: rewards)
            controller.onOnboardingStateChanged = { [weak self] controller, state in
                self?.dismissOnboarding(controller, state: state)
            }
            present(controller, animated: true)
            isfullScreenCalloutPresented = true

        }
        return
    }
    
    func presentSyncAlertCallout() {
        if Preferences.DebugFlag.skipNTPCallouts == true, isfullScreenCalloutPresented { return }

        if !FullScreenCalloutManager.shouldShowDefaultBrowserCallout(calloutType: .sync) {
            return
        }
                
        if !BraveSyncAPI.shared.isInSyncGroup {

            let controller = PrivacyEverywhereController()
            controller.rootView.dismiss = { [unowned controller] in
                controller.dismiss(animated: true)
            }
            controller.rootView.syncNow = { [unowned controller] in
                controller.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.openInsideSettingsNavigation(with: SyncWelcomeViewController())
                }
            }
            
            present(PopupViewController(contentController: controller), animated: true, completion: nil)
            isfullScreenCalloutPresented = true
        }
        
        return
    }
}
