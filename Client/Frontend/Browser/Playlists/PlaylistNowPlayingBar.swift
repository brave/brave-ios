// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit

protocol NowPlayingBarDelegate: class {
    func onAddToPlaylist()
    func onExpand()
    func onExit()
}

enum NowPlayingBarState {
    case add
    case existing
    case addNowPlaying
    case addedNowPlaying
    case nowPlaying
}

class NowPlayingBar: UIView {
    
    public weak var delegate: NowPlayingBarDelegate?
    
    public var state: NowPlayingBarState = .add {
        didSet {
            refreshUI()
        }
    }
    
    private let backgroundBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    private let infoStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 15.0
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 5.0, left: 15.0, bottom: 5.0, right: 15.0)
    }
    
    private let mediaInfoStackView = UIStackView().then {
        $0.axis = .vertical
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 5.0, left: 0.0, bottom: 5.0, right: 5.0)
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    private let buttonStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 2.0
    }
    
    private lazy var nowPlayingMediaSeparator = {
        createSeparator()
    }()
    
    private let iconView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.masksToBounds = true
        $0.layer.cornerRadius = 5.0
        $0.tintColor = .white
    }
    
    private let soundBarButton = UIButton().then {
        $0.setImage(#imageLiteral(resourceName: "videoPlayingIndicator").withRenderingMode(.alwaysTemplate), for: .normal)
        $0.imageView?.contentMode = .scaleAspectFit
        $0.tintColor = .white
    }
    
    private let titleLabel = UILabel().then {
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.font = .systemFont(ofSize: 15.0, weight: .medium)
    }
    
    private let mediaTitleLabel = UILabel().then {
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.lineBreakMode = .byTruncatingTail
        $0.font = .systemFont(ofSize: 12.0, weight: .medium)
    }
    
    private let mediaSubtitleLabel = UILabel().then {
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.font = .systemFont(ofSize: 11.0, weight: .regular)
    }
    
    private let expandButton = UIButton().then {
        $0.setImage(#imageLiteral(resourceName: "nowPlayingExpand").withRenderingMode(.alwaysTemplate), for: .normal)
        $0.imageView?.contentMode = .scaleAspectFit
        $0.tintColor = UIColor.white
    }
    
    private let closeButton = UIButton().then {
        $0.setImage(#imageLiteral(resourceName: "nowPlayingExit").withRenderingMode(.alwaysTemplate), for: .normal)
        $0.imageView?.contentMode = .scaleAspectFit
        $0.tintColor = .white
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundBlurView.contentView.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        
        addSubview(backgroundBlurView)
        
        infoStackView.addArrangedSubview(iconView)
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(mediaInfoStackView)
        
        mediaInfoStackView.addArrangedSubview(mediaTitleLabel)
        mediaInfoStackView.addArrangedSubview(mediaSubtitleLabel)
        
        addSubview(infoStackView)
        addSubview(buttonStackView)
        
        backgroundBlurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        infoStackView.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
        }
        
        buttonStackView.snp.makeConstraints {
            $0.left.greaterThanOrEqualTo(infoStackView.snp.right).offset(25.0)
            $0.right.top.bottom.equalToSuperview()
        }
        
        [soundBarButton, expandButton, closeButton].forEach({
            $0.snp.makeConstraints {
                $0.width.equalTo(44.0)
            }
        })
        
        self.snp.makeConstraints {
            $0.height.equalTo(44.0)
        }
        
        self.isUserInteractionEnabled = true
        expandButton.addTarget(self, action: #selector(onExpand(_:)), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(onExit(_:)), for: .touchUpInside)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onAddToPlaylist(_:))).then {
            $0.numberOfTouchesRequired = 1
            $0.numberOfTapsRequired = 1
        })
        
        Playlist.shared.currentlyPlayingInfo.observe({ [weak self] _, _ in
            self?.refreshUI()
        }).bind(to: self)
        
        refreshUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let roundPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight], cornerRadii: CGSize(width: 8, height: 8))
        let maskLayer = CAShapeLayer()
        maskLayer.path = roundPath.cgPath
        layer.mask = maskLayer
    }
    
    private func createSeparator() -> UIView {
        return UIView().then {
            $0.backgroundColor = #colorLiteral(red: 0.537254902, green: 0.5411764706, blue: 0.537254902, alpha: 1)
            $0.snp.makeConstraints {
                $0.width.equalTo(1.0 / UIScreen.main.scale)
            }
        }
    }
    
    private func refreshUI() {
        mediaTitleLabel.text = Playlist.shared.currentlyPlayingInfo.value?.name
        mediaSubtitleLabel.text = URL(string: Playlist.shared.currentlyPlayingInfo.value?.pageSrc ?? "")?.baseDomain ?? Playlist.shared.currentlyPlayingInfo.value?.pageSrc
        
        setupButtons()
        
        switch state {
        case .add:
            iconView.image = #imageLiteral(resourceName: "playlistsAdd").withRenderingMode(.alwaysTemplate)
            iconView.tintColor = .white
            titleLabel.text = "Add to playlist"
            titleLabel.isHidden = false
            mediaInfoStackView.isHidden = true
            
        case .existing:
            iconView.image = #imageLiteral(resourceName: "nowPlayingCheckmark")
            titleLabel.text = "In Playlist"
            titleLabel.isHidden = false
            mediaInfoStackView.isHidden = true
            
        case .addNowPlaying:
            iconView.image = #imageLiteral(resourceName: "playlistsAdd").withRenderingMode(.alwaysTemplate)
            iconView.tintColor = .white
            titleLabel.isHidden = true
            mediaInfoStackView.isHidden = false
            
        case .addedNowPlaying:
            iconView.image = #imageLiteral(resourceName: "nowPlayingCheckmark")
            titleLabel.isHidden = true
            mediaInfoStackView.isHidden = false
            
        case .nowPlaying:
            iconView.image = #imageLiteral(resourceName: "videoPlayingIndicator")
            titleLabel.isHidden = true
            mediaInfoStackView.isHidden = false
        }
    }
    
    private func setupButtons() {
        buttonStackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        infoStackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        infoStackView.addArrangedSubview(iconView)
        
        soundBarButton.snp.remakeConstraints {
            $0.width.equalTo(44.0)
        }
        
        if state == .add || state == .existing {
            infoStackView.addArrangedSubview(titleLabel)
            infoStackView.addArrangedSubview(mediaInfoStackView)
        }
        
        if state == .addNowPlaying || state == .addedNowPlaying {
            infoStackView.addArrangedSubview(createSeparator())
            infoStackView.addArrangedSubview(soundBarButton)
            infoStackView.addArrangedSubview(mediaInfoStackView)
            
            soundBarButton.snp.remakeConstraints {
                $0.width.equalTo(20.0)
            }
        }
        
        if state == .nowPlaying {
            infoStackView.addArrangedSubview(mediaInfoStackView)
        }
        
        buttonStackView.addArrangedSubview(expandButton)
        buttonStackView.addArrangedSubview(closeButton)
    }
    
    // MARK: - Delegates
    
    @objc
    private func onAddToPlaylist(_ gestureRecognizer: UIGestureRecognizer) {
        if state == .add {
            delegate?.onAddToPlaylist()
        } else {
            delegate?.onExpand()
        }
    }
    
    @objc
    private func onExpand(_ button: UIButton) {
        delegate?.onExpand()
    }
    
    @objc
    private func onExit(_ button: UIButton) {
        delegate?.onExit()
    }
}
