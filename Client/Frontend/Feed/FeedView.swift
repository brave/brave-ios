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
    
    override func reloadData() {
        super.reloadData()
    }
}

protocol BraveTodayHeaderDelegate {
    func didTapSettings()
}

class BraveTodayHeader: UIView {
    var delegate: BraveTodayHeaderDelegate?
    
    private let blurView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let titleLabel: UILabel = UILabel()
    private let settingsButton: UIButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(blurView)
        
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        titleLabel.text = "Brave Today"
        addSubview(titleLabel)
        
        settingsButton.setImage(UIImage(named: "settings_toggles"), for: .normal)
        settingsButton.addTarget(self, action: #selector(didTapSettings), for: .touchUpInside)
        addSubview(settingsButton)
        
        let line = UIView()
        line.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        addSubview(line)
        
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.left.equalTo(safeAreaLayoutGuide).offset(20)
            $0.centerY.equalToSuperview()
        }
        
        settingsButton.snp.makeConstraints {
            $0.right.equalTo(safeAreaLayoutGuide).inset(25)
            $0.centerY.equalToSuperview()
        }
        
        line.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func didTapSettings() {
        delegate?.didTapSettings()
    }
}
