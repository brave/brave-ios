// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Shared
import Storage
import SwiftKeychainWrapper
import Deferred

#if MOZ_TARGET_CLIENT
    import SwiftyJSON
#endif

class BraveToday: NSObject {
    static let shared = BraveToday()
    private weak var profile: BrowserProfile?
    
    // session
    // feed state
    
    override init() {
        super.init()
    }
    
    func register(profile: BrowserProfile?) {
        self.profile = profile
        
        // TODO: remove
        clearAll()
    }
    
    func clearAll() {
        _ = profile?.feed.deleteAllRecords()
    }
    
    func loadFeedData() {
        func dateFromStringConverter(date: String) -> Date? {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            return dateFormatter.date(from: date)
        }
        
        requestFeed { [weak self] data in
            guard let data = data else { return }
            for item in data {
                self?.profile?.feed.createRecord(publishTime: item.publishTime, feedSource: item.feedSource, url: item.url, img: item.img, title: item.title, description: item.description)
            }
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
            
            if let response = response as? HTTPURLResponse {
                debugPrint(response.allHeaderFields)
                if let encoding = response.allHeaderFields["Content-Encoding"] as? String {
                    print(encoding)
                    print(encoding == "gzip")
                }
            }

            guard let data = data else { return }
            debugPrint(data)
            do {
                let feed = try JSONDecoder().decode([FeedData].self, from: data)
                print(feed)
                
                completion(feed)
            } catch {
                print(error.localizedDescription)
            }
        }.resume()
    }
}

extension BraveToday: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodayCell", for: indexPath) as UITableViewCell
        
        return cell
    }
    
}

class BraveTodayFeedTable: UITableView {}
