// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import Static
import Shared

extension RewardsType {
    fileprivate var displayText: String {
        switch self {
        case .autoContribute: return "Auto-Contribute"
        case .oneTimeTip: return "One time tip"
        case .recurringTip: return "Recurring tip"
        default:
            return "-"
        }
    }
}
extension ContributionStep {
    fileprivate var displayText: String {
        switch self {
        case .stepAcOff:
            return "Auto-Contribute Off"
        case .stepRewardsOff:
            return "Rewards Off"
        case .stepAcTableEmpty:
            return "AC table empty"
        case .stepNotEnoughFunds:
            return "Not enough funds"
        case .stepFailed:
            return "Failed"
        case .stepCompleted:
            return "Completed"
        case .stepNo:
            return "No"
        case .stepStart:
            return "Start"
        case .stepPrepare:
            return "Prepare"
        case .stepReserve:
            return "Reserve"
        case .stepExternalTransaction:
            return "External transaction"
        case .stepCreds:
            return "Creds"
        @unknown default:
            return "-"
        }
    }
}
extension ContributionProcessor {
    fileprivate var displayText: String {
        switch self {
        case .braveTokens: return "Brave Tokens"
        case .braveUserFunds: return "User Funds"
        case .uphold: return "Uphold"
        case .none: return "None"
        @unknown default:
            return "-"
        }
    }
}

class RewardsInternalsContributionListController: TableViewController {
    private let rewards: BraveRewards
    private var contributions: [ContributionInfo] = []
    
    init(rewards: BraveRewards) {
        self.rewards = rewards
        super.init(style: .grouped)
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        title = "Contributions"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(tappedShare))
        
        rewards.ledger.allContributions { contributions in
            self.contributions = contributions
            self.reloadData()
        }
    }
    
    func reloadData() {
        let dateFormatter = DateFormatter().then {
            $0.dateStyle = .short
            $0.timeStyle = .short
        }
        let batFormatter = NumberFormatter().then {
            $0.minimumFractionDigits = 1
            $0.maximumFractionDigits = 3
        }
        
        dataSource.sections = contributions.map { cont in
            .init(
                header: .title(cont.contributionId),
                rows: [
                    Row(text: "Created at", detailText: dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(cont.createdAt)))),
                    Row(text: "Type", detailText: cont.type.displayText),
                    Row(text: "Amount", detailText: "\(batFormatter.string(from: NSNumber(value: cont.amount)) ?? "0.0") \(Strings.BAT)"),
                    Row(text: "Step", detailText: cont.step.displayText),
                    Row(text: "Retry Count", detailText: "\(cont.retryCount)"),
                    Row(text: "Processor", detailText: cont.processor.displayText),
                    cont.publishers.count > 1 ?
                        Row(text: "Publishers", selection: {
                            let controller = RewardsInternalsContributionPublishersListController(publishers: cont.publishers)
                            self.navigationController?.pushViewController(controller, animated: true)
                        }, accessory: .disclosureIndicator) :
                        Row(text: "Publisher", detailText: cont.publishers.first?.publisherKey, cellClass: SubtitleCell.self)
                ],
                uuid: cont.contributionId
            )
        }
    }
    
    @objc private func tappedShare() {
        let controller = RewardsInternalsShareController(rewards: self.rewards, initiallySelectedSharables: [.contributions])
        let container = UINavigationController(rootViewController: controller)
        present(container, animated: true)
    }
}

/// A file generator that create a JSON file that contains all the contributions that user has made
/// including through auto-contribute, tips, etc.
struct RewardsInternalsContributionsGenerator: RewardsInternalsFileGenerator {
    func generateFiles(at path: String, using builder: RewardsInternalsSharableBuilder, completion: @escaping (Error?) -> Void) {
        let ledger = builder.rewards.ledger
        ledger.allContributions { contributions in
            let conts = contributions.map { cont -> [String: Any] in
                return [
                    "ID": cont.contributionId,
                    "Created at": builder.dateAndTimeFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(cont.createdAt))),
                    "Type": cont.type.displayText,
                    "Amount": cont.amount,
                    "Step": cont.step.displayText,
                    "Retry Count": "\(cont.retryCount)",
                    "Processor": cont.processor.displayText,
                    "Publishers": cont.publishers.map { pub in
                        return [
                            "Publisher Key": pub.publisherKey,
                            "Total Amount": pub.totalAmount,
                            "Contributed Amount": pub.contributedAmount,
                        ]
                    }
                ]
            }
            let data: [String: Any] = [
                "Contributions": conts
            ]
            do {
                try builder.writeJSON(from: data, named: "contributions", at: path)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
