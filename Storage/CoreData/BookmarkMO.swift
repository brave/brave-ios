/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import CoreData 

public class BookmarkMO: NSManagedObject, Syncable {
    public var recordType: SyncRecordType = .bookmark

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
    
    /// Should not be set directly, due to specific formatting required, use `syncUUID` instead
    /// CD does not allow (easily) searching on transformable properties, could use binary, but would still require tranformtion
    //  syncUUID should never change
    @NSManaged public var syncDisplayUUID: String?
    @NSManaged public var syncParentDisplayUUID: String?
    @NSManaged public var parentFolder: BookmarkMO?
    @NSManaged public var children: Set<BookmarkMO>?
    
    @NSManaged public var domain: DomainMO?
    
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
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        created = Date()
        lastVisited = created
    }
    
//    func asDictionary(deviceId: [Int]?, action: Int?) -> [String: Any] {
//        return SyncBookmark(record: self, deviceId: deviceId, action: action).dictionaryRepresentation()
//    }

    public class func frc(parentFolder: BookmarkMO?) -> NSFetchedResultsController<NSFetchRequestResult> {
        let context = DataManager.shared.mainThreadContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        
        fetchRequest.entity = BookmarkMO.entity()
        fetchRequest.fetchBatchSize = 20

        let orderSort = NSSortDescriptor(key:"order", ascending: true)
        let createdSort = NSSortDescriptor(key:"created", ascending: false)
        fetchRequest.sortDescriptors = [orderSort, createdSort]

        if let parentFolder = parentFolder {
            fetchRequest.predicate = NSPredicate(format: "parentFolder == %@ AND isFavorite == NO", parentFolder)
        } else {
            fetchRequest.predicate = NSPredicate(format: "parentFolder == nil AND isFavorite == NO")
        }

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:context,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }
    
    public func asDictionary(deviceId: [Int]?, action: Int?) -> [String: Any] {
        return SyncBookmark(record: self, deviceId: deviceId, action: action).dictionaryRepresentation()
    }
    
    // Syncable
    public func update(syncRecord record: SyncRecord?) {
        guard let bookmark = record as? SyncBookmark, let site = bookmark.site else { return }
        title = site.title
        update(customTitle: site.customTitle, url: site.location)
        lastVisited = Date(timeIntervalSince1970:(Double(site.lastAccessedTime ?? 0) / 1000.0))
        // FIXME: Sync
        // syncParentUUID = bookmark.parentFolderObjectId
        // No auto-save, must be handled by caller if desired
    }
    
    public static func add(rootObject root: SyncRecord?, save: Bool, sendToSync: Bool, context: NSManagedObjectContext) -> Syncable? {
        // Explicit parentFolder to force method decision
        return add(rootObject: root as? SyncBookmark, save: save, sendToSync: sendToSync, parentFolder: nil, context: context)
    }
    
    // Should not be used for updating, modify to increase protection
    public class func add(rootObject root: SyncBookmark?, save: Bool = false, sendToSync: Bool = false, parentFolder: BookmarkMO? = nil, context: NSManagedObjectContext) -> BookmarkMO? {
        let bookmark = root
        let site = bookmark?.site
        
        var bk: BookmarkMO!
        if let id = root?.objectId, let foundbks = BookmarkMO.get(syncUUIDs: [id], context: context) as? [BookmarkMO], let foundBK = foundbks.first {
            // Found a pre-existing bookmark, cannot add duplicate
            // Turn into 'update' record instead
            bk = foundBK
        } else {
            bk = BookmarkMO(entity: BookmarkMO.entity(context: context), insertInto: context)
        }
        
        // FIXME: WebServer?
        /*
         // Should probably have visual indication before reaching this point
         if site?.location?.startsWith(WebServer.sharedInstance.base) ?? false {
         return nil
         }
         */
        
        // Use new values, fallback to previous values
        bk.url = site?.location ?? bk.url
        bk.title = site?.title ?? bk.title
        bk.customTitle = site?.customTitle ?? bk.customTitle // TODO: Check against empty titles
        bk.isFavorite = bookmark?.isFavorite ?? bk.isFavorite
        bk.isFolder = bookmark?.isFolder ?? bk.isFolder
        // FIXME: Sync
        // bk.syncUUID = root?.objectId ?? bk.syncUUID ?? SyncCrypto.shared.uniqueSerialBytes(count: 16)
        bk.created = site?.creationNativeDate ?? Date()
        bk.lastVisited = site?.lastAccessedNativeDate ?? Date()
        
        if let location = site?.location, let url = URL(string: location) {
            bk.domain = DomainMO.getOrCreateForUrl(url, context: context)
        }
        
        // Must assign both, in cae parentFolder does not exist, need syncParentUUID to attach later
        bk.parentFolder = parentFolder
        // FIXME: Sync
        // bk.syncParentUUID = bookmark?.parentFolderObjectId ?? bk.syncParentUUID
        
        // For folders that are saved _with_ a syncUUID, there may be child bookmarks
        //  (e.g. sync sent down bookmark before parent folder)
        if bk.isFolder {
            // Find all children and attach them
            if let children = BookmarkMO.getChildren(forFolderUUID: bk.syncUUID, context: context) {
                
                // TODO: Setup via bk.children property instead
                children.forEach { $0.parentFolder = bk }
            }
        }
        
        if save {
            DataManager.saveContext(context: context)
        }
        
        // FIXME: Sync
        /*
         if sendToSync && !bk.isFavorite {
         // Submit to server
         Sync.shared.sendSyncRecords(action: .create, records: [bk])
         }
         */
        
        return bk
    }
    
    // TODO: DELETE
    // Aways uses main context
    @discardableResult class func add(url: URL?,
                                      title: String?,
                                      customTitle: String? = nil, // Folders only use customTitle
        parentFolder:BookmarkMO? = nil,
        isFolder: Bool = false,
        isFavorite: Bool = false) -> BookmarkMO? {
        
        let site = SyncSite()
        site.title = title
        site.customTitle = customTitle
        site.location = url?.absoluteString
        
        let bookmark = SyncBookmark()
        bookmark.isFavorite = isFavorite
        bookmark.isFolder = isFolder
        bookmark.parentFolderObjectId = parentFolder?.syncUUID
        bookmark.site = site
        
        let context = isFavorite ? DataManager.shared.mainThreadContext : DataManager.shared.workerContext
        
        // Fetching bookmarks happen on mainThreadContext but we add it on worker context to work around the 
        // duplicated bookmarks bug.
        // To avoid CoreData crashes we get the parent folder on worker context via its objectID.
        // Favorites can't be nested, this is only relevant for bookmarks.
        var folderOnWorkerContext: BookmarkMO?
        if let folder = parentFolder {
            folderOnWorkerContext = (try? context.existingObject(with: folder.objectID)) as? BookmarkMO
        } 
        
        // Using worker context here, this propogates up, and merged into main.
        // There is some odd issue with duplicates when using main thread
        return self.add(rootObject: bookmark, save: true, sendToSync: true, parentFolder: folderOnWorkerContext, context: context)
    }
    
    static func getChildren(forFolderUUID syncUUID: [Int]?, ignoreFolders: Bool = false, context: NSManagedObjectContext,
                            orderSort: Bool = false) -> [BookmarkMO]? {
        guard let searchableUUID = SyncHelpers.syncDisplay(fromUUID: syncUUID) else {
            return nil
        }
        
        // New bookmarks are added with order 0, we are looking at created date then
        let sortRules = [NSSortDescriptor(key:"order", ascending: true), NSSortDescriptor(key:"created", ascending: false)]
        let sort = orderSort ? sortRules : nil
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = BookmarkMO.entity(context: context)
        fetchRequest.predicate =  NSPredicate(format: "syncParentDisplayUUID == %@ and isFolder == %@", searchableUUID, ignoreFolders ? "true" : "false")
        fetchRequest.sortDescriptors = sort
        
        do {
            let results = try context.fetch(fetchRequest) as? [BookmarkMO]
            return results
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return nil
    }
    
    public func update(customTitle: String?, url: String?, save: Bool = false) {
        
        // See if there has been any change
        if self.customTitle == customTitle && self.url == url {
            return
        }
        
        if let ct = customTitle, !ct.isEmpty {
            self.customTitle = customTitle
        }
        
        if let u = url, !u.isEmpty {
            self.url = url
        }
        
        if save {
            DataManager.saveContext(context: self.managedObjectContext)
        }
    }

    public class func contains(url: URL, getFavorites: Bool = false, context: NSManagedObjectContext) -> Bool {
        var found = false
        context.performAndWait {
            if let count = get(forUrl: url, countOnly: true, getFavorites: getFavorites, context: context) as? Int {
                found = count > 0
            }
        }
        return found
    }

    public class func frecencyQuery(context: NSManagedObjectContext, containing: String?) -> [BookmarkMO] {
        assert(!Thread.isMainThread)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.fetchLimit = 5
        fetchRequest.entity = BookmarkMO.entity()
        
        var predicate = NSPredicate(format: "lastVisited > %@", HistoryMO.ThisWeek as CVarArg)
        if let query = containing {
            predicate = NSPredicate(format: predicate.predicateFormat + " AND url CONTAINS %@", query)
        }
        fetchRequest.predicate = predicate

        do {
            if let results = try context.fetch(fetchRequest) as? [BookmarkMO] {
                return results
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return [BookmarkMO]()
    }

    public class func reorderBookmarks(frc: NSFetchedResultsController<NSFetchRequestResult>?, sourceIndexPath: IndexPath,
                                destinationIndexPath: IndexPath) {
        let dest = frc?.object(at: destinationIndexPath) as! BookmarkMO
        let src = frc?.object(at: sourceIndexPath) as! BookmarkMO
        
        if dest === src {
            return
        }
        
        // Warning, this could be a bottleneck, grabs ALL the bookmarks in the current folder
        // But realistically, with a batch size of 20, and most reads around 1ms, a bottleneck here is an edge case.
        // Optionally: grab the parent folder, and the on a bg thread iterate the bms and update their order. Seems like overkill.
        var bms = frc?.fetchedObjects as! [BookmarkMO]
        bms.remove(at: bms.index(of: src)!)
        if sourceIndexPath.row > destinationIndexPath.row {
            // insert before
            bms.insert(src, at: bms.index(of: dest)!)
        } else {
            let end = bms.index(of: dest)! + 1
            bms.insert(src, at: end)
        }
        
        for i in 0..<bms.count {
            bms[i].order = Int16(i)
        }
        
        // I am stumped, I can't find the notification that animation is complete for moving.
        // If I save while the animation is happening, the rows look screwed up (draw on top of each other).
        // Adding a delay to let animation complete avoids this problem
        DispatchQueue.main.async {
            DataManager.saveContext(context: frc?.managedObjectContext)
        }

    }
}

// TODO: Document well
// Getters
extension BookmarkMO {
    fileprivate static func get(forUrl url: URL, countOnly: Bool = false, getFavorites: Bool = false, context: NSManagedObjectContext) -> AnyObject? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = BookmarkMO.entity()
        let isFavoritePredicate = getFavorites ? "YES" : "NO"
        fetchRequest.predicate = NSPredicate(format: "url == %@ AND isFavorite == \(isFavoritePredicate)", url.absoluteString)
        do {
            if countOnly {
                let count = try context.count(for: fetchRequest)
                return count as AnyObject
            }
            let results = try context.fetch(fetchRequest) as? [BookmarkMO]
            return results?.first
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return nil
    }
}
