/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import CoreData
import Foundation
import Shared
import Storage

private let log = Logger.browserLogger

public final class Bookmark: NSManagedObject, WebsitePresentable, Syncable, CRUD {
    // Favorite bookmarks are shown only on homepanel as a tile, they are not visible on bookmarks panel.
    @NSManaged public var isFavorite: Bool
    @NSManaged public var isFolder: Bool
    @NSManaged public var title: String?
    @NSManaged public var customTitle: String?
    @NSManaged public var url: String?
    @NSManaged public var visits: Int32
    @NSManaged public var lastVisited: Date?
    @NSManaged public var created: Date?
    @NSManaged public var order: Int16
    @NSManaged public var tags: [String]?
    @NSManaged public var syncOrder: String?
    
    /// Should not be set directly, due to specific formatting required, use `syncUUID` instead
    /// CD does not allow (easily) searching on transformable properties, could use binary, but would still require tranformtion
    //  syncUUID should never change
    @NSManaged public var syncDisplayUUID: String?
    @NSManaged public var syncParentDisplayUUID: String?
    @NSManaged public var parentFolder: Bookmark?
    @NSManaged public var children: Set<Bookmark>?
    
    @NSManaged public var domain: Domain?
    
    public var recordType: SyncRecordType = .bookmark
    
    var syncParentUUID: [Int]? {
        get { return SyncHelpers.syncUUID(fromString: syncParentDisplayUUID) }
        set(value) {
            // Save actual instance variable
            syncParentDisplayUUID = SyncHelpers.syncDisplay(fromUUID: value)
            
            // Attach parent, only works if parent exists.
            let parent = Bookmark.get(parentSyncUUID: value, context: self.managedObjectContext)
            parentFolder = parent
        }
    }
    
    public var displayTitle: String? {
        if let custom = customTitle, !custom.isEmpty {
            return customTitle
        }
        
        if let t = title, !t.isEmpty {
            return title
        }
        
        // Want to return nil so less checking on frontend
        return nil
    }
    
    public class func frc(forFavorites: Bool = false, parentFolder: Bookmark?) -> NSFetchedResultsController<Bookmark> {
        let context = DataController.viewContext
        let fetchRequest = NSFetchRequest<Bookmark>()
        
        fetchRequest.entity = Bookmark.entity(context: context)
        fetchRequest.fetchBatchSize = 20
        
        let orderSort = NSSortDescriptor(key: "order", ascending: true)
        let createdSort = NSSortDescriptor(key: "created", ascending: false)
        fetchRequest.sortDescriptors = [orderSort, createdSort]
        
        fetchRequest.predicate = forFavorites ?
            NSPredicate(format: "isFavorite == YES") : allBookmarksOfAGivenLevelPredicate(parent: parentFolder)
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }

    public func update(customTitle: String?, url: String?, newSyncOrder: String? = nil, save: Bool = true,
                       sendToSync: Bool = true, context: NSManagedObjectContext? = nil) {
        
        DataController.performTask(context: context) { context in
            guard let bookmarkToUpdate = context.object(with: self.objectID) as? Bookmark else { return }
            
            // See if there has been any change
            if bookmarkToUpdate.customTitle == customTitle && bookmarkToUpdate.url == url && bookmarkToUpdate.syncOrder == newSyncOrder {
                return
            }
            
            if let ct = customTitle, !ct.isEmpty {
                bookmarkToUpdate.customTitle = customTitle
            }
            
            if let u = url, !u.isEmpty {
                bookmarkToUpdate.url = url
                if let theURL = URL(string: u) {
                    bookmarkToUpdate.domain = Domain.getOrCreateForUrl(theURL, context: context)
                } else {
                    bookmarkToUpdate.domain = nil
                }
            }
            
            // Checking if syncOrder has changed is imporant here for performance reasons.
            // Currently to do bookmark sorting right, we have to grab all bookmarks in a given directory
            // and update their order which is a costly operation.
            if newSyncOrder != nil && bookmarkToUpdate.syncOrder != newSyncOrder {
                bookmarkToUpdate.syncOrder = newSyncOrder
                Bookmark.setOrderForAllBookmarksOnGivenLevel(parent: bookmarkToUpdate.parentFolder, forFavorites: bookmarkToUpdate.isFavorite, context: context)
            }
            
            if !bookmarkToUpdate.isFavorite && sendToSync {
                Sync.shared.sendSyncRecords(action: .update, records: [bookmarkToUpdate], context: context)
            }
        }
    }
    
