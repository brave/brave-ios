// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import BraveUI

class SimpleShieldsView: UIView, Themeable {
    
    let faviconImageView = UIImageView()
    
    let hostLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 25.0)
    }
    
    let shieldsSwitch = ShieldsSwitch()
    
    private let braveShieldsLabel = UILabel().then {
        $0.text = Strings.braveShieldsStatusTitle
        $0.font = .systemFont(ofSize: 16, weight: .medium)
    }
    
    let statusLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.text = Strings.braveShieldsStatusValueUp.uppercased()
    }
    
    // Shields Up
    
    let blockCountStackView = UIStackView().then {
        $0.spacing = 12
        $0.alignment = .center
        $0.layoutMargins = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
        $0.isLayoutMarginsRelativeArrangement = true
    }
    
    let blockCountLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 36)
        $0.text = "0"
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private lazy var blockDescriptionLabel = ViewLabel().then {
        $0.attributedText = {
            let string = NSMutableAttributedString(
                string: Strings.braveShieldsBlockedCountLabel,
                attributes: [.font: UIFont.systemFont(ofSize: 13.0)]
            )
            let attachment = ViewTextAttachment(view: self.blockCountInfoButton)
            string.append(NSAttributedString(attachment: attachment))
            return string
        }()
        $0.backgroundColor = .clear
        $0.setContentCompressionResistancePriority(UILayoutPriority(999), for: .horizontal)
    }
    
    let blockCountInfoButton = Button().then {
        $0.setImage(UIImage(imageLiteralResourceName: "shields-help"), for: .normal)
        $0.hitTestSlop = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        $0.imageEdgeInsets = .zero
        $0.titleEdgeInsets = .zero
        $0.contentEdgeInsets = UIEdgeInsets(top: -2, left: 4, bottom: -3, right: 4)
        $0.accessibilityLabel = Strings.braveShieldsBlockedInfoButtonAccessibilityLabel
    }
    
    let footerLabel = UILabel().then {
        $0.text = Strings.braveShieldsSiteBroken
        $0.font = .systemFont(ofSize: 13.0)
        $0.appearanceTextColor = UIColor(rgb: 0x868e96)
        $0.numberOfLines = 0
    }
    
    // Shields Down
    
    let shieldsDownStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = 16
        $0.layoutMargins = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        $0.isLayoutMarginsRelativeArrangement = true
    }
    
    private let shieldsDownDisclaimerLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13)
        $0.text = Strings.shieldsDownDisclaimer
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    
    let reportSiteButton = ActionButton().then {
        $0.tintColor = Colors.grey800
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.titleEdgeInsets = UIEdgeInsets(top: 4, left: 20, bottom: 4, right: 20)
        $0.setTitle(Strings.reportABrokenSite, for: .normal)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let stackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 16
            $0.alignment = .center
            $0.layoutMargins = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
            $0.isLayoutMarginsRelativeArrangement = true
        }
        
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalTo(self)
        }
        
        [blockCountLabel, blockDescriptionLabel].forEach(blockCountStackView.addArrangedSubview)
        [shieldsDownDisclaimerLabel, reportSiteButton].forEach(shieldsDownStackView.addArrangedSubview)
        
        stackView.addStackViewItems(
            .view(UIStackView(arrangedSubviews: [faviconImageView, hostLabel]).then {
                $0.spacing = 8
                $0.alignment = .center
                $0.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
                $0.isLayoutMarginsRelativeArrangement = true
            }),
//            .customSpace(36),
            .view(shieldsSwitch),
            .view(UIStackView(arrangedSubviews: [braveShieldsLabel, statusLabel]).then {
                $0.spacing = 4
                $0.alignment = .center
            }),
            .customSpace(32),
            .view(blockCountStackView),
            .view(footerLabel),
            .view(shieldsDownStackView)
        )
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    func applyTheme(_ theme: Theme) {
        shieldsSwitch.offBackgroundColor = theme.isDark ?
            UIColor(rgb: 0x26262E) :
            UIColor(white: 0.9, alpha: 1.0)
        blockDescriptionLabel.textColor = theme.isDark ? UIColor.white : .black
        blockCountInfoButton.tintColor = theme.isDark ?
            Colors.orange400 :
            Colors.orange500
    }
}
