/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import CoreData
import Foundation
import Shared
import Storage

public protocol WebsitePresentable {
    var title: String? { get }
    var url: String? { get }
}

private let log = Logger.browserLogger

public final class Bookmark: NSManagedObject, WebsitePresentable, CRUD {
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
    @available(*, deprecated, message: "This is sync v1 property and is not used anymore")
    @NSManaged public var syncOrder: String?
    
    @NSManaged public var parentFolder: Bookmark?
    @NSManaged public var children: Set<Bookmark>?
    
    @NSManaged public var domain: Domain?
    
    @available(*, deprecated, message: "This is sync v1 property and is not used anymore")
    @NSManaged public var syncDisplayUUID: String?
    @available(*, deprecated, message: "This is sync v1 property and is not used anymore")
    @NSManaged public var syncParentDisplayUUID: String?
    
    private static let isFavoritePredicate = NSPredicate(format: "isFavorite == true")
    
    // MARK: - Public interface
    
    // MARK: Create
    
    public class func addFavorites(from list: [(url: URL, title: String)]) {
        DataController.perform { context in
            list.forEach {
                addInternal(url: $0.url, title: $0.title, isFavorite: true, context: .existing(context))
            }
        }
    }
    
    public class func addFavorite(url: URL, title: String?) {
        addInternal(url: url, title: title, isFavorite: true)
    }
    
    // MARK: Read
    
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
    
    public static func frc() -> NSFetchedResultsController<Bookmark> {
        let context = DataController.viewContext
        let fetchRequest = NSFetchRequest<Bookmark>()
        
        fetchRequest.entity = Bookmark.entity(context: context)
        fetchRequest.fetchBatchSize = 20
        
        let orderSort = NSSortDescriptor(key: "order", ascending: true)
        let createdSort = NSSortDescriptor(key: "created", ascending: false)
        fetchRequest.sortDescriptors = [orderSort, createdSort]
        
        fetchRequest.predicate = isFavoritePredicate
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }
    
    public class func contains(url: URL) -> Bool {
        let predicate = NSPredicate(format: "url == %@ AND isFavorite == true", url.absoluteString)
        
        return (count(predicate: predicate) ?? 0) > 0
    }
    
    public class var hasFavorites: Bool {
        guard let count = count(predicate: isFavoritePredicate) else { return false }
        return count > 0
    }
    
    public class var allFavorites: [Bookmark] {
        return all(where: isFavoritePredicate) ?? []
    }
    
    // MARK: Update
    
    public func update(customTitle: String?, url: String?) {
        if !hasTitle(customTitle) { return }
        updateInternal(customTitle: customTitle, url: url)
    }
    
    // Title can't be empty.
    private func hasTitle(_ title: String?) -> Bool {
        return title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
    
    /// WARNING: This method deletes all current favorites and replaces them with new one from the array.
    public class func forceOverwriteFavorites(with favorites: [(url: URL, title: String)]) {
        DataController.perform { context in
            Bookmark.deleteAll(predicate: isFavoritePredicate, context: .existing(context))
            
            favorites.forEach {
                addInternal(url: $0.url, title: $0.title, isFavorite: true,
                            context: .existing(context))
            }
        }
    }
    
    /// Passing in `isInteractiveDragReorder` will force the write to happen on
    /// the main view context. Defaults to `false`
    public class func reorderFavorites(sourceIndexPath: IndexPath,
                                       destinationIndexPath: IndexPath,
                                       isInteractiveDragReorder: Bool = false) {
        if destinationIndexPath.row == sourceIndexPath.row {
            log.error("Source and destination bookmarks are the same!")
            return
        }
        
        // If we're doing an interactive drag reorder then we want to make sure
        // to do the reorder on main queue so the underlying dataset & FRC is
        // updated immediately so the animation does not glitch out on drop.
        //
        // Doing it on a background thread will cause the favorites overlay
        // to temporarely show the old items and require a full-table refresh
        let context: WriteContext = isInteractiveDragReorder ?
            .existing(DataController.viewContext) :
            .new(inMemory: false)
        
        DataController.perform(context: context) { context in
            let destinationIndex = destinationIndexPath.row
            let sourceIndex = sourceIndexPath.row
            
            var allFavorites = Bookmark.getAllFavorites(context: context).sorted()
            // Out of bounds safety check, `swapAt` crashes beyond array length.
            if destinationIndex > allFavorites.count - 1 {
                assertionFailure("destinationIndex is out of bounds")
                return
            }
            
            allFavorites.swapAt(sourceIndex, destinationIndex)
            
            // Update order of all favorites that have changed.
            for (index, element) in allFavorites.enumerated() where index != element.order {
                element.order = Int16(index)
            }
            
            if isInteractiveDragReorder && context.hasChanges {
                do {
                    assert(Thread.isMainThread)
                    try context.save()
                } catch {
                    log.error("performTask save error: \(error)")
                }
            }
        }
    }
    
    // MARK: Delete
    
    public func delete(context: WriteContext? = nil) {
        deleteInternal(context: context ?? .new(inMemory: false))
    }
}

// MARK: - Internal implementations
extension Bookmark {
    static func entity(context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: "Bookmark", in: context)!
    }
    