    // Should not be used for updating, modify to increase protection
    private class func add(rootObject root: SyncBookmark?,
                           save: Bool = true,
                           sendToSync: Bool = true,
                           parentFolder: Bookmark? = nil,
                           context: NSManagedObjectContext? = nil) {
        
        DataController.performTask(context: context, save: save) { context in
            let bookmark = root
            let site = bookmark?.site
            
            var bk: Bookmark!
            
            if let id = root?.objectId, let foundbks = Bookmark.get(syncUUIDs: [id], context: context) as? [Bookmark], let foundBK = foundbks.first {
                // Found a pre-existing bookmark, cannot add duplicate
                // Turn into 'update' record instead
                bk = foundBK
            } else {
                bk = Bookmark(entity: Bookmark.entity(context: context), insertInto: context)
            }
            
            // BRAVE TODO:
            // if site?.location?.startsWith(WebServer.sharedInstance.base) ?? false {
            //    return nil
            // }
            
            // Use new values, fallback to previous values
            bk.url = site?.location ?? bk.url
            bk.title = site?.title ?? bk.title
            bk.customTitle = site?.customTitle ?? bk.customTitle // TODO: Check against empty titles
            bk.isFavorite = bookmark?.isFavorite ?? bk.isFavorite
            bk.isFolder = bookmark?.isFolder ?? bk.isFolder
            bk.syncUUID = root?.objectId ?? bk.syncUUID ?? SyncCrypto.uniqueSerialBytes(count: 16)
            bk.syncOrder = root?.syncOrder
            bk.created = root?.syncNativeTimestamp ?? Date()
            bk.lastVisited = bk.created
            
            if let location = site?.location, let url = URL(string: location) {
                bk.domain = Domain.getOrCreateForUrl(url, context: context, save: false)
            }
            
            // Update parent folder if one exists
            if let newParent = bookmark?.parentFolderObjectId {
                bk.syncParentUUID = newParent
            }
            
            if bk.syncOrder == nil {
                bk.newSyncOrder(forFavorites: bk.isFavorite, context: context)
            }
            
            // This also sets up a parent folder
            bk.syncParentUUID = bookmark?.parentFolderObjectId ?? bk.syncParentUUID
            
            // For folders that are saved _with_ a syncUUID, there may be child bookmarks
            //  (e.g. sync sent down bookmark before parent folder)
            if bk.isFolder {
                // Find all children and attach them
                if let children = Bookmark.getChildren(forFolderUUID: bk.syncUUID, context: context) {
                    // Re-link all orphaned children
                    children.forEach {
                        $0.syncParentUUID = bk.syncUUID
                        // The setter for syncParentUUID creates the parent/child relationship in CD, however in this specific instance
                        // the objects have not been written to disk, so cannot be fetched on a different context and the relationship
                        // will not be properly established. Manual attachment is necessary here during these batch additions.
                        $0.parentFolder = bk
                    }
                }
            }
            
            setOrderForAllBookmarksOnGivenLevel(parent: bk.parentFolder, forFavorites: bk.isFavorite,
                                                context: context)
            
            if sendToSync && !bk.isFavorite {
                // Submit to server, must be on main thread
                Sync.shared.sendSyncRecords(action: .create, records: [bk])
            }
        }
    }
    
    class func allBookmarksOfAGivenLevelPredicate(parent: Bookmark?) -> NSPredicate {
        let isFavoriteKP = #keyPath(Bookmark.isFavorite)
        let parentFolderKP = #keyPath(Bookmark.parentFolder)
        
