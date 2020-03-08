// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Storage
import Kingfisher
import pop

class TodayCardContainerView: UIView {
    fileprivate let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(blurView)
        blurView.snp.makeConstraints {
            $0.edges.equalTo(self)
        }
        
        blurView.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        blurView.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let roundPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight], cornerRadii: CGSize(width: 12, height: 12))
        let maskLayer = CAShapeLayer()
        maskLayer.path = roundPath.cgPath
        blurView.layer.mask = maskLayer
    }
}

enum TodayCardType: CGFloat {
    case horizontalList = 350
    case verticalList = 360
    case verticalListBranded = 440
    case verticalListNumbered = 420
    case headlineLarge = 410
    case headlineSmall = 260
    case adSmall = 140
    case adLarge = 380
}

struct TodayCard {
    let type: TodayCardType
    let items: [FeedItem] // Data that lives within an individual card design.
    
    // Special Data
    let sponsorData: SponsorData?
    let mainTitle: String?
}

class TodayCardView: TodayCardContainerView {
    var data: TodayCard?
    
    var cardTitleLabel: UILabel?
    var imageView: UIImageView?
    
    convenience init(data: TodayCard) {
        self.init(frame: .zero)
        self.data = data
        
        prepare()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func prepare() {
        if let data = data {
            
            if data.mainTitle?.isEmpty == false {
                let cardTitleLabel = UILabel()
                blurView.contentView.addSubview(cardTitleLabel)
                
                self.cardTitleLabel = cardTitleLabel
                self.cardTitleLabel?.snp.makeConstraints {
                    $0.top.equalTo(5)
                    $0.left.right.equalTo(5)
                }
            }
            
            switch data.type {
            case .horizontalList:
                generateHorizontalListLayout()
            case .verticalList:
                generateVerticalListLayout()
            case .verticalListBranded:
                generateVerticalListBrandedLayout()
            case .verticalListNumbered:
                generateVerticalListNumberedLayout()
            case .headlineLarge:
                generateHeadlineLargeLayout()
            case .headlineSmall:
                generateHeadlineSmallLayout()
            case .adSmall:
                generateAdSmallLayout()
            case .adLarge:
                generateAdLargeLayout()
            }
        }
    }
    
    private func generateHorizontalListLayout() {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 21, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.text = data?.mainTitle
        blurView.contentView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(20)
            $0.left.right.equalToSuperview().inset(20)
        }
        
        if let item = data?.items[0] {
            let contentView = TodayCardContentView(data: item, layout: .verticalSmallInset, delegate: self)
            blurView.contentView.addSubview(contentView)
            
            contentView.snp.makeConstraints {
                $0.left.equalToSuperview().inset(20)
                $0.width.equalToSuperview().inset(10).multipliedBy(0.33).priority(999)
                $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            }
        }
        
        if let item = data?.items[1] {
            let contentView = TodayCardContentView(data: item, layout: .verticalSmallInset, delegate: self)
            blurView.contentView.addSubview(contentView)
            
            contentView.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.width.equalToSuperview().inset(10).multipliedBy(0.33).priority(999)
                $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            }
        }
        
