// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Static
import Shared
import BraveShared

private let log = Logger.browserLogger

class BraveShieldsAndPrivacySettingsController: TableViewController {
    let profile: Profile
    let tabManager: TabManager
    let feedDataSource: FeedDataSource
    let historyManager: HistoryManager
    
    init(profile: Profile, tabManager: TabManager, feedDataSource: FeedDataSource, historyManager: HistoryManager) {
        self.profile = profile
        self.tabManager = tabManager
        self.feedDataSource = feedDataSource
        self.historyManager = historyManager
        super.init(style: .insetGrouped)
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.braveShieldsAndPrivacy
        
        dataSource.sections = [
            shieldsSection,
            clearPrivateDataSection,
            otherSettingsSection
        ]
    }
    
    // MARK: - Sections
    
    private lazy var shieldsSection: Section = {
        var shields = Section(
            header: .title(Strings.shieldsDefaults),
            rows: [
                .boolRow(title: Strings.blockAdsAndTracking, detailText: Strings.blockAdsAndTrackingDescription, option: Preferences.Shields.blockAdsAndTracking),
                .boolRow(title: Strings.HTTPSEverywhere, detailText: Strings.HTTPSEverywhereDescription, option: Preferences.Shields.httpsEverywhere),
                .boolRow(title: Strings.blockPhishingAndMalware, option: Preferences.Shields.blockPhishingAndMalware),
                .boolRow(title: Strings.blockScripts, detailText: Strings.blockScriptsDescription, option: Preferences.Shields.blockScripts),
                .boolRow(title: Strings.blockAllCookies, detailText: Strings.blockCookiesDescription, option: Preferences.Privacy.blockAllCookies, onValueChange: { [unowned self] in
                    func toggleCookieSetting(with status: Bool) {
                        // Lock/Unlock Cookie Folder
                        let completionBlock: (Bool) -> Void = { _ in
                            let success = FileManager.default.setFolderAccess([
                                (.cookie, status),
                                (.webSiteData, status)
                            ])
                            if success {
                                Preferences.Privacy.blockAllCookies.value = status
                            } else {
                                // Revert the changes. Not handling success here to avoid a loop.
                                FileManager.default.setFolderAccess([
                                    (.cookie, false),
                                    (.webSiteData, false)
                                ])
                                self.toggleSwitch(on: false, section: self.shieldsSection, rowUUID: Preferences.Privacy.blockAllCookies.key)
                                
                                // TODO: Throw Alert to user to try again?
                                let alert = UIAlertController(title: nil, message: Strings.blockAllCookiesFailedAlertMsg, preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: Strings.OKString, style: .default))
                                self.present(alert, animated: true)
                            }
                        }
                        // Save cookie to disk before purge for unblock load.
                        status ? HTTPCookie.saveToDisk(completion: completionBlock) : completionBlock(true)
                    }
                    if $0 {
                        let status = $0
                        // THROW ALERT to inform user of the setting
                        let alert = UIAlertController(title: Strings.blockAllCookiesAlertTitle, message: Strings.blockAllCookiesAlertInfo, preferredStyle: .alert)
                        let okAction = UIAlertAction(title: Strings.blockAllCookiesAction, style: .destructive, handler: { (action) in
                            toggleCookieSetting(with: status)
                        })
                        alert.addAction(okAction)
                        
                        let cancelAction = UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel, handler: { (action) in
                            self.toggleSwitch(on: false, section: self.shieldsSection, rowUUID: Preferences.Privacy.blockAllCookies.key)
                        })
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true)
                    } else {
                        toggleCookieSetting(with: $0)
                    }
                }),
                .boolRow(title: Strings.fingerprintingProtection, detailText: Strings.fingerprintingProtectionDescription, option: Preferences.Shields.fingerprintingProtection),
            ],
            footer: .title(Strings.shieldsDefaultsFooter)
        )
        if let locale = Locale.current.languageCode, let _ = ContentBlockerRegion.with(localeCode: locale) {
            shields.rows.append(.boolRow(title: Strings.useRegionalAdblock, option: Preferences.Shields.useRegionAdBlock))
        }
        return shields
    }()
    
    private lazy var toggles: [Bool] = {
        let savedToggles = Preferences.Privacy.clearPrivateDataToggles.value
        // Ensure if we ever add an option to the list of clearables we don't crash
        if savedToggles.count == clearables.count {
            return savedToggles
        }
        
        return self.clearables.map { $0.checked }
    }()
    
    private lazy var clearables: [(clearable: Clearable, checked: Bool)] = {
        var alwaysVisible: [(clearable: Clearable, checked: Bool)] =
            [(HistoryClearable(historyManager: self.historyManager), true),
             (CacheClearable(), true),
             (CookiesAndCacheClearable(), true),
             (PasswordsClearable(profile: self.profile), true),
             (DownloadsClearable(), true)]
        
        let others: [(clearable: Clearable, checked: Bool)] =
            [(PlayListCacheClearable(), false),
             (PlayListDataClearable(), false),
             (RecentSearchClearable(), true)]
        
        #if !NO_BRAVE_NEWS
        alwaysVisible.append((BraveNewsClearable(feedDataSource: self.feedDataSource), true))
        #endif
        
        alwaysVisible.append(contentsOf: others)
        
        return alwaysVisible
    }()
    
    private lazy var clearPrivateDataSection: Section = {
        return Section(
            header: .title(Strings.clearPrivateData),
            rows: clearables.indices.map { idx in
                let title = self.clearables[idx].clearable.label
                    
                return .boolRow(title: title, toggleValue: self.toggles[idx], valueChange: { [unowned self] checked in
                    self.toggles[idx] = checked
                    Preferences.Privacy.clearPrivateDataToggles.value = self.toggles
                }, cellReuseId: "\(title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))\(idx)")
            } + [
                Row(text: Strings.clearDataNow, selection: { [unowned self] in
                    self.tappedClearPrivateData()
                }, cellClass: CenteredButtonCell.self)
            ]
        )
    }()
    
    private lazy var otherSettingsSection: Section = {
        var section = Section(
            header: .title(Strings.otherPrivacySettingsSection),
            rows: [
                .boolRow(
                    title: Strings.privateBrowsingOnly,
                    option: Preferences.Privacy.privateBrowsingOnly,
                    onValueChange: { [weak self] value in
                        guard let self = self else { return }
                        self.pboModeToggled(value: value)
                    }
                ),
                .boolRow(title: Strings.blockPopups, option: Preferences.General.blockPopups),
                .boolRow(title: Strings.followUniversalLinks, option: Preferences.General.followUniversalLinks)
            ]
        )
        if #available(iOS 14.0, *) {
            section.rows.append(
                .boolRow(
                    title: Strings.googleSafeBrowsing,
                    detailText: Strings.googleSafeBrowsingUsingWebKitDescription,
                    option: Preferences.Shields.googleSafeBrowsing
                )
            )
        }
        return section
    }()
    
    // MARK: - Actions
    
    private func tappedClearPrivateData() {
        let alertController = UIAlertController(
            title: Strings.clearPrivateDataAlertTitle,
            message: Strings.clearPrivateDataAlertMessage,
            preferredStyle: .alert
        )
        let clearAction = UIAlertAction(title: Strings.clearPrivateDataAlertYesAction, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            Preferences.Privacy.clearPrivateDataToggles.value = self.toggles
            let spinner = SpinnerView().then {
                $0.present(on: self.view)
            }
            self.clearPrivateData(self.toggles.indices.compactMap {
                self.toggles[$0] ? self.clearables[$0].clearable : nil
            }).uponQueue(.main) {
                spinner.dismiss()
            }
        }
        alertController.addAction(clearAction)
        alertController.addAction(.init(title: Strings.cancelButtonTitle, style: .cancel))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func toggleSwitch(on: Bool, section: Section, rowUUID: String) {
        if let sectionRow: Row = section.rows.first(where: {$0.uuid == rowUUID}) {
            if let switchView: UISwitch = sectionRow.accessory.view as? UISwitch {
                switchView.setOn(on, animated: true)
            }
        }
    }
    
    private func pboModeToggled(value: Bool) {
        if value {
            let alert = UIAlertController(title: Strings.privateBrowsingOnly, message: Strings.privateBrowsingOnlyWarning, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel, handler: { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.toggleSwitch(on: false, section: self.otherSettingsSection, rowUUID: Preferences.Privacy.privateBrowsingOnly.key)
                }
            }))
            
            alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                let spinner = SpinnerView().then {
                    $0.present(on: self.view)
                }
                
                Preferences.Privacy.privateBrowsingOnly.value = value
                
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.1) {
                    let clearables: [Clearable] = [CookiesAndCacheClearable()]
                    self.clearPrivateData(clearables).uponQueue(.main) { [weak self] in
                        guard let self = self else { return }
                        
                        // First remove all tabs so that only a blank tab exists.
                        self.tabManager.removeAll()
                        
                        // Reset tab configurations and delete all webviews..
                        self.tabManager.reset()
                        
                        // Restore all existing tabs by removing the blank tabs and recreating new ones..
                        self.tabManager.removeAll()
                        
                        spinner.dismiss()
                    }
                }
            }))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            Preferences.Privacy.privateBrowsingOnly.value = value
        }
    }
    
    @discardableResult
    func clearPrivateData(_ clearables: [Clearable]) -> Deferred<Void> {
        func _clear(_ clearables: [Clearable], secondAttempt: Bool = false) -> Deferred<Void> {
            let deferred = Deferred<Void>()
            clearables.enumerated().map { clearable in
                log.info("Clearing \(clearable.element).")
                
                let res = Success()
                succeed().upon() { _ in // move off main thread
                    clearable.element.clear().upon() { result in
                        res.fill(result)
                    }
                }
                return res
            }
            .allSucceed()
            .upon { result in
                if !result.isSuccess && !secondAttempt {
                    log.error("Private data NOT cleared successfully")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        // For some reason, a second attempt seems to always succeed
                        _clear(clearables, secondAttempt: true).upon() { _ in
                            deferred.fill(())
                        }
                    })
                    return
                }
                
                if !result.isSuccess {
                    log.error("Private data NOT cleared after 2 attempts")
                }
                deferred.fill(())
            }
            return deferred
        }
        
        let clearAffectsTabs = clearables.contains { item in
            return item is CacheClearable || item is CookiesAndCacheClearable
        }
        
        let historyCleared = clearables.contains { $0 is HistoryClearable }
        
        if clearAffectsTabs {
            DispatchQueue.main.async {
                self.tabManager.allTabs.forEach({ $0.reload() })
            }
        }
        
        let deferred = Deferred<Void>()
        
        func _toggleFolderAccessForBlockCookies(locked: Bool) {
            if Preferences.Privacy.blockAllCookies.value, FileManager.default.checkLockedStatus(folder: .cookie) != locked {
                FileManager.default.setFolderAccess([
                    (.cookie, locked),
                    (.webSiteData, locked)
                ])
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Reset Webkit configuration to remove data from memory
            if clearAffectsTabs {
                self.tabManager.resetConfiguration()
                // Unlock the folders to allow clearing of data.
                _toggleFolderAccessForBlockCookies(locked: false)
            }
            
            _clear(clearables)
                .uponQueue(.main, block: {
                    if clearAffectsTabs {
                        self.tabManager.allTabs.forEach({ $0.reload() })
                    }
                    
                    if historyCleared {
                        self.tabManager.clearTabHistory()
                        
                        /// Donate Clear Browser History for suggestions
                        let clearBrowserHistoryActivity = ActivityShortcutManager.shared.createShortcutActivity(type: .clearBrowsingHistory)
                        self.userActivity = clearBrowserHistoryActivity
                        clearBrowserHistoryActivity.becomeCurrent()
                    }
                    
                    _toggleFolderAccessForBlockCookies(locked: true)
                    deferred.fill(())
                })
        }
        
        return deferred
    }
}
