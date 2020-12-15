// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

// MARK: - ShareTrackersViewDelegate

protocol ShareTrayViewDelegate: AnyObject {

    func didShareWithMail(_ view: ShareTrayView)
    func didShareWithTwitter(_ view: ShareTrayView)
    func didShareWithFacebook(_ view: ShareTrayView)
    func didShareWithDefault(_ view: ShareTrayView)
}

// MARK: - ShareTrackersView

class ShareTrayView: UIView, Themeable {
    
    // MARK: Properties
    
    private let mailShareButton = UIButton().then {
        $0.addTarget(self, action: #selector(tappedMailShareButton), for: .touchUpInside)
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
    
    weak var delegate: ShareTrayViewDelegate?

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
            $0.edges.equalToSuperview()
        }

        stackView.addStackViewItems(
            .view(mailShareButton),
            .view(twitterShareButton),
            .view(facebookShareButton),
            .view(defaultShareButton)
        )
    }
    
    // MARK: Actions
    
    @objc private func tappedMailShareButton() {
        delegate?.didShareWithMail(self)
    }
    
    @objc private func tappedTwitterShareButton() {
        delegate?.didShareWithTwitter(self)
    }
    
    @objc private func tappedFacebookShareButton() {
        delegate?.didShareWithFacebook(self)
    }
    
    @objc private func tappedDefaultShareButton() {
        delegate?.didShareWithDefault(self)
    }
    
    // MARK: Themeable
    
    func applyTheme(_ theme: Theme) {
        mailShareButton.tintColor = .white
        twitterShareButton.tintColor = .white
        facebookShareButton.tintColor = .white
        defaultShareButton.tintColor = .white
    }
}
