// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Storage

class TodayCardContainerView: UIView {
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
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
    case topNews = 400
    case horizontalList = 300
    case verticalList = 330
    case headlineLarge = 430
    case headlineSmall = 200
    case sponsor = 130
}

struct TodayCard {
    let type: TodayCardType
    let items: [FeedItem] // Data that lives within an individual card design.
    
    // Special Data
    let sponsorData: SponsorData?
}

class TodayCardView: TodayCardContainerView {
    convenience init(data: TodayCard) {
        self.init(frame: .zero)
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
