// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import BraveRewardsUI

extension BrandedImageCallout {
    class YouAreGettingPaidNonBlockingViewController: TranslucentBottomSheet {
        
        private let viewHelper = BrandedImageCallout.CommonViews.self
        
        let mainStackView = UIStackView().then {
            $0.axis = .vertical
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.spacing = 16
        }
        
        let body = LinkLabel().then {
            $0.font = .systemFont(ofSize: 14.0)
            $0.appearanceTextColor = .white
            $0.linkColor = BraveUX.braveOrange
            $0.text = "You're getting paid to see this background image.\nLearn more"
            $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            $0.setURLInfo(["Learn more": "terms"])
            
            $0.textContainerInset = UIEdgeInsets.zero
            $0.textContainer.lineFragmentPadding = 0
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            let headerStackView = viewHelper.rewardsLogoHeader(textColor: .white, textSize: 20).then {
                $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 311), for: .vertical)
            }
            
            [headerStackView, body].forEach(mainStackView.addArrangedSubview(_:))
            
            view.addSubview(mainStackView)
            
            body.onLinkedTapped = { _ in
                self.learnMoreHandler?()
            }
            
            mainStackView.snp.remakeConstraints {
                $0.top.equalToSuperview().inset(28)
                $0.left.right.equalToSuperview().inset(16)
                $0.bottom.equalToSuperview().inset(24)
            }
        }
    }
}