        // A bit hacky but you can't just pass 'nil' string to %@.
        let nilArgumentForPredicate = 0
        return NSPredicate(
            format: "%K == %@ AND %K == NO", parentFolderKP, parent ?? nilArgumentForPredicate, isFavoriteKP)
    }
    
    public class func add(from list: [(url: URL, title: String)]) {
        DataController.performTask { context in
            list.forEach { fav in
                Bookmark.add(url: fav.url, title: fav.title, isFavorite: true, save: false, context: context)
            }
        }
    }
    
    public class func add(url: URL?,
                          title: String?,
                          customTitle: String? = nil, // Folders only use customTitle
                          parentFolder: Bookmark? = nil,
                          isFolder: Bool = false,
                          isFavorite: Bool = false,
                          syncOrder: String? = nil,
                          save: Bool = true,
                          context: NSManagedObjectContext? = nil) {
        
        DataController.performTask(context: context) { context in
            let site = SyncSite()
            site.title = title
            site.customTitle = customTitle
            site.location = url?.absoluteString
            
            let bookmark = SyncBookmark()
            bookmark.isFavorite = isFavorite
            bookmark.isFolder = isFolder
            
            var parentFolderOnCorrectContext: Bookmark?
            
            if let parent = parentFolder {
                parentFolderOnCorrectContext = context.object(with: parent.objectID) as? Bookmark
                
            }
            
            bookmark.parentFolderObjectId = parentFolderOnCorrectContext?.syncUUID
            bookmark.site = site
            
            add(rootObject: bookmark, save: save, sendToSync: true,
                parentFolder: parentFolderOnCorrectContext, context: context)
        }
    }
    
    public class func contains(url: URL, getFavorites: Bool = false) -> Bool {
        guard let count = count(forUrl: url, getFavorites: getFavorites) else { return false }
        return count > 0
    }
    
    /// Reordering bookmarks has two steps:
    /// 1. Sets new `syncOrder` for the source(moving) Bookmark
    /// 2. Recalculates `syncOrder` for all Bookmarks on a given level. This is required because
    /// we use a special String-based order and algorithg. Simple String comparision doesn't work here.
    public class func reorderBookmarks(frc: NSFetchedResultsController<Bookmark>?, sourceIndexPath: IndexPath,
                                       destinationIndexPath: IndexPath) {
        guard let frc = frc else { return }
        
        let dest = frc.object(at: destinationIndexPath)
        let src = frc.object(at: sourceIndexPath)
        
        if dest === src {
            log.error("Source and destination bookmarks are the same!")
            return
        }
        
        // To avoid mixing threads, the FRC can't be used within background context operation.
        // We take data that relies on the FRC on main thread and pass it into background context
        // in a safely manner.
        guard let data = getReorderData(fromFrc: frc, sourceIndexPath: sourceIndexPath,
                                        destinationIndexPath: destinationIndexPath) else {
            log.error("""
                Failed to receive enough data from FetchedResultsController \
                to perform bookmark reordering.
                """)
            return
        }
        
        DataController.performTask { context in
            // To get reordering right, 3 Bookmark objects are needed:
            
            // 1. Source Bookmark - A Bookmark that we are moving with a drag operation
            // 2. Destination Bookmark - A Bookmark, which is a neighbour Bookmark depending on drag direction:
            // a) when moving from bottom to top, all other bookmarks are pushed up
            // and the destination bookmark is placed before the source Bookmark
            // b) when moving frop top to bottom, all other bookmarks are pushed down
            // and the destination bookmark is placed after the source Bookmark.
            guard let srcBookmark = context.bookmark(with: src.objectID),
                let destBookmark = context.bookmark(with: dest.objectID) else {
                    log.error("Could not retrieve source or destination bookmark on background context.")
                return
            }
            
            // Third object is next or previous Bookmark, depending on drag direction.
            // This Bookmark can also be empty when the source Bookmark is moved to the top or bottom
            // of the Bookmark collection.
            var nextOrPreviousBookmark: Bookmark?
            if let previousObjectId = data.nextOrPreviousBookmarkId {
                nextOrPreviousBookmark = context.bookmark(with: previousObjectId)
            }
            
            // syncOrder should be always set. Even if Sync is not initiated, we use
            // defualt local ordering starting with syncOrder = 0.0.1, 0.0.2 and so on.
            guard let destinationBookmarkSyncOrder = destBookmark.syncOrder else {
                log.error("syncOrder of destination bookmark is nil.")
                return
            }
            
            var previousOrder: String?
            var nextOrder: String?
            
            switch data.reorderMovement {
            case .up(let toTheTop):
                // Going up pushes all bookmarks down, so the destination bookmark is after the source bookmark
                nextOrder = destinationBookmarkSyncOrder
                if !toTheTop {
                    guard let previousSyncOrder = nextOrPreviousBookmark?.syncOrder else {
                        log.error("syncOrder of the previous bookmark is nil.")
                        return
                    }
                    previousOrder = previousSyncOrder
                }
            case .down(let toTheBottom):
                // Going down pushes all bookmark up, so the destinatoin bookmark is before the source bookmark.
                previousOrder = destinationBookmarkSyncOrder
                if !toTheBottom {
                    guard let nextSyncOrder = nextOrPreviousBookmark?.syncOrder else {
                        log.error("syncOrder of the next bookmark is nil.")
                        return
                    }
                    nextOrder = nextSyncOrder
                }
            }
            
            guard let updatedSyncOrder = Sync.shared.getBookmarkOrder(previousOrder: previousOrder, nextOrder: nextOrder) else {
                log.error("updated syncOrder from the javascript method was nil")
                return
            }
            
            srcBookmark.syncOrder = updatedSyncOrder
            // Now that we updated the `syncOrder` we have to go through all Bookmarks and update its `order`
            // attributes.
            self.setOrderForAllBookmarksOnGivenLevel(parent: srcBookmark.parentFolder,
                                                     forFavorites: srcBookmark.isFavorite, context: context)
            if !srcBookmark.isFavorite {
                Sync.shared.sendSyncRecords(action: .update, records: [srcBookmark])
            }
        }
    }
    
