// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared

struct BrandedImageCallout {
    struct CommonViews {
        static func rewardsLogoHeader(textColor: UIColor, textSize: CGFloat) -> UIStackView {
            let headerStackView = UIStackView().then {
                $0.spacing = 10
            }
            
            let imageView = UIImageView(image: #imageLiteral(resourceName: "brave_rewards_button_enabled")).then {
                $0.snp.makeConstraints {
                    $0.size.equalTo(24)
                }
            }
            
            let title = UILabel().then {
                $0.text = "Brave Rewards"
                $0.appearanceTextColor = textColor
                $0.font = UIFont.systemFont(ofSize: textSize, weight: .semibold)
            }
            
            [imageView, title].forEach(headerStackView.addArrangedSubview(_:))
            
            return headerStackView
        }
        
        static func primaryButton(text: String, showMoneyImage: Bool) -> UIStackView {
            let turnOnRewards = RoundInterfaceButton().then {
                $0.setTitle(text, for: .normal)
                $0.appearanceTextColor = .white
                $0.backgroundColor = BraveUX.blurple400
                $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                $0.contentEdgeInsets = UIEdgeInsets(top: 12, left: 25, bottom: 12, right: 25)
                if showMoneyImage {
                    $0.setImage(#imageLiteral(resourceName: "turn_rewards_on_money_icon"), for: .normal)
                    $0.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
                }
            }
            
            let buttonStackView = UIStackView(arrangedSubviews:
                [UIView.spacer(.horizontal, amount: 0),
                 turnOnRewards,
                 UIView.spacer(.horizontal, amount: 0)]).then {
                    $0.distribution = .equalSpacing
            }
            
            buttonStackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
            
            return buttonStackView
        }
        
        static func secondaryButton(text: String, showMoneyImage: Bool) -> UIStackView {
            let turnOnRewards = RoundInterfaceButton().then {
                $0.setTitle(text, for: .normal)
                $0.appearanceTextColor = .black
                $0.backgroundColor = .clear
                $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                $0.contentEdgeInsets = UIEdgeInsets(top: 12, left: 25, bottom: 12, right: 25)
                if showMoneyImage {
                    $0.setImage(#imageLiteral(resourceName: "turn_rewards_on_money_icon"), for: .normal)
                    $0.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
                }
            }
            
            let buttonStackView = UIStackView(arrangedSubviews:
                [UIView.spacer(.horizontal, amount: 0),
                 turnOnRewards,
                 UIView.spacer(.horizontal, amount: 0)]).then {
                    $0.distribution = .equalSpacing
            }
            
            buttonStackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
            
            return buttonStackView
        }
    }
}
