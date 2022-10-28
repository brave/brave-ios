// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import Data
import Shared
import BraveShared
import BraveUI
import BraveOnboarding
import Storage
import WebKit
import os.log

// TODO: Move this log to the Rewards/Ads target once we move Rewards/Ads files.
let adsRewardsLog = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ads-rewards")

extension BrowserViewController {
  func updateRewardsButtonState() {
    if !isViewLoaded { return }
    if !BraveRewards.isAvailable {
      self.topToolbar.locationView.rewardsButton.isHidden = true
      return
    }
    self.topToolbar.locationView.rewardsButton.isHidden = Preferences.Rewards.hideRewardsIcon.value || PrivateBrowsingManager.shared.isPrivateBrowsing
    self.topToolbar.locationView.rewardsButton.iconState = Preferences.Rewards.rewardsToggledOnce.value ? (rewards.isEnabled || rewards.isCreatingWallet ? .enabled : .disabled) : .initial
  }

  func showRewardsDebugSettings() {
    if AppConstants.buildChannel.isPublic { return }

    let settings = RewardsDebugSettingsViewController(rewards: rewards, legacyWallet: legacyWallet)
    let container = UINavigationController(rootViewController: settings)
    present(container, animated: true)
  }

  func showBraveRewardsPanel() {
    if !Preferences.FullScreenCallout.rewardsCalloutCompleted.value,
      Preferences.General.isNewRetentionUser.value == true,
      !Preferences.Rewards.rewardsToggledOnce.value {

      let controller = OnboardingRewardsAgreementViewController()
      controller.onOnboardingStateChanged = { [weak self] controller, state in
        self?.completeOnboarding(controller)
      }
      controller.onRewardsStatusChanged = { [weak self] status in
        self?.rewards.isEnabled = status
      }

      Preferences.FullScreenCallout.rewardsCalloutCompleted.value = true
      present(controller, animated: true)
      topToolbar.locationView.rewardsButton.iconState = Preferences.Rewards.rewardsToggledOnce.value ? (rewards.isEnabled || rewards.isCreatingWallet ? .enabled : .disabled) : .initial
      return
    }

    updateRewardsButtonState()

    guard let tab = tabManager.selectedTab else { return }

    let braveRewardsPanel = BraveRewardsViewController(
      tab: tab,
      rewards: rewards,
      legacyWallet: legacyWallet
    )
    braveRewardsPanel.actionHandler = { [weak self, unowned braveRewardsPanel] action in
      switch action {
      case .rewardsTransferTapped:
        guard let legacyWallet = self?.legacyWallet else { return }
        braveRewardsPanel.dismiss(animated: true) {
          let controller = WalletTransferViewController(legacyWallet: legacyWallet)
          controller.learnMoreHandler = { [weak self, unowned controller] in
            controller.dismiss(animated: true) {
              self?.loadNewTabWithRewardsURL(BraveUX.braveRewardsLearnMoreURL)
            }
          }
          let container = UINavigationController(rootViewController: controller)
          container.modalPresentationStyle = .formSheet
          self?.present(container, animated: true)
        }
      case .unverifiedPublisherLearnMoreTapped:
        self?.loadNewTabWithRewardsURL(BraveUX.braveRewardsUnverifiedPublisherLearnMoreURL)
      }
    }

    let popover = PopoverController(contentController: braveRewardsPanel)
    popover.addsConvenientDismissalMargins = false
    popover.present(from: topToolbar.locationView.rewardsButton, on: self)
    popover.popoverDidDismiss = { [weak self] _ in
      guard let self = self else { return }
      if let tabId = self.tabManager.selectedTab?.rewardsId, self.rewards.ledger?.selectedTabId == 0 {
        // Show the tab currently visible
        self.rewards.ledger?.selectedTabId = tabId
      }
    }
    // Hide the current tab
    rewards.ledger?.selectedTabId = 0
    // Fetch new promotions
    rewards.ledger?.fetchPromotions(nil)
  }

