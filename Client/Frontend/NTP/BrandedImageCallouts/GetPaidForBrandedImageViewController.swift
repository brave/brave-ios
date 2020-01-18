// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import BraveRewardsUI

extension BrandedImageCallout {
    class GetPaidForBrandedImageViewController: BottomSheetViewController {
        
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
            $0.setURLInfo(["hide sponsored images": "hide-sponsored-images"])
            
            $0.textContainerInset = UIEdgeInsets.zero
            $0.textContainer.lineFragmentPadding = 0
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            let headerStackView = viewHelper.rewardsLogoHeader(textColor: .black, textSize: 20).then {
                $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 311), for: .vertical)
            }
            
            let turnOnAdsButton = viewHelper.primaryButton(text: "Turn on Brave Ads", showMoneyImage: true)
            let turnOnAdsStackView = viewHelper.centeredView(turnOnAdsButton)
            
            turnOnAdsButton.addTarget(self, action: #selector(turnAdsOnTapped), for: .touchDown)
            
            [headerStackView, body, tos, turnOnAdsStackView].forEach(mainStackView.addArrangedSubview(_:))
            
            tos.onLinkedTapped = { action in
                if action.absoluteString == "hide-sponsored-images" {
                    Preferences.NewTabPage.backgroundSponsoredImages.value = false
                    self.close()
                }
            }
            
            contentView.addSubview(mainStackView)
            
            mainStackView.snp.remakeConstraints {
                $0.top.equalToSuperview().inset(28)
                $0.left.right.equalToSuperview().inset(16)
                $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(28)
            }
        }
        
        @objc func turnAdsOnTapped() {
            guard let rewards = (UIApplication.shared.delegate as? AppDelegate)?
                .browserViewController.rewards else { return }
            
            rewards.ads.isEnabled = true
            close()
        }
    }
}
