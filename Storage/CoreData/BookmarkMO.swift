/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import CoreData 

public class BookmarkMO: NSManagedObject {

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

