// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import BraveUI

class SimpleShieldsView: UIView, Themeable {
    
    let faviconImageView = UIImageView().then {
        $0.snp.makeConstraints {
            $0.size.equalTo(24)
        }
        $0.layer.cornerRadius = 4
        if #available(iOS 13.0, *) {
            $0.layer.cornerCurve = .continuous
        }
        $0.clipsToBounds = true
    }
    
    let hostLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 25.0)
    }
    
    let shieldsSwitch = ShieldsSwitch()
    
    private let braveShieldsLabel = UILabel().then {
        $0.text = Strings.Shields.statusTitle
        $0.font = .systemFont(ofSize: 16, weight: .medium)
    }
    
    let statusLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.text = Strings.Shields.statusValueUp.uppercased()
    }
    
    // Shields Up
    
    class BlockCountView: UIView, Themeable {
        let contentStackView = UIStackView().then {
            $0.spacing = 2
            $0.alignment = .center
        }
        
        let descriptionStackView = UIStackView().then {
            $0.spacing = 24
            $0.alignment = .center
            $0.layoutMargins = UIEdgeInsets(top: 13, left: 22, bottom: 14, right: 22)
            $0.isLayoutMarginsRelativeArrangement = true
        }
        
        let infoStackView = UIStackView().then {
            $0.alignment = .center
            $0.layoutMargins = UIEdgeInsets(top: 22, left: 14, bottom: 22, right: 14)
            $0.isLayoutMarginsRelativeArrangement = true
        }
        
        let shareStackView = UIStackView().then {
            $0.alignment = .center
            $0.layoutMargins = UIEdgeInsets(top: 22, left: 14, bottom: 22, right: 14)
            $0.isLayoutMarginsRelativeArrangement = true
        }
        
        let countLabel = UILabel().then {
            $0.font = .systemFont(ofSize: 36)
            $0.text = "0"
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        private lazy var descriptionLabel = ViewLabel().then {
            $0.attributedText = {
                let string = NSMutableAttributedString(
                    string: Strings.Shields.blockedCountLabel,
                    attributes: [.font: UIFont.systemFont(ofSize: 13.0)]
                )
                //let attachment = ViewTextAttachment(view: self.infoButton)
                //string.append(NSAttributedString(attachment: attachment))
                return string
            }()
            $0.backgroundColor = .clear
            $0.setContentCompressionResistancePriority(UILayoutPriority(999), for: .horizontal)
        }
        
        let infoButton = Button().then {
            $0.setImage(#imageLiteral(resourceName: "shields-help"), for: .normal)
            $0.hitTestSlop = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
            $0.imageEdgeInsets = .zero
            $0.titleEdgeInsets = .zero
            $0.contentEdgeInsets = UIEdgeInsets(top: -2, left: 4, bottom: -3, right: 4)
            $0.contentMode = .scaleAspectFit
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        let shareButton = Button().then {
            $0.setImage(#imageLiteral(resourceName: "shields-share"), for: .normal)
            $0.hitTestSlop = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
            $0.imageEdgeInsets = .zero
            $0.titleEdgeInsets = .zero
            $0.contentEdgeInsets = UIEdgeInsets(top: -2, left: 4, bottom: -3, right: 4)
            $0.contentMode = .scaleAspectFit
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
//            isAccessibilityElement = true
//            accessibilityTraits.insert(.button)
//            accessibilityHint = Strings.Shields.blockedInfoButtonAccessibilityLabel
            
//            addSubview(descriptionStackView)
//            descriptionStackView.addArrangedSubview(countLabel)
//            descriptionStackView.addArrangedSubview(descriptionLabel)
//            descriptionStackView.snp.makeConstraints {
//                $0.edges.equalToSuperview()
//            }
            
            addSubview(contentStackView)
            contentStackView.addArrangedSubview(descriptionStackView)
            contentStackView.addArrangedSubview(infoStackView)
            contentStackView.addArrangedSubview(shareStackView)
            
            descriptionStackView.addArrangedSubview(countLabel)
            descriptionStackView.addArrangedSubview(descriptionLabel)
            
            infoStackView.addArrangedSubview(infoButton)
            
            shareStackView.addArrangedSubview(shareButton)
            
            contentStackView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
        
        override var accessibilityLabel: String? {
            get {
                [countLabel.accessibilityLabel, Strings.Shields.blockedCountLabel]
                    .compactMap { $0 }
                    .joined(separator: " ")
            }
            set { assertionFailure() } // swiftlint:disable:this unused_setter_value
        }
        
//        override func accessibilityActivate() -> Bool {
//            infoButton.sendActions(for: .touchUpInside)
//            return true
//        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError()
        }
        
        func applyTheme(_ theme: Theme) {
            backgroundColor = theme.isDark ? UIColor(rgb: 0x303443) : Colors.neutral000
            countLabel.textColor = theme.isDark ? .white : .black
            descriptionLabel.textColor = theme.isDark ? UIColor.white : .black
//            infoButton.tintColor = theme.isDark ?
//                Colors.orange400 :
//                Colors.orange500
        }
    }
    
    let blockCountView = BlockCountView().then {
        $0.layer.cornerRadius = 6.0
    }
    
    let footerLabel = UILabel().then {
        $0.text = Strings.Shields.siteBroken
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
        $0.text = Strings.Shields.shieldsDownDisclaimer
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    
    let reportSiteButton = ActionButton(type: .system).then {
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.titleEdgeInsets = UIEdgeInsets(top: 4, left: 20, bottom: 4, right: 20)
        $0.setTitle(Strings.Shields.reportABrokenSite, for: .normal)
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
        
        [shieldsDownDisclaimerLabel, reportSiteButton].forEach(shieldsDownStackView.addArrangedSubview)
        
        stackView.addStackViewItems(
            .view(UIStackView(arrangedSubviews: [faviconImageView, hostLabel]).then {
                $0.spacing = 8
                $0.alignment = .center
                $0.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
                $0.isLayoutMarginsRelativeArrangement = true
            }),
            .view(shieldsSwitch),
            .view(UIStackView(arrangedSubviews: [braveShieldsLabel, statusLabel]).then {
                $0.spacing = 4
                $0.alignment = .center
            }),
            .customSpace(32),
            .view(blockCountView),
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
        blockCountView.applyTheme(theme)
        braveShieldsLabel.textColor = theme.colors.tints.home
        statusLabel.textColor = theme.colors.tints.home
        hostLabel.textColor = theme.isDark ? .white : .black
        shieldsDownDisclaimerLabel.textColor = theme.colors.tints.home
        reportSiteButton.tintColor = theme.isDark ? Colors.grey200 : Colors.grey800
    }
}
