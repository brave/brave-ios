// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import BraveRewardsUI

class NTPNotificationViewController: TranslucentBottomSheet {
    
    var headerText: String?
    var bodyText: String?
    var primaryButtonConfig: (text: String, showCoinIcon: Bool, action: (() -> Void))?
    
    var learnMoreHandler: (() -> Void)?
    
    private let mainStackView = UIStackView().then {
        $0.axis = .vertical
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.spacing = 16
    }
    
    private let titleStackView = UIStackView().then {
        $0.spacing = 10
        
        let imageView = UIImageView(image: #imageLiteral(resourceName: "brave_rewards_button_enabled")).then { image in
            image.snp.makeConstraints { make in
                make.size.equalTo(24)
            }
        }
        
        let title = UILabel().then {
            $0.text = "Brave Rewards"
            $0.appearanceTextColor = .white
            $0.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        }
        
        [imageView, title].forEach($0.addArrangedSubview(_:))

    }
    
    lazy var header = UILabel().then {
        $0.text = headerText
        $0.appearanceTextColor = .white
        
        $0.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        
        $0.numberOfLines = 0
        $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        $0.lineBreakMode = .byWordWrapping
    }
    
    lazy var body = LinkLabel().then {
        $0.text = bodyText
        $0.appearanceTextColor = .white
        
        $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 313), for: .vertical)
        $0.textContainerInset = UIEdgeInsets.zero
        $0.textContainer.lineFragmentPadding = 0
    }
    
    lazy var primaryButton = RoundInterfaceButton().then {
        $0.setTitle(primaryButtonConfig?.text, for: .normal)
        $0.appearanceTextColor = .white
        $0.backgroundColor = BraveUX.blurple400
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 12, left: 25, bottom: 12, right: 25)
        if primaryButtonConfig?.showCoinIcon == true {
            $0.setImage(#imageLiteral(resourceName: "turn_rewards_on_money_icon"), for: .normal)
            $0.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        }
    }
    
    let state: BrandedImageCalloutState
    
    var primaryButtonTapped: (() -> Void)?
    
    init?(state: BrandedImageCalloutState) {
        self.state = state
        super.init()
        
        // todo fill remaining states, possibly extract somewhere
        switch state {
        case .getPaidTurnRewardsOn, .getPaidTurnAdsOn:
            bodyText = "Get paid to see this background image.\nLearn more"
            body.setURLInfo(["Learn more": "terms"])
            body.onLinkedTapped = { _ in
                self.learnMoreHandler?()
            }
        case .youCanGetPaidTurnAdsOn:
            headerText = "You can support web creators with tokens."
            bodyText = "Earn tokens by viewing privacy-respecting ads."
            primaryButtonConfig = (text: "Turn on Brave Ads", showCoinIcon: true, action: {
                guard let rewards = (UIApplication.shared.delegate as? AppDelegate)?
                    .browserViewController.rewards else { return }
                
                rewards.ads.isEnabled = true
            })
        case .gettingPaidAlready:
            bodyText = "You're getting paid to see this background image.\nLearn more"
            body.setURLInfo(["Learn more": "terms"])
            body.onLinkedTapped = { _ in
                self.learnMoreHandler?()
            }
        case .dontShow:
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var views: [UIView] = [titleStackView]
        
        if headerText != nil {
            views.append(header)
        }
        
        if bodyText != nil {
            views.append(body)
        }
        
        if primaryButtonConfig != nil {
            let stackView = UIStackView(arrangedSubviews:
                [UIView.spacer(.horizontal, amount: 0),
                 primaryButton,
                 UIView.spacer(.horizontal, amount: 0)]).then {
                    $0.distribution = .equalSpacing
            }
            
            stackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
            
            views.append(stackView)
        }
        
        views.forEach(mainStackView.addArrangedSubview(_:))
        
        mainStackView.setCustomSpacing(0, after: header)
        
        view.addSubview(mainStackView)
        
        mainStackView.snp.remakeConstraints {
            $0.top.equalToSuperview().inset(28)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        
        primaryButton.addTarget(self, action: #selector(primaryButtonAction), for: .touchDown)
    }
    
    @objc func primaryButtonAction() {
        primaryButtonConfig?.action()
        close()
    }
}
