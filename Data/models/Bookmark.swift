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
    /// A date of last visit for a given URL, used in url bar search suggestions.
    @NSManaged public var lastVisited: Date?
    /// A date when of last update of the record. Used in bookmark sorting algorithm.
    @NSManaged public var lastModified: Date?
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
    
    /// If sync is not used, we still utilize its syncOrder algorithm to determine order of bookmarks.
    /// Base order is needed to distinguish between bookmarks on different devices and platforms.
    static var baseOrder: String {
        return Sync.shared.baseSyncOrder ?? "0.0."
    }
    
    override public func willSave() {
        defer { super.willSave() }
        
        // willSave() also triggers on deletes.
        if isDeleted { return }

        let now = Date()
        // willSave() is prone to recursion so we only modify the object there if lastModified property changed.
        // See willSave() documentation for more info.
        if lastModified != now && changedValues()[#keyPath(Bookmark.lastModified)] == nil {
            lastModified = now
            print("old order: \(order)")
            
            if let calculatedOrder = calculateOrder() {
                order = calculatedOrder
                print("calculated order: \(calculatedOrder)")
                print("sync order: \(syncOrder)")
            }
        }
    }
    
    public func asDictionary(deviceId: [Int]?, action: Int?) -> [String: Any] {
        return SyncBookmark(record: self, deviceId: deviceId, action: action).dictionaryRepresentation()
    }
    
    public class func frc(forFavorites: Bool = false, parentFolder: Bookmark?) -> NSFetchedResultsController<Bookmark> {
        let context = DataController.viewContext
        let fetchRequest = NSFetchRequest<Bookmark>()
        
        fetchRequest.entity = Bookmark.entity(context: context)
        fetchRequest.fetchBatchSize = 20
        
        let orderSort = NSSortDescriptor(key: "order", ascending: true)
        let lastModifiedSort = NSSortDescriptor(key: "lastModified", ascending: false) // newer first
        fetchRequest.sortDescriptors = [orderSort, lastModifiedSort]
        
        fetchRequest.predicate = forFavorites ?
            NSPredicate(format: "isFavorite == YES") : allBookmarksOfAGivenLevelPredicate(parent: parentFolder)
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // Syncable
    public func update(syncRecord record: SyncRecord?) {
        guard let bookmark = record as? SyncBookmark, let site = bookmark.site else { return }
        title = site.title
        update(customTitle: site.customTitle, url: site.location, newSyncOrder: bookmark.syncOrder)
        lastVisited = Date(timeIntervalSince1970: (Double(site.lastAccessedTime ?? 0) / 1000.0))
        syncParentUUID = bookmark.parentFolderObjectId
        created = record?.syncNativeTimestamp
        // No auto-save, must be handled by caller if desired
    }
    
    public func update(customTitle: String?, url: String?, newSyncOrder: String? = nil, save: Bool = false,
                       sendToSync: Bool = false) {
        var contextToUpdate: NSManagedObjectContext?
        
        // Syncable.update() doesn't save to CD at the moment, we need to use managedObjectContext here.
        if save == false {
            contextToUpdate = managedObjectContext
            // Updated object usually uses view context, all database writes should happen on a background thread
            // so we need to fetch the object using background context.
        } else if managedObjectContext?.concurrencyType != .privateQueueConcurrencyType {
            contextToUpdate = DataController.newBackgroundContext()
        }
        
        guard let bookmarkToUpdate = (try? contextToUpdate?.existingObject(with: objectID)) as? Bookmark,
            let context = contextToUpdate else {
                return
        }
        
        // See if there has been any change
        if self.customTitle == customTitle && self.url == url && syncOrder == newSyncOrder {
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
        
        if newSyncOrder != nil {
            syncOrder = newSyncOrder
        }
        
        if save {
            DataController.save(context: context)
        }
        
        if !isFavorite && sendToSync {
            Sync.shared.sendSyncRecords(action: .update, records: [bookmarkToUpdate])
        }
    }
    
    public static func add(rootObject root: SyncRecord?, save: Bool, sendToSync: Bool, context: NSManagedObjectContext) -> Syncable? {
        add(rootObject: root as? SyncBookmark,
            save: save,
            sendToSync: sendToSync,
            parentFolder: nil,
            context: context)
        
        // TODO: Saving is done asynchronously, we should return a completion handler.
        // Will probably need a refactor in Syncable protocol.
        // As for now, the return value for adding bookmark is never used.
        return nil
    }
    
    // Should not be used for updating, modify to increase protection
    class func add(rootObject root: SyncBookmark?,
                   save: Bool = false,
                   sendToSync: Bool = false,
                   parentFolder: Bookmark? = nil,
                   context: NSManagedObjectContext = DataController.newBackgroundContext()) -> Bookmark? {
        
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
        
        if bk.lastVisited == nil {
            bk.lastVisited = bk.created
        }
        
        if let location = site?.location, let url = URL(string: location) {
            bk.domain = Domain.getOrCreateForUrl(url, context: context, save: false)
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
            if let children = Bookmark.getChildren(forFolderUUID: bk.syncUUID) {
                
                // TODO: Setup via bk.children property instead
                children.forEach { $0.syncParentUUID = bk.syncParentUUID }
            }
        }
        
        if save {
            DataController.save(context: context)
        }
        
        if sendToSync && !bk.isFavorite {
            // Submit to server, must be on main thread
            Sync.shared.sendSyncRecords(action: .create, records: [bk])
        }
        
        return bk
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
        let context = DataController.newBackgroundContext()
        context.performAndWait {
            list.forEach { fav in
                Bookmark.add(url: fav.url, title: fav.title, isFavorite: true, save: false, context: context)
            }
            DataController.save(context: context)
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
        
        let site = SyncSite()
        site.title = title
        site.customTitle = customTitle
        site.location = url?.absoluteString
        
        let bookmark = SyncBookmark()
        bookmark.isFavorite = isFavorite
        bookmark.isFolder = isFolder
        bookmark.parentFolderObjectId = parentFolder?.syncUUID
        bookmark.site = site
        
        _ = add(rootObject: bookmark, save: save, sendToSync: true, parentFolder: parentFolder, context: context ?? DataController.newBackgroundContext())
    }
    
    public class func contains(url: URL, getFavorites: Bool = false) -> Bool {
        guard let count = count(forUrl: url, getFavorites: getFavorites) else { return false }
        return count > 0
    }
    
    public class func reorderBookmarks(frc: NSFetchedResultsController<Bookmark>?, sourceIndexPath: IndexPath,
                                       destinationIndexPath: IndexPath) {
        guard let frc = frc else { return }
        
        let dest = frc.object(at: destinationIndexPath)
        let src = frc.object(at: sourceIndexPath)
        
        if dest === src { return }
        
        // Note: sync order is also used for ordering favorites and non synchronized bookmarks.
        reorderWithSyncOrder(frc: frc, sourceBookmark: src, destinationBookmark: dest,
                             sourceIndexPath: sourceIndexPath, destinationIndexPath: destinationIndexPath)
        
        // DataController.save(context: frc.managedObjectContext)
        try! frc.managedObjectContext.save()
        if !src.isFavorite { Sync.shared.sendSyncRecords(action: .update, records: [src]) }
    }
    
    private class func reorderWithSyncOrder(frc: NSFetchedResultsController<Bookmark>,
                                            sourceBookmark src: Bookmark,
                                            destinationBookmark dest: Bookmark,
                                            sourceIndexPath: IndexPath,
                                            destinationIndexPath: IndexPath) {
        
        let isMovingUp = sourceIndexPath.row > destinationIndexPath.row
        
        // Depending on drag direction, all other bookmarks are pushed up or down.
        if isMovingUp {
            var prev: String?
            
            // Bookmark at the top has no previous bookmark.
            if destinationIndexPath.row > 0 {
                let index = IndexPath(row: destinationIndexPath.row - 1, section: destinationIndexPath.section)
                prev = frc.object(at: index).syncOrder
            }
            
            let next = dest.syncOrder
            src.syncOrder = Sync.shared.getBookmarkOrder(previousOrder: prev, nextOrder: next)
        } else {
            let prev = dest.syncOrder
            var next: String?
            
            // Bookmark at the bottom has no next bookmark.
            if let objects = frc.fetchedObjects, destinationIndexPath.row + 1 < objects.count {
                let index = IndexPath(row: destinationIndexPath.row + 1, section: destinationIndexPath.section)
                next = frc.object(at: index).syncOrder
            }
            
            src.syncOrder = Sync.shared.getBookmarkOrder(previousOrder: prev, nextOrder: next)
        }
    }
    
    private let syncOrderComparator: (Any, Any) -> ComparisonResult = { obj1, obj2 in
        guard let s1 = obj1 as? String, let s2 = obj2 as? String else {
            fatalError()
        }
        
        // Split is O(n)
        var i1 = s1.split(separator: ".").compactMap { Int($0) }
        var i2 = s2.split(separator: ".").compactMap { Int($0) }
        
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
    
    private func calculateOrder() -> Int16? {
        let predicate = isFavorite ?
            NSPredicate(format: "isFavorite == true") : Bookmark.allBookmarksOfAGivenLevelPredicate(parent: parentFolder)
        
        guard let context = managedObjectContext, let syncOrder = syncOrder else {
            return nil
        }
        
        context.refreshAllObjects()
        
        let orderSort = NSSortDescriptor(key: #keyPath(Bookmark.order), ascending: true)
        
        guard let allBookmarks = Bookmark.all(where: predicate, sortDescriptors: [orderSort], context: context),
                  allBookmarks.count > 1 else {
                return nil
        }
        
        guard let lastOrder = allBookmarks.last?.order else { return nil }
        
        var syncOrders = allBookmarks.compactMap { $0.syncOrder }
        
        let isNewRecord = objectID.isTemporaryID
//        if isNewRecord {
//            syncOrders.append(syncOrder)
//        }

        let sortedSyncOrders = (syncOrders as NSArray).sortedArray(comparator: syncOrderComparator) as NSArray
        let calculatedOrder = sortedSyncOrders.index(of: syncOrder)
        
        
        
        let result = calculatedOrder >= allBookmarks.count - 1 ? Int(lastOrder) + 1 : calculatedOrder
        
        return Int16(result)
    }
    
    /// Takes all Bookmarks and Favorites from 1.6 and sets correct order for them.
    /// 1.6 had few bugs with reordering which we want to avoid, in particular non-reordered bookmarks on 1.6
    /// all have order set to 0 which makes sorting confusing.
    /// In migration we take all bookmarks using the same sorting method as on 1.6 and add a proper `order`
    /// attribute to them. The goal is to have all bookmarks with a proper unique order number set.
    public class func migrateOrder(parentFolder: Bookmark? = nil,
                                   forFavorites: Bool,
                                   context: NSManagedObjectContext = DataController.newBackgroundContext()) {
        
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
        
        DataController.save(context: context)
    }
    
    // TODO: Migration syncUUIDS still needs to be solved
    // Should only ever be used for migration from old db
    // Always uses worker context
    class func addForMigration(url: String?, title: String, customTitle: String, parentFolder: Bookmark?, isFolder: Bool?) -> Bookmark? {
        
        let site = SyncSite()
        site.title = title
        site.customTitle = customTitle
        site.location = url
        
        let bookmark = SyncBookmark()
        bookmark.isFolder = isFolder
        // bookmark.parentFolderObjectId = [parentFolder]
        bookmark.site = site
        
        return self.add(rootObject: bookmark, save: true)
    }
    
    public func remove(sendToSync: Bool = true) {
        if isFavorite { delete() }
        
        // Before we delete a folder and its children, we need to grab all children bookmarks
        // and send them to sync with `delete` action.
        if isFolder && sendToSync {
            removeFolderAndSendSyncRecords(uuid: syncUUID)
            return
        }
        
        if sendToSync {
            Sync.shared.sendSyncRecords(action: .delete, records: [self])
        }
        
        delete()
    }
    
    private func removeFolderAndSendSyncRecords(uuid: [Int]?) {
        if !isFolder { return }
        
        var allBookmarks = [Bookmark]()
        allBookmarks.append(self)
        
        if let allNestedBookmarks = Bookmark.getRecursiveChildren(forFolderUUID: syncUUID) {
            log.warning("All nested bookmarks of :\(String(describing: title)) folder is nil")
            
            allBookmarks.append(contentsOf: allNestedBookmarks)
        }
        
        Sync.shared.sendSyncRecords(action: .delete, records: allBookmarks)
        
        delete()
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
    
    public static func getChildren(forFolderUUID syncUUID: [Int]?, ignoreFolders: Bool = false) -> [Bookmark]? {
        guard let searchableUUID = SyncHelpers.syncDisplay(fromUUID: syncUUID) else {
            return nil
        }
        
        let syncParentDisplayUUIDKeyPath = #keyPath(Bookmark.syncParentDisplayUUID)
        let isFolderKeyPath = #keyPath(Bookmark.isFolder)
        
        let predicate = NSPredicate(format: "\(syncParentDisplayUUIDKeyPath) == %@ AND \(isFolderKeyPath) == %@",
            searchableUUID, NSNumber(value: ignoreFolders))
        
        return all(where: predicate)
    }
    
    static func get(parentSyncUUID parentUUID: [Int]?, context: NSManagedObjectContext?) -> Bookmark? {
        guard let searchableUUID = SyncHelpers.syncDisplay(fromUUID: parentUUID), let context = context else {
            return nil
        }
        
        let predicate = NSPredicate(format: "syncDisplayUUID == %@", searchableUUID)
        return first(where: predicate, context: context)
    }
    
    public static func getFolders(bookmark: Bookmark?, context: NSManagedObjectContext) -> [Bookmark] {
        var predicate: NSPredicate?
        if let parent = bookmark?.parentFolder {
            predicate = NSPredicate(format: "isFolder == true and parentFolder == %@", parent)
        } else {
            predicate = NSPredicate(format: "isFolder == true and parentFolder = nil")
        }
        
        return all(where: predicate) ?? []
    }
    
    static func getAllBookmarks(context: NSManagedObjectContext) -> [Bookmark] {
        let predicate = NSPredicate(format: "isFavorite == NO")
        
        return all(where: predicate) ?? []
    }
    
    public class func remove(forUrl url: URL) {
        let context = DataController.newBackgroundContext()
        let predicate = isFavoriteOrBookmarkByUrlPredicate(url: url, getFavorites: false)
        
        let record = first(where: predicate, context: context)
        record?.delete()
    }
    
    /// Gets all nested bookmarks recursively.
    public static func getRecursiveChildren(forFolderUUID syncUUID: [Int]?,
                                            context: NSManagedObjectContext = DataController.viewContext) -> [Bookmark]? {
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
                if let nestedBookmarks = getRecursiveChildren(forFolderUUID: $0.syncUUID) {
                    allBookmarks.append(contentsOf: nestedBookmarks)
                }
            }
        }
        
        return allBookmarks
    }
    
    public class func frecencyQuery(context: NSManagedObjectContext, containing: String?) -> [Bookmark] {
        let fetchRequest = NSFetchRequest<Bookmark>()
        fetchRequest.fetchLimit = 5
        fetchRequest.entity = Bookmark.entity(context: context)
        
        var predicate = NSPredicate(format: "lastVisited > %@", History.ThisWeek as CVarArg)
        if let query = containing {
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
