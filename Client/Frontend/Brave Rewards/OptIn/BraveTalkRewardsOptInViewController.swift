// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveUI
import Shared
import BraveShared

class BraveTalkRewardsOptInViewController: UIViewController, PopoverContentComponent {
    
    /// Gets called when a user taps on 'Enable Rewards' button.
    var rewardsEnabledHandler: (() -> Void)?
    var linkTapped: ((URLRequest) -> Void)?
    
    private var braveTalkView: View {
        view as! View // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View()
    }
    
    override func viewDidLoad() {
        updatePreferredContentSize()
        
        braveTalkView.enableRewardsButton .addTarget(self, action: #selector(enableRewardsAction),
                                                     for: .touchUpInside)
        braveTalkView.disclaimer.onLinkedTapped = { [unowned self] link in
            var request: URLRequest?
            
            self.dismiss(animated: true) {
                switch link.absoluteString {
                case "tos":
                    request = URLRequest(url: BraveUX.batTermsOfUseURL)
                case "privacy-policy":
                    request = URLRequest(url: BraveUX.bravePrivacyURL)
                default:
                    assertionFailure()
                }
                
                if let request = request {
                    self.linkTapped?(request)
                }
            }
        }
    }
    
    @objc func enableRewardsAction() {
        dismiss(animated: true) {
            self.rewardsEnabledHandler?()
        }
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.preferredContentSizeCategory
            != traitCollection.preferredContentSizeCategory {
            
            updatePreferredContentSize()
        }
    }
    
    private func updatePreferredContentSize() {
        let height = UIFontMetrics.default.scaledValue(for: 450)
        preferredContentSize = .init(width: 350, height: height)
    }
}
