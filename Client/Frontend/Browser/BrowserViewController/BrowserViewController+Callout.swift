// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveShared
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
    
    func presentSyncAlertCallout() {
        if Preferences.DebugFlag.skipNTPCallouts == true { return }
        
        let hostingController = UIHostingController(rootView: PrivacyEverywhereView())
        hostingController.modalPresentationStyle = .popover
        
        let popover = hostingController.popoverPresentationController
        hostingController.preferredContentSize = hostingController.view.systemLayoutSizeFitting(view.bounds.size)
        
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: view.center.x, y: view.center.y, width: 0, height: 0)
        popover?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)

        self.present(hostingController, animated: true, completion: nil)


//        let hostingController = UIHostingController(rootView: PrivacyEverywhereView())
//        hostingController.modalPresentationStyle = .popover
//        hostingController.rootView.dismiss = { [unowned hostingController] in
//            hostingController.dismiss(animated: true)
//        }
//
//        let popover = hostingController.popoverPresentationController
//        hostingController.preferredContentSize = hostingController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
//
//        popover?.sourceView = self.view
//        popover?.sourceRect = CGRect(x: view.center.x, y: view.center.y, width: 0, height: 0)
//        popover?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
//
//        self.present(hostingController, animated: true, completion: nil)
    }
    
    func presentVPNAlertCallout() {
        if Preferences.DebugFlag.skipNTPCallouts == true { return }

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
        showedPopup.value = true
    }
    
    /// Shows a vpn screen based on vpn state.
    func presentCorrespondingVPNViewController() {
        guard let vc = BraveVPN.vpnState.enableVPNDestinationVC else { return }
        let nav = SettingsNavigationController(rootViewController: vc)
        nav.navigationBar.topItem?.leftBarButtonItem =
            .init(barButtonSystemItem: .cancel, target: nav, action: #selector(nav.done))
        let idiom = UIDevice.current.userInterfaceIdiom
        
        UIDevice.current.forcePortraitIfIphone(for: UIApplication.shared)
        
        nav.modalPresentationStyle = idiom == .phone ? .pageSheet : .formSheet
        present(nav, animated: true)
    }
    
    func presentBraveRewardsScreenCallout() {
        if Preferences.DebugFlag.skipNTPCallouts == true { return }

        if BraveRewards.isAvailable {
            let controller = OnboardingRewardsAgreementViewController(profile: profile, rewards: rewards)
            controller.onOnboardingStateChanged = { [weak self] controller, state in
                self?.dismissOnboarding(controller, state: state)
            }
            self.present(controller, animated: true)
        }
        return
    }
    
    func presentDefaultBrowserScreenCallout() {
        if Preferences.DebugFlag.skipNTPCallouts == true { return }
        
//        if !shouldShowIntroScreen {
//            return
//        }
//
//        shouldShowIntroScreen = false
        
        let onboardingController = WelcomeViewController(
            profile: nil,
            rewards: nil,
            state: WelcomeViewCalloutState.defaultBrowser(
                title: "Make Brave your default browser",
                details: "With Brave as default, every link you click opens with Brave's privacy protections.",
                primaryButtonTitle: "Set as default",
                secondaryButtonTitle: "Not now",
                primaryAction: {
                    print("Let's go")
                }, secondaryAction: {
                    //nextController.animateToReadyState()
                })
        )

        onboardingController.modalPresentationStyle = .fullScreen
        present(onboardingController, animated: false)
    }
    
    // 60 days until the next time the user sees the onboarding..
    //static let onboardingDaysInterval = TimeInterval(60.days)
}
