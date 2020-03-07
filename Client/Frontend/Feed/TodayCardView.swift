// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Storage
import Kingfisher

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
    case sponsor = 140
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
            case .sponsor:
                generateSponsorLayout()
            }
        }
    }
    
    private func generateHorizontalListLayout() {
        
    }
    
    private func generateVerticalListLayout() {
        
    }
    
    private func generateVerticalListBrandedLayout() {
        
    }
    
    private func generateVerticalListNumberedLayout() {
        
    }
    
    private func generateHeadlineLargeLayout() {
        guard let item = data?.items.first else { return }
        
        let contentView = TodayCardContentView(data: item, layout: .verticalLarge)
        blurView.contentView.addSubview(contentView)
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func generateHeadlineSmallLayout() {
        guard let item = data?.items.first else { return }
        
        let contentView = TodayCardContentView(data: item, layout: .verticalSmall)
        blurView.contentView.addSubview(contentView)
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func generateSponsorLayout() {
        let imageView = UIImageView()
        blurView.contentView.addSubview(imageView)
        
        self.imageView = imageView
        self.imageView?.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

// Used for all types except publisher
enum TodayCardContentLayout {
    case verticalLarge
    case verticalSmall
    case verticalSmallInset // used for horizontal lists
    case horizontal // fills vertical lists w/ or w/out image
}

class TodayCardContentView: UIView {
    var data: FeedItem!
    var layout: TodayCardContentLayout!
    
    private var imageView: UIImageView?
//    private var headlineLabel: UILabel?
//    private var timeAgoLabel: UILabel?
//    private var publisherLabel: UILabel?
//    private var publisherLogo: UIImageView?
//    private var optionsButton: UIButton?
    
    required convenience init(data: FeedItem, layout: TodayCardContentLayout) {
        self.init(frame: .zero)
        self.data = data
        self.layout = layout
        
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
        publisherLabel.text = data.feedSource
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
        publisherLabel.text = data.feedSource
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
        addSubview(imageView)
            
        imageView.snp.makeConstraints {
            $0.top.left.right.equalTo(0)
            $0.height.equalTo(270)
        }
        
        self.imageView = imageView
        
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 2
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
        publisherLabel.text = data.feedSource
        addSubview(publisherLabel)
        
        publisherLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(15)
            $0.left.right.equalToSuperview().inset(20)
        }
        
        layoutSubviews()
        loadImage(urlString: data.img)
    }
    
    private func layoutHorizontal() {
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
        headlineLabel.numberOfLines = 2
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
        publisherLabel.text = data.feedSource
        addSubview(publisherLabel)
        
        publisherLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(15)
            $0.left.right.equalToSuperview().inset(20)
        }
        
        layoutSubviews()
        loadImage(urlString: data.img)
    }
    
    private func loadImage(urlString: String) {
        guard let imageView = imageView, urlString.isEmpty == false else { return }
        
        let url = URL(string: urlString)
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
