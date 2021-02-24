// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SDWebImage
import AVFoundation

class PlaylistCell: UITableViewCell {
    
    private var favIconFetcher: FaviconFetcher?
    private var thumbnailGenerator: HLSThumbnailGenerator?
    
    private let thumbnailMaskView = CAShapeLayer().then {
        $0.fillColor = UIColor.white.cgColor
    }
    
    private let thumbnailView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 5.0
        $0.layer.masksToBounds = true
    }
    
    var thumbnailImage: UIImage? {
        didSet {
            self.thumbnailView.image = thumbnailImage
            self.thumbnailView.backgroundColor = .black
            self.setNeedsLayout()
            self.layoutIfNeeded()
            //self.updateThumbnail()
        }
    }
    
    let titleLabel = UILabel().then {
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.numberOfLines = 2
        $0.font = .systemFont(ofSize: 16.0, weight: .medium)
    }
    
    let detailLabel = UILabel().then {
        $0.textColor = #colorLiteral(red: 0.5254901961, green: 0.5568627451, blue: 0.5882352941, alpha: 1)
        $0.appearanceTextColor = #colorLiteral(red: 0.5254901961, green: 0.5568627451, blue: 0.5882352941, alpha: 1)
        $0.font = .systemFont(ofSize: 14.0, weight: .regular)
    }
    
    private let iconStackView = UIStackView().then {
        $0.axis = .horizontal
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
        
        self.preservesSuperviewLayoutMargins = false
        self.selectionStyle = .none
        
        contentView.addSubview(iconStackView)
        contentView.addSubview(infoStackView)
        iconStackView.addArrangedSubview(thumbnailView)
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(detailLabel)
        contentView.addSubview(separator)
        
        thumbnailView.snp.makeConstraints {
            $0.width.equalTo(94.0)
        }
        
        iconStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12.0)
            $0.top.bottom.equalToSuperview().inset(8.0)
        }
        
        infoStackView.snp.makeConstraints {
            $0.left.equalTo(iconStackView.snp.right).offset(8.0)
            $0.right.equalToSuperview().offset(-15.0)
            $0.centerY.equalToSuperview()
            $0.top.bottom.equalTo(iconStackView)
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
    
    private func updateThumbnail() {
        if let image = thumbnailView.image {
            let boundsScale = thumbnailView.bounds.size.width / thumbnailView.bounds.size.height
            let imageScale = image.size.width / image.size.height
            var drawingRect = thumbnailView.bounds

            if boundsScale > imageScale {
                drawingRect.size.width =  drawingRect.size.height * imageScale
                drawingRect.origin.x = (thumbnailView.bounds.size.width - drawingRect.size.width) / 2.0
            } else {
                drawingRect.size.height = drawingRect.size.width / imageScale
                drawingRect.origin.y = (thumbnailView.bounds.size.height - drawingRect.size.height) / 2.0
            }

            let path = UIBezierPath(roundedRect: drawingRect, cornerRadius: 5.0)
            thumbnailMaskView.path = path.cgPath
            thumbnailView.layer.mask = thumbnailMaskView
        }
    }
    
    override var layoutMargins: UIEdgeInsets {
        get {
            return .zero
        }

        set (newValue) {
            _ = newValue
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
    
    // MARK: - Thumbnail
    
    func loadThumbnail(item: PlaylistInfo, onDurationUpdated: ((TimeInterval?) -> Void)? = nil) {
        guard let url = URL(string: item.src) else { return }
        
        // Loading from Cache failed, attempt to fetch HLS thumbnail
        self.thumbnailGenerator = HLSThumbnailGenerator(url: url, time: 3, completion: { [weak self] image, trackDuration in
            guard let self = self else { return }
            
            if let trackDuration = trackDuration {
                onDurationUpdated?(trackDuration)
            }
            
            if let image = image {
                self.thumbnailImage = image
                self.thumbnailGenerator = nil
                SDImageCache.shared.store(image, forKey: url.absoluteString, completion: nil)
            } else {
                //We can fall back to AVAssetImageGenerator or FavIcon
                self.loadThumbnailFallbackImage(item: item)
            }
        })
    }
    
    // Fall back to AVAssetImageGenerator
    // If that fails, fallback to FavIconFetcher
    private func loadThumbnailFallbackImage(item: PlaylistInfo) {
        guard let url = URL(string: item.src) else { return }

        let imageCache = SDImageCache.shared
        let imageGenerator = AVAssetImageGenerator(asset: AVAsset(url: url))
        imageGenerator.appliesPreferredTrackTransform = false

        let time = CMTimeMake(value: 3, timescale: 1)
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, cgImage, _, result, error in
            guard let self = self else { return }
            
            if result == .succeeded, let cgImage = cgImage {
                let image = UIImage(cgImage: cgImage)
                imageCache.store(image, forKey: url.absoluteString, completion: nil)
                
                DispatchQueue.main.async {
                    self.thumbnailImage = image
                }
            } else {
                guard let url = URL(string: item.pageSrc) else { return }
                
                DispatchQueue.main.async {
                    self.favIconFetcher = FaviconFetcher(siteURL: url, kind: .largeIcon)
                    self.favIconFetcher?.load { [weak self] url, attributes in
                        guard let self = self else { return }
                        self.favIconFetcher = nil
                        self.thumbnailImage = attributes.image
                        
                        imageCache.store(attributes.image, forKey: url.absoluteString, completion: nil)
                    }
                }
            }
        }
    }
}
