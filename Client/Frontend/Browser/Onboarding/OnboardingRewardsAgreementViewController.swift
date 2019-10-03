// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards

class OnboardingRewardsAgreementViewController: OnboardingViewController {

    private var loadingView = UIActivityIndicatorView(style: .white)

    private var contentView: View {
        return view as! View // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View(theme: theme)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.agreeButton.addTarget(self, action: #selector(onAgreed), for: .touchDown)
        contentView.skipButton.addTarget(self, action: #selector(skipTapped), for: .touchDown)
        
        (view as! View).onTermsOfServicePressed = { [weak self] in  // swiftlint:disable:this force_cast
            guard let self = self else { return }
            
            self.present(OnboardingWebViewController(), animated: true, completion: nil)
        }
    }
    
    @objc
    private func onAgreed() {
        let titleColour = contentView.agreeButton.titleColor(for: .normal)
        contentView.agreeButton.setTitleColor(.clear, for: .normal)
        contentView.agreeButton.addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        loadingView.startAnimating()
        rewards?.ledger.createWallet { [weak self] error in
            guard let self = self else { return }

            self.loadingView.stopAnimating()
            self.contentView.agreeButton.setTitleColor(titleColour, for: .normal)
            self.continueTapped()
        }
    }
    
    override func applyTheme(_ theme: Theme) {
        styleChildren(theme: theme)
        contentView.applyTheme(theme)
    }
}
