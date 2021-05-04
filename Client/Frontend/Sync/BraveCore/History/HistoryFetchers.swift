// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import CoreData
import OrderedCollections

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
    
    var sectionCount: Int { get }
    
    func performFetch(_ completion: @escaping () -> Void)
    
    func object(at indexPath: IndexPath) -> Historyv2?
    
    func objectCount(for section: Int) -> Int
    
    func titleHeader(for section: Int) -> String

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
    
    var sectionCount: Int {
        return sectionDetails.count
    }
    
    func performFetch(_ completion: @escaping () -> Void) {
        historyList.removeAll()
        
        historyAPI?.search(withQuery: "", maxCount: 0, completion: { [weak self] historyNodeList in
            guard let self = self else { return }
            self.historyList = historyNodeList.map { [unowned self] historyNode in
                let historyItem = Historyv2(with: historyNode)
                
                for section in Historyv2.Section.allCases {
                    if let detailCount = self.sectionDetails[section] {
                        self.sectionDetails.updateValue(detailCount + 1, forKey: section)
                    } else {
                        self.sectionDetails.updateValue(0, forKey: section)
                    }
                }
            
                return historyItem
            }
            
            completion()
        })
    }
    
    func object(at indexPath: IndexPath) -> Historyv2? {
        var (sectionIndex, itemCount) = (0, 0)
        
        repeat {
            itemCount += objectCount(for: sectionIndex)
            
            sectionIndex += 1
        } while sectionIndex == indexPath.section
        
        return historyList[safe: itemCount + indexPath.row]
    }
    
    func objectCount(for section: Int) -> Int {
        return sectionDetails.elements[section].value
    }
    
    func titleHeader(for section: Int) -> String {
        return sectionDetails.elements[section].key.title

    }
    
    // MARK: Private
    
    private weak var historyAPI: BraveHistoryAPI?
    
    private var historyList = [Historyv2]()
    
    private var sectionDetails: OrderedDictionary<Historyv2.Section, Int> = [:]
}
