// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import CoreData
import Shared
import BraveShared

private let log = Logger.browserLogger

class Playlist {
    static let shared = Playlist()
    private let dbLock = NSRecursiveLock()
    
    private func reorderItems() {
        backgroundContext.performAndWait { [weak self] in
            guard let self = self else { return }
            let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
            request.fetchBatchSize = 20
            
            let orderSort = NSSortDescriptor(key: "order", ascending: true)
            request.sortDescriptors = [orderSort]
            
            do {
                let items = try self.backgroundContext.fetch(request)
                for (order, item) in items.enumerated() {
                    item.order = Int32(order)
                }
            } catch {
                log.error(error)
            }
            
            self.saveContext(self.backgroundContext)
        }
    }
    
    func updateItem(item: PlaylistInfo, completion: (() -> Void)? = nil) {
        if itemExists(item: item) {
            backgroundContext.perform { [weak self] in
                guard let self = self else { return }
                
                let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
                request.predicate = NSPredicate(format: "pageSrc == %@", item.pageSrc)
                
                do {
                    try self.backgroundContext.fetch(request).forEach({
                        $0.name = item.name
                        $0.pageTitle = item.pageTitle
                        $0.pageSrc = item.pageSrc
                        $0.duration = item.duration
                        $0.mimeType = item.mimeType
                        $0.mediaSrc = item.src
                    })
                } catch {
                    log.error(error)
                }
                
                self.saveContext(self.backgroundContext)
                
                DispatchQueue.main.async {
                    completion?()
                }
            }
        } else {
            self.addItem(item: item, cachedData: nil, completion: completion)
        }
    }
    
    func addItem(item: PlaylistInfo, cachedData: Data?, completion: (() -> Void)? = nil) {
        if !itemExists(item: item) {
            backgroundContext.perform { [weak self] in
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
                playlistItem.order = -9999
                
                self.saveContext(self.backgroundContext)
                self.reorderItems()
                
                let downloadType = PlayListDownloadType(rawValue: Preferences.Playlist.autoDownloadVideo.value)
                
                switch downloadType {
                    case .on:
                        PlaylistManager.shared.download(item: item)
                    case .wifi:
                        if DeviceInfo.hasWifiConnection() {
                            PlaylistManager.shared.download(item: item)
                        }
                    default:
                        break
                }
                
                DispatchQueue.main.async {
                    completion?()
                }
            }
        } else {
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func removeItem(item: PlaylistInfo) {
        if itemExists(item: item) {
            backgroundContext.performAndWait { [weak self] in
                guard let self = self else { return }
                let request = { () -> NSBatchDeleteRequest in
                    let request: NSFetchRequest<NSFetchRequestResult> = PlaylistItem.fetchRequest()
                    request.predicate = NSPredicate(format: "mediaSrc == %@", item.src)
                    
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                    deleteRequest.resultType = .resultTypeObjectIDs
                    return deleteRequest
                }()
                
                do {
                    if let result = try self.backgroundContext.execute(request) as? NSBatchDeleteResult, let deletedObjects = result.result as? [NSManagedObjectID] {
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: [NSDeletedObjectsKey: deletedObjects],
                            into: [self.mainContext, self.backgroundContext]
                        )
                    }
                } catch {
                    log.error(error)
                    
                    let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
                    request.predicate = NSPredicate(format: "mediaSrc == %@", item.src)
                    
                    do {
                        try self.backgroundContext.fetch(request).forEach({
                            self.backgroundContext.delete($0)
                        })
                    } catch {
                        log.error(error)
                    }
                }
                
                self.saveContext(self.backgroundContext)
                self.reorderItems()
                self.backgroundContext.reset()
            }
        }
    }
    
    func removeAll() {
        destroy()
        persistentContainer = create()
    }
    
    func getItems() -> [PlaylistInfo] {
        let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        request.fetchBatchSize = 20
        
        let orderSort = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [orderSort]
        
        do {
            return try mainContext.fetch(request).map({ PlaylistInfo(item: $0) })
        } catch {
            log.error(error)
            return []
        }
    }
    
    func getItem(pageSrc: String) -> PlaylistItem? {
        let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        request.predicate = NSPredicate(format: "pageSrc == %@", pageSrc)
        
        do {
            if let item = try mainContext.fetch(request).first {
                return item
            }
        } catch {
            log.error(error)
        }
        return nil
    }
    
    func getCache(pageSrc: String) -> Data? {
        let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        request.predicate = NSPredicate(format: "pageSrc == %@", pageSrc)
        request.fetchLimit = 1
        
        do {
            return try mainContext.fetch(request).first?.cachedData
        } catch {
            log.error(error)
        }
        return nil
    }
    
    func updateCache(pageSrc: String, cachedData: Data?) {
        let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        request.predicate = NSPredicate(format: "pageSrc == %@", pageSrc)
        request.fetchLimit = 1
        
        do {
            try mainContext.fetch(request).first?.cachedData = cachedData
            saveContext(mainContext)
        } catch {
            log.error(error)
        }
    }
    
    func itemExists(item: PlaylistInfo) -> Bool {
        let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        request.predicate = NSPredicate(format: "pageSrc == %@", item.pageSrc)
        
        do {
            return try mainContext.count(for: request) > 0
        } catch {
            log.error(error)
        }
        return false
    }
    
    func getPlaylistCount() -> Int {
        let request: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        
        do {
            return try mainContext.count(for: request)
        } catch {
            log.error(error)
            return 0
        }
    }
    
    func fetchResultsController() -> NSFetchedResultsController<PlaylistItem> {
        let descriptor = NSEntityDescription.entity(forEntityName:
                                                        "PlaylistItem",
                                                    in: mainContext)!
        
        let fetchRequest: NSFetchRequest<PlaylistItem> = PlaylistItem.fetchRequest()
        
        fetchRequest.entity = descriptor
        fetchRequest.fetchBatchSize = 20
        
        let orderSort = NSSortDescriptor(key: "order", ascending: true)
        fetchRequest.sortDescriptors = [orderSort]

        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: mainContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }
    
    private init() {
        mainContext.reset()
    }
    
    private lazy var persistentContainer: NSPersistentContainer = {
        return create()
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
        NSPersistentContainer(name: "Playlist")
    }()
    
    private func create() -> NSPersistentContainer {
        dbLock.lock(); defer { dbLock.unlock() }
        
        cachedPersistentContainer.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            guard let self = self else { return }
            
            if error != nil {
                self.destroy()
                
                self.cachedPersistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
                    if let error = error as NSError? {
                        assertionFailure("Playlist Load persistent store error: \(error)")
                    }
                })
            }
        })
        return cachedPersistentContainer
    }
    
    private func destroy() {
        dbLock.lock(); defer { dbLock.unlock() }
        
        cachedPersistentContainer.persistentStoreDescriptions.forEach({
            if let url = $0.url {
                do {
                    try cachedPersistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
                } catch {
                    log.error(error)
                }
            }
        })
    }
}
