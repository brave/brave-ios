// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data
import BraveRewards
import BraveShared
import CoreData
import Shared

private let log = Logger.browserLogger

// A Lightweight wrapper around BraveCore history
// with the same layout/interface as `History (from CoreData)`
class Historyv2: WebsitePresentable {
    
    // MARK: Lifecycle
    
    init(with node: HistoryNode) {
        self.historyNode = node
    }
    
    // MARK: Internal
    
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
    
    public var sectionIdentifier: String? {
        if created?.compare(Historyv2.today) == ComparisonResult.orderedDescending {
            return Strings.today
        } else if created?.compare(Historyv2.yesterday) == ComparisonResult.orderedDescending {
            return Strings.yesterday
        } else if created?.compare(Historyv2.thisWeek) == ComparisonResult.orderedDescending {
            return Strings.lastWeek
        } else {
            return Strings.lastMonth
        }
    }
    
    // MARK: Private
    
    private let historyNode: HistoryNode
    private static let historyAPI = BraveHistoryAPI()
    
    private static let today = getDate(0)
    private static let yesterday = getDate(-1)
    private static let thisWeek = getDate(-7)
    private static let thisMonth = getDate(-31)
    
    private class func getDate(_ dayOffset: Int) -> Date {
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

// MARK: History Fetching

extension Historyv2 {

    public class func add(url: URL, title: String, dateAdded: Date) {
        Historyv2.historyAPI.addHistory(HistoryNode(url: url, title: title, dateAdded: dateAdded))
    }
    
    public static func frc(parent: Historyv2?) -> HistoryV2FetchResultsController? {
        return Historyv2Fetcher(historyAPI: Historyv2.historyAPI)
    }
    
    public func delete() {
        Historyv2.historyAPI.removeHistory(historyNode)
    }
    
    public class func deleteAll(_ completion: @escaping () -> Void) {
        Historyv2.historyAPI.removeAll {
            completion()
        }
    }
    
    public class func suffix(_ maxLength: Int, _ completion: @escaping ([Historyv2]) -> Void) {
        Historyv2.historyAPI.search(withQuery: nil, maxCount: UInt(max(20, maxLength)), completion: { historyResults in
            completion(historyResults.map { Historyv2(with: $0) })
        })
    }

    public static func byFrequency(query: String? = nil, _ completion: @escaping ([WebsitePresentable]) -> Void) {
        guard let query = query, !query.isEmpty else { return }
        
        Historyv2.historyAPI.search(withQuery: nil, maxCount: 200, completion: { historyResults in
            completion(historyResults.map { Historyv2(with: $0) })
        })
    }
    
    public func update(customTitle: String?, dateAdded: Date?) {
        if let title = customTitle {
            historyNode.title = title
        }
        
        if let date = dateAdded {
            historyNode.dateAdded = date
        }
    }
}
