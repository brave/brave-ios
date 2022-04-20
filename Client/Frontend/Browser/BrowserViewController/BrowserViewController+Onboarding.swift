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

    presentOnboardingWelcomeScreen(on: self)
  }

  private func presentOnboardingWelcomeScreen(on parentController: UIViewController) {
    if Preferences.DebugFlag.skipOnboardingIntro == true { return }

    // 1. Existing user.
    // 2. User already completed onboarding.
    if Preferences.General.basicOnboardingCompleted.value == OnboardingState.completed.rawValue {
      return
    }

    // 1. User is brand new
    // 2. User hasn't completed onboarding
    if Preferences.General.basicOnboardingCompleted.value != OnboardingState.completed.rawValue,
      Preferences.General.isNewRetentionUser.value == true {
      let onboardingController = WelcomeViewController(
        profile: profile,
        rewards: rewards)
      onboardingController.modalPresentationStyle = .fullScreen
      parentController.present(onboardingController, animated: false)
      isOnboardingOrFullScreenCalloutPresented = true
    }
  }

  private func addNTPTutorialPage() {
    if showNTPEducation().isEnabled, let url = showNTPEducation().url {
      tabManager.addTab(
        PrivilegedRequest(url: url) as URLRequest,
        afterTab: self.tabManager.selectedTab,
        isPrivate: PrivateBrowsingManager.shared.isPrivateBrowsing)
    }
  }

  func showNTPOnboarding() {
    if Preferences.General.isNewRetentionUser.value == true,
      Preferences.DebugFlag.skipNTPCallouts != true,
      !topToolbar.inOverlayMode,
      topToolbar.currentURL == nil {
      
      if !Preferences.FullScreenCallout.omniboxCalloutCompleted.value {
        presentOmniBoxOnboarding()
      }
      
      if !Preferences.FullScreenCallout.ntpCalloutCompleted.value {
        presentNTPStatsOnboarding()
      }
    }
  }
  
  private func presentOmniBoxOnboarding() {
    // If a controller is already presented (such as menu), do not show onboarding
    guard presentedViewController == nil else {
      return
    }
            
    let frame = view.convert(
      topToolbar.locationView.urlTextField.frame,
      from: topToolbar.locationView).insetBy(dx: -7.0, dy: -6.0)
    
    // Present the popover
    let controller = WelcomeOmniBoxOnboardingController()
    controller.setText(title: "Type a website name or URL", details: "See the Brave Difference:\nNo ads. No trackers. Way faster page load.")

    presentPopoverContent(using: controller, with: frame, cornerRadius: 6.0) {
      Preferences.FullScreenCallout.omniboxCalloutCompleted.value = true
    }
  }

  private func presentNTPStatsOnboarding() {
    // If a controller is already presented (such as menu), do not show onboarding
    guard presentedViewController == nil else {
      return
    }

    // We can only show this onboarding on the NTP
    guard let ntpController = tabManager.selectedTab?.newTabPageViewController,
      let statsFrame = ntpController.ntpStatsOnboardingFrame
    else {
      return
    }

    // Project the statsFrame to the current frame
    let frame = view.convert(statsFrame, from: ntpController.view).insetBy(dx: -5.0, dy: 9.0)

    // Present the popover
    let controller = WelcomeNTPOnboardingController()
    controller.setText(details: Strings.Onboarding.ntpOnboardingPopOverTrackerDescription)

    presentPopoverContent(using: controller, with: frame, cornerRadius: 12.0) {
      Preferences.FullScreenCallout.ntpCalloutCompleted.value = true
    }
  }
  
  private func presentPopoverContent(
    using contentController: UIViewController & PopoverContentComponent,
    with frame: CGRect,
    cornerRadius: CGFloat,
    completion: @escaping () -> Void) {
    // Create a border view
    let borderView = UIView().then {
      let borderLayer = CAShapeLayer().then {
        let frame = frame.with { $0.origin = .zero }
        $0.strokeColor = UIColor.white.cgColor
        $0.fillColor = UIColor.clear.cgColor
        $0.lineWidth = 2.0
        $0.strokeEnd = 1.0
        $0.path = UIBezierPath(roundedRect: frame, cornerRadius: cornerRadius).cgPath
      }
      $0.layer.addSublayer(borderLayer)
    }

    view.addSubview(borderView)
    borderView.frame = frame
      
    let popover = PopoverController(contentController: contentController)
    popover.arrowDistance = 10.0
    
    let maskShape = CAShapeLayer().then {
      $0.fillRule = .evenOdd
      $0.fillColor = UIColor.white.cgColor
      $0.strokeColor = UIColor.clear.cgColor
    }
    
    popover.present(from: borderView, on: self) { [weak popover, weak self] in
      guard let popover = popover,
        let self = self
      else { return }

      // Mask the shadow
      let maskFrame = self.view.convert(frame, to: popover.backgroundOverlayView)
      guard !maskFrame.isNull &&
            !maskFrame.isInfinite &&
            !maskFrame.isEmpty &&
            !popover.backgroundOverlayView.bounds.isNull &&
            !popover.backgroundOverlayView.bounds.isInfinite &&
            !popover.backgroundOverlayView.bounds.isEmpty else {
        return
      }

      guard maskFrame.origin.x.isFinite &&
            maskFrame.origin.y.isFinite &&
            maskFrame.size.width.isFinite &&
            maskFrame.size.height.isFinite &&
            maskFrame.size.width > 0 &&
            maskFrame.size.height > 0 else {
        return
      }
    }
      
    popover.backgroundOverlayView.layer.mask = maskShape
    
    popover.popoverDidDismiss = { _ in
      maskShape.removeFromSuperlayer()
      borderView.removeFromSuperview()
      
      completion()
    }
    
    DispatchQueue.main.async {
      maskShape.path = {
        let path = CGMutablePath()
        path.addRect(popover.backgroundOverlayView.bounds)
        return path
      }()
    }
  }

  func notifyTrackersBlocked(domain: String, trackers: [String: [String]]) {
    let controller = WelcomeBraveBlockedAdsController().then {
      var trackers = trackers
      let first = trackers.popFirst()
      let tracker = first?.key
      let trackerCount =
        ((first?.value.count ?? 0) - 1)
        + trackers.reduce(0, { res, values in
          res + values.value.count
        })

      $0.setData(domain: domain, trackerBlocked: tracker ?? "", trackerCount: trackerCount)
    }

    let popover = PopoverController(contentController: controller)
    popover.present(from: topToolbar.locationView.shieldsButton, on: self)

    let pulseAnimationView = RadialPulsingAnimation(ringCount: 3)
    pulseAnimationView.present(
      icon: topToolbar.locationView.shieldsButton.imageView?.image,
      from: topToolbar.locationView.shieldsButton,
      on: popover,
      browser: self)
    
    pulseAnimationView.animationViewPressed = { [weak self] in
      popover.dismissPopover() {
        self?.presentBraveShieldsViewController()
      }
    }
    
    popover.popoverDidDismiss = { [weak self] _ in
      pulseAnimationView.removeFromSuperview()

      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        guard let self = self else { return }

        if self.shouldShowPlaylistOnboardingThisSession {
          self.showPlaylistOnboarding(tab: self.tabManager.selectedTab)
        }
      }
    }
  }

  /// New Tab Page Education screen should load after onboarding is finished and user is on locale JP
  /// - Returns: A tuple which shows NTP Education is enabled and URL to be loaded
  func showNTPEducation() -> (isEnabled: Bool, url: URL?) {
    guard let url = BraveUX.ntpTutorialPageURL else {
      return (false, nil)
    }

    return (Locale.current.regionCode == "JP", url)
  }

  func completeOnboarding(_ controller: UIViewController) {
    Preferences.General.basicOnboardingCompleted.value = OnboardingState.completed.rawValue
    controller.dismiss(animated: true)
  }
}
