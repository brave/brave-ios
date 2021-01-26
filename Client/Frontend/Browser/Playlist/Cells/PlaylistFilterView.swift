// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveShared
import Shared

class PlaylistFilterView: UIView {
    
    private let filterButton = UIButton().then {
        $0.setTitle(Strings.PlayList.listFilterActionTitle, for: .normal)
        $0.setTitleColor(#colorLiteral(red: 0.2, green: 0.6039215686, blue: 0.9411764706, alpha: 1), for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .medium)
        $0.isHidden = true
    }
    
    private let titleLabel = UILabel().then {
        $0.text = Strings.PlayList.playListSectionTitle
        $0.textColor = #colorLiteral(red: 0.5254901961, green: 0.5568627451, blue: 0.5882352941, alpha: 1)
        $0.font = .systemFont(ofSize: 13.0, weight: .medium)
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        preservesSuperviewLayoutMargins = false
        
        addSubview(filterButton)
        addSubview(titleLabel)
        
        filterButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().inset(20.0)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(filterButton.snp.bottom)
            $0.left.equalToSuperview().inset(35.0)
            $0.bottom.equalToSuperview().offset(-5.0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
