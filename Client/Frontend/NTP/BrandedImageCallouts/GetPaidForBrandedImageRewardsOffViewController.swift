// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import BraveRewardsUI
import SafariServices

extension BrandedImageCallout {
    class GetPaidForBrandedImageRewardsOffViewController: BottomSheetViewController {
        
        private let viewHelper = BrandedImageCallout.CommonViews.self
        
        let mainStackView = UIStackView().then {
            $0.axis = .vertical
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.spacing = 16
        }
        
        let body = UILabel().then {
            $0.text = "Get paid to see this background image. Turn on Brave Rewards to claim your share."
            $0.appearanceTextColor = .black
            
            $0.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            
            $0.numberOfLines = 0
            $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            $0.lineBreakMode = .byWordWrapping
        }
        
        let tos = LinkLabel().then {
            $0.font = .systemFont(ofSize: 12.0)
            $0.appearanceTextColor = .black
            $0.linkColor = BraveUX.braveOrange
            $0.text = """
            By turning Rewards, you agree to the Terms of Service \
            You can also choose to hide sponsored images.
            """
            
            $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 313), for: .vertical)
            $0.setURLInfo(["Terms of Service": "tos", "hide sponsored images": "hide-sponsored-images"])
            
            $0.textContainerInset = UIEdgeInsets.zero
            $0.textContainer.lineFragmentPadding = 0
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            let headerStackView = viewHelper.rewardsLogoHeader(textColor: .black, textSize: 20).then {
                $0.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 311), for: .vertical)
            }
            
            let turnRewardsOnButton = viewHelper.primaryButton(text: "Turn on Rewards", showMoneyImage: false)
            let turnRewardsOnButtonStackView = viewHelper.centeredView(turnRewardsOnButton)
            
            let learnMoreButton = viewHelper.secondaryButton(text: "Learn more", showMoneyImage: false)
            let learnMoreStackView = viewHelper.centeredView(learnMoreButton)
            
            [headerStackView, body, tos, turnRewardsOnButtonStackView, learnMoreStackView]
                .forEach(mainStackView.addArrangedSubview(_:))
            
            contentView.addSubview(mainStackView)
            
            tos.onLinkedTapped = { action in
                var urlString = ""
                
                if action.absoluteString == "tos" {
                    urlString = "https://www.brave.com/terms_of_use"
                    guard let url = URL(string: urlString) else { return }
                    self.showSFSafariViewController(url: url)
                } else if action.absoluteString == "hide-sponsored-images" {
                    Preferences.NewTabPage.backgroundSponsoredImages.value = false
                    self.close()
                }
            }
            
            learnMoreButton.addTarget(self, action: #selector(learnMoreTapped), for: .touchDown)
            turnRewardsOnButton.addTarget(self, action: #selector(turnRewardsOnTapped), for: .touchDown)
            
            mainStackView.snp.remakeConstraints {
                $0.top.equalToSuperview().inset(28)
                $0.left.right.equalToSuperview().inset(16)
                $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(28)
            }
        }
        
        @objc func turnRewardsOnTapped() {
            guard let rewards = (UIApplication.shared.delegate as? AppDelegate)?
                .browserViewController.rewards else { return }
            
            rewards.ledger.createWalletAndFetchDetails { _ in
                
            }
            
            close()
        }
        
        @objc func learnMoreTapped() {
            guard let url = URL(string: "https://brave.com/brave-rewards/") else { return }
            showSFSafariViewController(url: url)
        }
        
        private func showSFSafariViewController(url: URL) {
            let config = SFSafariViewController.Configuration()

            let vc = SFSafariViewController(url: url, configuration: config)
            vc.modalPresentationStyle = .overFullScreen
            
            self.present(vc, animated: true)
        }
    }
}
