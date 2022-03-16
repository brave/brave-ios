// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import Storage
import Data
import BraveCore

class FrequencyQuery {
    
    private let historyAPI: BraveHistoryAPI
    private let bookmarkManager: BookmarkManager
    
    private let frequencyQueue = DispatchQueue(label: "frequency-query-queue")
    private var task: DispatchWorkItem?
    
    init(historyAPI: BraveHistoryAPI, bookmarkManager: BookmarkManager) {
        self.historyAPI = historyAPI
        self.bookmarkManager = bookmarkManager
    }
    
    deinit {
        task?.cancel()
    }
    
    public func sitesByFrequency(containing query: String, completion: @escaping ([Site]) -> Void) {
        task?.cancel()

        var searchResult = [Site]()
        
        task = DispatchWorkItem {
            // brave-core fetch can be slow over 200ms per call,
            // a cancellable serial queue is used for it.
            DispatchQueue.main.async {
                // History Fetch
                self.historyAPI.byFrequency(query: query) { historyList in
                    let historySites = historyList.map { Site(url: $0.url.absoluteString, title: $0.title ?? "", siteType: .history) }
                    searchResult += historySites
                    
                    // Bookmarks Fetch
                    self.bookmarkManager.byFrequency(query: query) { sites in
                        let bookmarkSites = sites.map { Site(url: $0.url ?? "", title: $0.title ?? "", siteType: .bookmark) }
                        searchResult += bookmarkSites
                        
                        completion(searchResult)
                    }
                }
            }
        }
        
        if let task = self.task {
            frequencyQueue.async(execute: task)
        }
    }
}