    private enum ReorderMovement {
        case up(toTheTop: Bool)
        case down(toTheBottom: Bool)
    }
    
    private struct FrcReorderData {
        let nextOrPreviousBookmarkId: NSManagedObjectID?
        /// The dragged Bookmark can go in two directions each having two types, so 4 ways in total:
        /// 1. Go all way to the top
        /// 2. Go up(between two Bookmarks)
        /// 3. Go all way to the bottom
        /// 4. Go down(between two Bookmarks)
        let reorderMovement: ReorderMovement
    }
    
    private class func getReorderData(fromFrc frc: NSFetchedResultsController<Bookmark>,
                                      sourceIndexPath src: IndexPath,
                                      destinationIndexPath dest: IndexPath) -> FrcReorderData? {
        
        var data: FrcReorderData?
        
        guard let count = frc.fetchedObjects?.count else {
            log.error("frc.fetchedObject is nil")
            return nil
        }
        
        var nextOrPreviousBookmarkObjectId: NSManagedObjectID?
        var reorderMovement: ReorderMovement?
        
        let isMovingUp = src.row > dest.row
        
        if isMovingUp {
            let bookmarkMovedToTop = dest.row == 0
            if !bookmarkMovedToTop {
                let previousBookmarkIndex = IndexPath(row: dest.row - 1, section: dest.section)
                nextOrPreviousBookmarkObjectId = frc.object(at: previousBookmarkIndex).objectID
            }
            
            reorderMovement = bookmarkMovedToTop ? .up(toTheTop: true) : .up(toTheTop: false)
        } else {
            let bookmarkMovedToBottom = dest.row + 1 >= count
            if !bookmarkMovedToBottom {
                let nextBookmarkIndex = IndexPath(row: dest.row + 1, section: dest.section)
                nextOrPreviousBookmarkObjectId = frc.object(at: nextBookmarkIndex).objectID
            }
            
            reorderMovement = bookmarkMovedToBottom ? .down(toTheBottom: true) : .down(toTheBottom: false)
        }
        
        guard let movement = reorderMovement else { fatalError() }
        
        data = FrcReorderData(nextOrPreviousBookmarkId: nextOrPreviousBookmarkObjectId,
                              reorderMovement: movement)
        
        return data
    }
    
