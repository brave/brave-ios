// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import Storage
import Data

class FrequencyQuery {
    
    public static func sitesByFrequency(containing query: String? = nil,
                                        completion: @escaping (Set<Site>) -> Void) {
        
        Historyv2.byFrequency(query: query) { historyList in
            let historySites = historyList
                .map { Site(url: $0.url ?? "", title: $0.title ?? "") }
            
            Bookmarkv2.byFrequency(query: query) { bookmarkList in
                let bookmarkSites = bookmarkList
                    .map { Site(url: $0.url ?? "", title: $0.title ?? "", bookmarked: true) }
                
                let result = Set<Site>(historySites + bookmarkSites)
                
                completion(result)
            }
        }
    }
}
