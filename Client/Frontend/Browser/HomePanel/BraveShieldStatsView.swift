/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import BraveShared

class BraveShieldStatsView: UIView, Themeable {
    func applyTheme(_ theme: Theme) {
        // BRAVE TODO:
    }
    
    fileprivate let millisecondsPerItem: Int = 50
    
    lazy var adsStatView: StatView = {
        let statView = StatView(frame: CGRect.zero)
        statView.title = Strings.ShieldsAdStats
        statView.color = UX.BraveOrange
        return statView
    }()

    lazy var trackersStatView: StatView = {
        let statView = StatView(frame: CGRect.zero)
        statView.title = Strings.ShieldsTrackerStats
        statView.color = UX.Purple
        return statView
    }()

    lazy var httpsStatView: StatView = {
        let statView = StatView(frame: CGRect.zero)
        statView.title = Strings.ShieldsHttpsStats
        statView.color = UX.Green
        return statView
    }()

    lazy var timeStatView: StatView = {
        let statView = StatView(frame: CGRect.zero)
        statView.title = Strings.ShieldsTimeStats
        statView.color = PrivateBrowsingManager.shared.isPrivateBrowsing ? UX.GreyA : UX.GreyJ
        return statView
    }()
    
    lazy var stats: [StatView] = {
        return [self.trackersStatView, self.adsStatView, self.httpsStatView, self.timeStatView]
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        for s: StatView in stats {
            addSubview(s)
        }
        
        update()
        
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: NSNotification.Name(rawValue: BraveGlobalShieldStats.DidUpdateNotification), object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func layoutSubviews() {
        let width: CGFloat = frame.width / CGFloat(stats.count)
        var offset: CGFloat = 0
        for s: StatView in stats {
            var f: CGRect = s.frame
            f.origin.x = offset
            f.size = CGSize(width: width, height: frame.height)
            s.frame = f
            offset += width
        }
    }
    
    @objc private func update() {
        adsStatView.stat = "\(BraveGlobalShieldStats.shared.adblock)"
        trackersStatView.stat = "\(BraveGlobalShieldStats.shared.trackingProtection)"
        httpsStatView.stat = "\(BraveGlobalShieldStats.shared.httpse)"
        timeStatView.stat = timeSaved
    }
    
    func applyTheme(_ themeName: String) {
        
    }
    
    var timeSaved: String {
        get {
            let estimatedMillisecondsSaved = (BraveGlobalShieldStats.shared.adblock + BraveGlobalShieldStats.shared.trackingProtection) * millisecondsPerItem
            let hours = estimatedMillisecondsSaved < 1000 * 60 * 60 * 24
            let minutes = estimatedMillisecondsSaved < 1000 * 60 * 60
            let seconds = estimatedMillisecondsSaved < 1000 * 60
            var counter: Double = 0
            var text = ""
            
            if seconds {
                counter = ceil(Double(estimatedMillisecondsSaved / 1000))
                text = Strings.ShieldsTimeStatsSeconds
            } else if minutes {
                counter = ceil(Double(estimatedMillisecondsSaved / 1000 / 60))
                text = Strings.ShieldsTimeStatsMinutes
            } else if hours {
                counter = ceil(Double(estimatedMillisecondsSaved / 1000 / 60 / 60))
                text = Strings.ShieldsTimeStatsHour
            } else {
                counter = ceil(Double(estimatedMillisecondsSaved / 1000 / 60 / 60 / 24))
                text = Strings.ShieldsTimeStatsDays
            }
            
            return "\(Int(counter))\(text)"
        }
    }
}

class StatView: UIView {
    var color: UIColor = UX.GreyJ {
        didSet {
            statLabel.textColor = color
        }
    }
    
    var stat: String = "" {
        didSet {
            statLabel.text = "\(stat)"
        }
    }
    
    var title: String = "" {
        didSet {
            titleLabel.text = "\(title)"
        }
    }
    
    fileprivate var statLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.bold)
        return label
    }()
    
    fileprivate var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UX.HomePanel.StatTitleColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(statLabel)
        addSubview(titleLabel)
        
        statLabel.snp.makeConstraints({ (make) -> Void in
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.centerY.equalTo(self).offset(-(statLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).height)-10)
        })
        
        titleLabel.snp.makeConstraints({ (make) -> Void in
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.top.equalTo(statLabel.snp.bottom).offset(5)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
