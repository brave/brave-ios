// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import BraveRewardsUI
import SafariServices

/// A view controller that is presented after user taps on 'Learn more' on one of `NTPNotificationViewController` views.
class NTPLearnMoreViewController: BottomSheetViewController {
    private let viewHelper = BrandedImageCallout.CommonViews.self
    
    var headerText: String?
    var bodyText: String?
    var primaryButtonConfig: (text: String, showCoinIcon: Bool, action: (() -> Void))?
    var secondaryButtonConfig: (text: String, action: (() -> Void))?
    
    let mainStackView = UIStackView().then {
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
            $0.text = Strings.braveRewardsTitle
            $0.appearanceTextColor = .black
            $0.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        }
        
        [imageView, title].forEach($0.addArrangedSubview(_:))
    }
    
    lazy var header = UILabel().then {
        $0.text = headerText
        $0.appearanceTextColor = .black
        
        $0.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        $0.numberOfLines = 0
        $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        $0.lineBreakMode = .byWordWrapping
    }
    
    lazy var body = LinkLabel().then {
        $0.font = .systemFont(ofSize: 12.0)
        $0.appearanceTextColor = .black
        $0.linkColor = BraveUX.braveOrange
        $0.text = bodyText
        
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
    
    lazy var secondaryButton = RoundInterfaceButton().then {
        $0.setTitle(secondaryButtonConfig?.text, for: .normal)
        $0.appearanceTextColor = .black
        $0.backgroundColor = .clear
        $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    
    let state: BrandedImageCalloutState
    
    var linkHandler: ((URL) -> Void)?
    
    init?(state: BrandedImageCalloutState) {
        self.state = state
        super.init()
        
        switch state {
        case .getPaidTurnRewardsOn:
            headerText = Strings.NTP.getPaidForThisImageTurnRewards
            
            let tos = Strings.termsOfServiceURL
            let tosPart = String(format: Strings.NTP.turnRewardsTos, tos)
            
            let hideImages = Strings.NTP.hideSponsoredImages
            let hideImagesPart = String(format: Strings.NTP.chooseToHideSponsoredImages, hideImages)
            
            let fullBodyText = "\(tosPart) \(hideImagesPart)"
            
            bodyText = fullBodyText
            body.setURLInfo([tos: "tos", hideImages: "hide-sponsored-images"])
            body.onLinkedTapped = { action in
                if action.absoluteString == "tos" {
                    let urlString = "https://www.brave.com/terms_of_use"
                    guard let url = URL(string: urlString) else { return }
                    self.showSFSafariViewController(url: url)
                } else if action.absoluteString == "hide-sponsored-images" {
                    Preferences.NewTabPage.backgroundSponsoredImages.value = false
                    self.close()
                }
            }
            
            primaryButtonConfig = (text: Strings.NTP.turnOnBraveRewards, showCoinIcon: false, action: {
                guard let rewards = (UIApplication.shared.delegate as? AppDelegate)?
                    .browserViewController.rewards else { return }
                
                rewards.ledger.createWalletAndFetchDetails { _ in }
                self.close()
            })
            
            secondaryButtonConfig = (text: Strings.disclaimerLearnMore, action: {
                guard let url = URL(string: "https://brave.com/brave-rewards/") else { return }
                self.showSFSafariViewController(url: url)
            })
        case .getPaidTurnAdsOn:
            headerText = Strings.NTP.getPaidForThisImageTurnAds
            
            let hideImages = Strings.NTP.hideSponsoredImages
            let hideImagesPart = String(format: Strings.NTP.chooseToHideSponsoredImages, hideImages)
            bodyText = hideImagesPart
            body.setURLInfo([hideImages: "hide-sponsored-images"])
            body.onLinkedTapped = { action in
                if action.absoluteString == "hide-sponsored-images" {
                    Preferences.NewTabPage.backgroundSponsoredImages.value = false
                    self.close()
                }
            }
            
            primaryButtonConfig = (text: Strings.NTP.turnOnBraveAds, showCoinIcon: true, action: {
                guard let rewards = (UIApplication.shared.delegate as? AppDelegate)?
                    .browserViewController.rewards else { return }
                
                rewards.ads.isEnabled = true
                self.close()
            })
            
        case .gettingPaidAlready:
            headerText = Strings.NTP.youArePaidToSeeThisImage
            
            let learnMore = Strings.disclaimerLearnMore
            let learnMorePart = String(format: Strings.NTP.learnMoreAboutBrandedImages, learnMore)
            
            let hideImages = Strings.NTP.hideSponsoredImages
            let hideImagesPart = String(format: Strings.NTP.chooseToHideSponsoredImages, hideImages)
            
            bodyText = "\(learnMorePart) \(hideImagesPart)"

            body.setURLInfo([learnMore: "sponsored-images", hideImages: "hide-sponsored-images"])
            body.onLinkedTapped = { action in
                if action.absoluteString == "sponsored-images" {
                    guard let url = URL(string: "https://brave.com/brave-rewards/") else { return }
                    self.linkHandler?(url)
                    self.close()
                } else if action.absoluteString == "hide-sponsored-images" {
                    Preferences.NewTabPage.backgroundSponsoredImages.value = false
                    self.close()
                }
            }
        case .dontShow, .youCanGetPaidTurnAdsOn:
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
            
            primaryButton.addTarget(self, action: #selector(primaryButtonAction), for: .touchDown)
        }
        
        if secondaryButtonConfig != nil {
            let stackView = UIStackView(arrangedSubviews:
                [UIView.spacer(.horizontal, amount: 0),
                 secondaryButton,
                 UIView.spacer(.horizontal, amount: 0)]).then {
                    $0.distribution = .equalSpacing
            }
            
            stackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
            views.append(stackView)
            
            secondaryButton.addTarget(self, action: #selector(secondaryButtonAction), for: .touchDown)
        }
        
        views.forEach(mainStackView.addArrangedSubview(_:))
        
        contentView.addSubview(mainStackView)
        
        mainStackView.snp.remakeConstraints {
            $0.top.equalToSuperview().inset(28)
            $0.left.right.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(28)
        }
    }
    
    private func showSFSafariViewController(url: URL) {
        let config = SFSafariViewController.Configuration()
        
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.modalPresentationStyle = .overFullScreen
        
        self.present(vc, animated: true)
    }
    
    @objc func primaryButtonAction() {
        primaryButtonConfig?.action()
    }
    
    @objc func secondaryButtonAction() {
        secondaryButtonConfig?.action()
    }
}
