// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SnapKit

class WelcomeViewController: UIViewController {
    private let backgroundImageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "LaunchBackground")
    }
    
    private let topImageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "Launch_Leaves_Top")
    }
    
    private let iconView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "LaunchIcon")
    }
    
    private let bottomImageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "Launch_Leaves_Bottom")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [backgroundImageView, topImageView, iconView, bottomImageView].forEach {
            view.addSubview($0)
        }
        
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        topImageView.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
        }
    }
}
