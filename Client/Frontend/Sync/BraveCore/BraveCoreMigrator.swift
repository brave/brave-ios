// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import Shared
import BraveShared
import Data
import CoreData

private let log = Logger.browserLogger

class BraveCoreMigrator {
    
    private let dataImportExporter = BraveCoreImportExportUtility()
    private let bookmarksAPI = BraveBookmarksAPI()
    private var observer: BookmarkModelListener?
    
    public init() {
        /*var didFinishTest = false
        //Add fake bookmarks to CoreData
        self.testMigration { [weak self] in
            guard let self = self else {
                didFinishTest = true
                return
            }
            
            //Wait for BookmarkModel to Load if needed..
            //
            //If the user is in a sync group, leave the sync chain just in case,
            //so they don't lose everything while testing.
            //
            //Delete all existing BraveCore bookmarks.
            //
            //Finally perform the migration..
            if self.bookmarksAPI.isLoaded {
                BraveSyncAPI.shared.leaveSyncGroup()
                self.bookmarksAPI.removeAll()
                self.migrate() { _ in
                    didFinishTest = true
                }
            } else {
                self.observer = self.bookmarksAPI.add(BookmarksModelLoadedObserver({ [weak self] in
                    guard let self = self else { return }
                    self.observer?.destroy()
                    self.observer = nil

                    BraveSyncAPI.shared.leaveSyncGroup()
                    self.bookmarksAPI.removeAll()
                    self.migrate() { _ in
                        didFinishTest = true
                    }
                }))
            }
        }
        
        while !didFinishTest {
            RunLoop.current.run(mode: .default, before: .distantFuture)
        }
        
        print("DONE TESTING MIGRATION")*/
    }
    
    public func migrate(_ completion: ((_ success: Bool) -> Void)? = nil) {
        if Preferences.Chromium.syncV2BookmarksMigrationCompleted.value {
            completion?(true)
            return
        }
        
        func performMigrationIfNeeded(_ completion: ((Bool) -> Void)?) {
            if !Preferences.Chromium.syncV2BookmarksMigrationCompleted.value {
                log.info("Migrating to Chromium Bookmarks v1 - Exporting")
                self.exportBookmarks { [weak self] success in
                    if success {
                        log.info("Migrating to Chromium Bookmarks v1 - Start")
                        self?.migrateBookmarks() { success in
                            Preferences.Chromium.syncV2BookmarksMigrationCompleted.value = success
                            completion?(success)
                        }
                    } else {
                        log.info("Migrating to Chromium Bookmarks v1 failed: Exporting")
                        completion?(success)
                    }
                }
            } else {
                completion?(true)
            }
        }
        
        //If the bookmark model has already loaded, the observer does NOT get called!
        //Therefore we should continue to migrate the bookmarks
        if bookmarksAPI.isLoaded {
            performMigrationIfNeeded(completion)
        } else {
            //Wait for the bookmark model to load before we attempt to perform migration!
            self.observer = bookmarksAPI.add(BookmarksModelLoadedObserver({ [weak self] in
                guard let self = self else { return }
                self.observer?.destroy()
                self.observer = nil

                performMigrationIfNeeded(completion)
            }))
        }
    }
    
    public func exportBookmarks(to url: URL, _ completion: @escaping (_ success: Bool) -> Void) {
        self.dataImportExporter.exportBookmarks(to: url, bookmarks: Bookmark.getAllTopLevelBookmarks()) { success in
            completion(success)
        }
    }
    
    private func exportBookmarks(_ completion: @escaping (_ success: Bool) -> Void) {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsDirectory = paths.first else {
            return completion(false)
        }
        
        guard let url = URL(string: "\(documentsDirectory)/Bookmarks.html") else {
            return completion(false)
        }
        
        self.dataImportExporter.exportBookmarks(to: url, bookmarks: Bookmark.getAllTopLevelBookmarks()) { success in
            completion(success)
        }
    }
    
