// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared

extension ShieldsViewController {
    class View: UIView, Themeable {
        
        private let scrollView = UIScrollView().then {
            $0.delaysContentTouches = false
        }
        
        var contentView: UIView? {
            didSet {
                oldValue?.removeFromSuperview()
                if let view = contentView {
                    scrollView.addSubview(view)
                    view.snp.makeConstraints {
                        $0.edges.equalToSuperview()
                    }
                }
            }
        }
        
        let stackView = UIStackView().then {
            $0.axis = .vertical
            $0.isLayoutMarginsRelativeArrangement = true
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let simpleShieldView = SimpleShieldsView()
        let advancedControlsBar = AdvancedControlsBarView()
        let advancedShieldView = AdvancedShieldsView().then {
            $0.isHidden = true
        }
        
        let reportBrokenSiteView = ReportBrokenSiteView()
        let siteReportedView = SiteReportedView()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            stackView.addArrangedSubview(simpleShieldView)
            stackView.addArrangedSubview(advancedControlsBar)
            stackView.addArrangedSubview(advancedShieldView)
            
            addSubview(scrollView)
            scrollView.addSubview(stackView)
            
            scrollView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            
            scrollView.contentLayoutGuide.snp.makeConstraints {
                $0.left.right.equalTo(self)
            }
            
            stackView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            
            contentView = stackView
        }
        
        func applyTheme(_ theme: Theme) {
            simpleShieldView.applyTheme(theme)
            advancedControlsBar.applyTheme(theme)
            advancedShieldView.applyTheme(theme)
            reportBrokenSiteView.applyTheme(theme)
            
            backgroundColor = theme.isDark ? UIColor(rgb: 0x17171f) : UIColor.white
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError()
        }
    }
    