    public class func migrateBookmarkOrders() {
        DataController.performTask { context in
            Bookmark.migrateOrder(forFavorites: true, context: context)
            Bookmark.migrateOrder(forFavorites: false, context: context)
        }
    }
    
    /// Takes all Bookmarks and Favorites from 1.6 and sets correct order for them.
    /// 1.6 had few bugs with reordering which we want to avoid, in particular non-reordered bookmarks on 1.6
    /// all have order set to 0 which makes sorting confusing.
    /// In migration we take all bookmarks using the same sorting method as on 1.6 and add a proper `order`
    /// attribute to them. The goal is to have all bookmarks with a proper unique order number set.
    private class func migrateOrder(parentFolder: Bookmark? = nil,
                                   forFavorites: Bool,
                                   context: NSManagedObjectContext) {
        
        let predicate = forFavorites ?
            NSPredicate(format: "isFavorite == true") : allBookmarksOfAGivenLevelPredicate(parent: parentFolder)
        
        let orderSort = NSSortDescriptor(key: #keyPath(Bookmark.order), ascending: true)
        let folderSort = NSSortDescriptor(key: #keyPath(Bookmark.isFolder), ascending: false)
        let createdSort = NSSortDescriptor(key: #keyPath(Bookmark.created), ascending: true)
        
        let sort = [orderSort, folderSort, createdSort]
        
        guard let allBookmarks = all(where: predicate, sortDescriptors: sort, context: context),
            !allBookmarks.isEmpty else {
                return
        }
        
        for (i, bookmark) in allBookmarks.enumerated() {
            bookmark.order = Int16(i)
            // Calling this method recursively to get ordering for nested bookmarks
            if !forFavorites && bookmark.isFolder {
                migrateOrder(parentFolder: bookmark, forFavorites: forFavorites, context: context)
            }
        }
    }
    
    public func delete(save: Bool = true, sendToSync: Bool = true, context: NSManagedObjectContext? = nil) {
        func deleteFromStore(context: NSManagedObjectContext?) {
            DataController.performTask { context in
                let objectOnContext = context.object(with: self.objectID)
                context.delete(objectOnContext)
                if save { DataController.save(context: context)}
            }
        }
        
        if isFavorite { deleteFromStore(context: context) }
        
        if sendToSync {
            // Before we delete a folder and its children, we need to grab all children bookmarks
            // and send them to sync with `delete` action.
            if isFolder {
                removeFolderAndSendSyncRecords(uuid: syncUUID)
            } else {
                Sync.shared.sendSyncRecords(action: .delete, records: [self])
            }
        }
        
        deleteFromStore(context: context)
    }
    
    /// Removes a single Bookmark of a given URL.
    /// In case of having two bookmarks with the same url, a bookmark to delete is chosen randomly.
    public class func remove(forUrl url: URL) {
        DataController.performTask { context in
            let predicate = isFavoriteOrBookmarkByUrlPredicate(url: url, getFavorites: false)
            
            let record = first(where: predicate, context: context)
            record?.delete(context: context)
        }
    }
    
    private func removeFolderAndSendSyncRecords(uuid: [Int]?) {
        if !isFolder { return }
        
        var allBookmarks = [Bookmark]()
        allBookmarks.append(self)
        
        DataController.performTask { context in
            if let allNestedBookmarks = Bookmark.getRecursiveChildren(forFolderUUID: self.syncUUID, context: context) {
                log.warning("All nested bookmarks of :\(String(describing: self.title)) folder is nil")
                
                allBookmarks.append(contentsOf: allNestedBookmarks)
            }
            
            Sync.shared.sendSyncRecords(action: .delete, records: allBookmarks)
            
            self.delete(context: context)
        }
    }
}

// TODO: Document well
// MARK: - Getters
extension Bookmark {
    fileprivate static func count(forUrl url: URL, getFavorites: Bool = false) -> Int? {
        let predicate = isFavoriteOrBookmarkByUrlPredicate(url: url, getFavorites: getFavorites)
        return count(predicate: predicate)
    }
    
    private static func isFavoriteOrBookmarkByUrlPredicate(url: URL, getFavorites: Bool) -> NSPredicate {
        let urlKeyPath = #keyPath(Bookmark.url)
        let isFavoriteKeyPath = #keyPath(Bookmark.isFavorite)
        
        return NSPredicate(format: "\(urlKeyPath) == %@ AND \(isFavoriteKeyPath) == \(NSNumber(value: getFavorites))", url.absoluteString)
    }
    
    public static func getChildren(forFolderUUID syncUUID: [Int]?, includeFolders: Bool = true,
                                   context: NSManagedObjectContext? = nil) -> [Bookmark]? {
        let context = context ?? DataController.viewContext
        guard let searchableUUID = SyncHelpers.syncDisplay(fromUUID: syncUUID) else {
            return nil
        }
        
        let syncParentDisplayUUIDKeyPath = #keyPath(Bookmark.syncParentDisplayUUID)
        let isFolderKeyPath = #keyPath(Bookmark.isFolder)
        
        var query = "\(syncParentDisplayUUIDKeyPath) == %@"
        
        if !includeFolders {
            query += " AND \(isFolderKeyPath) == false"
        }
        
        let predicate = NSPredicate(format: query, searchableUUID)
        
        return all(where: predicate, context: context)
    }
    
    static func get(parentSyncUUID parentUUID: [Int]?, context: NSManagedObjectContext?) -> Bookmark? {
        guard let searchableUUID = SyncHelpers.syncDisplay(fromUUID: parentUUID), let context = context else {
            return nil
        }
        
        let predicate = NSPredicate(format: "syncDisplayUUID == %@", searchableUUID)
        return first(where: predicate, context: context)
    }
    
    public static func getFolders(bookmark: Bookmark?, context: NSManagedObjectContext? = nil) -> [Bookmark] {
        var predicate: NSPredicate?
        if let parent = bookmark?.parentFolder {
            predicate = NSPredicate(format: "isFolder == true and parentFolder == %@", parent)
        } else {
            predicate = NSPredicate(format: "isFolder == true and parentFolder = nil")
        }
        
        return all(where: predicate, context: context) ?? []
    }
    
    static func getAllBookmarks(context: NSManagedObjectContext) -> [Bookmark] {
        let predicate = NSPredicate(format: "isFavorite == NO")
        
        return all(where: predicate, context: context) ?? []
    }
    
    /// Gets all nested bookmarks recursively.
    public static func getRecursiveChildren(forFolderUUID syncUUID: [Int]?, context: NSManagedObjectContext) -> [Bookmark]? {
        guard let searchableUUID = SyncHelpers.syncDisplay(fromUUID: syncUUID) else {
            return nil
        }
        
        let syncParentDisplayUUIDKeyPath = #keyPath(Bookmark.syncParentDisplayUUID)
        
        let predicate = NSPredicate(format: "\(syncParentDisplayUUIDKeyPath) == %@", searchableUUID)
        
        var allBookmarks = [Bookmark]()
        
        let result = all(where: predicate, context: context)
        
        result?.forEach {
            allBookmarks.append($0)
            
            if $0.isFolder {
                if let nestedBookmarks = getRecursiveChildren(forFolderUUID: $0.syncUUID, context: context) {
                    allBookmarks.append(contentsOf: nestedBookmarks)
                }
            }
        }
        
        return allBookmarks
    }
}

// MARK: - Syncable methods
extension Bookmark {
    public static func createResolvedRecord(rootObject root: SyncRecord?, save: Bool,
                                            context: NSManagedObjectContext) {
        add(rootObject: root as? SyncBookmark,
            save: save,
            sendToSync: false,
            context: context)
        
        // TODO: Saving is done asynchronously, we should return a completion handler.
        // Will probably need a refactor in Syncable protocol.
        // As for now, the return value for adding bookmark is never used.
    }

    public func updateResolvedRecord(_ record: SyncRecord?, context: NSManagedObjectContext? = nil) {
        guard let bookmark = record as? SyncBookmark, let site = bookmark.site else { return }
        title = site.title
        update(customTitle: site.customTitle, url: site.location,
               newSyncOrder: bookmark.syncOrder, save: false, sendToSync: false, context: context)
        lastVisited = Date(timeIntervalSince1970: (Double(site.lastAccessedTime ?? 0) / 1000.0))
        syncParentUUID = bookmark.parentFolderObjectId
        if let recordCreated = record?.syncNativeTimestamp {
            created = recordCreated
        }
        // No auto-save, must be handled by caller if desired
    }
    
    public func deleteResolvedRecord(save: Bool, context: NSManagedObjectContext?) {
        delete(save: save, sendToSync: false, context: context)
    }
    
    public func asDictionary(deviceId: [Int]?, action: Int?) -> [String: Any] {
        return SyncBookmark(record: self, deviceId: deviceId, action: action).dictionaryRepresentation()
    }
}

// MARK: - Comparable
extension Bookmark: Comparable {
    // Please note that for equality check `syncUUID` is used
    // but for checking if a Bookmark is less/greater than another Bookmark we check using `syncOrder`
    public static func == (lhs: Bookmark, rhs: Bookmark) -> Bool {
        return lhs.syncUUID == rhs.syncUUID
    }
    
    public static func < (lhs: Bookmark, rhs: Bookmark) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }
    
    private func compare(_ rhs: Bookmark) -> ComparisonResult {
        
        guard let lhsSyncOrder = syncOrder, let rhsSyncOrder = rhs.syncOrder else {
            log.info("""
                Wanting to compare bookmark: \(String(describing: displayTitle)) \
                and \(String(describing: rhs.displayTitle)) but no syncOrder is set \
                in at least one of them.
                """)
            return .orderedSame
        }
        
        // Split is O(n)
        let lhsSyncOrderBits = lhsSyncOrder.split(separator: ".").compactMap { Int($0) }
        let rhsSyncOrderBits = rhsSyncOrder.split(separator: ".").compactMap { Int($0) }
        
        // Preventing going out of bounds.
        for i in 0..<min(lhsSyncOrderBits.count, rhsSyncOrderBits.count) {
            let comparison = lhsSyncOrderBits[i].compare(rhsSyncOrderBits[i])
            if comparison != .orderedSame { return comparison }
        }
        
        // We went through all numbers and everything is equal.
        // Need to check if one of arrays has more numbers because 0.0.1.1 > 0.0.1
        //
        // Alternatively, we could append zeros to make int arrays between the two objects
        // have same length. 0.0.1 vs 0.0.1.2 would convert to 0.0.1.0 vs 0.0.1.2
        return lhsSyncOrderBits.count.compare(rhsSyncOrderBits.count)
    }
}

extension Bookmark: Frecencyable {
    static func getByFrecency(query: String? = nil,
                              context: NSManagedObjectContext? = nil) -> [WebsitePresentable] {
        let context = context ?? DataController.viewContext
        let fetchRequest = NSFetchRequest<Bookmark>()
        fetchRequest.fetchLimit = 5
        fetchRequest.entity = Bookmark.entity(context: context)
        
        var predicate = NSPredicate(format: "lastVisited > %@", History.ThisWeek as CVarArg)
        if let query = query {
            predicate = NSPredicate(format: predicate.predicateFormat + " AND url CONTAINS %@", query)
        }
        fetchRequest.predicate = predicate
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            log.error(error)
        }
        return [Bookmark]()
    }
}

extension Int {
    func compare(_ against: Int) -> ComparisonResult {
        if self > against { return .orderedDescending }
        if self < against { return .orderedAscending }
        return .orderedSame
    }
}

private extension NSManagedObjectContext {
    /// Returns a Bookmark for a given object id.
    /// This operation is thread-safe.
    func bookmark(with id: NSManagedObjectID) -> Bookmark? {
        return self.object(with: id) as? Bookmark
    }
}
