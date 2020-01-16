// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import BraveRewardsUI

extension BrandedImageCallout {
    class GetPaidForBrandedImageViewController: UIViewController {
        
        private let viewHelper = BrandedImageCallout.CommonViews.self
        
        let mainStackView = UIStackView().then {
            $0.axis = .vertical
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.spacing = 16
        }
        
        let body = UILabel().then {
            $0.text = "Get paid to see this background image. Turn on Brave Rewards to claim your share."
            $0.appearanceTextColor = .black
            
            $0.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            
            $0.numberOfLines = 0
            $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            $0.lineBreakMode = .byWordWrapping
        }
        
        let tos = LinkLabel().then {
            $0.font = .systemFont(ofSize: 12.0)
            $0.appearanceTextColor = .black
            $0.linkColor = BraveUX.braveOrange
            $0.text = "You can also choose to hide sponsored images."
            
            $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 313), for: .vertical)
            $0.setURLInfo(["hide sponsored images": "terms"])
            
            $0.textContainerInset = UIEdgeInsets.zero
            $0.textContainer.lineFragmentPadding = 0
        }
        
        override func viewDidLoad() {
            
            let headerStackView = viewHelper.rewardsLogoHeader(textColor: .black, textSize: 20).then {
                $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 311), for: .vertical)
            }
            
            let buttonStackView = viewHelper.primaryButton(text: "Turn on Rewards", showMoneyImage: true)
            
            [headerStackView, body, tos, buttonStackView].forEach(mainStackView.addArrangedSubview(_:))
            
            view.addSubview(mainStackView)
            
            mainStackView.snp.remakeConstraints {
                $0.top.equalToSuperview().inset(28)
                $0.left.right.equalToSuperview().inset(16)
                $0.bottom.equalToSuperview().inset(48)
            }
            
            let width = min(view.frame.width - 32, 400)
            let size = tos.sizeThatFits(CGSize(width: width, height: CGFloat.infinity))
            
            tos.snp.remakeConstraints {
                $0.height.equalTo(size.height)
            }
        }
        
        override func viewDidLayoutSubviews() {
            [body].forEach {
                $0.preferredMaxLayoutWidth = view.frame.width - 32
            }
        }
    }
}