    // MARK: Create
    
    /// - parameter completion: Returns object id associated with this object.
    /// IMPORTANT: this id might change after the object has been saved to persistent store. Better to use it within one context.
    class func addInternal(url: URL?,
                           title: String?,
                           customTitle: String? = nil,
                           parentFolder: Bookmark? = nil,
                           isFolder: Bool = false,
                           isFavorite: Bool = false,
                           save: Bool = true,
                           context: WriteContext = .new(inMemory: false),
                           completion: ((NSManagedObjectID) -> Void)? = nil) {
        
        DataController.perform(context: context) { context in
            var parentFolderOnCorrectContext: Bookmark?
            
            if let parent = parentFolder {
                parentFolderOnCorrectContext = context.object(with: parent.objectID) as? Bookmark
                
            }
            
            create(url: url, title: title, customTitle: customTitle, isFolder: isFolder,
                   isFavorite: isFavorite, save: save,
                   parentFolder: parentFolderOnCorrectContext,
                   context: .existing(context)) { objectId in
                completion?(objectId)
            }
        }
    }
    
    /// - parameter completion: Returns object id associated with this object.
    /// IMPORTANT: this id might change after the object has been saved to persistent store. Better to use it within one context.
    private class func create(url: URL?,
                              title: String?,
                              customTitle: String? = nil,
                              isFolder: Bool = false,
                              isFavorite: Bool = false,
                              save: Bool = true,
                              parentFolder: Bookmark? = nil,
                              context: WriteContext = .new(inMemory: false),
                              completion: ((NSManagedObjectID) -> Void)? = nil) {
        
        DataController.perform(context: context, save: save, task: { context in
            let bk = Bookmark(entity: entity(context: context), insertInto: context)
            
            let location = url?.absoluteString
            
            bk.url = location
            bk.title = title
            bk.customTitle = customTitle
            bk.isFavorite = isFavorite
            bk.isFolder = isFolder
            bk.created = Date()
            bk.lastVisited = bk.created
            
            if let location = location, let url = URL(string: location) {
                bk.domain = Domain.getOrCreateInternal(url, context: context,
                                                       saveStrategy: .delayedPersistentStore)
            }
            
            if let lastOrder = getAllFavorites(context: context).map(\.order).max() {
                bk.order = lastOrder + 1
            }
            
            completion?(bk.objectID)
        })
    }
    
    // MARK: Update
    
    private func updateInternal(customTitle: String?, url: String?, save: Bool = true,
                                context: WriteContext = .new(inMemory: false)) {
        
        DataController.perform(context: context) { context in
            guard let bookmarkToUpdate = context.object(with: self.objectID) as? Bookmark else { return }
            
            // See if there has been any change
            if bookmarkToUpdate.customTitle == customTitle && bookmarkToUpdate.url == url {
                return
            }
            
            bookmarkToUpdate.customTitle = customTitle
            bookmarkToUpdate.title = customTitle ?? bookmarkToUpdate.title
            
            if let u = url, !u.isEmpty {
                bookmarkToUpdate.url = url
                if let theURL = URL(string: u) {
                    bookmarkToUpdate.domain =
                        Domain.getOrCreateInternal(theURL, context: context,
                                                   saveStrategy: .delayedPersistentStore)
                } else {
                    bookmarkToUpdate.domain = nil
                }
            }
        }
    }
    
    // MARK: Read
    
    class func allBookmarksOfAGivenLevelPredicate(parent: Bookmark?) -> NSPredicate {
        let isFavoriteKP = #keyPath(Bookmark.isFavorite)
        let parentFolderKP = #keyPath(Bookmark.parentFolder)
        
        // A bit hacky but you can't just pass 'nil' string to %@.
        let nilArgumentForPredicate = 0
        return NSPredicate(
            format: "%K == %@ AND %K == NO", parentFolderKP, parent ?? nilArgumentForPredicate, isFavoriteKP)
    }
    
    static func getAllFavorites(context: NSManagedObjectContext? = nil) -> [Bookmark] {
        let predicate = NSPredicate(format: "isFavorite == YES")
        
        return all(where: predicate, context: context ?? DataController.viewContext) ?? []
    }
    
    // MARK: Delete
    
    private func deleteInternal(context: WriteContext = .new(inMemory: false)) {
        func deleteFromStore(context: WriteContext) {
            DataController.perform(context: context) { context in
                let objectOnContext = context.object(with: self.objectID)
                context.delete(objectOnContext)
            }
        }
        
        if isFavorite { deleteFromStore(context: context) }
        deleteFromStore(context: context)
    }
}

// MARK: - Comparable
extension Bookmark: Comparable {
    public static func < (lhs: Bookmark, rhs: Bookmark) -> Bool {
        return lhs.order < rhs.order
    }
}
