// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import BraveUI
import BraveShared
import Shared

// MARK: TrackingType

public enum TrackingType: Equatable {
    case trackerCountShare(count: Int)
    case trackerAdWarning
    case videoAdBlock
    case trackerAdCountBlock(count: Int)
    case encryptedConnectionWarning
    
    var title: String {
        switch self {
            case .trackerCountShare(let count):
                return String(format: Strings.ShieldEducation.trackerCountShareTitle, "\(count)")
            case .trackerAdWarning:
                return Strings.ShieldEducation.trackerAdWarningTitle
            case .videoAdBlock:
                return Strings.ShieldEducation.videoAdBlockTitle
            case .trackerAdCountBlock(let count):
                return String(format: Strings.ShieldEducation.trackerAdCountBlockTitle, "\(count)")
            case .encryptedConnectionWarning:
                return Strings.ShieldEducation.encryptedConnectionWarningTitle
        }
    }
    
    var subTitle: String {
        switch self {
            case .trackerCountShare:
                return Strings.ShieldEducation.trackerCountShareSubtitle
            case .trackerAdWarning:
                return Strings.ShieldEducation.trackerAdWarningSubtitle
            case .videoAdBlock:
                return Strings.ShieldEducation.videoAdBlockSubtitle
            case .trackerAdCountBlock:
                return Strings.ShieldEducation.trackerAdCountBlockSubtitle
            case .encryptedConnectionWarning:
                return Strings.ShieldEducation.encryptedConnectionWarningSubtitle
        }
    }
    
    var actionTitle: String {
        switch self {
            case .trackerCountShare,
                 .videoAdBlock,
                 .trackerAdCountBlock,
                 .encryptedConnectionWarning:
                return Strings.ShieldEducation.educationDismissTitle
            case .trackerAdWarning:
                return Strings.ShieldEducation.educationInspectTitle
        }
    }
}

// MARK: - ShareTrackersController

class ShareTrackersController: UIViewController, Themeable, PopoverContentComponent {
    
    // MARK: Action
    
    enum Action {
        case takeALookTapped
        case dontShowAgainTapped
        case shareEmailTapped
        case shareTwitterTapped
        case shareFacebookTapped
        case shareMoreTapped
    }
    
    // MARK: Properties
    
    private let tab: Tab
    private let trackingType: TrackingType
    
    private let shareTrackersView: ShareTrackersView
    
    private lazy var gradientView = GradientView(
        colors: [#colorLiteral(red: 0.968627451, green: 0.2274509804, blue: 0.1098039216, alpha: 1), #colorLiteral(red: 0.7490196078, green: 0.07843137255, blue: 0.6352941176, alpha: 1)],
        positions: [0, 1],
        startPoint: .zero,
        endPoint: CGPoint(x: 1, y: 0.5))
    
    // MARK: Lifecycle
    
    init(tab: Tab, trackingType: TrackingType) {
        self.tab = tab
        self.trackingType = trackingType
        self.shareTrackersView = ShareTrackersView(trackingType: trackingType)
        
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
        
        applyTheme(Theme.of(tab))
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
        
        if case .trackerAdWarning = trackingType {
            shareTrackersView.insertSubview(gradientView, at: 0)
            
            gradientView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
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
    
    // MARK: UX
    
    struct UX {
        static let contentMargins: UIEdgeInsets = UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32)
        static let actionButtonInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
    
    // MARK: Properties
    
    private let trackingType: TrackingType

    private let shareTrayView = ShareTrayView()
    
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 20
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UX.contentMargins
    }
    
    private lazy var titleLabel = UILabel().then {
        $0.backgroundColor = .clear
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        $0.numberOfLines = 0
    }
    
    private let subtitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16)
        $0.numberOfLines = 0
    }
    
    private lazy var actionButton: UIButton = {
        let actionButton = InsetButton()
        actionButton.contentEdgeInsets = UX.actionButtonInsets
        actionButton.layer.cornerRadius = 20
        actionButton.clipsToBounds = true
        actionButton.layer.borderWidth = 1
        actionButton.layer.borderColor = UIColor.white.cgColor
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        return actionButton
    }()
    
    // MARK: Lifecycle
    
    init(frame: CGRect = .zero, trackingType: TrackingType) {
        self.trackingType = trackingType
        
        super.init(frame: frame)
        
        doLayout()
        setContent()
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    private func doLayout() {
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
            })
        )
        
        if case .trackerCountShare = trackingType {
            stackView.addArrangedSubview(shareTrayView)
        } else {
            stackView.addArrangedSubview(actionButton)
        }
    }
    
    private func setContent() {
        titleLabel.attributedText = {
            let imageAttachment = NSTextAttachment().then {
                $0.image = #imageLiteral(resourceName: "share-bubble-shield")
            }
            
            let string = NSMutableAttributedString(attachment: imageAttachment)
            
            string.append(NSMutableAttributedString(
                string: trackingType.title,
                attributes: [.font: UIFont.systemFont(ofSize: 20.0)]
            ))
            return string.withLineSpacing(3)
        }()
        
        subtitleLabel.attributedText = NSAttributedString(string: trackingType.subTitle).withLineSpacing(2)
        
        actionButton.setTitle(trackingType.actionTitle, for: .normal)
    }
    
    // MARK: Themeable
    
    func applyTheme(_ theme: Theme) {
        titleLabel.appearanceTextColor = .white
        subtitleLabel.appearanceTextColor = .white
        actionButton.appearanceTextColor = .white
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
        
        doLayout()
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    private func doLayout() {
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
    
    // MARK: Themeable
    
    func applyTheme(_ theme: Theme) {
        mailShareButton.tintColor = .white
        twitterShareButton.tintColor = .white
        facebookShareButton.tintColor = .white
        defaultShareButton.tintColor = .white
    }
}
