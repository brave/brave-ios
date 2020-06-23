// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveRewards
import Static
import DeviceCheck
import BraveRewardsUI
import Shared

/// A place where all rewards debugging information will live.
class RewardsInternalsViewController: TableViewController {
    
    private let rewards: BraveRewards
    private var internalsInfo: RewardsInternalsInfo?
    
    init(rewards: BraveRewards) {
        self.rewards = rewards
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
        rewards.ledger.rewardsInternalInfo { info in
            self.internalsInfo = info
        }
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Rewards Internals"
        
        guard let info = internalsInfo else { return }
        
        let dateFormatter = DateFormatter().then {
            $0.dateStyle = .short
        }
        let batFormatter = NumberFormatter().then {
            $0.minimumFractionDigits = 1
            $0.maximumFractionDigits = 3
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(tappedShare))
        
        var sections: [Static.Section] = [
            .init(
                header: .title("Wallet Info"),
                rows: [
                    Row(text: "Key Info Seed", detailText: "\(info.isKeyInfoSeedValid ? "Valid" : "Invalid")"),
                    Row(text: "Wallet Payment ID", detailText: info.paymentId, cellClass: SubtitleCell.self),
                    Row(text: "Wallet Creation Date", detailText: dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(info.bootStamp))))
                ]
            ),
            .init(
                header: .title("Device Info"),
                rows: [
                    Row(text: "Status", detailText: DCDevice.current.isSupported ? "Supported" : "Not supported"),
                    Row(text: "Enrollment State", detailText: DeviceCheckClient.isDeviceEnrolled() ? "Enrolled" : "Not enrolled")
                ]
            )
        ]
        
        if let balance = rewards.ledger.balance {
            let keyMaps = [
                "anonymous": "Anonymous",
                "blinded": "Rewards BAT",
                "uphold": "Uphold Wallet"
            ]
            let walletRows = balance.wallets.lazy.filter({ $0.key != "uphold" }).map { (key, value) -> Row in
                Row(text: keyMaps[key] ?? key, detailText: "\(batFormatter.string(from: value) ?? "0.0") \(Strings.BAT)")
            }
            sections.append(
                .init(
                    header: .title("Balance Info"),
                    rows: [
                        Row(text: "Total Balance", detailText: "\(batFormatter.string(from: NSNumber(value: balance.total)) ?? "0.0") \(Strings.BAT)")
                    ] + walletRows
                )
            )
        }
        
        sections.append(
            .init(
                rows: [
                    Row(text: "Logs", selection: {
                        let controller = RewardsInternalsLogController(rewards: self.rewards)
                        self.navigationController?.pushViewController(controller, animated: true)
                    }, accessory: .disclosureIndicator),
                    Row(text: "Promotions", selection: {
                        let controller = RewardsInternalsPromotionListController(rewards: self.rewards)
                        self.navigationController?.pushViewController(controller, animated: true)
                    }, accessory: .disclosureIndicator),
                    Row(text: "Contributions", selection: {
                        let controller = RewardsInternalsContributionListController(rewards: self.rewards)
                        self.navigationController?.pushViewController(controller, animated: true)
                    }, accessory: .disclosureIndicator)
                ]
            )
        )
        
        dataSource.sections = sections
    }
    
    @objc private func tappedShare() {
        let controller = RewardsInternalsShareController(rewards: self.rewards, initiallySelectedSharables: RewardsInternalsSharable.default)
        let container = UINavigationController(rootViewController: controller)
        present(container, animated: true)
    }
}

/// A file generator that creates a JSON file containing basic information such as wallet info, device info
/// and balance info
struct RewardsInternalsBasicInfoGenerator: RewardsInternalsFileGenerator {
    func generateFiles(at path: String, using builder: RewardsInternalsSharableBuilder, completion: @escaping (Error?) -> Void) {
        // Only 1 file to make here
        var internals: RewardsInternalsInfo?
        builder.rewards.ledger.rewardsInternalInfo { info in
            internals = info
        }
        guard let info = internals else {
            completion(RewardsInternalsSharableError.rewardsInternalsUnavailable)
            return
        }
        
        let data: [String: Any] = [
            "Wallet Info": [
                "Key Info Seed": "\(info.isKeyInfoSeedValid ? "Valid" : "Invalid")",
                "Wallet Payment ID": info.paymentId,
                "Wallet Creation Date": builder.dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(info.bootStamp)))
            ],
            "Device Info": [
                "DeviceCheck Status": DCDevice.current.isSupported ? "Supported" : "Not supported",
                "DeviceCheck Enrollment State": DeviceCheckClient.isDeviceEnrolled() ? "Enrolled" : "Not enrolled",
                "OS": "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
                "Model": UIDevice.current.model,
            ],
            "Balance Info": builder.rewards.ledger.balance?.wallets ?? ""
        ]
        
        do {
            try builder.writeJSON(from: data, named: "basic", at: path)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}
