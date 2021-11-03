// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SnapKit

class WelcomeViewController: UIViewController {
    private let profile: Profile?
    private let rewards: BraveRewards?
    
    init(profile: Profile?, rewards: BraveRewards?) {
        self.profile = profile
        self.rewards = rewards
        super.init(nibName: nil, bundle: nil)
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
    
    private let searchEnginesView = WelcomeViewSearchEnginesView()
    
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
        $0.isHidden = true
    }
    
    private var searchEngines: SearchEngines? {
        profile?.searchEngines
    }
    
    private lazy var availableEngines: [OpenSearchEngine] = {
        SearchEngines.getUnorderedBundledEngines(isOnboarding: true, locale: .current)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        skipButton.addTarget(self, action: #selector(onSkipButtonPressed(_:)), for: .touchUpInside)
        
        [backgroundImageView, topImageView, bottomImageView, contentContainer, skipButton].forEach {
            view.addSubview($0)
        }
        
        [calloutView, iconView].forEach {
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
            $0.bottom.lessThanOrEqualTo(skipButton.snp.top).inset(30.0)
        }
        
        skipButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(30.0)
        }
        
        bottomImageView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        calloutView.setState(state: .welcome(title: "Welcome to Brave!"), animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.animateToPrivacyState()
        }
    }
    
    private func animateToPrivacyState() {
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
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn) {
            self.topImageView.transform = topTransform
            self.bottomImageView.transform = bottomTransform
            self.skipButton.alpha = 1.0
        } completion: { finished in
             
        }
        
        calloutView.setState(state: .privacy(title: "Privacy, simplified",
                                             details: "You're just a step away from the best privacy online. Ready?",
                                             buttonTitle: "Let's go",
                                             action: {
            self.animateToDefaultBrowserState()
        }), animated: true)
    }
    
    private func animateToDefaultBrowserState() {
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
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn) {
            self.topImageView.transform = topTransform
            self.bottomImageView.transform = bottomTransform
            self.iconView.image = #imageLiteral(resourceName: "welcome-view-phone")
            self.skipButton.alpha = 1.0
        } completion: { finished in
             
        }
        
        contentContainer.spacing = -260.0
        contentContainer.snp.updateConstraints {
            $0.centerY.equalToSuperview().offset(60.0)
        }
        
        calloutView.setState(state: .defaultBrowser(title: "Make Brave your default browser",
                                                    details: "With Brave as default, every link you click opens with Brave's privacy protections.",
                                                    primaryButtonTitle: "Set as default",
                                                    secondaryButtonTitle: "Not now",
                                                    primaryAction: {
            print("Let's go")
        }, secondaryAction: {
            self.animateToReadyState()
        }), animated: true)
    }
    
    private func animateToReadyState() {
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
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn) {
            self.topImageView.transform = topTransform
            self.bottomImageView.transform = bottomTransform
            self.iconView.image = #imageLiteral(resourceName: "welcome-view-ready-icon")
            self.skipButton.alpha = 1.0
        } completion: { finished in
             
        }
        
        contentContainer.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        
        [iconView, calloutView, searchEnginesView].forEach {
            contentContainer.addArrangedSubview($0)
        }
        
        contentContainer.spacing = 0
        contentContainer.snp.updateConstraints {
            $0.centerY.equalToSuperview()
        }
        
        contentContainer.setCustomSpacing(-40.0, after: iconView)
        contentContainer.setCustomSpacing(15.0, after: calloutView)
        
        availableEngines.forEach { engine in
            self.searchEnginesView.addButton(icon: engine.image, title: engine.displayName) { [weak self] in
                self?.onSearchEngineSelected(engine)
            }
        }
        
        searchEnginesView.addButton(icon: UIImage(), title: "Enter a website") {
            
        }
        
        searchEnginesView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(240.0)
        }
        
        calloutView.setState(state: .ready(title: "You're ready to browse!",
                                           details: "Select a popular site below or enter your own...",
                                           moreDetails: "...and watch those trackers & ads disappear."), animated: true)
    }
    
    @objc
    private func onSkipButtonPressed(_ button: UIButton) {
        // Set the default search engine
        onSearchEngineSelected(nil)
        
        
    }
    
    private func onSearchEngineSelected(_ engine: OpenSearchEngine?) {
        if let engine = engine {
            searchEngines?.setInitialDefaultEngine(engine.shortName)
        } else {
            let defaultEngine = searchEngines?.defaultEngine().shortName
            if let engine = availableEngines.first(where: { $0.shortName == defaultEngine }) {
                searchEngines?.setInitialDefaultEngine(engine.shortName)
            }
        }
    }
}
