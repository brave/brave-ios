// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data
import BraveCore
import BraveShared
import CoreData
import Shared

private let log = Logger.browserLogger

// A Lightweight wrapper around BraveCore history
// with the same layout/interface as `History (from CoreData)`
class Historyv2: WebsitePresentable {
    
    /// Sections in History List to be displayed
    enum Section: Int, CaseIterable {
        /// History happened Today
        case today
        /// History happened Yesterday
        case yesterday
        /// History happened between yesterday and end of this week
        case lastWeek
        /// History happened between end of this week and end of this month
        case thisMonth
        
        /// The list of titles time period
        var title: String {
            switch self {
                case .today:
                     return Strings.today
                case .yesterday:
                     return Strings.yesterday
                case .lastWeek:
                     return Strings.lastWeek
                case .thisMonth:
                     return Strings.lastMonth
            }
        }
    }
    
    // MARK: Lifecycle
    
    init(with node: HistoryNode) {
        self.historyNode = node
    }
    
    // MARK: Internal
    
    public let historyNode: HistoryNode
    
    public var url: String? {
        historyNode.url.absoluteString
    }
    
    public var title: String? {
        historyNode.title
    }
    
    public var created: Date? {
        get {
            return historyNode.dateAdded
        }
        
        set {
            historyNode.dateAdded = newValue ?? Date()
        }
    }
    
    public var domain: String? {
        historyNode.url.domainURL.absoluteString
    }
    
    public var sectionID: Section? {
        fetchHistoryTimePeriod(visited: created)
    }
    
    // MARK: Private

    private func fetchHistoryTimePeriod(visited: Date?) -> Section? {
        let todayOffset = 0
        let yesterdayOffset = -1
        let thisWeekOffset = -7
        let thisMonthOffset = -31
        
        if created?.compare(getDate(todayOffset)) == ComparisonResult.orderedDescending {
            return .today
        } else if created?.compare(getDate(yesterdayOffset)) == ComparisonResult.orderedDescending {
            return .yesterday
        } else if created?.compare(getDate(thisWeekOffset)) == ComparisonResult.orderedDescending {
            return .lastWeek
        } else if created?.compare(getDate(thisMonthOffset))  == ComparisonResult.orderedDescending {
            return .thisMonth
        }
        
        return nil
    }
    
    private func getDate(_ dayOffset: Int) -> Date {
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let nowComponents = calendar.dateComponents(
            [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day], from: Date())
        
        guard let today = calendar.date(from: nowComponents) else {
            return Date()
        }
        
        return (calendar as NSCalendar).date(
            byAdding: NSCalendar.Unit.day, value: dayOffset, to: today, options: []) ?? Date()
    }
}
