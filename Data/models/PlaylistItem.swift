// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreData
import Shared

private let log = Logger.browserLogger

@objc(PlaylistItem)
final public class PlaylistItem: NSManagedObject, CRUD, Identifiable {
    @NSManaged public var cachedData: Data?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var duration: TimeInterval
    @NSManaged public var mediaSrc: String?
    @NSManaged public var mimeType: String?
    @NSManaged public var name: String?
    @NSManaged public var order: Int32
    @NSManaged public var pageSrc: String?
    @NSManaged public var pageTitle: String?
    @NSManaged public var playlistFolder: PlaylistFolder?
    
    public var id: String {
        objectID.uriRepresentation().absoluteString
    }
    
    public class func frc() -> NSFetchedResultsController<PlaylistItem> {
        let context = DataController.viewContext
        let fetchRequest = NSFetchRequest<PlaylistItem>()
        fetchRequest.entity = PlaylistItem.entity(context)
        fetchRequest.fetchBatchSize = 20
        
        let orderSort = NSSortDescriptor(key: "order", ascending: true)
        let createdSort = NSSortDescriptor(key: "dateAdded", ascending: false)
        fetchRequest.sortDescriptors = [orderSort, createdSort]
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }
    
    public class func frc(parentFolder: PlaylistFolder?) -> NSFetchedResultsController<PlaylistItem> {
        let context = DataController.viewContext
        let fetchRequest = NSFetchRequest<PlaylistItem>()
        fetchRequest.entity = PlaylistItem.entity(context)
        fetchRequest.fetchBatchSize = 20
        
        if let parentFolder = parentFolder {
            fetchRequest.predicate = NSPredicate(format: "playlistFolder.uuid == %@", parentFolder.uuid!)
        } else {
            fetchRequest.predicate = NSPredicate(format: "playlistFolder == nil")
        }
        
        let orderSort = NSSortDescriptor(key: "order", ascending: true)
        let createdSort = NSSortDescriptor(key: "dateAdded", ascending: false)
        fetchRequest.sortDescriptors = [orderSort, createdSort]
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }
    
    public class func allFoldersFRC() -> NSFetchedResultsController<PlaylistItem> {
        let context = DataController.viewContext
        let fetchRequest = NSFetchRequest<PlaylistItem>()
        fetchRequest.entity = PlaylistItem.entity(context)
        fetchRequest.fetchBatchSize = 20
        
        let orderSort = NSSortDescriptor(key: "order", ascending: true)
        let createdSort = NSSortDescriptor(key: "dateAdded", ascending: false)
        fetchRequest.sortDescriptors = [orderSort, createdSort]
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }
    
