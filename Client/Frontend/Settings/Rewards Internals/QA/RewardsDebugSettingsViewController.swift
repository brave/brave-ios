// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveRewards
import BraveShared
import Shared
import Static
import CoreServices

private typealias EnvironmentOverride = Preferences.Rewards.EnvironmentOverride

class RewardsDebugSettingsViewController: TableViewController {
    
    let rewards: BraveRewards
    let legacyWallet: BraveLedger?
    private var adsInfo: (viewed: Int, amount: Double, paymentDate: Date?)?
    
    init(rewards: BraveRewards, legacyWallet: BraveLedger?) {
        self.rewards = rewards
        self.legacyWallet = legacyWallet
        
        super.init(style: .grouped)
        
        self.rewards.ads.detailsForCurrentCycle { [weak self] viewed, amount, date in
            self?.adsInfo = (viewed, amount, date)
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    private let segmentedControl = UISegmentedControl(items: EnvironmentOverride.sortedCases.map { $0.name })
    
    @objc private func environmentChanged() {
        let value = segmentedControl.selectedSegmentIndex
        guard value < EnvironmentOverride.sortedCases.count else { return }
        let overrideForIndex = EnvironmentOverride.sortedCases[value]
        Preferences.Rewards.environmentOverride.value = overrideForIndex.rawValue
        self.rewards.reset()
        self.showResetRewardsAlert()
    }
    
    private let reconcileTimeTextField = UITextField().then {
        $0.borderStyle = .roundedRect
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.spellCheckingType = .no
        $0.returnKeyType = .done
        $0.textAlignment = .right
        $0.keyboardType = .numberPad
        $0.text = "\(BraveLedger.reconcileInterval)"
        $0.placeholder = "0"
    }
    
    private let customUserAgentTextField = UITextField().then {
        $0.borderStyle = .roundedRect
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.spellCheckingType = .no
        $0.returnKeyType = .done
        $0.textAlignment = .right
    }
    
    @objc private func reconcileTimeEditingEnded() {
        guard let value = Int32(reconcileTimeTextField.text ?? "") else {
            let alert = UIAlertController(title: "Invalid value", message: "Time has been reset to 0 (no override)", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            reconcileTimeTextField.text = "0"
            BraveLedger.reconcileInterval = 0
            return
        }
        BraveLedger.reconcileInterval = value
    }
    
    private let adsDismissalTextField = UITextField().then {
        $0.borderStyle = .roundedRect
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.spellCheckingType = .no
        $0.keyboardType = .numberPad
        $0.returnKeyType = .done
        $0.textAlignment = .right
        $0.placeholder = "0"
    }
    
    @objc private func adsDismissalEditingEnded() {
        let value = Int(adsDismissalTextField.text ?? "") ?? 0
        Preferences.Rewards.adsDurationOverride.value = value > 0 ? value : nil
    }
    
    @objc private func customUserAgentEditingEnded() {
        rewards.ledger.customUserAgent = customUserAgentTextField.text
    }
    
    private var numpadDismissalToolbar: UIToolbar {
        return UIToolbar().then {
            $0.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(textFieldDismissed))
            ]
            $0.frame = CGRect(width: self.view.bounds.width, height: 44)
        }
    }
    
    @objc private func textFieldDismissed() {
        view.endEditing(true)
    }
    
    private let dateFormatter = DateFormatter().then {
        $0.dateStyle = .short
        $0.timeStyle = .none
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        title = "Rewards QA Settings"
        navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .done, target: self, action: #selector(tappedDone))
        
        let override: EnvironmentOverride = EnvironmentOverride(rawValue: Preferences.Rewards.environmentOverride.value) ?? .none
        segmentedControl.selectedSegmentIndex = EnvironmentOverride.sortedCases.firstIndex(of: override) ?? 0
        segmentedControl.addTarget(self, action: #selector(environmentChanged), for: .valueChanged)
        reconcileTimeTextField.addTarget(self, action: #selector(reconcileTimeEditingEnded), for: .editingDidEnd)
        reconcileTimeTextField.frame = CGRect(x: 0, y: 0, width: 50, height: 32)
        reconcileTimeTextField.inputAccessoryView = numpadDismissalToolbar
        
        adsDismissalTextField.addTarget(self, action: #selector(adsDismissalEditingEnded), for: .editingDidEnd)
        adsDismissalTextField.frame = CGRect(x: 0, y: 0, width: 50, height: 32)
        adsDismissalTextField.inputAccessoryView = numpadDismissalToolbar
        adsDismissalTextField.text = "\(Preferences.Rewards.adsDurationOverride.value ?? 0)"
        
        customUserAgentTextField.addTarget(self, action: #selector(customUserAgentEditingEnded), for: .editingDidEnd)
        customUserAgentTextField.delegate = self
        customUserAgentTextField.frame = CGRect(x: 0, y: 0, width: 125, height: 32)
        customUserAgentTextField.inputAccessoryView = numpadDismissalToolbar
        customUserAgentTextField.text = rewards.ledger.customUserAgent
        
        KeyboardHelper.defaultHelper.addDelegate(self)
        
        reloadSections()
    }
    
    private func reloadSections() {
        let isDefaultEnvironmentProd = AppConstants.buildChannel != .debug
        
        dataSource.sections = [
            Section(
                header: .title("Environment"),
                rows: [
                    Row(text: "Default", detailText: isDefaultEnvironmentProd ? "Prod" : "Staging"),
                    Row(text: "Override", accessory: .view(segmentedControl)),
                ],
                footer: .title("Changing the environment automatically resets Brave Rewards.\n\nThe app must be force-quit after rewards is reset")
            ),
            Section(
                header: .title("Wallet"),
                rows: [
                    Row(text: "Internals", selection: { [unowned self] in
                        let controller = RewardsInternalsDebugViewController(ledger: self.rewards.ledger)
                        self.navigationController?.pushViewController(controller, animated: true)
                    }, accessory: .disclosureIndicator),
                    Row(text: "Fetch & Claim Promotions", selection: { [unowned self] in
                        self.fetchAndClaimPromotions()
                    }, cellClass: ButtonCell.self)
                ]
            ),
            Section(
                header: .title("Legacy Wallet"),
                rows: [
                    Row(text: "Internals", selection: { [unowned self] in
                        guard let legacyWallet = legacyWallet else {
                            let alert = UIAlertController(title: "Legacy Wallet", message: "No Wallet Found. Use \"Create Legacy Wallet\" action below to duplicate the current wallet", preferredStyle: .alert)
                            alert.addAction(.init(title: "OK", style: .default, handler: nil))
                            self.present(alert, animated: true)
                            return
                        }
                        let controller = RewardsInternalsDebugViewController(ledger: legacyWallet)
                        self.navigationController?.pushViewController(controller, animated: true)
                    }, accessory: .disclosureIndicator),
                    Row(text: "Create Legacy Wallet", selection: { [unowned self] in
                        self.createLegacyLedger()
                    }, cellClass: ButtonCell.self)
                ]
            ),
            Section(
                header: .title("Ads"),
                rows: [
                    Row(text: "Dismissal Timer", detailText: "Number of seconds before an ad is automatically dismissed. 0 = Default", accessory: .view(adsDismissalTextField), cellClass: MultilineSubtitleCell.self),
                    Row(text: "Ads Received", detailText: adsInfo.map { "\($0.viewed)" } ?? "—"),
                    Row(text: "Estimated Payout", detailText: adsInfo.map { "\($0.amount) BAT" } ?? "—"),
                    Row(text: "Next Payment Date", detailText: adsInfo?.paymentDate.map { self.dateFormatter.string(from: $0) } ?? "—"),
                ]
            ),
            Section(
                header: .title("Database"),
                rows: [
                    Row(text: "Import Rewards Database", selection: {
                        self.tappedImportRewardsDatabase()
                    }, cellClass: ButtonCell.self),
                    Row(text: "Export Rewards Database", selection: {
                        self.tappedShareRewardsDatabase()
                    }, cellClass: ButtonCell.self),
                ]
            ),
            Section(
                header: .title("Ledger Flags"),
                rows: [
                    Row(text: "Is Debug", accessory: .switchToggle(value: BraveLedger.isDebug, { value in
                        BraveLedger.isDebug = value
                        BraveAds.isDebug = value
                    })),
                    Row(text: "Use Short Retries", accessory: .switchToggle(value: BraveLedger.useShortRetries, { value in
                        BraveLedger.useShortRetries = value
                    })),
                    Row(text: "Reconcile Time", detailText: "Number of minutes between reconciles. 0 = No Override", accessory: .view(reconcileTimeTextField), cellClass: MultilineSubtitleCell.self),
                    Row(text: "Custom User Agent", detailText: "Non-persistant. Empty = default", accessory: .view(customUserAgentTextField), cellClass: MultilineSubtitleCell.self)
                ]
            ),
            Section(
                rows: [
                    Row(text: "Reset Rewards", selection: {
                        self.tappedReset()
                    }, cellClass: ButtonCell.self)
                ]
            )
        ]
    }
    
    private func fetchAndClaimPromotions() {
        rewards.ledger.fetchPromotions { [weak self] promotions in
            guard let self = self else { return }
            let activePromotions = promotions.filter { $0.status == .active }
            if activePromotions.isEmpty {
                let alert = UIAlertController(title: "Promotions", message: "No Active Promotions Found", preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
                return
            }
            let group = DispatchGroup()
            var successCount: Int = 0
            var claimedAmount: Double = 0
            var failuresCount: Int = 0
            for promo in activePromotions {
                group.enter()
                self.rewards.ledger.claimPromotion(promo) { success in
                    if success {
                        successCount += 1
                        claimedAmount += promo.approximateValue
                    } else {
                        failuresCount += 1
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) { [weak self] in
                guard let self = self else { return }
                let alert = UIAlertController(title: "Promotions", message: "Claimed: \(claimedAmount) BAT in \(successCount) Grants. (\(failuresCount) failures)", preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    private func createLegacyLedger() {
        let fm = FileManager.default
        let stateStorage = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!)
        let legacyLedger = stateStorage.appendingPathComponent("legacy_ledger")
        let ledgerFolder = stateStorage.appendingPathComponent("ledger")
        
        do {
            // Check if we've already migrated the users wallet to the `legacy_rewards` folder
            if fm.fileExists(atPath: legacyLedger.path) {
                // Reset it if so
                try fm.removeItem(atPath: legacyLedger.path)
            }
            // Copy the current `ledger` directory into the new legacy state storage path
            try fm.copyItem(at: ledgerFolder, to: legacyLedger)
            // Remove the old Rewards DB so that it starts fresh
            try fm.removeItem(atPath: ledgerFolder.appendingPathComponent("Rewards.db").path)
            // And remove the sqlite journal file if it exists
            let journalPath = ledgerFolder.appendingPathComponent("Rewards.db-journal").path
            if fm.fileExists(atPath: journalPath) {
                try fm.removeItem(atPath: journalPath)
            }
            
            showResetRewardsAlert()
        } catch {
            print("Failed to migrate legacy wallet into a new folder: \(error)")
        }
    }
    
    private func displayAlert(title: String? = nil, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func tappedImportRewardsDatabase() {
        let docPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeData), String(kUTTypeDatabase)], in: .import)
        if #available(iOS 13.0, *) {
            docPicker.shouldShowFileExtensions = true
        }
        docPicker.delegate = self
        self.present(docPicker, animated: true)
    }
    
    private func tappedShareRewardsDatabase() {
        guard let appSupportPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first else { return }
        let dbPath = (appSupportPath as NSString).appendingPathComponent("ledger/Rewards.db")
        let activity = UIActivityViewController(activityItems: [URL(fileURLWithPath: dbPath)], applicationActivities: nil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            activity.popoverPresentationController?.sourceView = view
        }
        self.present(activity, animated: true)
    }
    
    @objc private func tappedReset() {
        rewards.reset()
        showResetRewardsAlert()
    }
    
    @objc private func tappedDone() {
        dismiss(animated: true)
    }
    
    private func showResetRewardsAlert() {
        let alert = UIAlertController(
            title: "Rewards Reset",
            message: "Brave must be restarted to ensure expected Rewards behavior",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Exit Now", style: .destructive, handler: { _ in
            fatalError()
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}

extension RewardsDebugSettingsViewController: KeyboardHelperDelegate {
    public func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: state.intersectionHeightForView(view), right: 0)
    }
    public func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

extension RewardsDebugSettingsViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension RewardsDebugSettingsViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let documentURL = urls.first, documentURL.pathExtension == "db" else { return }
        guard let appSupportPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first else { return }
        let dbPath = (appSupportPath as NSString).appendingPathComponent("ledger/Rewards.db")
        do {
            _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: dbPath), withItemAt: documentURL)
            if FileManager.default.fileExists(atPath: "\(dbPath)-journal") {
                try FileManager.default.removeItem(atPath: "\(dbPath)-journal")
            }
            let alert = UIAlertController(
                title: "Database Imported",
                message: "Brave must be restarted after importing a database for data to be read from it correctly.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Exit Now", style: .destructive, handler: { _ in
                fatalError()
            }))
            alert.addAction(UIAlertAction(title: "Later…", style: .default, handler: nil))
            present(alert, animated: true)
        } catch {
            let alert = UIAlertController(title: "Failed To Import Database", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
        }
    }
}

