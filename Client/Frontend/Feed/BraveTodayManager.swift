// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Shared
import Storage
import SwiftKeychainWrapper
import Deferred

class BraveToday: NSObject {
    static let shared = BraveToday()
    private var profile: BrowserProfile?
    
    var isEnabled = false
    
    fileprivate var feed: FeedComposer?
    
    override init() {
        super.init()
    }
    
    func register(profile: BrowserProfile?) {
        self.profile = profile
        
        guard let profile = profile else { return }
        feed = FeedComposer(profile: profile)
    }
    
    func clearAll() {
        _ = profile?.feed.deleteAllRecords()
    }
    
    func loadFeed(completion: @escaping () -> Void) {
        requestFeedData { [weak self] data in
            guard let data = data else { return }
            self?.saveFeedData(data: data)
            self?.feed?.compose()
            completion()
        }
    }
    
    private func saveFeedData(data: [FeedData]) {
        func dateFromStringConverter(date: String) -> Date? {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
            return dateFormatter.date(from: date)
        }
        
        for item in data {
            // Only unique URL will save successfully
            var publishTime: Timestamp = 0
            
            if let dateString = item.publishTime {
                guard let date = dateFromStringConverter(date: dateString) else { break }
                publishTime = date.toTimestamp()
            }
            
            let data = self.profile?.feed.createRecord(publishTime: publishTime,
                                                        feedSource: item.feedSource ?? "",
                                                        url: item.url ?? "",
                                                        img: item.img ?? "",
                                                        title: item.title ?? "",
                                                        description: item.description ?? "").value
            
            if data?.isFailure == true {
                debugPrint(item)
                debugPrint(data?.failureValue ?? "")
            }
        }
    }
    
    private func requestFeedData(completion: @escaping ([FeedData]?) -> Void) {
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
    
    func feedCount() -> Int {
        return feed?.items.count ?? 0
    }
}

extension BraveToday: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let feed = feed else { return 0 }
        return isEnabled ? feed.items.count : 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodayCell", for: indexPath) as UITableViewCell
        if let feed = feed {
            let item: FeedRow = feed.items[indexPath.row]
            (cell as? TodayCell)?.setData(data: item)
        }
        return cell
    }
}