    private func migrateBookmarks(_ completion: @escaping (_ success: Bool) -> Void) {
        //Migrate to the mobile folder by default..
        guard let rootFolder = bookmarksAPI.mobileNode else {
            log.error("Invalid Root Folder - Mobile Node")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        DataController.performOnMainContext { context in
            var didSucceed = true
            for bookmark in Bookmark.getAllTopLevelBookmarks(context) {
                if self.migrateChromiumBookmarks(context: context, bookmark: bookmark, chromiumBookmark: rootFolder) {
                    bookmark.delete(context: .existing(context))
                } else {
                    didSucceed = false
                }
            }
            
            DispatchQueue.main.async {
                completion(didSucceed)
            }
        }
    }
    
    private func migrateChromiumBookmarks(context: NSManagedObjectContext, bookmark: Bookmark, chromiumBookmark: BookmarkNode) -> Bool {
        guard let title = bookmark.isFolder ? bookmark.customTitle : bookmark.title else {
            log.error("Invalid Bookmark Title")
            return false
        }
        
        if bookmark.isFolder {
            // Create a folder..
            guard let folder = chromiumBookmark.addChildFolder(withTitle: title) else {
                log.error("Error Creating Bookmark Folder")
                return false
            }
            
            var canDeleteFolder = true
            // Recursively migrate all bookmarks and sub-folders in that root folder..
            for childBookmark in bookmark.children ?? [] {
                if migrateChromiumBookmarks(context: context, bookmark: childBookmark, chromiumBookmark: folder) {
                    childBookmark.delete(context: .existing(context))
                } else {
                    canDeleteFolder = false
                }
            }
            
            if canDeleteFolder {
                bookmark.delete(context: .existing(context))
            }
        } else if let absoluteUrl = bookmark.url, let url = URL(string: absoluteUrl) {
            // Migrate URLs..
            if chromiumBookmark.addChildBookmark(withTitle: title, url: url) == nil {
                log.error("Failed to Migrate Bookmark URL")
                return false
            }
            
            bookmark.delete(context: .existing(context))
        } else {
            return false
        }
        return true
    }
}

extension BraveCoreMigrator {
    class BookmarksModelLoadedObserver: NSObject & BookmarkModelObserver {
        private let onModelLoaded: () -> Void
        
        init(_ onModelLoaded: @escaping () -> Void) {
            self.onModelLoaded = onModelLoaded
        }
        
        func bookmarkModelLoaded() {
            self.onModelLoaded()
        }
    }
}

extension BraveCoreMigrator {
    private func testMigration(_ completion: @escaping () -> Void) {
        //CODE FOR TESTING MIGRATION!
        //DELETES ALL EXISTING CORE-DATA BOOKMARKS, CREATES A BUNCH OF FAKE BOOKMARKS..
        Preferences.Chromium.syncV2BookmarksMigrationCompleted.value = false

        DataController.perform { context in
            //Delete all existing bookmarks
            Bookmark.getAllTopLevelBookmarks(context).forEach({
                $0.delete(context: .existing(context))
            })

            //TOP LEVEL
            Bookmark.add(url: URL(string: "https://amazon.ca/")!, title: "Amazon", context: .existing(context))
            Bookmark.add(url: URL(string: "https://google.ca/")!, title: "Google", context: .existing(context))

            //TEST FOLDER
            Bookmark.addFolder(title: "TEST", context: .existing(context))

            //TEST -> Brave
            let test = Bookmark.getTopLevelFolders(context).first(where: { $0.customTitle == "TEST" })
            Bookmark.add(url: URL(string: "https://brave.com/")!, title: "Brave", parentFolder: test, context: .existing(context))

            //TEST -> DEPTH Folder
            Bookmark.addFolder(title: "DEPTH", parentFolder: test, context: .existing(context))

            //TEST -> DEPTH -> REDDIT
            let depth = Bookmark.getAllBookmarks(context: context).first(where: { $0.isFolder && $0.parentFolder?.customTitle == "TEST" && $0.customTitle == "DEPTH" })
            Bookmark.add(url: URL(string: "https://reddit.com/")!, title: "Reddit", parentFolder: depth, context: .existing(context))
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
