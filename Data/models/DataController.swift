/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import CoreData
import Shared
import XCGLogger

private let log = Logger.browserLogger

/// A helper structure for `DataController.perform()` method
/// to decide whether a new or existing context should be used
/// to perform a database write operation.
enum WriteContext {
    /// Requests DataController to create new background context for the task.
    case new(inMemory: Bool)
    /// Requests DataController to use an existing context.
    /// (To prevent creating multiple contexts per call and mixing threads)
    case existing(_ context: NSManagedObjectContext)
}

public class DataController: NSObject {
    private static let databaseName = "Brave.sqlite"
    
    // MARK: - Public interface
    
    public static var shared: DataController = DataController()
    public static var sharedInMemory: DataController = InMemoryDataController()
    
    public func storeExists() -> Bool {
        return FileManager.default.fileExists(atPath: storeURL.path)
    }
    
    public func migrateToNewPathIfNeeded() throws {
        enum MigrationError: Error {
            case Store(String)
        }
        
        if FileManager.default.fileExists(atPath: oldStoreURL.path) && !storeExists() /* TODO: Detect better solution */ {
            addPersistentStore(for: migrationContainer, store: oldStoreURL)
            
            let coordinator = migrationContainer.persistentStoreCoordinator
            guard let oldStore = coordinator.persistentStore(for: oldStoreURL) else {
                throw MigrationError.Store("Old store unavailable")
            }
            try coordinator.migratePersistentStore(oldStore, to: storeURL, options: nil, withType: NSSQLiteStoreType)
            try coordinator.destroyPersistentStore(at: oldStoreURL, ofType: NSSQLiteStoreType, options: nil)
            
            let documentFiles = try FileManager.default.contentsOfDirectory(
                at: oldStoreURL.deletingPathExtension(),
                includingPropertiesForKeys: nil,
                options: [])
            
            // Delete all Brave.X files
            try documentFiles
                .filter({$0.lastPathComponent.hasPrefix(DataController.databaseName)})
                .forEach(FileManager.default.removeItem)
        }
    }
    
    // MARK: - Data framework interface
    
    static func perform(context: WriteContext = .new(inMemory: false), save: Bool = true,
                        task: @escaping (NSManagedObjectContext) -> Void) {
        
        switch context {
        case .existing(let existingContext):
            // If existing context is provided, we only call the code closure.
            // Queue operation and saving is done in `performTask()`
            // called at higher level when a `.new` WriteContext is passed.
            task(existingContext)
        case .new(let inMemory):
            // Though keeping same queue does not make a difference but kept them diff for independent processing.
            let queue = inMemory ? DataController.sharedInMemory.operationQueue :  DataController.shared.operationQueue
            
            queue.addOperation({
                let backgroundContext = inMemory ? DataController.newBackgroundContextInMemory() : DataController.newBackgroundContext()
                // performAndWait doesn't block main thread because it fires on OperationQueue`s background thread.
                backgroundContext.performAndWait {
                    task(backgroundContext)
                    
                    guard save && backgroundContext.hasChanges else { return }
                    
                    do {
                        assert(!Thread.isMainThread)
                        try backgroundContext.save()
                    } catch {
                        log.error("performTask save error: \(error)")
                    }
                }
            })
        }
    }
    
    // Context object also allows us access to all persistent container data if needed.
    static var viewContext: NSManagedObjectContext {
        return DataController.shared.container.viewContext
    }
    
    // Context object also allows us access to all persistent container data if needed.
    static var viewContextInMemory: NSManagedObjectContext {
        return DataController.sharedInMemory.container.viewContext
    }
    
    static func save(context: NSManagedObjectContext?) {
        guard let context = context else {
            log.warning("No context on save")
            return
        }
        
        if context.concurrencyType == .mainQueueConcurrencyType {
            log.warning("Writing to view context, this should be avoided.")
        }
        
        context.perform {
            if !context.hasChanges { return }
            
            do {
                try context.save()
            } catch {
                assertionFailure("Error saving DB: \(error)")
            }
        }
    }
    
    func addPersistentStore(for container: NSPersistentContainer, store: URL) {
        let storeDescription = NSPersistentStoreDescription(url: store)
        
        // This makes the database file encrypted until device is unlocked.
        let completeProtection = FileProtectionType.complete as NSObject
        storeDescription.setOption(completeProtection, forKey: NSPersistentStoreFileProtectionKey)
        
        container.persistentStoreDescriptions = [storeDescription]
    }
    
    // MARK: - Private
    private lazy var migrationContainer: NSPersistentContainer = {
        return createContainer(store: oldStoreURL)
    }()
    
    private lazy var container: NSPersistentContainer = {
        return createContainer(store: storeURL)
    }()
    
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    /// Warning! Please use storeURL. oldStoreURL is for migration purpose only.
    private lazy var oldStoreURL: URL = {
        return createStoreURL(directory: FileManager.SearchPathDirectory.documentDirectory)
    }()
    
    private lazy var storeURL: URL = {
        return createStoreURL(directory: FileManager.SearchPathDirectory.applicationSupportDirectory)
    }()
    
    private func createContainer(store: URL) -> NSPersistentContainer {
        let modelName = "Model"
        guard let modelURL = Bundle(for: DataController.self).url(forResource: modelName, withExtension: "momd") else {
            fatalError("Error loading model from bundle for store: \(store.absoluteString)")
        }
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing managed object model from: \(modelURL)")
        }
        
        let container = NSPersistentContainer(name: modelName, managedObjectModel: mom)
        
        addPersistentStore(for: container, store: store)
        
        // Dev note: This completion handler might be misleading: the persistent store is loaded synchronously by default.
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error {
                fatalError("Load persistent store error: \(error)")
            }
        })
        // We need this so the `viewContext` gets updated on changes from background tasks.
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }
    
    private func createStoreURL(directory: FileManager.SearchPathDirectory) -> URL {
        let urls = FileManager.default.urls(for: directory, in: .userDomainMask)
        guard let docURL = urls.last else {
            log.error("Could not load url for: \(directory)")
            fatalError()
        }
        
        return docURL.appendingPathComponent(DataController.databaseName)
    }
    
    private static func newBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = DataController.shared.container.newBackgroundContext()
        // In theory, the merge policy should not matter
        // since all operations happen on a synchronized operation queue.
        // But in case of any bugs it's better to have one, so the app won't crash for users.
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        return backgroundContext
    }
    
    private static func newBackgroundContextInMemory() -> NSManagedObjectContext {
        let backgroundContext = DataController.sharedInMemory.container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        return backgroundContext
    }
}
