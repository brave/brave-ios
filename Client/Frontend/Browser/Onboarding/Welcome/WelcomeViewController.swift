// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SnapKit
import BraveShared
import pop

private enum WelcomeViewID: Int {
    case background = 1
    case topImage = 2
    case contents = 3
    case callout = 4
    case iconView = 5
    case searchView = 6
    case bottomImage = 7
    case skipButton = 8
}

class WelcomeViewController: UIViewController {
    private let profile: Profile?
    private let rewards: BraveRewards?
    private var state: WelcomeViewCalloutState?
    
    var onAdsWebsiteSelected: ((URL?) -> Void)?
    
    convenience init(profile: Profile?, rewards: BraveRewards?) {
        self.init(profile: profile,
                  rewards: rewards,
                  state: .welcome(title: "Welcome to Brave!"))
    }
    
    init(profile: Profile?, rewards: BraveRewards?, state: WelcomeViewCalloutState?) {
        self.profile = profile
        self.rewards = rewards
        self.state = state
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
        self.modalPresentationStyle = .fullScreen
        self.loadViewIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let backgroundImageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "welcome-view-background")
        $0.contentMode = .scaleAspectFill
    }
    
    private let topImageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "welcome-view-top-image")
        $0.contentMode = .scaleAspectFill
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private let contentContainer = UIStackView().then {
        $0.axis = .vertical
        $0.distribution = .fillProportionally
        $0.spacing = -95.0
        $0.layoutMargins = UIEdgeInsets(top: 0.0, left: 22.0, bottom: 0.0, right: 22.0)
        $0.isLayoutMarginsRelativeArrangement = true
    }
    
    private let calloutView = WelcomeViewCallout(pointsUp: false)
    
    private let iconView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "welcome-view-icon")
        $0.contentMode = .scaleAspectFit
    }
    
    private let searchView = WelcomeViewSearchView().then {
        $0.isHidden = true
    }
    
    private let bottomImageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "welcome-view-bottom-image")
        $0.contentMode = .scaleAspectFill
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private let skipButton = UIButton(type: .custom).then {
        $0.setTitle("Skip", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.alpha = 0.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doLayout()
        
        if let state = state {
            setLayoutState(state: state)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Preferences.General.basicOnboardingCompleted.value = OnboardingState.completed.rawValue
        
        if case .welcome = self.state {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.animateToPrivacyState()
            }
        }
    }
    
    private func doLayout() {
        backgroundImageView.tag = WelcomeViewID.background.rawValue
        topImageView.tag = WelcomeViewID.topImage.rawValue
        contentContainer.tag = WelcomeViewID.contents.rawValue
        calloutView.tag = WelcomeViewID.callout.rawValue
        iconView.tag = WelcomeViewID.iconView.rawValue
        searchView.tag = WelcomeViewID.searchView.rawValue
        bottomImageView.tag = WelcomeViewID.bottomImage.rawValue
        skipButton.tag = WelcomeViewID.skipButton.rawValue
        
        skipButton.addTarget(self, action: #selector(onSkipButtonPressed(_:)), for: .touchUpInside)
        
        [backgroundImageView, topImageView, bottomImageView, contentContainer, skipButton].forEach {
            view.addSubview($0)
        }
        
        [calloutView, iconView, searchView].forEach {
            contentContainer.addArrangedSubview($0)
        }
        
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        topImageView.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
        }
        
        contentContainer.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview()
            $0.bottom.lessThanOrEqualTo(skipButton.snp.top).offset(-30.0)
        }
        
        skipButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(30.0)
            $0.height.equalTo(48.0)
        }
        
        bottomImageView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setLayoutState(state: WelcomeViewCalloutState) {
        self.state = state
        
        switch state {
        case .welcome:
            topImageView.transform = .identity
            bottomImageView.transform = .identity
            iconView.transform = .identity
            contentContainer.spacing = -95.0
            contentContainer.snp.updateConstraints {
                $0.centerY.equalToSuperview()
                $0.bottom.lessThanOrEqualTo(skipButton.snp.top).offset(-30.0)
            }
            calloutView.setState(state: state)
            
        case .privacy:
            let topTransform = { () -> CGAffineTransform in
                var transformation = CGAffineTransform.identity
                transformation = transformation.scaledBy(x: 1.3, y: 1.3)
                transformation = transformation.translatedBy(x: 0.0, y: -50.0)
                return transformation
            }()
            
            let bottomTransform = { () -> CGAffineTransform in
                var transformation = CGAffineTransform.identity
                transformation = transformation.scaledBy(x: 1.5, y: 1.5)
                transformation = transformation.translatedBy(x: 0.0, y: 30.0)
                return transformation
            }()
            
            topImageView.transform = topTransform
            bottomImageView.transform = bottomTransform
            skipButton.alpha = 1.0
            calloutView.setState(state: state)
            
        case .defaultBrowser:
            let topTransform = { () -> CGAffineTransform in
                var transformation = CGAffineTransform.identity
                transformation = transformation.scaledBy(x: 1.5, y: 1.5)
                transformation = transformation.translatedBy(x: 0.0, y: -70.0)
                return transformation
            }()
            
            let bottomTransform = { () -> CGAffineTransform in
                var transformation = CGAffineTransform.identity
                transformation = transformation.scaledBy(x: 2.0, y: 2.0)
                transformation = transformation.translatedBy(x: 0.0, y: 40.0)
                return transformation
            }()
                
            let imageViewTransform = { () -> CGAffineTransform in
                var transformation = CGAffineTransform.identity
                transformation = transformation.translatedBy(x: 0.0, y: 50.0)
                return transformation
            }()
            
            topImageView.transform = topTransform
            bottomImageView.transform = bottomTransform
            iconView.do {
                $0.image = #imageLiteral(resourceName: "welcome-view-phone")
                $0.transform = imageViewTransform
            }
            skipButton.alpha = 1.0
            contentContainer.spacing = -260.0
            contentContainer.snp.updateConstraints {
                $0.centerY.equalToSuperview().offset(60.0)
                $0.bottom.lessThanOrEqualTo(skipButton.snp.top).inset(30.0)
            }
            calloutView.setState(state: state)
            
        case .defaultBrowserWarning:
            let topTransform = { () -> CGAffineTransform in
                var transformation = CGAffineTransform.identity
                transformation = transformation.scaledBy(x: 1.5, y: 1.5)
                transformation = transformation.translatedBy(x: 0.0, y: -70.0)
                return transformation
            }()

            let bottomTransform = { () -> CGAffineTransform in
                var transformation = CGAffineTransform.identity
                transformation = transformation.scaledBy(x: 2.0, y: 2.0)
                transformation = transformation.translatedBy(x: 0.0, y: 40.0)
                return transformation
            }()

            let imageViewTransform = { () -> CGAffineTransform in
                var transformation = CGAffineTransform.identity
                transformation = transformation.translatedBy(x: 0.0, y: 40.0)
                return transformation
            }()

            topImageView.transform = topTransform
            bottomImageView.transform = bottomTransform
            iconView.do {
                $0.image = #imageLiteral(resourceName: "welcome-view-phone")
                $0.transform = imageViewTransform
            }
            contentContainer.spacing = -260.0
            contentContainer.snp.updateConstraints {
                $0.centerY.equalToSuperview().offset(60.0)
                $0.bottom.lessThanOrEqualTo(skipButton.snp.top).inset(30.0)
            }
            calloutView.setState(state: state)
            
        case .ready:
            let topTransform = { () -> CGAffineTransform in
                var transformation = CGAffineTransform.identity
                transformation = transformation.scaledBy(x: 2.0, y: 2.0)
                transformation = transformation.translatedBy(x: 0.0, y: -70.0)
                return transformation
            }()
            
            let bottomTransform = { () -> CGAffineTransform in
                var transformation = CGAffineTransform.identity
                transformation = transformation.scaledBy(x: 2.0, y: 2.0)
                transformation = transformation.translatedBy(x: 0.0, y: 40.0)
                return transformation
            }()
            
            let imageViewTransform = { () -> CGAffineTransform in
                var transformation = CGAffineTransform.identity
                transformation = transformation.scaledBy(x: 0.75, y: 0.75)
                transformation = transformation.translatedBy(x: 0.0, y: 95.0)
                return transformation
            }()
                
            let contentViewTransform = { () -> CGAffineTransform in
                var transformation = CGAffineTransform.identity
                transformation = transformation.translatedBy(x: 0.0, y: -145.0)
                return transformation
            }()
            
            topImageView.transform = topTransform
            bottomImageView.transform = bottomTransform
            iconView.do {
                $0.image = #imageLiteral(resourceName: "welcome-view-ready-icon")
                $0.transform = imageViewTransform
            }
                
            skipButton.snp.makeConstraints {
                $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(30.0)
            }
            skipButton.alpha = 1.0
            
            contentContainer.arrangedSubviews.forEach {
                $0.removeFromSuperview()
            }
            
            [iconView, calloutView, searchView].forEach {
                self.contentContainer.addArrangedSubview($0)
                $0.isHidden = false
            }
            
            contentContainer.do {
                $0.spacing = 0.0
                $0.transform = contentViewTransform
            }
                
            contentContainer.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.bottom.greaterThanOrEqualTo(skipButton.snp.top).offset(200.0)
            }
            
            websitesForRegion().forEach { item in
                self.searchView.addButton(icon: item.icon, title: item.title) { [unowned self] in
                    self.onWebsiteSelected(item)
                }
            }
            
            searchView.addButton(icon: #imageLiteral(resourceName: "welcome-view-search-view-generic"), title: "Enter a website") { [unowned self] in
                self.onEnterCustomWebsite()
            }
            
            searchView.snp.makeConstraints {
                $0.height.greaterThanOrEqualTo(240.0)
            }
            calloutView.setState(state: state)
        }
    }
    
    private func animateToPrivacyState() {
        let nextController = WelcomeViewController(profile: profile,
                                                   rewards: rewards,
                                                   state: nil)
        nextController.onAdsWebsiteSelected = onAdsWebsiteSelected
        let state = WelcomeViewCalloutState.privacy(title: "Privacy, simplified",
                             details: "You're just a step away from the best privacy online. Ready?",
                             buttonTitle: "Let's go",
                             action: {
                                nextController.animateToDefaultBrowserState()
                             }
        )
        nextController.setLayoutState(state: state)
        self.present(nextController, animated: true, completion: nil)
    }
    
    private func animateToDefaultBrowserState() {
        let nextController = WelcomeViewController(profile: profile,
                                                   rewards: rewards)
        nextController.onAdsWebsiteSelected = onAdsWebsiteSelected
        let state = WelcomeViewCalloutState.defaultBrowser(title: "Make Brave your default browser",
                                    details: "With Brave as default, every link you click opens with Brave's privacy protections.",
                                    primaryButtonTitle: "Set as default",
                                    secondaryButtonTitle: "Not now",
                                    primaryAction: {
                                        nextController.onSetDefaultBrowser()
                                    }, secondaryAction: {
                                        nextController.animateToReadyState()
                                    }
        )
        nextController.setLayoutState(state: state)
        self.present(nextController, animated: true, completion: nil)
    }
    
    private func animateToReadyState() {
        let nextController = WelcomeViewController(profile: profile,
                                                   rewards: rewards)
        nextController.onAdsWebsiteSelected = onAdsWebsiteSelected
        let state = WelcomeViewCalloutState.ready(title: "You're ready to browse!",
                                      details: "Select a popular site below or enter your own...",
                                      moreDetails: "...and watch those trackers & ads disappear.")
        nextController.setLayoutState(state: state)
        self.present(nextController, animated: true, completion: nil)
    }
    
    @objc
    private func onSkipButtonPressed(_ button: UIButton) {
        close()
    }
    
    private func onWebsiteSelected(_ item: WebsiteRegion) {
        close()
        if let url = URL(string: item.domain) {
            self.onAdsWebsiteSelected?(url)
        }
    }
    
    private func onEnterCustomWebsite() {
        close()
        self.onAdsWebsiteSelected?(nil)
    }
    
    private func onSetDefaultBrowser() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
        animateToReadyState()
    }
    
    private func close() {
        var presenting: UIViewController = self
        while true {
            if let presentingController = presenting.presentingViewController {
                presenting = presentingController
                if presenting.isKind(of: BrowserViewController.self) {
                    break
                }
                continue
            }
            
            if let presentingController = presenting as? UINavigationController,
               let topController = presentingController.topViewController {
                presenting = topController
                if presenting.isKind(of: BrowserViewController.self) {
                    break
                }
            }
            
            break
        }
        presenting.dismiss(animated: true, completion: nil)
    }
    
    private struct WebsiteRegion {
        let icon: UIImage
        let title: String
        let domain: String
    }
    
    private func websitesForRegion() -> [WebsiteRegion] {
        var siteList = [WebsiteRegion]()
        
        switch Locale.current.regionCode {
            // Canada
        case "CA":
            siteList = [
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-yahoo"), title: "Yahoo", domain: "https://yahoo.com/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-environment-canada"), title: "Environment Canada", domain: "https://weather.gc.ca/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-cdn-tire"), title: "Canadian Tire", domain: "https://canadiantire.ca/")
            ]
            
            // United Kingdom
        case "GB":
            siteList = [
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-bbc"), title: "BBC", domain: "https://bbc.co.uk/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-sky"), title: "Sky", domain: "https://sky.com/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-wired"), title: "Wired", domain: "https://wired.com/")
            ]
            
            // Germany
        case "DE":
            siteList = [
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-yahoo"), title: "Yahoo", domain: "https://yahoo.com/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-gmx"), title: "GMX", domain: "https://gmx.net/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-mobilede"), title: "Mobile", domain: "https://mobile.de/")
            ]
            
            // France
        case "FR":
            siteList = [
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-yahoo"), title: "Yahoo", domain: "https://yahoo.com/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-jdf"), title: "Les Journal des Femmes", domain: "https://journaldesfemmes.fr/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-programme-tv"), title: "Programme TV", domain: "https://programme-tv.net/")
            ]
            
            // India
        case "IN":
            siteList = [
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-hotstar"), title: "Hot Star", domain: "https://hotstar.com/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-cricketbuzz"), title: "Cricket Buzz", domain: "https://cricbuzz.com/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-flipkart"), title: "Flipkart", domain: "https://flipkart.com/")
            ]
            
            // Australia
        case "AU":
            siteList = [
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-news-au"), title: "News", domain: "https://news.com.au/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-gumtree"), title: "Gumtree", domain: "https://gumtree.com.au/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-realestate-au"), title: "Real Estate", domain: "https://realestate.com.au/")
            ]
            
            // Ireland
        case "IE":
            siteList = [
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-rte"), title: "RTÉ", domain: "https://rte.ie/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-independent"), title: "Independent", domain: "https://independent.ie/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-donedeal"), title: "DoneDeal", domain: "https://donedeal.ie/")
            ]
            
            // Japan
        case "JP":
            siteList = [
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-yahoo"), title: "Yahoo", domain: "https://m.yahoo.co.jp/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-wired"), title: "Wired", domain: "https://wired.jp/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-number-bunshin"), title: "Number Web", domain: "https://number.bunshun.jp/")
            ]
            
            // United States
        case "US":
            siteList = [
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-yahoo"), title: "Yahoo", domain: "https://yahoo.com/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-wired"), title: "Wired", domain: "https://wired.com/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-espn"), title: "ESPN", domain: "https://espn.com/")
            ]
            
        default:
            siteList = [
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-yahoo"), title: "Yahoo", domain: "https://yahoo.com/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-wired"), title: "Wired", domain: "https://wired.com/"),
                WebsiteRegion(icon: #imageLiteral(resourceName: "welcome-view-search-view-espn"), title: "ESPN", domain: "https://espn.com/")
            ]
        }
        return siteList
    }
}

