// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SDWebImage
import AVFoundation

class PlaylistCell: UITableViewCell {
    var thumbnailGenerator: HLSThumbnailGenerator?
    
    private let thumbnailMaskView = CAShapeLayer().then {
        $0.fillColor = UIColor.white.cgColor
    }
    
    let thumbnailView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 5.0
        if #available(iOS 13.0, *) {
            $0.layer.cornerCurve = .continuous
        }
        $0.layer.masksToBounds = true
    }
    
    let titleLabel = UILabel().then {
        $0.appearanceTextColor = .white
        $0.numberOfLines = 2
        $0.font = .systemFont(ofSize: 16.0, weight: .medium)
    }
    
    let detailLabel = UILabel().then {
        $0.appearanceTextColor = #colorLiteral(red: 0.5254901961, green: 0.5568627451, blue: 0.5882352941, alpha: 1)
        $0.font = .systemFont(ofSize: 14.0, weight: .regular)
    }
    
    private let iconStackView = UIStackView().then {
        $0.alignment = .center
        $0.spacing = 15.0
    }
    
    private let infoStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .top
        $0.spacing = 5.0
    }
    
    private let separator = UIView().then {
        $0.backgroundColor = UIColor(white: 1.0, alpha: 0.15)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        preservesSuperviewLayoutMargins = false
        selectionStyle = .none
        
        contentView.addSubview(iconStackView)
        contentView.addSubview(infoStackView)
        iconStackView.addArrangedSubview(thumbnailView)
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(detailLabel)
        contentView.addSubview(separator)
        
        thumbnailView.snp.makeConstraints {
            // Keeps a 94.0px width on iPhone-X as per design
            $0.width.equalTo(iconStackView.snp.height).multipliedBy(1.46875 /* 94.0 / (tableViewCellHeight - (8.0 * 2)) */)
        }
        
        iconStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12.0)
            $0.top.bottom.equalToSuperview().inset(8.0)
        }
        
        infoStackView.snp.makeConstraints {
            $0.left.equalTo(iconStackView.snp.right).offset(8.0)
            $0.right.equalToSuperview().offset(-15.0)
            $0.centerY.equalToSuperview()
            $0.top.greaterThanOrEqualTo(iconStackView.snp.top)
            $0.bottom.lessThanOrEqualTo(iconStackView.snp.bottom)
        }
        
        separator.snp.makeConstraints {
            $0.left.equalTo(titleLabel.snp.left)
            $0.right.bottom.equalToSuperview()
            $0.height.equalTo(1.0 / UIScreen.main.scale)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var layoutMargins: UIEdgeInsets {
        get {
            return .zero
        }

        set { //swiftlint:disable:this unused_setter_value
            super.layoutMargins = .zero
        }
    }
    
    override var separatorInset: UIEdgeInsets {
        get {
            return UIEdgeInsets(top: 0, left: self.titleLabel.frame.origin.x, bottom: 0, right: 0)
        }
        
        set (newValue) {
            _ = newValue
            super.separatorInset = UIEdgeInsets(top: 0, left: self.titleLabel.frame.origin.x, bottom: 0, right: 0)
        }
    }
}
