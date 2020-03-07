// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct FeedRow {
    var cards: [TodayCard]
}

class FeedComposer: NSObject {
    private let sessionId = UUID().uuidString
    private (set) var items: [FeedRow] = []
    private var profile: BrowserProfile!
    
    required convenience init(profile: BrowserProfile) {
        self.init()
        self.profile = profile
    }
    
    override init() {
        super.init()
    }
    
    // Can be called more than once per session
    // Manages to populate the in memory feed layout based on
    // simple filtering. TODO: add more complex filters and layouts
    
    func compose() {
        guard var feedItems = profile.feed.getRecords(session: sessionId, limit: 30).value.successValue else { return }
        
        var usedIds: [Int] = []
        feedItems.shuffle()
        
//        // v0.1 - add all items as large headline types
//        for i in 0..<feedItems.count {
//            let item = feedItems[i]
//            let card = TodayCard(type: .headlineLarge, items: [item], sponsorData: nil, mainTitle: "")
//            let feedRow = FeedRow(cards: [card])
//
//            items.append(feedRow)
//            usedIds.append(item.id)
//        }
        
        // v0.2 - add all items as small headline types
        var i = 0
        while i < feedItems.count {
            let item = feedItems[i]
            usedIds.append(item.id)

            let card = TodayCard(type: .headlineSmall, items: [item], sponsorData: nil, mainTitle: "")
            var cards: [TodayCard] = [card]

            if i + 1 < feedItems.count {
                i = i + 1

                let item = feedItems[i]
                let card = TodayCard(type: .headlineSmall, items: [item], sponsorData: nil, mainTitle: "")
                cards.append(card)
                usedIds.append(item.id)
            }

            let feedRow = FeedRow(cards: cards)

            items.append(feedRow)
            i = i + 1
        }
        
        // Update all used db records with latest session id
        // We should always update the records if loaded into in-memory feed.
        // This prevents feed duplicates from appearing.
        let data = profile.feed.updateRecords(usedIds, session: sessionId).value
        if data.isFailure == true {
            debugPrint(data.failureValue ?? "")
        }
    }
}