  public func showWalletTransferExpiryPanelIfNeeded() {
    func _show() {
      let controller = WalletTransferExpiredViewController()
      let popover = PopoverController(contentController: controller)
      popover.popoverDidDismiss = { _ in
        Preferences.Rewards.transferUnavailableLastSeen.value = Date().timeIntervalSince1970
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        popover.present(from: self.topToolbar.locationView.rewardsButton, on: self)
      }
    }

    let now = Date()

    guard let legacyWallet = legacyWallet,
      !legacyWallet.isLedgerTransferExpired,
      presentedViewController == nil,
      Locale.current.regionCode == "JP"
    else { return }

    legacyWallet.transferrableAmount { amount in
      guard amount > 0 else { return }
      let gap = AppConstants.buildChannel.isPublic ? 3.days : 2.minutes
      if let lastSeenTimeInterval = Preferences.Rewards.transferUnavailableLastSeen.value {
        // Check if they've seen it in the past 3 days
        if now.timeIntervalSince1970 > lastSeenTimeInterval + gap {
          _show()
        }
      } else {
        _show()
      }
    }
  }

  func claimPendingPromotions() {
    guard
      let ledger = rewards.ledger,
      case let promotions = ledger.pendingPromotions.filter({ $0.status == .active }),
      !promotions.isEmpty else {
      return
    }
    Task {
      for promo in promotions {
        let success = await ledger.claimPromotion(promo)
        adsRewardsLog.info("[BraveRewards] Auto-Claim Promotion - \(success) for \(promo.approximateValue)")
      }
    }
  }

  func authorizeUpholdWallet(from tab: Tab, queryItems items: [String: String]) {
    guard let ledger = rewards.ledger else { return }
    ledger.authorizeExternalWallet(
      ofType: .uphold,
      queryItems: items
    ) { result, redirectURL in
      switch result {
      case .ledgerOk:
        // Fetch the wallet
        ledger.fetchUpholdWallet { _ in
          if let redirectURL = redirectURL {
            // Requires verification
            let request = URLRequest(url: redirectURL)
            tab.loadRequest(request)
          } else {
            // Done
            self.tabManager.removeTab(tab)
            self.showBraveRewardsPanel()
          }
        }
      default:
        // Some other issue occured with authorization
        let popup = AlertPopupView(
          imageView: nil,
          title: Strings.userWalletGenericErrorTitle,
          message: Strings.userWalletGenericErrorMessage,
          titleWeight: .semibold,
          titleSize: 18.0
        )
        popup.addButton(title: Strings.userWalletCloseButtonTitle, type: .primary, fontSize: 14.0) { () -> PopupViewDismissType in
          return .flyDown
        }
        popup.showWithType(showType: .flyUp)
      }
    }
  }

  @objc func resetNTPNotification() {
    Preferences.NewTabPage.brandedImageShowed.value = false
    Preferences.NewTabPage.atleastOneNTPNotificationWasShowed.value = false
  }

  static func migrateAdsConfirmations(for configruation: BraveRewards.Configuration) {
    // To ensure after a user launches 1.21 that their ads confirmations, viewed count and
    // estimated payout remain correct.
    //
    // This hack is unfortunately neccessary due to a missed migration path when moving
    // confirmations from ledger to ads, we must extract `confirmations.json` out of ledger's
    // state file and save it as a new file under the ads directory.
    let base = configruation.storageURL
    let ledgerStateContainer = base.appendingPathComponent("ledger/random_state.plist")
    let adsConfirmations = base.appendingPathComponent("ads/confirmations.json")
    let fm = FileManager.default

    if !fm.fileExists(atPath: ledgerStateContainer.path) || fm.fileExists(atPath: adsConfirmations.path) {
      // Nothing to migrate or already migrated
      return
    }

    do {
      let contents = NSDictionary(contentsOfFile: ledgerStateContainer.path)
      guard let confirmations = contents?["confirmations.json"] as? String else {
        adsRewardsLog.debug("No confirmations found to migrate in ledger's state container")
        return
      }
      try confirmations.write(toFile: adsConfirmations.path, atomically: true, encoding: .utf8)
    } catch {
      adsRewardsLog.error("Failed to migrate confirmations.json to ads folder: \(error.localizedDescription)")
    }
  }

