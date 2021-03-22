// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import AVKit

class VideoPlayerInfoBar: UIView {
    private var favIconFetcher: FaviconFetcher?
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark)).then {
        $0.contentView.backgroundColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3098039216, alpha: 0.8)
    }
    
    private let favIconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 6.0
        $0.layer.masksToBounds = true
    }
    
    let titleLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 15.0, weight: .medium)
    }
    
    let pictureInPictureButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(#imageLiteral(resourceName: "playlist_pip"), for: .normal)
        $0.isHidden = !AVPictureInPictureController.isPictureInPictureSupported()
    }
    
    let fullscreenButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(#imageLiteral(resourceName: "playlist_fullscreen"), for: .normal)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(blurView)
        addSubview(favIconImageView)
        addSubview(titleLabel)
        addSubview(pictureInPictureButton)
        addSubview(fullscreenButton)
        
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        favIconImageView.snp.makeConstraints {
            $0.width.height.equalTo(28.0)
            $0.left.top.bottom.equalToSuperview().inset(20.0)
        }
        
        titleLabel.snp.makeConstraints {
            $0.left.equalTo(favIconImageView.snp.right).offset(13.0)
            $0.centerY.equalToSuperview()
        }
        
        pictureInPictureButton.snp.makeConstraints {
            $0.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(20.0)
            $0.centerY.equalToSuperview()
        }
        
        fullscreenButton.snp.makeConstraints {
            $0.left.equalTo(pictureInPictureButton.snp.right).offset(32.0)
            $0.right.equalToSuperview().offset(-20.0)
            $0.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateFavIcon(domain: String) {
        favIconImageView.cancelFaviconLoad()
        favIconImageView.clearMonogramFavicon()
        favIconImageView.contentMode = .scaleAspectFit
        favIconImageView.image = FaviconFetcher.defaultFaviconImage
        
        if let url = URL(string: domain) {
            favIconImageView.loadFavicon(for: url)
        }
    }
}
