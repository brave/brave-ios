// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Shared
import Storage
import SwiftKeychainWrapper
import Deferred

struct FeedRow {
    var cards: [TodayCard]
}

class BraveToday: NSObject {
    static let shared = BraveToday()
    private var profile: BrowserProfile?
    
    var isEnabled = false
    
    fileprivate let sessionId = UUID().uuidString
    fileprivate var feed: [FeedRow] = []
    
    override init() {
        super.init()
    }
    
    func register(profile: BrowserProfile?) {
        self.profile = profile
    }
    
    func clearAll() {
        _ = profile?.feed.deleteAllRecords()
    }
    
    func loadFeedData(completion: @escaping () -> Void) {
        func dateFromStringConverter(date: String) -> Date? {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
            return dateFormatter.date(from: date)
        }
        
        requestFeed { [weak self] data in
            guard let data = data else { return }
            for item in data {
                // Only unique URL will save successfully
                var publishTime: Timestamp = 0
                if let dateString = item.publishTime {
                    guard let date = dateFromStringConverter(date: dateString) else { break }
                    publishTime = date.toTimestamp()
                }
                
                let data = self?.profile?.feed.createRecord(publishTime: publishTime, feedSource: item.feedSource ?? "", url: item.url ?? "", img: item.img ?? "", title: item.title ?? "", description: item.description ?? "").value
                if data?.isFailure == true {
                    debugPrint(item)
                    debugPrint(data?.failureValue ?? "")
                }
            }
            
            completion()
        }
    }
    
    // Can be called more than once per session
    // Manages to populate the in memory feed layout based on
    // simple filtering. TODO: add more complex filters and layouts
    
    func generateFeed(completion: @escaping () -> Void) {
        guard let feedItems = profile?.feed.getRecords(session: sessionId, limit: 40).value.successValue else {
            completion()
            return
        }
        
        var usedIds: [Int] = []
        
        // v0.1 - add all items as large headline types
        for item in feedItems {
            let card = TodayCard(type: .headlineLarge, items: [item], sponsorData: nil)
            let feedRow = FeedRow(cards: [card])
            feed.append(feedRow)
            usedIds.append(item.id)
        }
        
        // Update all used db records with latest session id
        // We should always update the records if loaded into in-memory feed.
        // This prevents feed duplicates from appearing.
        let data = profile?.feed.updateRecords(usedIds, session: sessionId).value
        if data?.isFailure == true {
            debugPrint(data?.failureValue ?? "")
        }
        
        completion()
    }
    
    func feedCount() -> Int {
        return feed.count
    }
    
    private func requestFeed(completion: @escaping ([FeedData]?) -> Void) {
        guard let url = URL(string: "https://sjc.rapidpacket.com/~xtat/bt/latest.json") else { return }
        
        var request = URLRequest(url: url)
        request.addValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        
        let session = URLSession.shared

        session.dataTask(with: request) {data, response, error in
            if error != nil {
                print(error!.localizedDescription)
                return
            }

            guard let data = data else { return }
            do {
                let feed = try JSONDecoder().decode([FeedData].self, from: data)
                completion(feed)
            } catch {
                print(error.localizedDescription)
            }
        }.resume()
    }
}

extension BraveToday: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isEnabled ? feed.count : 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodayCell", for: indexPath) as UITableViewCell
        let item: FeedRow = feed[indexPath.row]
        (cell as? TodayCell)?.setData(data: item)
        return cell
    }
}
