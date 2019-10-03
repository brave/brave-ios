// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import BraveRewards
import Lottie

extension OnboardingRewardsViewController {
    
    private struct UX {
        /// A negative spacing is needed to make rounded corners for details view visible.
        static let negativeSpacing: CGFloat = -16
        static let descriptionContentInset: CGFloat = 32
        static let animationContentInset: CGFloat = 50.0
    }
    
    class View: UIView {
        
        let joinButton = CommonViews.primaryButton(text: Strings.OBJoinButton).then {
            $0.accessibilityIdentifier = "OnboardingRewardsViewController.JoinButton"
        }
        
        let skipButton = CommonViews.secondaryButton().then {
            $0.accessibilityIdentifier = "OnboardingRewardsViewController.SkipButton"
        }
        
        private let mainStackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = UX.negativeSpacing
        }
        
        let imageView = AnimationView(name: "onboarding-rewards").then {
            $0.contentMode = .scaleAspectFit
            $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            $0.backgroundBehavior = .pauseAndRestore
            $0.loopMode = .loop
            $0.play()
        }
        
        private let descriptionView = UIView().then {
            $0.layer.cornerRadius = 12
            $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        
        private let descriptionStackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 32
        }
        
        private let titleLabel = CommonViews.primaryText(Strings.OBRewardsTitle)
        
        private let descriptionLabel = CommonViews.secondaryText("").then {
            $0.attributedText = BraveAds.isSupportedRegion(Locale.current.identifier) ?  Strings.OBRewardsDetailInAdRegion.boldWords(with: $0.font, amount: 2) : Strings.OBRewardsDetailOutsideAdRegion.boldWords(with: $0.font, amount: 1)
        }
        
        private lazy var textStackView = UIStackView().then { stackView in
            stackView.axis = .vertical
            stackView.spacing = 8
            
            [titleLabel, descriptionLabel].forEach {
                stackView.addArrangedSubview($0)
            }
        }
        
        private let buttonsStackView = UIStackView().then {
            $0.distribution = .equalCentering
        }
        
        init(theme: Theme) {
            super.init(frame: .zero)
            
            applyTheme(theme)
            mainStackView.tag = OnboardingViewAnimationID.details.rawValue
            descriptionStackView.tag = OnboardingViewAnimationID.detailsContent.rawValue
            imageView.tag = OnboardingViewAnimationID.background.rawValue
            
            addSubview(imageView)
            addSubview(mainStackView)
            mainStackView.snp.makeConstraints {
                $0.leading.equalTo(self.safeArea.leading)
                $0.trailing.equalTo(self.safeArea.trailing)
                $0.bottom.equalTo(self.safeArea.bottom)
            }
            
            descriptionView.addSubview(descriptionStackView)
            descriptionStackView.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(UX.descriptionContentInset)
            }
            
            mainStackView.addArrangedSubview(descriptionView)

            [skipButton, joinButton, UIView.spacer(.horizontal, amount: 0)]
                .forEach(buttonsStackView.addArrangedSubview(_:))
            
            [textStackView, buttonsStackView].forEach(descriptionStackView.addArrangedSubview(_:))
        }
        
        func updateDetailsText(_ text: String, boldWords: Int) {
            self.descriptionLabel.attributedText = text.boldWords(with: self.descriptionLabel.font, amount: boldWords)
        }
        
        func applyTheme(_ theme: Theme) {
            descriptionView.backgroundColor = OnboardingViewController.colorForTheme(theme)
            titleLabel.appearanceTextColor = theme.colors.tints.home
            descriptionLabel.appearanceTextColor = theme.colors.tints.home
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let size = imageView.intrinsicContentSize
            let scaleFactor = bounds.width / size.width
            let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
            
            imageView.frame = CGRect(x: 0.0, y: UX.animationContentInset, width: newSize.width, height: newSize.height)
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) { fatalError() }
    }
}

private extension String {
    func boldWords(with font: UIFont, amount: Int) -> NSMutableAttributedString {
        let mutableDescriptionText = NSMutableAttributedString(string: self)
        
        let components = self.components(separatedBy: " ")
        for i in 0..<min(amount, components.count) {
            if let range = self.range(of: components[i]) {
                let nsRange = NSRange(range, in: self)
                let font = UIFont.systemFont(ofSize: font.pointSize, weight: UIFont.Weight.bold)
                
                mutableDescriptionText.addAttribute(NSAttributedString.Key.font, value: font, range: nsRange)
            }
        }
        
        return mutableDescriptionText
    }
}