extension WelcomeViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return WelcomeAnimator(isPresenting: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return WelcomeAnimator(isPresenting: false)
    }
}

// Disabling orientation changes
extension WelcomeViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
}

private class WelcomeAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    
    private struct WelcomeViewInfo {
        let backgroundImageView: UIView
        let topImageView: UIView
        let contentContainer: UIView
        let calloutView: UIView
        let iconView: UIView
        let searchEnginesView: UIView
        let bottomImageView: UIView
        let skipButton: UIView
        
        var allViews: [UIView] {
            return [
                backgroundImageView,
                topImageView,
                contentContainer,
                calloutView,
                iconView,
                searchEnginesView,
                bottomImageView,
                skipButton
            ]
        }
        
        init?(view: UIView) {
            guard let backgroundImageView = view.subview(with: WelcomeViewID.background.rawValue),
                  let topImageView = view.subview(with: WelcomeViewID.topImage.rawValue),
                  let contentContainer = view.subview(with: WelcomeViewID.contents.rawValue),
                  let calloutView = view.subview(with: WelcomeViewID.callout.rawValue),
                  let iconView = view.subview(with: WelcomeViewID.iconView.rawValue),
                  let searchEnginesView = view.subview(with: WelcomeViewID.searchView.rawValue),
                  let bottomImageView = view.subview(with: WelcomeViewID.bottomImage.rawValue),
                  let skipButton = view.subview(with: WelcomeViewID.skipButton.rawValue) else {
                return nil
            }
            
            self.backgroundImageView = backgroundImageView
            self.topImageView = topImageView
            self.contentContainer = contentContainer
            self.calloutView = calloutView
            self.iconView = iconView
            self.searchEnginesView = searchEnginesView
            self.bottomImageView = bottomImageView
            self.skipButton = skipButton
        }
    }
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        
        guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        
        guard let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        
        // Get animatable views
        guard let fromWelcomeView = WelcomeViewInfo(view: fromView),
              let toWelcomeView = WelcomeViewInfo(view: toView) else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        
        // Setup
        fromView.frame = container.bounds
        toView.frame = container.bounds
        container.addSubview(toView)
        fromView.setNeedsLayout()
        fromView.layoutIfNeeded()
        toView.setNeedsLayout()
        toView.layoutIfNeeded()

        // Setup animation
        let totalAnimationTime = self.transitionDuration(using: transitionContext)
        let fromViews = fromWelcomeView.allViews
        let toViews = toWelcomeView.allViews
        
        toWelcomeView.contentContainer.setNeedsLayout()
        toWelcomeView.contentContainer.layoutIfNeeded()
        
        // Do animations
        for e in fromViews.enumerated() {
            let fromView = e.element
            let toView = toViews[e.offset].then {
                $0.alpha = 0.0
            }
            
            if fromView == fromWelcomeView.backgroundImageView {
                continue
            }
            
            if fromView == fromWelcomeView.topImageView ||
                fromView == fromWelcomeView.bottomImageView {
                UIView.animate(withDuration: totalAnimationTime, delay: 0.0, options: .curveEaseInOut) {
                    fromView.transform = toView.transform
                } completion: { finished in
                    
                }
            } else {
                POPBasicAnimation(propertyNamed: kPOPViewFrame)?.do {
                    $0.fromValue = fromView.frame
                    $0.toValue = toView.frame
                    $0.duration = totalAnimationTime
                    $0.beginTime = CACurrentMediaTime()
                    fromView.layer.pop_add($0, forKey: "frame")
                }
                
                UIView.animate(withDuration: totalAnimationTime,
                               delay: 0.0,
                               options: [.curveEaseInOut]) {
                    fromView.alpha = 0.0
                    toView.alpha = 1.0
                } completion: { finished in
                    
                }
            }
        }
        
        if let fromCallout = fromWelcomeView.calloutView as? WelcomeViewCallout,
           let toCallout = toWelcomeView.calloutView as? WelcomeViewCallout {
            fromCallout.animateFromCopy(view: toCallout, duration: totalAnimationTime, delay: 0.0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + totalAnimationTime) {
            for view in toViews {
                view.alpha = 1.0
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
}

private extension UIView {
    func subview(with tag: Int) -> UIView? {
        if self.tag == tag {
            return self
        }
        
        for view in self.subviews {
            if view.tag == tag {
                return view
            }
            
            if let view = view.subview(with: tag) {
                return view
            }
        }
        return nil
    }
}
