// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared

extension BrandedImageCallout {
    class SupportWebCreatorsWithTokensView: TranslucentBottomSheet {
        
        private let viewHelper = BrandedImageCallout.CommonViews.self
        
        let mainStackView = UIStackView().then {
            $0.axis = .vertical
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.spacing = 16
        }
        
        let body = UILabel().then {
            $0.text = "You can support web creators with tokens."
            $0.appearanceTextColor = .white
            
            $0.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            
            $0.numberOfLines = 0
            $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            $0.lineBreakMode = .byWordWrapping
        }
        
        let body2 = UILabel().then {
            $0.text = "Earn tokens by viewing privacy-respecting ads."
            $0.appearanceTextColor = .white
            
            $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            
            $0.numberOfLines = 0
            $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 313), for: .vertical)
            $0.lineBreakMode = .byWordWrapping
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            let headerStackView = viewHelper.rewardsLogoHeader(textColor: .white, textSize: 16).then {
                $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 311), for: .vertical)
            }
            
            let turnOnAdsButton = viewHelper.primaryButton(text: "Turn on Brave Ads", showMoneyImage: true)
            let turnOnAdsStackView = viewHelper.centeredView(turnOnAdsButton)
            
            [headerStackView, body, body2, turnOnAdsStackView].forEach(mainStackView.addArrangedSubview(_:))
            
            mainStackView.setCustomSpacing(0, after: body)
            
            view.addSubview(mainStackView)
            
            mainStackView.snp.remakeConstraints {
                $0.top.equalToSuperview().inset(28)
                $0.left.right.equalToSuperview().inset(16)
                $0.bottom.equalToSuperview().inset(16)
            }
        }
    }
}
