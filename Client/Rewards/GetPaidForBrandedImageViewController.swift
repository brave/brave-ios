// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared

class GetPaidForBrandedImageViewController: UIViewController {
    
    let mainStackView = UIStackView().then {
        $0.axis = .vertical
        //$0.distribution = .fill
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.spacing = 16
    }
    
    override func viewDidLoad() {
        
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
            $0.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
            $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 311), for: .vertical)
        }
        
        [imageView, title].forEach(headerStackView.addArrangedSubview(_:))
        
        
        let body = UILabel().then {
            $0.text = "Get paid to see this background image. Turn on Brave Rewards to claim your share."
            
            $0.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            
            $0.numberOfLines = 0
            $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            $0.lineBreakMode = .byWordWrapping
            
            $0.preferredMaxLayoutWidth = view.frame.width - 32
        }
        
        let tos = UILabel().then {
            $0.text = """
            By turning on Rewards, you agree to the Terms of Service. You can also choose \
            to hide sponsored images.
            """
            
            $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            
            $0.numberOfLines = 0
            $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 313), for: .vertical)
            $0.lineBreakMode = .byWordWrapping
            
            $0.preferredMaxLayoutWidth = view.frame.width - 32
        }
        
        let turnOnRewards = RoundInterfaceButton().then {
            $0.setTitle("Turn on Rewards", for: .normal)
            $0.backgroundColor = BraveUX.blurple400
            $0.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
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
        
        [headerStackView, body, tos, buttonStackView].forEach(mainStackView.addArrangedSubview(_:))
        
        view.addSubview(mainStackView)
        
        mainStackView.snp.remakeConstraints {
            $0.top.equalToSuperview().inset(28)
            $0.left.right.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(48)
        }
    }   
    
}
