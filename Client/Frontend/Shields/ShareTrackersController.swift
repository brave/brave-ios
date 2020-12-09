// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import BraveUI
import BraveShared
import Shared

// MARK: - ShareTrackersController

class ShareTrackersController: UIViewController, Themeable, PopoverContentComponent {
    
    // MARK: Action
    
    enum Action {
        case rewardsTransferTapped
        case unverifiedPublisherLearnMoreTapped
    }
    
    // MARK: Properties
    
    private let tab: Tab
    
    private let shareTrackersView = ShareTrackersView()
    
    // MARK: Lifecycle
    
    init(tab: Tab) {
        self.tab = tab
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
                applyTheme(Theme.of(nil))
            }
        }
    }
    
    // MARK: Internal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyTheme(Theme.of(nil))
        
        doLayout()
    }
    
    private func doLayout() {
        
        view.addSubview(shareTrackersView)

        view.snp.makeConstraints {
            $0.width.equalTo(264)
            $0.height.equalTo(shareTrackersView)
        }
        
        shareTrackersView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    // MARK: Themeable
    
    func applyTheme(_ theme: Theme) {
        view.backgroundColor = UIColor(rgb: 0x339AF0)
        shareTrackersView.applyTheme(theme)
    }
}

// MARK: - ShareTrackersView

private class ShareTrackersView: UIView, Themeable {
    
    // MARK: Properties
    
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 20
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32)
    }
        
//    let trackerShieldIconView = Button().then {
//        $0.setImage(#imageLiteral(resourceName: "share-bubble-shield"), for: .normal)
//        $0.imageEdgeInsets = .zero
//        $0.titleEdgeInsets = .zero
//        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 4)
//    }
    
//    let trackerShieldIconView = UIImageView().then {
//        $0.image = #imageLiteral(resourceName: "share-bubble-shield").template
//        $0.contentMode = .scaleAspectFit
//        $0.setContentHuggingPriority(.required, for: .horizontal)
//        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
//    }
//
//    private lazy var titleLabel = ViewLabel().then {
//        $0.textAlignment = .left
//
//        $0.attributedText = {
//            let string = NSMutableAttributedString(attachment: ViewTextAttachment(view: self.trackerShieldIconView))
//
//            string.append(NSMutableAttributedString(
//                string: "1000 trackers & ads blocked",
//                attributes: [.font: UIFont.systemFont(ofSize: 20.0)]
//            ))
//            return string
//        }()
//        $0.backgroundColor = .clear
//        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
//    }
    
    private lazy var titleLabel = UILabel().then {
        $0.attributedText = {
            let imageAttachment = NSTextAttachment().then {
                $0.image = #imageLiteral(resourceName: "share-bubble-shield")
            }
            
            let string = NSMutableAttributedString(attachment: imageAttachment)
            
            string.append(NSMutableAttributedString(
                string: "1000 trackers & ads blocked",
                attributes: [.font: UIFont.systemFont(ofSize: 20.0)]
            ))
            return string
        }()
        
        $0.backgroundColor = .clear
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        $0.numberOfLines = 0
    }
    

    
    private let subtitleLabel = UILabel().then {
        $0.text = "Congratulations.nYou're pretty special."
        $0.font = .systemFont(ofSize: 16)
        $0.numberOfLines = 0
    }
    
    let shareTrayView = ShareTrayView()
    
    // MARK: Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.addStackViewItems(
            .view(UIStackView().then {
                $0.alignment = .center
                $0.spacing = 10
                $0.addStackViewItems(
                    .view(UIStackView().then {
                        $0.axis = .vertical
                        $0.spacing = 8
                        $0.addStackViewItems(
                            .view(titleLabel),
                            .view(subtitleLabel)
                        )
                        $0.setContentHuggingPriority(.required, for: .vertical)
                    })
                )
            }),
            .view(shareTrayView)
        )
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    func applyTheme(_ theme: Theme) {
        titleLabel.appearanceTextColor = .white
        subtitleLabel.appearanceTextColor = .white
    }
}

// MARK: - ShareTrackersView

private class ShareTrayView: UIView, Themeable {
    
    // MARK: Properties
    
    private let mailShareButton = UIButton().then {
        $0.setImage(#imageLiteral(resourceName: "share-bubble-mail").template, for: .normal)
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .white
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private let twitterShareButton = UIButton().then {
        $0.setImage(#imageLiteral(resourceName: "share-bubble-twitter").template, for: .normal)
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .white
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private let facebookShareButton = UIButton().then {
        $0.setImage(#imageLiteral(resourceName: "share-bubble-facebook").template, for: .normal)
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .white
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private let defaultShareButton = UIButton().then {
        $0.setImage(#imageLiteral(resourceName: "share-bubble-more").template, for: .normal)
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .white
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // MARK: Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let stackView = UIStackView().then {
            $0.alignment = .leading
            $0.spacing = 8
            $0.isUserInteractionEnabled = false
        }
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
        }

        stackView.addStackViewItems(
            .view(mailShareButton),
            .view(twitterShareButton),
            .view(facebookShareButton),
            .view(defaultShareButton)
        )
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
}
