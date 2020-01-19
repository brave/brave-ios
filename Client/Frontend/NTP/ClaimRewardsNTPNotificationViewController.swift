// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import BraveRewardsUI

class ClaimRewardsNTPNotificationViewController: TranslucentBottomSheet {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let mainView = mainView else {
            assertionFailure()
            return
        }
        
        // Confetti background
        mainView.setCustomSpacing(0, after: mainView.header)
        mainView.body.font = .systemFont(ofSize: 14.0)
        
        let bgView = UIView().then {
            if let image = #imageLiteral(resourceName: "confetti").withAlpha(0.7) {
                $0.backgroundColor =  UIColor(patternImage: image)
            }
        }
        mainView.insertSubview(bgView, at: 0)
        bgView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        if let text = mainView.body.text {
            let font = mainView.body.font ?? UIFont.systemFont(ofSize: 14, weight: .regular)
            mainView.body.attributedText =
                text.attributedText(stringToChange: Strings.NTP.goodJob, font: font, color: .white)
        }
        
        view.addSubview(mainView)
        
        mainView.snp.remakeConstraints {
            $0.top.equalToSuperview().inset(28)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }
    
    private var mainView: NTPNotificationView? {
        var config = NTPNotificationViewConfig(textColor: .white)
        
        guard let rewards = (UIApplication.shared.delegate as? AppDelegate)?
            .browserViewController.rewards,
            let promo = rewards.ledger.pendingPromotions.first else {
                return nil
        }
        
        let goodJob = Strings.NTP.goodJob
        let grantAmount = BATValue(promo.approximateValue).displayString
        
        let earnings = grantAmount + " " + Strings.BAT
        
        let batEarnings = String(format: Strings.NTP.earningsReport, earnings)
        
        let text = "\(goodJob) \(batEarnings)"
        
        config.bodyText = (text: text, urlInfo: [:], action: nil)
        
        config.primaryButtonConfig =
            (text: Strings.NTP.claimRewards,
             showCoinIcon: true,
             action: { [weak self] in
                Preferences.NewTabPage.attemptToShowClaimRewardsNotification.value = false
                
                rewards.ledger.claimPromotion(promo) { [weak self] success in
                    if !success {
                        let alert = UIAlertController(title: Strings.genericErrorTitle, message: Strings.genericErrorBody, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: Strings.ok, style: .default, handler: nil))
                        self?.present(alert, animated: true)
                    }
                }

                self?.close()
            })
        
        return NTPNotificationView(config: config)
    }
}
