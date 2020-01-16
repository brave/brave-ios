// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared

class SupportWebCreatorsWithTokensView: UIViewController {
    
    private let viewHelper = BrandedImageCalloutHelper.CommonViews.self
    
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
        let headerStackView = viewHelper.rewardsLogoHeader(textColor: .white, textSize: 16)
        
        headerStackView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 311), for: .vertical)
        
        let turnOnRewards = RoundInterfaceButton().then {
            $0.setTitle("Turn on Brave Ads", for: .normal)
            $0.appearanceTextColor = .white
            $0.backgroundColor = BraveUX.blurple400
            $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            $0.contentEdgeInsets = UIEdgeInsets(top: 12, left: 25, bottom: 12, right: 25)
            $0.setImage(#imageLiteral(resourceName: "turn_rewards_on_money_icon"), for: .normal)
            $0.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        }
        
        let buttonStackView = UIStackView(arrangedSubviews:
            [UIView.spacer(.horizontal, amount: 0),
             turnOnRewards,
             UIView.spacer(.horizontal, amount: 0)]).then {
                $0.distribution = .equalSpacing
        }
        
        buttonStackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        [headerStackView, body, body2, buttonStackView].forEach(mainStackView.addArrangedSubview(_:))
        
        mainStackView.setCustomSpacing(0, after: body)
        
        view.addSubview(mainStackView)
        
        mainStackView.snp.remakeConstraints {
            $0.top.equalToSuperview().inset(28)
            $0.left.right.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
        }
    }
    
    override func viewDidLayoutSubviews() {
        [body, body2].forEach {
            $0.preferredMaxLayoutWidth = view.frame.width - 32
        }
    }
}