    /*
    /// The custom loaded view for the `ShieldsViewController`
    class View: UIView, Themeable {
        private let scrollView = UIScrollView()
        
        let stackView: UIStackView = {
            let sv = UIStackView()
            sv.axis = .vertical
            sv.spacing = 15.0
            sv.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            sv.isLayoutMarginsRelativeArrangement = true
            sv.translatesAutoresizingMaskIntoConstraints = false
            return sv
        }()
        
        let overviewStackView: OverviewContainerStackView = {
            let sv = OverviewContainerStackView()
            sv.isHidden = true
            return sv
        }()
        
        let shieldsContainerStackView = ShieldsContainerStackView()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            stackView.addArrangedSubview(overviewStackView)
            stackView.addArrangedSubview(shieldsContainerStackView)
            
            addSubview(scrollView)
            scrollView.addSubview(stackView)
        }
        
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            scrollView.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
            
            scrollView.contentLayoutGuide.snp.remakeConstraints {
                $0.left.right.equalTo(self)
            }
            
            stackView.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
        }
        
        // MARK: - Themeable
        func applyTheme(_ theme: Theme) {
            styleChildren(theme: theme)
            
            backgroundColor = theme.colors.home
            
            // Overview
            overviewStackView.overviewFooterLabel.textColor = overviewStackView.overviewLabel.textColor.withAlphaComponent(0.6)
            
            // Normal shields panel
            shieldsContainerStackView.set(theme: theme)
        }
    }
    
    class OverviewContainerStackView: UIStackView {
        
        let overviewLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 15.0)
            label.text = Strings.shieldsOverview
            return label
        }()
        
        let overviewFooterLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 15.0)
            label.text = Strings.shieldsOverviewFooter
            return label
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            axis = .vertical
            spacing = 15.0
            
            addArrangedSubview(overviewLabel)
            addArrangedSubview(overviewFooterLabel)
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError()
        }
    }
    
    class ShieldsContainerStackView: UIStackView {
        /// Create a header label
        private class func headerLabel(title: String) -> UILabel {
            let label = UILabel()
            label.font = .systemFont(ofSize: 15.0)
            label.text = title
            return label
        }
        
        private class func dividerView() -> UIView {
            let divider = UIView()
            divider.backgroundColor = BraveUX.colorForSidebarLineSeparators
            divider.snp.makeConstraints { $0.height.equalTo(1.0 / UIScreen.main.scale) }
            return divider
        }
        
        // Site Host Label
        let hostLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 21.0, weight: .medium)
            label.lineBreakMode = .byTruncatingMiddle
            label.minimumScaleFactor = 0.75
            label.adjustsFontSizeToFitWidth = true
            return label
        }()
        
        // Stats
        let statsHeaderLabel = headerLabel(title: Strings.blockingMonitor)
        let adsTrackersStatView = StatView(title: Strings.adsAndTrackers)
        let httpsUpgradesStatView = StatView(title: Strings.HTTPSUpgrades)
        let scriptsBlockedStatView = StatView(title: Strings.scriptsBlocked)
        let fingerprintingStatView = StatView(title: Strings.fingerprintingMethods)
        
        // Settings
        let settingsDivider = dividerView()
        let settingsHeaderLabel = headerLabel(title: Strings.individualControls)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            axis = .vertical
            spacing = 15.0
            
            // Stats
            addArrangedSubview(hostLabel)
            addArrangedSubview(statsHeaderLabel)
            setCustomSpacing(15.0, after: statsHeaderLabel)
            let statViews = [adsTrackersStatView, httpsUpgradesStatView, scriptsBlockedStatView, fingerprintingStatView]
            statViews.forEach {
                addArrangedSubview($0)
                if $0 !== statViews.last {
                    setCustomSpacing(3.0, after: $0)
                }
            }
            
            // Controls
            addArrangedSubview(settingsDivider)
            addArrangedSubview(settingsHeaderLabel)
            
            [adsTrackersControl, httpsUpgradesControl, blockMalwareControl, blockScriptsControl, fingerprintingControl].forEach {
                addArrangedSubview($0)
                setCustomSpacing(18.0, after: $0)
            }
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError()
        }
        
        func set(theme: Theme) {
            let stats = theme.colors.stats
            [
                adsTrackersStatView: stats.ads,
                httpsUpgradesStatView: stats.httpse,
                scriptsBlockedStatView: stats.trackers
            ].forEach {
                $0.0.valueLabel.appearanceTextColor = $0.1
            }
            
            let faddedColor = theme.colors.tints.home.withAlphaComponent(0.8)
            statsHeaderLabel.appearanceTextColor = faddedColor
            settingsHeaderLabel.appearanceTextColor = faddedColor
        }
    }
    
    /// Displays some UI that displays the block count of a stat. Set `valueLabel.text` to the stat
    class StatView: UIView {
        /// The number the shield has blocked
        let valueLabel: UILabel = {
            let l = UILabel()
            l.font = .boldSystemFont(ofSize: 28.0)
            l.adjustsFontSizeToFitWidth = true
            l.textAlignment = .center
            l.text = "0"
            return l
        }()
        /// The stat being blocked (i.e. Ads and Trackers)
        let titleLabel: UILabel = {
            let l = UILabel()
            l.font = .systemFont(ofSize: 15.0)
            l.adjustsFontSizeToFitWidth = true
            l.numberOfLines = 0
            return l
        }()
        /// Create the stat view with a given title
        init(title: String) {
            super.init(frame: .zero)
            titleLabel.text = title
            
            addSubview(valueLabel)
            addSubview(titleLabel)
            
            translatesAutoresizingMaskIntoConstraints = false
            titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            valueLabel.snp.makeConstraints {
                $0.width.equalTo(50.0)
                $0.top.bottom.equalTo(self)
                $0.left.equalTo(self)
            }
            titleLabel.snp.makeConstraints {
                $0.left.equalTo(valueLabel.snp.right).offset(12)
                $0.top.bottom.equalTo(self)
                $0.right.equalTo(self)
            }
        }
        
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }
    }*/
}

extension ShieldsViewController {

    var closeActionAccessibilityLabel: String {
        return Strings.Popover.closeShieldsMenu
    }
}
