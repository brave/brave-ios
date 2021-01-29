// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import CoreData
import Shared

private let log = Logger.browserLogger

class Playlist {
    static let shared = Playlist()
    private let dbLock = NSRecursiveLock()
    
    func updateItem(mediaSrc: String, item: PlaylistInfo, completion: @escaping () -> Void) {
        if self.itemExists(item: item) {
            self.backgroundContext.perform {
                let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
                request.predicate = NSPredicate(format: "mediaSrc == %@", mediaSrc)
                
                (try? self.backgroundContext.fetch(request))?.forEach({
                    $0.mediaSrc = item.src
                })
                
                self.saveContext(self.backgroundContext)
                completion()
            }
        } else {
            self.addItem(item: item, cachedData: nil, completion: completion)
        }
    }
    
    func addItem(item: PlaylistInfo, cachedData: Data?, completion: @escaping () -> Void) {
        if !self.itemExists(item: item) {
            self.backgroundContext.perform { [weak self] in
                guard let self = self else { return }

                let playlistItem = PlaylistItem(context: self.backgroundContext)
                playlistItem.name = item.name
                playlistItem.pageTitle = item.pageTitle
                playlistItem.pageSrc = item.pageSrc
                playlistItem.dateAdded = Date()
                playlistItem.cachedData = cachedData ?? Data()
                playlistItem.duration = item.duration
                playlistItem.mimeType = item.mimeType
                playlistItem.mediaSrc = item.src
                
                self.saveContext(self.backgroundContext)
                completion()
            }
        } else {
            completion()
        }
    }
    
    func removeItem(item: PlaylistInfo) {
        if self.itemExists(item: item) {
            self.backgroundContext.performAndWait { [weak self] in
                guard let self = self else { return }
                let request = { () -> NSBatchDeleteRequest in
                    let request: NSFetchRequest<NSFetchRequestResult> = PlaylistItem.fetchRequest()
                    request.predicate = NSPredicate(format: "pageSrc == %@", item.pageSrc)
                    
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                    deleteRequest.resultType = .resultTypeObjectIDs
                    return deleteRequest
                }()
                
                if let result = (try? self.backgroundContext.execute(request)) as? NSBatchDeleteResult {
                    if let deletedObjects = result.result as? [NSManagedObjectID] {
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: [NSDeletedObjectsKey: deletedObjects],
                            into: [self.mainContext, self.backgroundContext]
                        )
                    }
                } else {
                    let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
                    request.predicate = NSPredicate(format: "pageSrc == %@", item.pageSrc)
                    
                    (try? self.backgroundContext.fetch(request))?.forEach({
                        self.backgroundContext.delete($0)
                    })
                }
                
                self.saveContext(self.backgroundContext)
                self.backgroundContext.reset()
            }
        }
    }
    
    func removeAll() {
        self.destroy()
        self.persistentContainer = self.create()
    }
    
    func getItems() -> [PlaylistInfo] {
        let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        return (try? self.mainContext.fetch(request))?.map({
            return PlaylistInfo(item: $0)
        }) ?? []
    }
    
    func getCache(item: PlaylistInfo) -> Data {
        let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        request.predicate = NSPredicate(format: "pageSrc == %@", item.pageSrc)
        request.fetchLimit = 1
        return (try? self.mainContext.fetch(request))?.first?.cachedData ?? Data()
    }
    
    func updateCache(item: PlaylistInfo, cachedData: Data) {
        let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        request.predicate = NSPredicate(format: "pageSrc == %@", item.pageSrc)
        request.fetchLimit = 1
        
        (try? self.mainContext.fetch(request))?.first?.cachedData = cachedData
        self.saveContext(self.mainContext)
    }
    
    func itemExists(item: PlaylistInfo) -> Bool {
        let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        request.predicate = NSPredicate(format: "pageSrc == %@", item.pageSrc)
        return ((try? self.mainContext.count(for: request)) ?? 0) > 0
    }
    
    func getPlaylistCount() -> Int {
        let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        return (try? self.mainContext.count(for: request)) ?? 0
    }
    
    func fetchResultsController() -> NSFetchedResultsController<PlaylistItem> {
        let descriptor = NSEntityDescription.entity(forEntityName:
                                                        "PlaylistItem",
                                                    in: self.mainContext)!
        
        let fetchRequest: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        
        fetchRequest.entity = descriptor
        fetchRequest.fetchBatchSize = 20
        
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        let dateAddedSort = NSSortDescriptor(key: "dateAdded", ascending: false)
        fetchRequest.sortDescriptors = [nameSort, dateAddedSort]

        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: self.mainContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }
    
    private init() {
        self.mainContext.reset()
    }
    
    private lazy var persistentContainer: NSPersistentContainer = {
        return self.create()
    }()
    
    private lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    private lazy var mainContext: NSManagedObjectContext = {
        let context = persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    
    private func save() {
        saveContext(mainContext)
    }
    
    private func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                log.error("Error Saving Context: \(error)")
            }
        }
    }
    
    // MARK: - CoreData Stack
    
    private lazy var cachedPersistentContainer = {
        return NSPersistentContainer(name: "Playlist")
    }()
    
    private func create() -> NSPersistentContainer {
        dbLock.lock(); defer { dbLock.unlock() }
        
        cachedPersistentContainer.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            guard let self = self else { return }
            
            if error != nil {
                self.destroy()
                
                self.cachedPersistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
                    if let error = error as NSError? {
                        fatalError("Playlist Load persistent store error: \(error)")
                    }
                })
            }
        })
        return cachedPersistentContainer
    }
    
    private func destroy() {
        dbLock.lock(); defer { dbLock.unlock() }
        
        cachedPersistentContainer.persistentStoreDescriptions.forEach({
            try? cachedPersistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: $0.url!, ofType: NSSQLiteStoreType, options: nil)
        })
    }
}
