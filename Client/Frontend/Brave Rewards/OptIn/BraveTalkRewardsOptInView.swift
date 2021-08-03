// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveUI
import Shared
import BraveShared

extension BraveTalkRewardsOptInViewController {
    class View: UIView {
        
        let enableRewardsButton = ActionButton().then {
            $0.layer.borderWidth = 0
            $0.titleLabel?.font = .systemFont(ofSize: 16.0, weight: .semibold)
            $0.setTitleColor(.white, for: .normal)
            $0.setTitle(Strings.Rewards.braveTalkRewardsOptInButtonTitle, for: .normal)
            $0.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
            $0.backgroundColor = .braveLighterBlurple
        }
        
        private let image = UIImageView(image: #imageLiteral(resourceName: "rewards_onboarding_cashback")).then {
            $0.contentMode = .scaleAspectFit
            
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOpacity = 0.25
            $0.layer.shadowOffset = CGSize(width: 0, height: 1)
            $0.layer.shadowRadius = 4
        }
        
        private let title = UILabel().then {
            $0.text = Strings.Rewards.braveTalkRewardsOptInTitle
            $0.font = .systemFont(ofSize: 20)
            $0.textColor = .bravePrimary
            $0.numberOfLines = 0
            $0.textAlignment = .center
        }
        
        private let body = UILabel().then {
            $0.text = Strings.Rewards.braveTalkRewardsOptInBody
            $0.font = .systemFont(ofSize: 17)
            $0.textColor = .braveLabel
            $0.numberOfLines = 0
            $0.textAlignment = .center
        }
        
        let disclaimer = LinkLabel().then {
            $0.text = String(format: Strings.Rewards.braveTalkRewardsOptInDisclaimer,
                             Strings.OBRewardsAgreementDetailLink,
                             Strings.privacyPolicy)
            $0.font = .systemFont(ofSize: 12)
            $0.textColor = .braveLabel
            $0.textAlignment = .center
            $0.setURLInfo([Strings.OBRewardsAgreementDetailLink: "tos",
                           Strings.privacyPolicy: "privacy-policy"])
        }
        
        private let optinBackground = UIImageView(image: #imageLiteral(resourceName: "optin_bg")).then {
            $0.contentMode = .scaleAspectFit
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = .braveBackground
            
            let stackView = UIStackView().then {
                $0.axis = .vertical
                $0.spacing = 12
                $0.addStackViewItems(.view(image),
                                     .view(title),
                                     .view(body),
                                     .view(enableRewardsButton),
                                     .view(disclaimer))
            }
            
            addSubview(stackView)
            
            stackView.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview().inset(32)
                $0.top.equalToSuperview().inset(44)
                $0.bottom.equalToSuperview().inset(24)
                $0.width.lessThanOrEqualTo(PopoverController.preferredPopoverWidth)
            }
            
            insertSubview(optinBackground, belowSubview: stackView)
            optinBackground.snp.makeConstraints {
                $0.left.top.equalToSuperview().inset(10)
            }
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError()
        }
    }
}
