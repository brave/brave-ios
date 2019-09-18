// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import BraveRewardsUI

class OnboardingAdsCountdownViewController: OnboardingViewController, UNUserNotificationCenterDelegate {
    
    private var contentView: View {
        return view as! View // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View(theme: theme, themeColour: themeColour)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.countdownText = "3"
        
        //On this screen, when you press "Start Browsing", we need to mark all onboarding as complete, therefore we trigger `skip`..
        contentView.finishedButton.addTarget(self, action: #selector(skipTapped), for: .touchDown)
        
        //On this screen, when you press "I didn't see an ad", we need to go to the next screen..
        contentView.invalidButton.addTarget(self, action: #selector(continueTapped), for: .touchDown)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        contentView.animate(from: 0.0, to: 1.0, duration: 3.0) { [weak self] in
            guard let self = self else { return }
            
            (UIApplication.shared.delegate as? AppDelegate)?.browserViewController.displayMyFirstAdIfAvailable({
                self.skipTapped()
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.contentView.setState(.adConfirmation)
            }
        }
    }
}
