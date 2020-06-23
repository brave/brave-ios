// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import Static
import Shared

class RewardsInternalsContributionPublishersListController: TableViewController {
    private let publishers: [ContributionPublisher]
    init(publishers: [ContributionPublisher]) {
        self.publishers = publishers
        super.init(style: .grouped)
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Publishers"
        
        let batFormatter = NumberFormatter().then {
            $0.minimumFractionDigits = 1
            $0.maximumFractionDigits = 3
        }
        
        dataSource.sections = publishers.map { pub in
            .init(
                header: .title(pub.publisherKey),
                rows: [
                    Row(text: "Total amount", detailText: "\(batFormatter.string(from: NSNumber(value: pub.totalAmount)) ?? "0.0") \(Strings.BAT)"),
                    Row(text: "Contribution amount", detailText: "\(batFormatter.string(from: NSNumber(value: pub.contributedAmount)) ?? "0.0") \(Strings.BAT)"),
                ]
            )
        }
    }
}
