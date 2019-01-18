/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
 If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import CoreData
import Shared
import BraveShared
import JavaScriptCore

private let log = Logger.browserLogger

// Sync related methods for Bookmark model.
extension Bookmark {
    /// If sync is not used, we still utilize its syncOrder algorithm to determine order of bookmarks.
    /// Base order is needed to distinguish between bookmarks on different devices and platforms.
    static var baseOrder: String { return Preferences.Sync.baseSyncOrder.value }
    
    /// Sets order for all bookmarks. Needed after user joins sync group for the first time.
    /// Returns an array of bookmarks with updated `syncOrder`.
    class func updateBookmarksWithNewSyncOrder(parentFolder: Bookmark? = nil,
                                               context: NSManagedObjectContext) -> [Bookmark]? {
        
        var bookmarksToSend = [Bookmark]()
        
        let predicate = allBookmarksOfAGivenLevelPredicate(parent: parentFolder)
        
        let orderSort = NSSortDescriptor(key: #keyPath(Bookmark.order), ascending: true)
        let createdSort = NSSortDescriptor(key: #keyPath(Bookmark.created), ascending: false)
        
        let sort = [orderSort, createdSort]
        
        guard let allBookmarks = all(where: predicate, sortDescriptors: sort, context: context) else {
            return nil
        }
        
        // Sync ordering starts with 1.
        var counter = 1
        
        for bookmark in allBookmarks where bookmark.syncOrder == nil {
            
            if let parent = parentFolder, let syncOrder = parent.syncOrder {
                let order = syncOrder + ".\(counter)"
                bookmark.syncOrder = order
            } else {
                let order = baseOrder + "\(counter)"
                bookmark.syncOrder = order
            }
            
            bookmarksToSend.append(bookmark)
            counter += 1
            
            // Calling this method recursively to get ordering for nested bookmarks
            if bookmark.isFolder {
                if let updatedNestedBookmarks = updateBookmarksWithNewSyncOrder(parentFolder: bookmark,
                                                                                context: context) {
                    bookmarksToSend.append(contentsOf: updatedNestedBookmarks)
                }
            }
        }
        
        return bookmarksToSend
    }
    
    private class func maxSyncOrder(parent: Bookmark?,
                                    forFavorites: Bool,
                                    context: NSManagedObjectContext) -> String? {
        
        let predicate = forFavorites ?
            NSPredicate(format: "isFavorite == true") : allBookmarksOfAGivenLevelPredicate(parent: parent)
        
        guard let allBookmarks = all(where: predicate, context: context) else { return nil }
        
        // New bookmarks are sometimes added to context before this method is called.
        // We need to filter out bookmarks with empty sync orders.
        let highestOrderBookmark = allBookmarks.filter { $0.syncOrder != nil }.max { a, b in
            guard let aOrder = a.syncOrder, let bOrder = b.syncOrder else { return false } // Should be never nil at this point
            
            return aOrder < bOrder
        }
        
        return highestOrderBookmark?.syncOrder
    }
    
    func newSyncOrder(forFavorites: Bool, context: NSManagedObjectContext) {
        let lastBookmarkOrder = Bookmark.maxSyncOrder(parent: parentFolder,
                                                      forFavorites: forFavorites,
                                                      context: context)
        
        // The sync lib javascript method doesn't handle cases when there are no other bookmarks on a given level.
        // We need to do it locally, there are 3 cases:
        // 1. At least one bookmark is present at a given level -> we do the JS call
        // 2. Root level, no bookmarks added -> need to use baseOrder
        // 3. Nested folder, no bookmarks -> need to get parent folder syncOrder
        if lastBookmarkOrder == nil && parentFolder == nil {
            syncOrder = Bookmark.baseOrder + "1"
        } else if let parentOrder = parentFolder?.syncOrder, lastBookmarkOrder == nil {
            syncOrder = parentOrder + ".1"
        } else {
            syncOrder = Sync.shared.getBookmarkOrder(previousOrder: lastBookmarkOrder, nextOrder: nil)
        }
    }
    
    class func removeSyncOrders() {
        let context = DataController.newBackgroundContext()
        let allBookmarks = getAllBookmarks(context: context)
        
        allBookmarks.forEach { bookmark in
            bookmark.syncOrder = nil
            // TODO: Clear syncUUIDs
            //            bookmark.syncUUID = nil
        }
        
        DataController.save(context: context)
        Preferences.Sync.baseSyncOrder.reset()
    }
    
    class func setOrderForAllBookmarksOnGivenLevel(parent: Bookmark?, forFavorites: Bool, context: NSManagedObjectContext) {
        let predicate = forFavorites ?
            NSPredicate(format: "isFavorite == true") : allBookmarksOfAGivenLevelPredicate(parent: parent)
        
        guard let allBookmarks = all(where: predicate, context: context), !allBookmarks.isEmpty else { return }
        
        guard let sortedSyncOrders = (allBookmarks as NSArray).sortedArray(comparator: syncOrderComparator) as? [Bookmark] else {
            return
        }
        
        for (order, bookmark) in sortedSyncOrders.enumerated() {
            bookmark.order = Int16(order)
        }
    }
    
    static let syncOrderComparator: (Any, Any) -> ComparisonResult = { obj1, obj2 in
        guard let s1 = obj1 as? Bookmark, let s2 = obj2 as? Bookmark,
            let order1 = s1.syncOrder, let order2 = s2.syncOrder else {
                fatalError()
        }
        
        // Split is O(n)
        var i1 = order1.split(separator: ".").compactMap { Int($0) }
        var i2 = order2.split(separator: ".").compactMap { Int($0) }
        
        // Preventing going out of bounds.
        let iterationCount = min(i1.count, i2.count)
        
        for i in 0..<iterationCount {
            // We went through all numbers and everything is equal.
            // Need to check if one of arrays has more numbers because 0.0.1.1 > 0.0.1
            //
            // Alternatively, we could append zeros to make int arrays between the two objects
            // have same length. 0.0.1 vs 0.0.1.2 would convert to 0.0.1.0 vs 0.0.1.2
            if i1[i] == i2[i] && (iterationCount - 1) == i {
                if i1.count == i2.count { return .orderedSame }
                if i1.count > i2.count { return .orderedDescending }
                if i1.count < i2.count { return .orderedAscending }
            }
            
            if i1[i] == i2[i] && iterationCount != i { // number equal, going through next one
                continue
            }
            
            if i1[i] > i2[i] { return .orderedDescending }
            if i1[i] < i2[i] { return .orderedAscending }
            
        }
        
        return .orderedSame
    }
}
