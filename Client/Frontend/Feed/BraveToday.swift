// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Shared
import Storage
import SwiftKeychainWrapper
import Deferred

class FeedObject: NSObject {
    var items: [FeedItem]
    var cardType: TodayCardType
    
    init(items: [FeedItem], cardType: TodayCardType) {
        self.items = items
        self.cardType = cardType
    }
}

class BraveToday: NSObject {
    static let shared = BraveToday()
    private weak var profile: BrowserProfile?
    
    // session
    // feed state
    
    var isEnabled = false
    
    fileprivate var feed: [FeedObject] = []
    
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
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            return dateFormatter.date(from: date)
        }
        
        requestFeed { [weak self] data in
            guard let data = data else { return }
            for item in data {
                // Only unique URL will save successfully
                var publishTime: Timestamp = 0
                if let dateString = item.publishTime, let date = dateFromStringConverter(date: dateString) {
                    publishTime = date.toTimestamp()
                }
                guard let data = self?.profile?.feed.createRecord(publishTime: publishTime, feedSource: item.feedSource ?? "", url: item.url ?? "", img: item.img ?? "", title: item.title ?? "", description: item.description ?? "").value.successValue else { continue }
                debugPrint(data)
            }
            
            // TODO: Append new data to feed
            
            completion()
        }
    }
    
    private func requestFeed(completion: @escaping ([FeedData]?) -> Void) {
        let urlString = "https://sjc.rapidpacket.com/~xtat/bt/latest.json"
        guard let url = URL(string: urlString) else { return }
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
        let item: FeedObject = feed[indexPath.row]
        (cell as? TodayCell)?.setData(feedObject: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}

extension BraveToday: UITableViewDelegate {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        debugPrint(scrollView.contentOffset.y + view.frame.height)
//        if scrollView.contentOffset.y + view.frame.height > 30 {
//            showBraveTodayOnboarding()
//        }
//    }
}

class BraveTodayFeedTable: UITableView {}
