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
            self.thumbnailView.backgroundColor = thumbnailImage == nil ? .black : .clear
            self.setNeedsLayout()
            self.layoutIfNeeded()
            self.updateThumbnail()
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
        $0.spacing = 8.0
    }
    
    private let separator = UIView().then {
        $0.backgroundColor = #colorLiteral(red: 0.1294117647, green: 0.1450980392, blue: 0.1607843137, alpha: 1)
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
            $0.top.bottom.equalToSuperview().inset(1.0)
        }
        
        infoStackView.snp.makeConstraints {
            $0.left.equalTo(iconStackView.snp.right).offset(8.0)
            $0.right.equalToSuperview().offset(-15.0)
            $0.centerY.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview().inset(1.0)
            $0.bottom.lessThanOrEqualToSuperview().inset(1.0)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateThumbnail()
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
    
    func loadThumbnail(item: PlaylistInfo) {
        guard let url = URL(string: item.src) else { return }
        
        let request = URLRequest(url: url)
        let cache = URLCache.shared
        let imageCache = SDImageCache.shared
        self.thumbnailView.backgroundColor = nil

        if let cachedImage = imageCache.imageFromCache(forKey: url.absoluteString) {
            self.thumbnailImage = cachedImage
            return
        }

        if let cachedResponse = cache.cachedResponse(for: request), let cachedImage = UIImage(data: cachedResponse.data) {
            self.thumbnailImage = cachedImage
            return
        }

        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = false

        let time = CMTimeMake(value: 0, timescale: 600)

        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, cgImage, _, result, error in
            guard let self = self else {
                return
            }
            
            if result == .succeeded, let cgImage = cgImage {
                let image = UIImage(cgImage: cgImage)
                if let data = image.pngData(),
                   let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    cache.storeCachedResponse(cachedResponse, for: request)
                    imageCache.store(image, forKey: url.absoluteString, completion: nil)
                }
                
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
                        self.thumbnailView.backgroundColor = attributes.backgroundColor
                    }
                }
            }
        }
    }
}