    public static func addItem(_ item: PlaylistInfo, cachedData: Data?, completion: (() -> Void)? = nil) {
        DataController.perform(context: .new(inMemory: false), save: false) { context in
            let playlistItem = PlaylistItem(context: context)
            playlistItem.name = item.name
            playlistItem.pageTitle = item.pageTitle
            playlistItem.pageSrc = item.pageSrc
            playlistItem.dateAdded = Date()
            playlistItem.cachedData = cachedData ?? Data()
            playlistItem.duration = item.duration
            playlistItem.mimeType = item.mimeType
            playlistItem.mediaSrc = item.src
            playlistItem.order = Int32.min
            playlistItem.playlistFolder = PlaylistFolder.getFolder(uuid: PlaylistFolder.savedFolderUUID, context: context)
            
            PlaylistItem.reorderItems(context: context)
            PlaylistItem.saveContext(context)
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    public static func getItems(parentFolder: PlaylistFolder?) -> [PlaylistItem] {
        let predicate: NSPredicate
        if let parentFolder = parentFolder {
            predicate = NSPredicate(format: "playlistFolder.uuid == %@", parentFolder.uuid!)
        } else {
            predicate = NSPredicate(format: "playlistFolder == nil")
        }
        
        let orderSort = NSSortDescriptor(key: "order", ascending: true)
        let createdSort = NSSortDescriptor(key: "dateAdded", ascending: false)
        return PlaylistItem.all(where: predicate,
                                     sortDescriptors: [orderSort, createdSort],
                                     fetchBatchSize: 20) ?? []
    }
    
    public static func getItem(pageSrc: String) -> PlaylistItem? {
        return PlaylistItem.first(where: NSPredicate(format: "pageSrc == %@", pageSrc))
    }
    
    public static func itemExists(_ item: PlaylistInfo) -> Bool {
        if let count = PlaylistItem.count(predicate: NSPredicate(format: "pageSrc == %@ OR mediaSrc == %@", item.pageSrc, item.src)), count > 0 {
            return true
        }
        return false
    }
    
    public static func cachedItem(cacheURL: URL) -> PlaylistItem? {
        return PlaylistItem.all()?.first(where: {
            var isStale = false
            
            if let cacheData = $0.cachedData,
               let url = try? URL(resolvingBookmarkData: cacheData, bookmarkDataIsStale: &isStale) {
                return url.path == cacheURL.path
            }
            return false
        })
    }
    
    public static func updateItem(_ item: PlaylistInfo, completion: (() -> Void)? = nil) {
        if itemExists(item) {
            DataController.perform(context: .new(inMemory: false), save: false) { context in
                if let existingItem = PlaylistItem.first(where: NSPredicate(format: "pageSrc == %@ OR mediaSrc == %@", item.pageSrc, item.src), context: context) {
                    existingItem.name = item.name
                    existingItem.pageTitle = item.pageTitle
                    existingItem.pageSrc = item.pageSrc
                    existingItem.duration = item.duration
                    existingItem.mimeType = item.mimeType
                    existingItem.mediaSrc = item.src
                }
                
                PlaylistItem.saveContext(context)
                
                DispatchQueue.main.async {
                    completion?()
                }
            }
        } else {
            addItem(item, cachedData: nil, completion: completion)
        }
    }
    
    public static func updateCache(pageSrc: String, cachedData: Data?) {
        DataController.perform(context: .new(inMemory: false), save: true) { context in
            let item = PlaylistItem.first(where: NSPredicate(format: "pageSrc == %@", pageSrc), context: context)
            
            if let cachedData = cachedData, !cachedData.isEmpty {
                item?.cachedData = cachedData
            } else {
                item?.cachedData = nil
            }
        }
    }
    
    public static func removeItem(_ item: PlaylistInfo) {
        PlaylistItem.deleteAll(predicate: NSPredicate(format: "pageSrc == %@ OR mediaSrc == %@", item.pageSrc, item.src), context: .new(inMemory: false), includesPropertyValues: false)
    }
    
    public static func removeItems(_ items: [PlaylistInfo]) {
        let pageSrcs = items.map({ $0.pageSrc })
        let mediaSrcs = items.map({ $0.src })
        
        PlaylistItem.deleteAll(predicate: NSPredicate(format: "pageSrc IN %@ OR mediaSrc IN %@", pageSrcs, mediaSrcs), context: .new(inMemory: false), includesPropertyValues: false)
    }
    
    public static func moveItems(items: [NSManagedObjectID], to folderUUID: String?) {
        DataController.perform { context in
            var folder: PlaylistFolder?
            if let folderUUID = folderUUID {
                folder = PlaylistFolder.getFolder(uuid: folderUUID, context: context)
            }
            
            let playlistItems = items.compactMap { try? context.existingObject(with: $0) as? PlaylistItem }
            playlistItems.forEach {
                $0.playlistFolder = folder
                folder?.playlistItems?.insert($0)
            }
        }
    }
    
    // MARK: - Internal
    private static func reorderItems(context: NSManagedObjectContext) {
        DataController.perform(context: .existing(context), save: true) { context in
            let request = NSFetchRequest<PlaylistItem>()
            request.entity = PlaylistItem.entity(context)
            request.fetchBatchSize = 20
            
            let orderSort = NSSortDescriptor(key: "order", ascending: true)
            let items = PlaylistItem.all(sortDescriptors: [orderSort], context: context) ?? []
            
            for (order, item) in items.enumerated() {
                item.order = Int32(order)
            }
        }
    }
    
    @nonobjc
    private class func fetchRequest() -> NSFetchRequest<PlaylistItem> {
        NSFetchRequest<PlaylistItem>(entityName: "PlaylistItem")
    }
    
    private static func entity(_ context: NSManagedObjectContext) -> NSEntityDescription {
        NSEntityDescription.entity(forEntityName: "PlaylistItem", in: context)!
    }
    
    private static func saveContext(_ context: NSManagedObjectContext) {
        if context.concurrencyType == .mainQueueConcurrencyType {
            log.warning("Writing to view context, this should be avoided.")
        }
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                assertionFailure("Error saving DB: \(error)")
            }
        }
    }
}
