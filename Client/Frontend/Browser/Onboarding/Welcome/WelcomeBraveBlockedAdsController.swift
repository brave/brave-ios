// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SnapKit
import BraveUI

class WelcomeBraveBlockedAdsController: UIViewController, PopoverContentComponent {
    private let label = UILabel().then {
        $0.numberOfLines = 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.trailing.top.bottom.equalToSuperview().inset(32.0)
        }
    }
    
    func setData(domain: String, trackerBlocked: String, trackerCount: Int) {
        let text = NSMutableAttributedString()
        text.append(NSAttributedString(string: "Brave blocked", attributes: [
            .foregroundColor: UIColor.braveLabel,
            .font: UIFont.systemFont(ofSize: 17.0)
        ]))
        
        text.append(NSAttributedString(string: " \(trackerBlocked) ", attributes: [
            .foregroundColor: UIColor.braveLabel,
            .font: UIFont.systemFont(ofSize: 17.0, weight: .bold)
        ]))
        
        if trackerCount > 0 {
            text.append(NSAttributedString(string: "and \(trackerCount) other trackers on: \(domain).\n\nTap the Shield from any site to see all the stuff we blocked.", attributes: [
                .foregroundColor: UIColor.braveLabel,
                .font: UIFont.systemFont(ofSize: 17.0)
            ]))
        } else {
            text.append(NSAttributedString(string: "on: \(domain).\n\nTap the Shield from any site to see all the stuff we blocked.", attributes: [
                .foregroundColor: UIColor.braveLabel,
                .font: UIFont.systemFont(ofSize: 17.0)
            ]))
        }
        
        label.attributedText = text
    }
}
