// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import Storage
import Data

class FrequencyQuery {
    
    private let historyManager: HistoryManager
    private let bookmarkManager: BookmarkManager
    
    private let queue = DispatchQueue(label: "frequency-query-queue")
    private var cancellable: DispatchWorkItem?
    
    init(historyManager: HistoryManager, bookmarkManager: BookmarkManager) {
        self.historyManager = historyManager
        self.bookmarkManager = bookmarkManager
    }
    
    public func sitesByFrequency(containing query: String? = nil, completion: @escaping (Set<Site>) -> Void) {
        historyManager.byFrequency(query: query) { [weak self] historyList in
            let historySites = historyList
                .map { Site(url: $0.absoluteUrl ?? "", title: $0.title ?? "") }

            self?.cancellable = DispatchWorkItem {
                // brave-core fetch can be slow over 200ms per call,
                // a cancellable serial queue is used for it.
                DispatchQueue.main.async {
                    self?.bookmarkManager.byFrequency(query: query) { sites in
                        let bookmarkSites = sites.map { Site(url: $0.absoluteUrl ?? "", title: $0.title ?? "", bookmarked: true) }

                        let result = Set<Site>(historySites+bookmarkSites)

                        completion(result)
                    }
                }
            }
        }
        
        if let task = cancellable {
            queue.async(execute: task)
        }
    }
}
