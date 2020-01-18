// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared

extension BrandedImageCallout {
    class ClaimRewardsViewController: TranslucentBottomSheet {
        
        private let viewHelper = BrandedImageCallout.CommonViews.self
        
        let mainStackView = UIStackView().then {
            $0.axis = .vertical
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.spacing = 16
        }
        
        let body = UILabel().then {
            let bold: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)]
            let normal: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14, weight: .regular)]

            let t1 = NSMutableAttributedString(string: "Way to go!", attributes: bold)
            let t2 = NSMutableAttributedString(
                string: "You earned 42 BAT last month from viewing privacy-respecting ads.", attributes: normal)
            
            let text = NSMutableAttributedString(attributedString: t1)
            text.append(NSMutableAttributedString(string: " "))
            text.append(t2)
            
            $0.attributedText = text
            $0.appearanceTextColor = .white
            
            $0.numberOfLines = 0
            $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            $0.lineBreakMode = .byWordWrapping
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "confetti").withAlpha(0.75)!)
            
            let headerStackView = viewHelper.rewardsLogoHeader(textColor: .white, textSize: 16).then {
                $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 311), for: .vertical)
            }
            
            let claimRewardsButton = viewHelper.primaryButton(text: "Claim my rewards", showMoneyImage: true)
            let claimRewardsStackView = viewHelper.centeredView(claimRewardsButton)
            
            [headerStackView, body, claimRewardsStackView].forEach(mainStackView.addArrangedSubview(_:))
            view.addSubview(mainStackView)

            mainStackView.snp.remakeConstraints {
                $0.top.equalToSuperview().inset(28)
                $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
                $0.bottom.equalToSuperview().inset(24)
            }
        }
    }
    
}
