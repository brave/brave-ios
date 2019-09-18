// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import BraveRewardsUI
import BraveShared

class OnboardingAdsCountdownViewController: OnboardingViewController, UNUserNotificationCenterDelegate {
    
    private var rewards: BraveRewards?
    private var notificationsHandler: AdsNotificationHandler?
    private var rewardsObserver: LedgerObserver?
    private var publisher: PublisherInfo?
    private var timeSinceAnimationStarted: Date?
    
    private var contentView: View {
        return view as! View // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View(theme: theme)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBraveRewards()
        
        //Countdown timer
        contentView.countdownText = "3"
        
        //On this screen, when you press "Start Browsing", we need to mark all onboarding as complete, therefore we trigger `skip`..
        contentView.finishedButton.addTarget(self, action: #selector(skipTapped), for: .touchDown)
        
        //On this screen, when you press "I didn't see an ad", we need to go to the next screen..
        contentView.invalidButton.addTarget(self, action: #selector(continueTapped), for: .touchDown)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let time = timeSinceAnimationStarted, Date().timeIntervalSince(time) >= 3.0 {
            self.contentView.setState(.adConfirmation)
            return
        }
        
        timeSinceAnimationStarted = Date()
        contentView.resetAnimation()
        contentView.animate(from: 0.0, to: 1.0, duration: 3.0) { [weak self] in
            guard let self = self else { return }
            self.displayMyFirstAdIfAvailable {
                self.skipTapped()
            }
        }
    }
    
    override func applyTheme(_ theme: Theme) {
        styleChildren(theme: theme)
        contentView.applyTheme(theme)
    }
}

extension OnboardingAdsCountdownViewController {
    
    private func setupBraveRewards() {
        #if NO_REWARDS
        rewards = nil
        rewardsObserver = nil
        #else
        RewardsHelper.configureRewardsLogs()
        rewards = BraveRewards(configuration: .default)
        rewardsObserver = LedgerObserver(ledger: rewards!.ledger)
        #endif
        
        setupRewardsObservers()
        
        if let rewards = rewards {
            notificationsHandler = AdsNotificationHandler(ads: rewards.ads, presentingController: self)
            notificationsHandler?.actionOccured = { [weak self] notification, action in
                guard let self = self else { return }
                if action == .opened {
                    self.openURL(url: notification.url)
                }
            }
        }
    }
    
    private func setupRewardsObservers() {
        guard let rewards = rewards, let observer = rewardsObserver else { return }
        rewards.ledger.add(observer)
        observer.fetchedPanelPublisher = { [weak self] publisher, tabId in
            guard let self = self, self.isViewLoaded else { return }
            self.publisher = publisher
        }
        
        observer.notificationAdded = { [weak self] _ in
            guard let self = self, self.isViewLoaded else { return }
            self.contentView.setState(.adConfirmation)
        }
        
        observer.notificationsRemoved = { [weak self] _ in
            guard let self = self, self.isViewLoaded else { return }
            self.contentView.setState(.adConfirmation)
        }
    }
    
    private func displayMyFirstAdIfAvailable(_ completion: (() -> Void)? = nil) {
        guard let rewards = rewards, rewards.ledger.isEnabled && rewards.ads.isEnabled else { return }
        if Preferences.Rewards.myFirstAdShown.value { return }

        if BraveAds.isSupportedRegion(Locale.current.identifier) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if Preferences.Rewards.myFirstAdShown.value { return }
                Preferences.Rewards.myFirstAdShown.value = true
                AdsViewController.displayFirstAd(on: self) { [weak self] url in
                    self?.openURL(url: url)
                    completion?()
                }
            }
        }
    }
    
    private func openURL(url: URL) {
        (UIApplication.shared.delegate as? AppDelegate)?.browserViewController.openInNewTab(url, isPrivate: PrivateBrowsingManager.shared.isPrivateBrowsing)
    }
}
