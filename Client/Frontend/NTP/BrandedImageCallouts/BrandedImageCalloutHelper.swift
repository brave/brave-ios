// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit

struct BrandedImageCalloutHelper {
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
    }
}
