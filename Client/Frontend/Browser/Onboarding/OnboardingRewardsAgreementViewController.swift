// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

class OnboardingRewardsAgreementViewController: OnboardingViewController {
    private var contentView: View {
        return view as! View // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View(theme: theme, themeColour: themeColour)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.agreeButton.addTarget(self, action: #selector(continueTapped), for: .touchDown)
        contentView.skipButton.addTarget(self, action: #selector(skipTapped), for: .touchDown)
        
        (view as! View).onTermsOfServicePressed = { [weak self] in  // swiftlint:disable:this force_cast
            guard let self = self else { return }
            
            self.present(OnboardingWebViewController(), animated: true, completion: nil)
        }
    }
}
