// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit

class PlaylistItemPlayingView: UIView {
    
    let titleLabel = UILabel().then {
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.font = .systemFont(ofSize: 14.0, weight: .medium)
    }
    
    let detailLabel = UILabel().then {
        $0.textColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
        $0.appearanceTextColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
        $0.font = .systemFont(ofSize: 12.0, weight: .regular)
    }
    
    private let addButton = UIButton().then {
        let image = #imageLiteral(resourceName: "add_tab")
        $0.setTitle("Add", for: .normal)
        $0.setImage(image, for: .normal)
        $0.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: 10 - image.size.width, bottom: 0.0, right: 0.0)
        $0.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 0, bottom: 0.0, right: 0.0)
        $0.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 20.0, bottom: 8.0, right: 20.0)
        $0.contentHorizontalAlignment = .left
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.appearanceTextColor = .white
        $0.titleLabel?.font = .systemFont(ofSize: 12.0, weight: .semibold)
        $0.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        $0.layer.borderWidth = 1.0
        $0.layer.cornerRadius = 18.0
    }
    
    private let infoStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 5.0
    }
    
    private let stackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 15.0
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.preservesSuperviewLayoutMargins = false
        self.backgroundColor = #colorLiteral(red: 0.05098039216, green: 0.2862745098, blue: 0.4823529412, alpha: 1)
        
        self.addSubview(stackView)
        stackView.addArrangedSubview(infoStackView)
        stackView.addArrangedSubview(addButton)
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(detailLabel)

        stackView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(15.0)
            $0.right.equalToSuperview().offset(-15.0)
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-5.0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
