// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class FeedView: UITableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        
        bounces = true
        register(FeedCell.self, forCellReuseIdentifier: "FeedCell")
        isScrollEnabled = true
        showsVerticalScrollIndicator = false
        separatorStyle = .none
        backgroundColor = .clear
        tableFooterView = UIView()
        cellLayoutMarginsFollowReadableWidth = true
        accessibilityIdentifier = "Feed"
        estimatedRowHeight = 100
        sectionHeaderHeight = 0
        sectionFooterHeight = 0
        
        let footer = UIView(frame: CGRect(width: UIScreen.main.bounds.width, height: 20))
        tableFooterView = footer
        
        if #available(iOS 13.0, *) {
            automaticallyAdjustsScrollIndicatorInsets = false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
