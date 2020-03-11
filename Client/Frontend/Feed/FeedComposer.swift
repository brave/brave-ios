// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Storage

struct FeedRow {
    var cards: [FeedCard]
}

class FeedComposer: NSObject {
    private var sessionId = UUID().uuidString
    private (set) var items: [FeedRow] = []
    private var profile: BrowserProfile!
    
    required convenience init(profile: BrowserProfile) {
        self.init()
        self.profile = profile
    }
    
    override init() {
        super.init()
    }
    
    func reset() {
        sessionId = UUID().uuidString
        items = []
        compose(completion: nil)
    }
    
    func getOne(publisher: String) -> FeedItem? {
        guard let feedItem = profile.feed.getFeedRecords(session: sessionId, publisher: publisher, limit: 1, requiresImage: false, contentType: .any).value.successValue?.first else { return nil }
        
        let data = profile.feed.updateFeedRecords([feedItem.id], session: sessionId).value
        if data.isFailure == true {
            debugPrint(data.failureValue ?? "")
        }
        
        return feedItem
    }
    
    // Can be called more than once per session
    // Manages to populate the in memory feed layout based on
    // simple filtering. TODO: add more complex filters and layouts
    func compose(completion: (() -> Void)?) {
        DispatchQueue.global().async { [weak self] in
            guard let sessionId = self?.sessionId else { return }
            
            var tempFeed: [FeedRow] = []
            var usedIds: [Int] = []
            
            //
            //
            // Get Digg Card
            
            if Int.random(in: 0 ... 3) == 1, let items = self?.profile.feed.getFeedRecords(session: sessionId, publisher: "digg", limit: 3, requiresImage: false, contentType: .any).value.successValue, items.count == 3 {
                var specialData: FeedCardSpecialData?
                if let item = items.first, item.publisherLogo.isEmpty == false {
                    specialData = FeedCardSpecialData(title: nil, logo: item.publisherLogo, publisher: item.publisherName)
                }
                
                // Build card
                let card = FeedCard(type: .verticalListNumbered, items: items, specialData: specialData)
                tempFeed.append(FeedRow(cards: [card]))
                
                // Mark used items with current sessionId
                for item in items {
                    usedIds.append(item.id)
                }
            }
            
            //
            //
            // Get Amazon Card
            if Int.random(in: 0 ... 2) == 1, let items = self?.profile.feed.getFeedRecords(session: sessionId, publisher: "amazon", limit: 3, requiresImage: false, contentType: .product).value.successValue, items.count == 3 {
                var specialData: FeedCardSpecialData?
                if let item = items.first, item.publisherLogo.isEmpty == false {
                    specialData = FeedCardSpecialData(title: "Amazon Deals", logo: item.publisherLogo, publisher: item.publisherName)
                }
                
                // Build card
                let card = FeedCard(type: .horizontalList, items: items, specialData: specialData)
                tempFeed.append(FeedRow(cards: [card]))
                
                // Mark used items with current sessionId
                for item in items {
                    usedIds.append(item.id)
                }
            }
            
            //
            //
            // Get New Egg Card
            if Int.random(in: 0 ... 3) == 1, let items = self?.profile.feed.getFeedRecords(session: sessionId, publisher: "newegg", limit: 3, requiresImage: false, contentType: .product).value.successValue, items.count == 3 {
                var specialData: FeedCardSpecialData?
                if let item = items.first, item.publisherLogo.isEmpty == false {
                    specialData = FeedCardSpecialData(title: "Deals", logo: item.publisherLogo, publisher: item.publisherName)
                }
                
                // Build card
                let card = FeedCard(type: .horizontalList, items: items, specialData: specialData)
                tempFeed.append(FeedRow(cards: [card]))
                
                // Mark used items with current sessionId
                for item in items {
                    usedIds.append(item.id)
                }
            }
            
            //
            //
            // Get BuzzFeed Card
            if Int.random(in: 0 ... 10) == 1, let items = self?.profile.feed.getFeedRecords(session: sessionId, publisher: "buzzfeed", limit: 3, requiresImage: false, contentType: .article).value.successValue, items.count == 3 {
                var specialData: FeedCardSpecialData?
                if let item = items.first, item.publisherLogo.isEmpty == false {
                    specialData = FeedCardSpecialData(title: "Latest Buzz", logo: item.publisherLogo, publisher: item.publisherName)
                }
                
                // Build card
                let card = FeedCard(type: .verticalListBranded, items: items, specialData: specialData)
                tempFeed.append(FeedRow(cards: [card]))
                
                // Mark used items with current sessionId
                for item in items {
                    usedIds.append(item.id)
                }
            }
            
            //
            //
            // Get Technology Labeled Card
            if Int.random(in: 0 ... 3) == 1, let items = self?.profile.feed.getFeedRecords(session: sessionId, publisher: "mashable", limit: 3, requiresImage: false, contentType: .article).value.successValue, items.count == 3 {
                var specialData: FeedCardSpecialData?
                if let item = items.first, item.publisherLogo.isEmpty == false {
                    specialData = FeedCardSpecialData(title: "Technology", logo: item.publisherLogo, publisher: item.publisherName)
                }
                
                // Build card
                let card = FeedCard(type: .verticalListBranded, items: items, specialData: specialData)
                tempFeed.append(FeedRow(cards: [card]))
                
                // Mark used items with current sessionId
                for item in items {
                    usedIds.append(item.id)
                }
            }
            
            //
            //
            // Get Science Labeled Card
            if Int.random(in: 0 ... 6) == 1, let items = self?.profile.feed.getFeedRecords(session: sessionId, publisher: "popsci", limit: 3, requiresImage: false, contentType: .article).value.successValue, items.count == 3 {
                var specialData: FeedCardSpecialData?
                if let item = items.first, item.publisherLogo.isEmpty == false {
                    specialData = FeedCardSpecialData(title: nil, logo: item.publisherLogo, publisher: item.publisherName)
                }
                
                // Build card
                let card = FeedCard(type: .verticalListNumbered, items: items, specialData: specialData)
                tempFeed.append(FeedRow(cards: [card]))
                
                // Mark used items with current sessionId
                for item in items {
                    usedIds.append(item.id)
                }
            }
            
            //
            //
            // Get Science Labeled Card
            if Int.random(in: 0 ... 3) == 1, let items = self?.profile.feed.getFeedRecords(session: sessionId, publisher: "wired", limit: 3, requiresImage: false, contentType: .article).value.successValue, items.count == 3 {
                var specialData: FeedCardSpecialData?
                if let item = items.first, item.publisherLogo.isEmpty == false {
                    specialData = FeedCardSpecialData(title: "Wired News", logo: item.publisherLogo, publisher: item.publisherName)
                }
                
                // Build card
                let card = FeedCard(type: .verticalListBranded, items: items, specialData: specialData)
                tempFeed.append(FeedRow(cards: [card]))
                
                // Mark used items with current sessionId
                for item in items {
                    usedIds.append(item.id)
                }
            }
            
            //
            //
            // End of publisher specific cards.
            // Need to update rows so we don't pull the same data again further down.
            _ = self?.profile.feed.updateFeedRecords(usedIds, session: sessionId).value
            usedIds = []
            
            //
            //
            // Get Small Headline Rows
            if let items = self?.profile.feed.getFeedRecords(session: sessionId, limit: 8, requiresImage: true, contentType: .article).value.successValue {
                var i = 0
                while i < items.count {
                    let item = items[i]
                    usedIds.append(item.id)
        
                    let card = FeedCard(type: .headlineSmall, items: [item], specialData: nil)
                    var cards: [FeedCard] = [card]
        
                    if i + 1 < items.count {
                        i = i + 1
        
                        let item = items[i]
                        let card = FeedCard(type: .headlineSmall, items: [item], specialData: nil)
                        cards.append(card)
                        usedIds.append(item.id)
                    }
        
                    let feedRow = FeedRow(cards: cards)
        
                    tempFeed.append(feedRow)
                    i = i + 1
                }
                
                // Need to update rows so we don't pull the same data again further down.
                _ = self?.profile.feed.updateFeedRecords(usedIds, session: sessionId).value
                usedIds = []
            }
            
            //
            //
            // Get Large Headline Cards
            if let items = self?.profile.feed.getFeedRecords(session: sessionId, limit: 4, requiresImage: true, contentType: .article).value.successValue {
                for i in 0..<items.count {
                    let item = items[i]
                    let card = FeedCard(type: .headlineLarge, items: [item], specialData: nil)
                    let feedRow = FeedRow(cards: [card])

                    tempFeed.append(feedRow)
                    usedIds.append(item.id)
                }
                
                // Need to update rows so we don't pull the same data again further down.
                _ = self?.profile.feed.updateFeedRecords(usedIds, session: sessionId).value
                usedIds = []
            }
            
            //
            //
            // Get mixed news in vertical lists -- these should contain images since we could fallback to headline cards.
            if Int.random(in: 0 ... 2) == 1, let items = self?.profile.feed.getFeedRecords(session: sessionId, limit: 3, requiresImage: true, contentType: .article).value.successValue {
                var i = 0
                while i < items.count {
                    if i + 2 < items.count {
                        let card = FeedCard(type: .verticalList, items: [items[i], items[i+1], items[i+2]], specialData: nil)
                        let feedRow = FeedRow(cards: [card])

                        tempFeed.append(feedRow)

                        usedIds.append(items[i].id)
                        usedIds.append(items[i+1].id)
                        usedIds.append(items[i+2].id)

                        i = i + 3
                    } else if i + 1 < items.count {
                        // Fallback to 2 small cards if only 2 left.
                        let item = items[i]
                        usedIds.append(item.id)

                        let card = FeedCard(type: .headlineSmall, items: [item], specialData: nil)
                        var cards: [FeedCard] = [card]

                        if i + 1 < items.count {
                            i = i + 1

                            let item = items[i]
                            let card = FeedCard(type: .headlineSmall, items: [item], specialData: nil)
                            cards.append(card)
                            usedIds.append(item.id)
                        }

                        let feedRow = FeedRow(cards: cards)

                        tempFeed.append(feedRow)
                        i = i + 1
                    } else {
                        // Fallback to large headline if 1 left
                        let item = items[i]
                        let card = FeedCard(type: .headlineLarge, items: [item], specialData: nil)
                        let feedRow = FeedRow(cards: [card])

                        tempFeed.append(feedRow)
                        usedIds.append(item.id)

                        i = i + 1
                    }
                }
                
                // Need to update rows so we don't pull the same data again further down.
                _ = self?.profile.feed.updateFeedRecords(usedIds, session: sessionId).value
                usedIds = []
            }
            
            //
            //
            // Get sponsored lists
            
            //
            //
            // Now suffle the list
            tempFeed.shuffle()
            
            //
            //
            // Prepend sponsor banner if feed count is 0
            
            //
            //
            // Append to feed == all done
            for row in tempFeed {
                self?.items.append(row)
            }
            
            //
            //
            // All Done.
            completion?()
        }
    }
}
