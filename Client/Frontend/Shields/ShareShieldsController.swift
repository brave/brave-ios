// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveShared
import Shared
import BraveUI

// MARK: - ShareShieldsViewController

class ShareShieldsViewController: UIViewController, Themeable {

    // MARK: Action
    
    enum Action {
        case shareEmailClicked
        case shareTwitterClicked
        case shareFacebookClicked
        case shareDefaultClicked
    }

    // MARK: UX
    
    private struct UX {
        static let defaultInset = UIEdgeInsets(equalInset: 19)
        static let contentSizeChange: CGFloat = 64
    }

    // MARK: Properties
    
    private let theme: Theme

    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 3
        $0.alignment = .fill
        $0.layoutMargins = UX.defaultInset
        $0.isLayoutMarginsRelativeArrangement = true
    }

    var actionHandler: ((Action) -> Void)?

    // MARK: Lifecycle
    
    init(theme: Theme) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.Share.shareScreenTitle

        doLayoutAndAddGestureRecognizers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferredContentSize = contentStackView.systemLayoutSizeFitting(
            CGSize(width: view.bounds.size.width - UX.contentSizeChange,
                   height: view.bounds.size.height - UX.contentSizeChange),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).with {
            $0.width += UX.contentSizeChange
        }

        navigationController?.preferredContentSize = preferredContentSize
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
                applyTheme(theme)
            }
        }
    }

    // MARK: Internal
    
    private func doLayoutAndAddGestureRecognizers() {
        let shareTypeViewEmail = ShareTypeView(type: .email)
        let shareEmailGesture = UITapGestureRecognizer(target: self, action: #selector(shareClicked(_:)))
        shareTypeViewEmail.addGestureRecognizer(shareEmailGesture)

        let shareTypeViewTwitter = ShareTypeView(type: .twitter)
        let shareTwitterGesture = UITapGestureRecognizer(target: self, action: #selector(shareClicked(_:)))
        shareTypeViewTwitter.addGestureRecognizer(shareTwitterGesture)

        let shareTypeViewFacebook = ShareTypeView(type: .facebook)
        let shareFacebookGesture = UITapGestureRecognizer(target: self, action: #selector(shareClicked(_:)))
        shareTypeViewFacebook.addGestureRecognizer(shareFacebookGesture)

        let shareTypeViewDefault = ShareTypeView(type: .default)
        let shareDefaultGesture = UITapGestureRecognizer(target: self, action: #selector(shareClicked(_:)))
        shareTypeViewDefault.addGestureRecognizer(shareDefaultGesture)

        view.addSubview(contentStackView)

        contentStackView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
        }

        contentStackView.addStackViewItems(
            .view(shareTypeViewEmail),
            .view(shareTypeViewTwitter),
            .view(shareTypeViewFacebook),
            .view(shareTypeViewDefault)
        )
    }

    // MARK: Themeable
    
    func applyTheme(_ theme: Theme) {
        view.backgroundColor = theme.isDark ? BraveUX.popoverDarkBackground : UIColor.white

        contentStackView.arrangedSubviews.forEach { subview in
            if let typeView = subview as? ShareTypeView {
                typeView.applyTheme(theme)
            }
        }
    }

    // MARK: Actions
    
    @objc fileprivate func shareClicked(_ sender: UITapGestureRecognizer) {
        if let typeView = sender.view as? ShareTypeView {
            switch typeView.shareType {
                case .email:
                    actionHandler?(.shareEmailClicked)
                case .twitter:
                    actionHandler?(.shareTwitterClicked)
                case .facebook:
                    actionHandler?(.shareFacebookClicked)
                case .default:
                    actionHandler?(.shareDefaultClicked)
            }
        }
    }
}

// MARK: - ShareTypeView

private class ShareTypeView: UIView, Themeable {

    // MARK: ShareType
    
    enum ShareType {
        case email
        case twitter
        case facebook
        case `default`

        var title: String {
            switch self {
                case .email:
                    return Strings.Share.emailShareActionTitle
                case .twitter:
                    return Strings.Share.twitterShareActionTitle
                case .facebook:
                    return Strings.Share.facebookShareActionTitle
                case .default:
                    return Strings.Share.moreShareActionTitle
            }
        }

        var icon: UIImage {
            switch self {
                case .twitter:
                    return  #imageLiteral(resourceName: "share-twitter")
                case .facebook:
                    return  #imageLiteral(resourceName: "share-facebook")
                default:
                    return  #imageLiteral(resourceName: "share-mail")
            }
        }
    }

    // MARK: UX
    
    private struct UX {
        static let defaultOffsetInset: CGFloat = 19
        static let iconSize: CGFloat = 24
    }

    // MARK: Properties
    
    let shareType: ShareType

    private let contentView = UIView().then {
        $0.backgroundColor = .clear
    }

    private let titleLabel = UILabel().then {
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 19)
        $0.numberOfLines = 0
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    private let titleImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .darkGray
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // MARK: Lifecycle
    
    init(frame: CGRect = .zero, type: ShareType) {
        shareType = type

        super.init(frame: frame)

        doLayout()
        setContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal
    
    private func doLayout() {
        addSubview(contentView)

        if shareType == .default {
            contentView.addSubview(titleLabel)
        } else {
            contentView.addSubviews([titleImageView, titleLabel])
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UX.defaultOffsetInset)
        }

        if shareType != .default {
            titleImageView.snp.makeConstraints {
                $0.width.equalTo(UX.iconSize)
                $0.height.equalTo(UX.iconSize)
                $0.trailing.equalTo(titleLabel.snp.leading).offset(-UX.defaultOffsetInset)
                $0.top.equalTo(contentView.snp.top)
                $0.bottom.equalTo(titleLabel.snp.bottom)
            }
        }

        let labelOffset = shareType == .default ? 0 : UX.iconSize / 2

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview().offset(labelOffset)
            $0.bottom.equalToSuperview()
        }

        layer.cornerRadius = 6
        layer.masksToBounds = true
    }

    private func setContent() {
        titleLabel.text = shareType.title
        titleImageView.image = shareType.icon
    }

    func applyTheme(_ theme: Theme) {
        backgroundColor = theme.isDark ? UIColor(rgb: 0x303443) : Colors.neutral000
        titleLabel.textColor = theme.isDark ? .white : .black
    }
}
