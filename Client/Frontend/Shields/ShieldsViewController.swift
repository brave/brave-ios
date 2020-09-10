// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Storage
import SnapKit
import Shared
import BraveShared
import Data
import BraveUI

/// Displays shield settings and shield stats for a given URL
class ShieldsViewController: UIViewController, PopoverContentComponent {
    
    let tab: Tab
    private lazy var url: URL? = {
        guard let _url = tab.url else { return nil }
        
        if _url.isErrorPageURL {
            return _url.originalURLFromErrorURL
        }
        
        return _url
    }()
    
    var shieldsSettingsChanged: ((ShieldsViewController) -> Void)?
    
    private var statsUpdateObservable: AnyObject?
    
    /// Create with an initial URL and block stats (or nil if you are not on any web page)
    init(tab: Tab) {
        self.tab = tab
        
        super.init(nibName: nil, bundle: nil)
        
        tab.contentBlocker.statsDidChange = { [weak self] _ in
            self?.updateShieldBlockStats()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private var shieldsUpSwitch: ShieldsSwitch {
        return shieldsView.simpleShieldView.shieldsSwitch
    }
    
    // MARK: - State
    
    private func updateToggleStatus() {
        var domain: Domain?
        if let url = url {
            let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
            domain = Domain.getOrCreate(forUrl: url, persistent: !isPrivateBrowsing)
        }

        if let domain = domain {
            shieldsUpSwitch.isOn = !domain.isShieldExpected(.AllOff, considerAllShieldsOption: false)
        } else {
            shieldsUpSwitch.isOn = true
        }
        
        shieldControlMapping.forEach { shield, view, option in
            // Updating based on global settings
            if let option = option {
                // Sets the default setting
                view.toggleSwitch.isOn = option.value
            }
            // Domain specific overrides after defaults have already been setup
            
            if let domain = domain {
                // site-specific shield has been overridden, update
                view.toggleSwitch.isOn = domain.isShieldExpected(shield, considerAllShieldsOption: false)
            }
        }
        updateGlobalShieldState(shieldsUpSwitch.isOn)
    }
    
    private func updateShieldBlockStats() {
        shieldsView.simpleShieldView.blockCountLabel.text = String(
            tab.contentBlocker.stats.adCount +
            tab.contentBlocker.stats.trackerCount +
            tab.contentBlocker.stats.httpsCount +
            tab.contentBlocker.stats.scriptCount +
            tab.contentBlocker.stats.fingerprintingCount
        )
    }
    
    private func updateBraveShieldState(shield: BraveShield, on: Bool, option: Preferences.Option<Bool>?) {
        guard let url = url else { return }
        let allOff = shield == .AllOff
        // `.AllOff` uses inverse logic. Technically we set "all off" when the switch is OFF, unlike all the others
        // If the new state is the same as the global preference, reset it to nil so future shield state queries
        // respect the global preference rather than the overridden value. (Prevents toggling domain state from
        // affecting future changes to the global pref)
        let isOn = allOff ? !on : on
        Domain.setBraveShield(forUrl: url, shield: shield, isOn: isOn,
                              isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing)
    }
    
    private func updateGlobalShieldState(_ on: Bool, animated: Bool = false) {
        shieldsView.simpleShieldView.statusLabel.text = on ?
            Strings.braveShieldsStatusValueUp.uppercased() :
            Strings.braveShieldsStatusValueDown.uppercased()
        
        // Whether or not shields are available for this URL.
        let isShieldsAvailable = url?.isLocal == false
        // If shields aren't available, we don't show the switch and show the "off" state
        let shieldsEnabled = isShieldsAvailable ? on : false
        if animated {
            var partOneViews: [UIView]
            var partTwoViews: [UIView]
            if shieldsEnabled {
                partOneViews = [self.shieldsView.simpleShieldView.shieldsDownStackView]
                partTwoViews = [
                    self.shieldsView.simpleShieldView.blockCountStackView,
                    self.shieldsView.simpleShieldView.footerLabel,
                    self.shieldsView.advancedControlsBar
                ]
                if advancedControlsShowing {
                    partTwoViews.append(self.shieldsView.advancedShieldView)
                }
            } else {
                partOneViews = [
                    self.shieldsView.simpleShieldView.blockCountStackView,
                    self.shieldsView.simpleShieldView.footerLabel,
                    self.shieldsView.advancedControlsBar,
                ]
                if advancedControlsShowing {
                    partOneViews.append(self.shieldsView.advancedShieldView)
                }
                partTwoViews = [self.shieldsView.simpleShieldView.shieldsDownStackView]
            }
            // Step 1, hide
            UIView.animate(withDuration: 0.1, animations: {
                partOneViews.forEach { $0.alpha = 0.0 }
            }, completion: { _ in
                partOneViews.forEach {
                    $0.alpha = 1.0
                    $0.isHidden = true
                }
                partTwoViews.forEach {
                    $0.alpha = 0.0
                    $0.isHidden = false
                }
                UIView.animate(withDuration: 0.15, animations: {
                    partTwoViews.forEach { $0.alpha = 1.0 }
                })
                
                self.updatePreferredContentSize()
            })
        } else {
            shieldsView.simpleShieldView.blockCountStackView.isHidden = !shieldsEnabled
            shieldsView.simpleShieldView.footerLabel.isHidden = !shieldsEnabled
            shieldsView.simpleShieldView.shieldsDownStackView.isHidden = shieldsEnabled
            shieldsView.advancedControlsBar.isHidden = !shieldsEnabled
            
            updatePreferredContentSize()
        }
    }
    
    private func updatePreferredContentSize() {
        shieldsView.stackView.setNeedsLayout()
        shieldsView.stackView.layoutIfNeeded()
        
        preferredContentSize = shieldsView.stackView.systemLayoutSizeFitting(
            UIScreen.main.bounds.size,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
    
    // MARK: -
    
    /// Groups the shield types with their control and global preference
    private lazy var shieldControlMapping: [(BraveShield, AdvancedShieldsView.ToggleView, Preferences.Option<Bool>?)] = [
        (.AdblockAndTp, shieldsView.advancedShieldView.adsTrackersControl, Preferences.Shields.blockAdsAndTracking),
        (.SafeBrowsing, shieldsView.advancedShieldView.blockMalwareControl, Preferences.Shields.blockPhishingAndMalware),
        (.NoScript, shieldsView.advancedShieldView.blockScriptsControl, Preferences.Shields.blockScripts),
        (.HTTPSE, shieldsView.advancedShieldView.httpsUpgradesControl, Preferences.Shields.httpsEverywhere),
        (.FpProtection, shieldsView.advancedShieldView.fingerprintingControl, Preferences.Shields.fingerprintingProtection),
    ]
    
    var shieldsView: View2 {
        return view as! View2 // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View2()
        shieldsView.applyTheme(Theme.of(tab))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        shieldsView.simpleShieldView.hostLabel.text = url?.normalizedHost()
        shieldsView.simpleShieldView.shieldsSwitch.addTarget(self, action: #selector(shieldsOverrideSwitchValueChanged), for: .valueChanged)
        shieldsView.advancedShieldView.siteTitle.titleLabel.text = url?.normalizedHost()?.uppercased()
        
        shieldsView.advancedControlsBar.addTarget(self, action: #selector(tappedAdvancedControlsBar), for: .touchUpInside)
        shieldsView.simpleShieldView.blockCountInfoButton.addTarget(self, action: #selector(tappedAboutShieldsButton), for: .touchUpInside)
        
        updateShieldBlockStats()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        updateToggleStatus()
        
        shieldControlMapping.forEach { shield, toggle, option in
            toggle.valueToggled = { [unowned self] on in
                // Localized / per domain toggles triggered here
                self.updateBraveShieldState(shield: shield, on: on, option: option)
                self.shieldsSettingsChanged?(self)
            }
        }
    }
    
    @objc private func shieldsOverrideSwitchValueChanged() {
        let isOn = shieldsUpSwitch.isOn
        self.updateGlobalShieldState(isOn, animated: true)
        self.updateBraveShieldState(shield: .AllOff, on: isOn, option: nil)
        self.shieldsSettingsChanged?(self)
    }
    
    private var advancedControlsShowing: Bool = false
    
    @objc private func tappedAdvancedControlsBar() {
        advancedControlsShowing.toggle()
        UIView.animate(withDuration: 0.25) {
            self.shieldsView.advancedShieldView.isHidden.toggle()
        }
        updatePreferredContentSize()
    }
    
    @objc private func tappedAboutShieldsButton() {
        let aboutShields = AboutShieldsViewController(tab: tab)
        aboutShields.preferredContentSize = preferredContentSize
        navigationController?.pushViewController(aboutShields, animated: true)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