        if let item = data?.items[2] {
            let contentView = TodayCardContentView(data: item, layout: .verticalSmallInset, delegate: self)
            blurView.contentView.addSubview(contentView)
            
            contentView.snp.makeConstraints {
                $0.right.equalToSuperview().inset(20)
                $0.width.equalToSuperview().inset(10).multipliedBy(0.33).priority(999)
                $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            }
        }
    }
    
    private func generateVerticalListLayout() {
        if let item = data?.items[0] {
            let contentView = TodayCardContentView(data: item, layout: .horizontal, delegate: self)
            blurView.contentView.addSubview(contentView)
            
            contentView.snp.makeConstraints {
                $0.top.equalTo(20)
                $0.left.right.equalToSuperview().inset(20)
                $0.height.equalToSuperview().inset(10).multipliedBy(0.33).priority(999)
            }
        }
        
        if let item = data?.items[1] {
            let contentView = TodayCardContentView(data: item, layout: .horizontal, delegate: self)
            blurView.contentView.addSubview(contentView)
            
            contentView.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.left.right.equalToSuperview().inset(20)
                $0.height.equalToSuperview().inset(10).multipliedBy(0.33).priority(999)
            }
        }
        
        if let item = data?.items[2] {
            let contentView = TodayCardContentView(data: item, layout: .horizontal, delegate: self)
            blurView.contentView.addSubview(contentView)
            
            contentView.snp.makeConstraints {
                $0.bottom.equalToSuperview().inset(20)
                $0.left.right.equalToSuperview().inset(20)
                $0.height.equalToSuperview().inset(10).multipliedBy(0.33).priority(999)
            }
        }
    }
    
    private func generateVerticalListBrandedLayout() {
        // TODO: needs work
        
        if let item = data?.items[0] {
            let contentView = TodayCardContentView(data: item, layout: .horizontal, delegate: self)
            blurView.contentView.addSubview(contentView)
            
            contentView.snp.makeConstraints {
                $0.top.equalTo(20)
                $0.left.right.equalToSuperview().inset(20)
                $0.height.equalToSuperview().inset(10).multipliedBy(0.33).priority(999)
            }
        }
        
        if let item = data?.items[1] {
            let contentView = TodayCardContentView(data: item, layout: .horizontal, delegate: self)
            blurView.contentView.addSubview(contentView)
            
            contentView.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.left.right.equalToSuperview().inset(20)
                $0.height.equalToSuperview().inset(10).multipliedBy(0.33).priority(999)
            }
        }
        
        if let item = data?.items[2] {
            let contentView = TodayCardContentView(data: item, layout: .horizontal, delegate: self)
            blurView.contentView.addSubview(contentView)
            
            contentView.snp.makeConstraints {
                $0.bottom.equalToSuperview().inset(20)
                $0.left.right.equalToSuperview().inset(20)
                $0.height.equalToSuperview().inset(10).multipliedBy(0.33).priority(999)
            }
        }
    }
    
    private func generateVerticalListNumberedLayout() {
        // TODO: needs work
        
        if let item = data?.items[0] {
            let contentView = TodayCardContentView(data: item, layout: .horizontal, delegate: self)
            blurView.contentView.addSubview(contentView)
            
            contentView.snp.makeConstraints {
                $0.top.equalTo(20)
                $0.left.right.equalToSuperview().inset(20)
                $0.height.equalToSuperview().inset(10).multipliedBy(0.33).priority(999)
            }
        }
        
        if let item = data?.items[1] {
            let contentView = TodayCardContentView(data: item, layout: .horizontal, delegate: self)
            blurView.contentView.addSubview(contentView)
            
            contentView.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.left.right.equalToSuperview().inset(20)
                $0.height.equalToSuperview().inset(10).multipliedBy(0.33).priority(999)
            }
        }
        
        if let item = data?.items[2] {
            let contentView = TodayCardContentView(data: item, layout: .horizontal, delegate: self)
            blurView.contentView.addSubview(contentView)
            
            contentView.snp.makeConstraints {
                $0.bottom.equalToSuperview().inset(20)
                $0.left.right.equalToSuperview().inset(20)
                $0.height.equalToSuperview().inset(10).multipliedBy(0.33).priority(999)
            }
        }
    }
    
    private func generateHeadlineLargeLayout() {
        guard let item = data?.items.first else { return }
        
        let contentView = TodayCardContentView(data: item, layout: .verticalLarge, delegate: self)
        blurView.contentView.addSubview(contentView)
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func generateHeadlineSmallLayout() {
        guard let item = data?.items.first else { return }
        
        let contentView = TodayCardContentView(data: item, layout: .verticalSmall, delegate: self)
        blurView.contentView.addSubview(contentView)
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func generateAdSmallLayout() {
        guard let item = data?.items.first else { return }
        
        let contentView = TodayCardContentView(data: item, layout: .image, delegate: self)
        blurView.contentView.addSubview(contentView)
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func generateAdLargeLayout() {
        guard let item = data?.items.first else { return }
        
        let contentView = TodayCardContentView(data: item, layout: .image, delegate: self)
        blurView.contentView.addSubview(contentView)
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    fileprivate func bounceOnLayer(layer: CALayer) {
        if let anim = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY) {
            anim.toValue = NSValue(cgSize: CGSize(width: 0.95, height: 0.95))
            anim.autoreverses = true
            anim.springBounciness = 4
            anim.springSpeed = 20
            anim.repeatCount = 1
            layer.pop_add(anim, forKey: "size")
        }
    }
}

extension TodayCardView: TodayCardContentDelegate {
    func didTapCardContentView(view: TodayCardContentView, target: TodayCardAnimationTarget) {
        switch target {
        case .card:
            bounceOnLayer(layer: self.layer)
        case .content:
            bounceOnLayer(layer: view.layer)
        }
        
        let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
        impactFeedbackgenerator.prepare()
        impactFeedbackgenerator.impactOccurred()
    }
}

enum TodayCardAnimationTarget {
    case card
    case content
}

// Used for all types except publisher
enum TodayCardContentLayout {
    case verticalLarge
    case verticalSmall
    case verticalSmallInset // used for horizontal lists
    case horizontal // fills vertical lists w/ or w/out image
    case image // ads
}

protocol TodayCardContentDelegate {
    func didTapCardContentView(view: TodayCardContentView, target: TodayCardAnimationTarget)
}

class TodayCardContentView: UIView {
    var data: FeedItem!
    var layout: TodayCardContentLayout!
    var delegate: TodayCardContentDelegate?
    
    private var imageView: UIImageView?
    
    required convenience init(data: FeedItem, layout: TodayCardContentLayout, delegate: TodayCardContentDelegate?) {
        self.init(frame: .zero)
        self.data = data
        self.layout = layout
        self.delegate = delegate
        
        prepare()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func prepare() {
        switch layout {
        case .verticalLarge:
            layoutVerticalLarge()
        case .verticalSmall:
            layoutVerticalSmall()
        case .verticalSmallInset:
            layoutVerticalSmallInset()
        case .horizontal:
            layoutHorizontal()
        case .image:
            layoutImage()
        default:
            break
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        addGestureRecognizer(tap)
    }
    
    @objc func tapped() {
        guard let tabManager = (UIApplication.shared.delegate as? AppDelegate)?.browserViewController.tabManager else {
            return
        }
        
        guard let url = URL(string: data.url) else { return }
        
        let request = URLRequest(url: url)
        if let tab = tabManager.selectedTab {
            tab.loadRequest(request)
        }
        
        switch layout {
        case .verticalLarge, .verticalSmall, .image:
            delegate?.didTapCardContentView(view: self, target: .card)
        case .verticalSmallInset, .horizontal:
            delegate?.didTapCardContentView(view: self, target: .content)
        default:
            break
        }
    }
    
    private func layoutVerticalLarge() {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor(rgb: 0xBCBCBC).withAlphaComponent(0.2)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
            
        imageView.snp.makeConstraints {
            $0.top.left.right.equalTo(0)
            $0.height.equalTo(270)
        }
        
        self.imageView = imageView
        
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 3
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.text = data.title
        addSubview(headlineLabel)
        
        headlineLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(12)
            $0.left.right.equalToSuperview().inset(20)
        }
        
        let timeAgoLabel = UILabel()
        timeAgoLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        timeAgoLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        timeAgoLabel.numberOfLines = 1
        timeAgoLabel.text = Date.fromTimestamp(data.publishTime).toRelativeTimeString()
        addSubview(timeAgoLabel)
        
        timeAgoLabel.snp.makeConstraints {
            $0.top.equalTo(headlineLabel.snp.bottom).offset(4)
            $0.left.right.equalToSuperview().inset(20)
        }
        
        let publisherLabel = UILabel()
        publisherLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        publisherLabel.textColor = .white
        publisherLabel.numberOfLines = 1
        publisherLabel.text = data.publisherName
        addSubview(publisherLabel)
        
        publisherLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(15)
            $0.left.right.equalToSuperview().inset(20)
        }
        
        layoutSubviews()
        loadImage(urlString: data.img)
    }
    
    private func layoutVerticalSmall() {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor(rgb: 0xBCBCBC).withAlphaComponent(0.2)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
            
        imageView.snp.makeConstraints {
            $0.top.left.right.equalTo(0)
            $0.height.equalTo(115)
        }
        
        self.imageView = imageView
        
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 4
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.text = data.title
        addSubview(headlineLabel)
        
        headlineLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(12)
            $0.left.right.equalToSuperview().inset(12)
        }
        
        let timeAgoLabel = UILabel()
        timeAgoLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        timeAgoLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        timeAgoLabel.numberOfLines = 1
        timeAgoLabel.text = Date.fromTimestamp(data.publishTime).toRelativeTimeString()
        addSubview(timeAgoLabel)
        
        timeAgoLabel.snp.makeConstraints {
            $0.top.equalTo(headlineLabel.snp.bottom).offset(4)
            $0.left.right.equalToSuperview().inset(12)
        }
        
        let publisherLabel = UILabel()
        publisherLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        publisherLabel.textColor = .white
        publisherLabel.numberOfLines = 1
        publisherLabel.text = data.publisherName
        addSubview(publisherLabel)
        
        publisherLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(12)
            $0.left.right.equalToSuperview().inset(12)
        }
        
        layoutSubviews()
        loadImage(urlString: data.img)
    }
    
    private func layoutVerticalSmallInset() {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor(rgb: 0xBCBCBC).withAlphaComponent(0.2)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        addSubview(imageView)
            
        imageView.snp.makeConstraints {
            $0.top.left.right.equalTo(0)
            $0.height.equalTo(98)
        }
        
        self.imageView = imageView
        
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 5
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.text = data.title
        addSubview(headlineLabel)
        
        headlineLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(12)
            $0.left.right.equalTo(0)
        }
        
        let timeAgoLabel = UILabel()
        timeAgoLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        timeAgoLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        timeAgoLabel.numberOfLines = 1
        timeAgoLabel.text = Date.fromTimestamp(data.publishTime).toRelativeTimeString()
        addSubview(timeAgoLabel)
        
        timeAgoLabel.snp.makeConstraints {
            $0.top.equalTo(headlineLabel.snp.bottom).offset(4)
            $0.left.right.equalTo(0)
            $0.bottom.equalTo(0)
        }
        
        layoutSubviews()
        loadImage(urlString: data.img)
    }
    
    private func layoutHorizontal() {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor(rgb: 0xBCBCBC).withAlphaComponent(0.2)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        addSubview(imageView)
            
        imageView.snp.makeConstraints {
            $0.right.top.bottom.equalTo(0)
            $0.size.equalTo(98)
        }
        
        self.imageView = imageView
        
        let textContainer = UIView()
        addSubview(textContainer)
        
        textContainer.snp.makeConstraints {
            $0.left.equalTo(0)
            $0.right.equalTo(imageView.snp.left).inset(-20)
            $0.centerY.equalTo(imageView)
        }
        
        let publisherLabel = UILabel()
        publisherLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        publisherLabel.textColor = .white
        publisherLabel.numberOfLines = 1
        publisherLabel.text = data.publisherName
        textContainer.addSubview(publisherLabel)
        
        publisherLabel.snp.makeConstraints {
            $0.top.equalTo(0)
            $0.left.right.equalTo(0)
        }
        
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 3
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.text = data.title
        textContainer.addSubview(headlineLabel)
        
        headlineLabel.snp.makeConstraints {
            $0.top.equalTo(publisherLabel.snp.bottom).offset(6)
            $0.left.right.equalTo(0)
        }
        
        let timeAgoLabel = UILabel()
        timeAgoLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        timeAgoLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        timeAgoLabel.numberOfLines = 1
        timeAgoLabel.text = Date.fromTimestamp(data.publishTime).toRelativeTimeString()
        textContainer.addSubview(timeAgoLabel)
        
        timeAgoLabel.snp.makeConstraints {
            $0.top.equalTo(headlineLabel.snp.bottom).offset(4)
            $0.left.right.bottom.equalTo(0)
        }
        
        layoutSubviews()
        
        if data.img.isEmpty == false {
            loadImage(urlString: data.img)
        } else {
            imageView.alpha = 0
        }
    }
    
    private func layoutImage() {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor(rgb: 0xBCBCBC).withAlphaComponent(0.2)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        addSubview(imageView)
            
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        self.imageView = imageView
        
        layoutSubviews()
        loadImage(urlString: data.img)
    }
    
    private func loadImage(urlString: String) {
        guard let imageView = imageView, urlString.isEmpty == false else { return }
        
        let url = URL(string: urlString)
        
        if url?.pathExtension == "gif" {
            imageView.image = UIImage.gifImageWithURL(urlString)
        } else {
            imageView.kf.indicatorType = .activity
            imageView.kf.setImage(
                with: url,
                placeholder: nil,
                options: [
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ]) { result in
                switch result {
                case .success(let value):
                    print("Task done for: \(value.source.url?.absoluteString ?? "")")
                case .failure(let error):
                    print("Job failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
