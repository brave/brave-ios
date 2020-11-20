// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import BraveUI
import BraveShared
import Shared

private let log = Logger.rewardsLogger

class BraveRewardsViewController: UIViewController, Themeable, PopoverContentComponent {
    enum Action {
        case rewardsTransferTapped
        case unverifiedPublisherLearnMoreTapped
    }
    
    let tab: Tab
    let rewards: BraveRewards
    let legacyWallet: BraveLedger?
    var actionHandler: ((Action) -> Void)?
    
    private var ledgerObserver: LedgerObserver?
    private var publisher: PublisherInfo? {
        didSet {
            let isVerified = publisher?.status == .verified
            rewardsView.publisherView.learnMoreButton.isHidden = isVerified
            rewardsView.publisherView.hostLabel.attributedText = publisher?.attributedDisplayName(fontSize: BraveRewardsPublisherView.UX.hostLabelFontSize)
            rewardsView.publisherView.bodyLabel.text = isVerified ? Strings.Rewards.supportingPublisher : Strings.Rewards.unverifiedPublisher
            if !isVerified {
                rewardsView.publisherView.faviconImageView.clearMonogramFavicon()
                rewardsView.publisherView.faviconImageView.image = #imageLiteral(resourceName: "rewards-panel-unverified-pub").withRenderingMode(.alwaysOriginal)
                rewardsView.publisherView.faviconImageView.contentMode = .center
            } else {
                if let url = tab.url {
                    rewardsView.publisherView.faviconImageView.contentMode = .scaleAspectFit
                    rewardsView.publisherView.faviconImageView.loadFavicon(for: url)
                } else {
                    rewardsView.publisherView.faviconImageView.isHidden = true
                }
            }
        }
    }
    
    private var supportedListCount: Int = 0
    
    init(tab: Tab, rewards: BraveRewards, legacyWallet: BraveLedger?) {
        self.tab = tab
        self.rewards = rewards
        self.legacyWallet = legacyWallet
        
        super.init(nibName: nil, bundle: nil)
        
        let observer = LedgerObserver(ledger: rewards.ledger)
        rewards.ledger.add(observer)
        ledgerObserver = observer
        
        observer.fetchedPanelPublisher = { [weak self] publisher, tabId in
            guard let self = self else { return }
            if tabId == tab.rewardsId {
                self.publisher = publisher
            }
        }
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    private var rewardsView: BraveRewardsView {
        view as! BraveRewardsView // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = BraveRewardsView()
        applyTheme(Theme.of(nil))
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
                applyTheme(Theme.of(nil))
            }
        }
    }
    
    func applyTheme(_ theme: Theme) {
        rewardsView.applyTheme(theme)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rewardsView.rewardsToggle.isOn = rewards.isEnabled
        
        if !rewards.isEnabled {
            rewardsView.statusView.setVisibleStatus(status: .rewardsOff, animated: false)
            rewardsView.publisherView.isHidden = true
        } else {
            if let url = tab.url, !url.isLocal {
                rewardsView.publisherView.hostLabel.text = url.baseDomain
                rewards.ledger.fetchPublisherActivity(from: url, faviconURL: nil, publisherBlob: nil, tabId: UInt64(tab.rewardsId))
            } else {
                rewardsView.publisherView.isHidden = true
            }
            rewards.ledger.fetchPromotions(nil)
            rewards.ledger.listAutoContributePublishers { [weak self] list in
                guard let self = self else { return }
                self.supportedListCount = list.count
                self.rewardsView.statusView.setVisibleStatus(status: list.isEmpty ? .rewardsOnNoCount : .rewardsOn, animated: false)
                self.rewardsView.statusView.countView.countLabel.text = "\(list.count)"
            }
        }
        
        rewardsView.legacyWalletTransferButton.isHidden = true
        if !Preferences.Rewards.dismissedLegacyWalletTransfer.value {
            if let legacyWallet = legacyWallet {
                legacyWallet.transferrableAmount({ [weak self] total in
                    guard let self = self else { return }
                    if total > 0 {
                        self.rewardsView.legacyWalletTransferButton.isHidden = false
                    }
                })
            }
        }
        
        if let displayName = publisher?.attributedDisplayName(fontSize: BraveRewardsPublisherView.UX.hostLabelFontSize) {
            rewardsView.publisherView.hostLabel.attributedText = displayName
        } else {
            rewardsView.publisherView.hostLabel.text = tab.url?.baseDomain
        }
        rewardsView.publisherView.learnMoreButton.addTarget(self, action: #selector(tappedUnverifiedPubLearnMore), for: .touchUpInside)
        rewardsView.subtitleLabel.text = rewards.isEnabled ? Strings.Rewards.enabledBody : Strings.Rewards.disabledBody
        rewardsView.rewardsToggle.addTarget(self, action: #selector(rewardsToggleValueChanged), for: .valueChanged)
        rewardsView.legacyWalletTransferButton.addTarget(self, action: #selector(tappedRewardsTransfer), for: .touchUpInside)
        rewardsView.legacyWalletTransferButton.dismissButton.addTarget(self, action: #selector(tappedDismissRewardsTransfer), for: .touchUpInside)
        
        view.snp.makeConstraints {
            $0.width.equalTo(360)
            $0.height.equalTo(rewardsView)
        }
        
        if !AppConstants.buildChannel.isPublic {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedHostLabel(_:)))
            rewardsView.publisherView.hostLabel.isUserInteractionEnabled = true
            rewardsView.publisherView.hostLabel.addGestureRecognizer(tapGesture)
        }
    }
    
    // MARK: - Actions
    
    private var isCreatingWallet: Bool = false
    @objc private func rewardsToggleValueChanged() {
        let isOn = rewardsView.rewardsToggle.isOn
        rewards.isEnabled = isOn
        rewardsView.subtitleLabel.text = isOn ? Strings.Rewards.enabledBody : Strings.Rewards.disabledBody
        if rewardsView.rewardsToggle.isOn {
            rewardsView.statusView.setVisibleStatus(status: supportedListCount > 0 ? .rewardsOn : .rewardsOnNoCount)
        } else {
            rewardsView.statusView.setVisibleStatus(status: .rewardsOff)
        }
        if publisher != nil {
            UIView.animate(withDuration: 0.15) {
                self.rewardsView.publisherView.isHidden = !self.rewardsView.rewardsToggle.isOn
                self.rewardsView.publisherView.alpha = self.rewardsView.rewardsToggle.isOn ? 1.0 : 0.0
            }
        }
    }
    
    @objc private func tappedRewardsTransfer() {
        actionHandler?(.rewardsTransferTapped)
    }
    
    @objc private func tappedDismissRewardsTransfer() {
        Preferences.Rewards.dismissedLegacyWalletTransfer.value = true
        UIView.animate(withDuration: 0.15) {
            self.rewardsView.legacyWalletTransferButton.isHidden = true
            self.rewardsView.legacyWalletTransferButton.alpha = 0.0
        }
    }
    
    @objc private func tappedUnverifiedPubLearnMore() {
        actionHandler?(.unverifiedPublisherLearnMoreTapped)
    }
    
    // MARK: - Debug Actions
    
    @objc private func tappedHostLabel(_ gesture: UITapGestureRecognizer) {
        if gesture.state != .ended { return }
        guard let publisher = publisher else { return }
        rewards.ledger.refreshPublisher(withId: publisher.id) { [weak self] status in
            guard let self = self else { return }
            let copy = publisher.copy() as! PublisherInfo // swiftlint:disable:this force_cast
            copy.status = status
            self.publisher = copy
            
            let alert = UIAlertController(title: nil, message: "Refreshed", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
