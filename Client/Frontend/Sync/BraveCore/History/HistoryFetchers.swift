// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import CoreData

// MARK: - HistoryV2FetchResultsDelegate

protocol HistoryV2FetchResultsDelegate: AnyObject {
    
    func controllerWillChangeContent(_ controller: HistoryV2FetchResultsController)
    
    func controllerDidChangeContent(_ controller: HistoryV2FetchResultsController)
    
    func controller(_ controller: HistoryV2FetchResultsController, didChange anObject: Any,
                    at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    
    func controller(_ controller: HistoryV2FetchResultsController, didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    
    func controllerDidReloadContents(_ controller: HistoryV2FetchResultsController)
}

// MARK: - HistoryV2FetchResultsController

protocol HistoryV2FetchResultsController {
    
    var delegate: HistoryV2FetchResultsDelegate? { get set }
    
    var fetchedObjects: [Historyv2]? { get }
    
    var fetchedObjectsCount: Int { get }
    
    func performFetch(_ completion: @escaping () -> Void)
    
    func object(at indexPath: IndexPath) -> Historyv2?
}

// MARK: - Historyv2Fetcher

class Historyv2Fetcher: NSObject, HistoryV2FetchResultsController {
    
    // MARK: Lifecycle
    
    init(historyAPI: BraveHistoryAPI) {
        self.historyAPI = historyAPI
        super.init()
    }
    
    // MARK: Internal
    
    weak var delegate: HistoryV2FetchResultsDelegate?
    
    var fetchedObjects: [Historyv2]? {
        return historyList
    }
    
    var fetchedObjectsCount: Int {
        return historyList.count
    }
    
    func performFetch(_ completion: @escaping () -> Void) {
        historyList.removeAll()
        
        historyAPI?.search(withQuery: "", maxCount: 0, completion: { [weak self] historyNodeList in
            guard let self = self else { return }
            self.historyList = historyNodeList.map { Historyv2(with: $0) }
            
            completion()
        })
    }
    
    func object(at indexPath: IndexPath) -> Historyv2? {
        return historyList[safe: indexPath.row]
    }
    
    // MARK: Private
    
    private weak var historyAPI: BraveHistoryAPI?
    
    private var historyList = [Historyv2]()
}
