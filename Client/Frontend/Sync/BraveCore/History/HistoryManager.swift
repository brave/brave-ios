// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data
import BraveCore
import BraveShared
import CoreData
import Shared

class HistoryManager {
    
    // MARK: Lifecycle
    
    init(historyAPI: BraveHistoryAPI?) {
        self.historyAPI = historyAPI
    }
    
    // MARK: Internal
    
    public func add(url: URL, title: String, dateAdded: Date, isURLTyped: Bool = true) {
        guard let historyAPI = historyAPI else {
            return
        }

        let historyNode = HistoryNode(url: url, title: title, dateAdded: dateAdded)
        historyAPI.addHistory(historyNode, isURLTyped: isURLTyped)
    }

    public func frc() -> HistoryV2FetchResultsController? {
        guard let historyAPI = self.historyAPI else {
            return nil
        }

        return Historyv2Fetcher(historyAPI: historyAPI)
    }

    public func delete(_ historyNode: HistoryNode) {
        guard let historyAPI = self.historyAPI else {
            return
        }

        historyAPI.removeHistory(historyNode)
    }

    public func deleteAll(_ completion: @escaping () -> Void) {
        guard let historyAPI = self.historyAPI else {
            return
        }

        historyAPI.removeAll {
            completion()
        }
    }

    public func suffix(_ maxLength: Int, _ completion: @escaping ([HistoryNode]) -> Void) {
        guard let historyAPI = self.historyAPI else {
            return
        }

        historyAPI.search(withQuery: nil, maxCount: UInt(max(20, maxLength)), completion: { historyResults in
            completion(historyResults.map { $0 })
        })
    }

    public func byFrequency(query: String? = nil, _ completion: @escaping ([HistoryNode]) -> Void) {
        guard let query = query, !query.isEmpty,
              let historyAPI = self.historyAPI else {
            return
        }

        historyAPI.search(withQuery: query, maxCount: 200, completion: { historyResults in
            completion(historyResults.map { $0 })
        })
    }

    public func update(_ historyNode: HistoryNode, customTitle: String?, dateAdded: Date?) {
        if let title = customTitle {
            historyNode.title = title
        }

        if let date = dateAdded {
            historyNode.dateAdded = date
        }
    }
    
    // MARK: Private
    
    private var observer: HistoryServiceListener?
    private let historyAPI: BraveHistoryAPI?
}

// MARK: Brave-Core Only

extension HistoryManager {
    
    public func waitForHistoryServiceLoaded(_ completion: @escaping () -> Void) {
        guard let historyAPI = self.historyAPI else { return }
        
        if historyAPI.isBackendLoaded {
            DispatchQueue.main.async {
                completion()
            }
        } else {
            observer = historyAPI.add(HistoryServiceStateObserver({ [weak self] in
                if case .serviceLoaded = $0 {
                    self?.observer?.destroy()
                    self?.observer = nil
                    
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }))
        }
    }
}