  private func loadNewTabWithRewardsURL(_ url: URL) {
    self.presentedViewController?.dismiss(animated: true)

    if let tab = tabManager.getTabForURL(url) {
      tabManager.selectTab(tab)
    } else {
      let request = URLRequest(url: url)
      let isPrivate = PrivateBrowsingManager.shared.isPrivateBrowsing
      tabManager.addTabAndSelect(request, isPrivate: isPrivate)
    }
  }

  /// Removes any scheduled or delivered ad grant reminders which may have been added prior to
  /// removal of those reminders.
  public func removeScheduledAdGrantReminders() {
    let idPrefix = "rewards.notification.monthly-claim"
    let center = UNUserNotificationCenter.current()
    center.getPendingNotificationRequests { requests in
      let ids =
        requests
        .filter { $0.identifier.hasPrefix(idPrefix) }
        .map(\.identifier)
      if ids.isEmpty { return }
      center.removeDeliveredNotifications(withIdentifiers: ids)
      center.removePendingNotificationRequests(withIdentifiers: ids)
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
    ledgerObserver = rewardsObserver

    rewardsObserver.walletInitalized = { [weak self] result in
      guard let self = self, let client = self.deviceCheckClient else { return }
      if result == .ledgerOk || result == .walletCreated, !DeviceCheckClient.isDeviceEnrolled() {
        ledger.setupDeviceCheckEnrollment(client) {}
        self.updateRewardsButtonState()
      }
    }
    rewardsObserver.promotionsAdded = { [weak self] promotions in
      self?.claimPendingPromotions()
    }
    rewardsObserver.fetchedPanelPublisher = { [weak self] publisher, tabId in
      guard let self = self, self.isViewLoaded, let tab = self.tabManager.selectedTab, tab.rewardsId == tabId else { return }
      self.publisher = publisher
    }

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
}

extension Tab {
  func reportPageLoad(to rewards: BraveRewards, redirectionURLs urls: [URL]) {
    guard let webView = webView, let url = webView.url else { return }
    if url.isLocal || PrivateBrowsingManager.shared.isPrivateBrowsing { return }

    var htmlBlob: String?
    var classifierText: String?

    let group = DispatchGroup()
    group.enter()

    webView.evaluateSafeJavaScript(functionName: "new XMLSerializer().serializeToString", args: ["document"], contentWorld: WKContentWorld.defaultClient, escapeArgs: false) { html, _ in
      htmlBlob = html as? String
      group.leave()
    }

    if shouldClassifyLoadsForAds {
      group.enter()
      webView.evaluateSafeJavaScript(functionName: "document?.body?.innerText", contentWorld: .defaultClient, asFunction: false) { text, _ in
        classifierText = text as? String
        group.leave()
      }
    }

    group.notify(queue: .main) {
      let faviconURL = URL(string: self.displayFavicon?.url ?? "")
      if faviconURL == nil {
        adsRewardsLog.warning("No favicon found in \(self) to report to rewards panel")
      }
      rewards.reportLoadedPage(
        url: url, redirectionURLs: urls.isEmpty ? [url] : urls,
        faviconURL: faviconURL, tabId: Int(self.rewardsId),
        html: htmlBlob ?? "", adsInnerText: classifierText)
    }
  }

  func reportPageNavigation(to rewards: BraveRewards) {
    rewards.reportTabNavigation(tabId: self.rewardsId)
  }
}

extension BrowserViewController: BraveAdsCaptchaHandler {
  public func handleAdaptiveCaptcha(forPaymentId paymentId: String, captchaId: String) {
    if Preferences.Rewards.adaptiveCaptchaFailureCount.value >= 10 {
      adsRewardsLog.info("Skipping adaptive captcha request as failure count exceeds threshold.")
      return
    }
    Task {
      do {
        try await rewards.ledger?.solveAdaptiveCaptcha(paymentId: paymentId, captchaId: captchaId)
      } catch {
        // Increase failure count, stop attempting attestation altogether passed a specific count
        Preferences.Rewards.adaptiveCaptchaFailureCount.value += 1
        adsRewardsLog.error("Failed to solve adaptive captcha: \(error.localizedDescription)")
      }
    }
  }
}
