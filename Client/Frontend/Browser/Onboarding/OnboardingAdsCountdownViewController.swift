// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import BraveRewardsUI
import BraveShared

class OnboardingAdsCountdownViewController: OnboardingViewController, UNUserNotificationCenterDelegate {
    
    private struct UX {
        static let animationTime = 3.0
    }
    
    private var timeSinceAnimationStarted: Date?
    
    private var contentView: View {
        return view as! View // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View(theme: theme)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Countdown timer
        contentView.countdownText = String(UX.animationTime)
        contentView.finishedButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let time = timeSinceAnimationStarted, Date().timeIntervalSince(time) >= UX.animationTime {
            self.contentView.setState(.finished)
            return
        }
        
        timeSinceAnimationStarted = Date()
        contentView.resetAnimation()
        contentView.animate(from: 0.0, to: 1.0, duration: UX.animationTime) { [weak self] in
            guard let self = self else { return }
            self.displayMyFirstAdIfAvailable { action in
                if action == .timedOut {
                    //User possibly missed the ad.. show them confirmation screen.
                    self.contentView.setState(.finished)
                } else {
                    //User saw the ad.. they interacted with it.. onboarding is finished.
                    self.continueTapped()
                }
            }
        }
    }
    
    override func continueTapped() {
        Preferences.General.basicOnboardingProgress.value = OnboardingProgress.ads.rawValue
        super.continueTapped()
    }
    
    override func applyTheme(_ theme: Theme) {
        styleChildren(theme: theme)
        contentView.applyTheme(theme)
    }
}

extension OnboardingAdsCountdownViewController {
    
    private func displayMyFirstAdIfAvailable(_ completion: ((AdsNotificationHandler.Action) -> Void)? = nil) {
        if BraveAds.isSupportedRegion(Locale.current.identifier) {
            Preferences.Rewards.myFirstAdShown.value = true
            AdsViewController.displayFirstAd(on: self) { [weak self] action, url  in
                if action == .opened {
                    self?.openURL(url: url)
                }
                
                completion?(action)
            }
        }
    }
    
    private func openURL(url: URL) {
        guard let tabManager = (UIApplication.shared.delegate as? AppDelegate)?.browserViewController.tabManager else {
            return
        }
        
        let request = URLRequest(url: url)
        tabManager.addTabAndSelect(request, isPrivate: PrivateBrowsingManager.shared.isPrivateBrowsing)
    }
}
