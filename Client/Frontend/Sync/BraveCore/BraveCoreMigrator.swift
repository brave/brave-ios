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

class BraveCoreMigrator {
    
    public init() {
        self.observer = bookmarksAPI.add(BookmarksModelLoadedObserver({ [weak self] in
            guard let self = self else { return }
            self.observer?.destroy()
            self.observer = nil

            if !BraveCoreMigrator.chromiumBookmarksMigration_v1 {
                print("STARITNG MIGRATION")
                if self.migrateBookmarks() {
                    BraveCoreMigrator.chromiumBookmarksMigration_v1 = true
                }
            }
        }))
    }
    
    public static var chromiumBookmarksMigration_v1: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "chromiumBookmarksMigration_v1")
        }
        
        set {
            UserDefaults.standard.setValue(newValue, forKey: "chromiumBookmarksMigration_v1")
        }
    }
    
    private let bookmarksAPI = BraveBookmarksAPI()
    private var observer: BookmarkModelListener?
    
    private struct BookmarkInfo: Hashable {
        let title: String?
        let url: String?
        let isFolder: Bool
        let children: [BookmarkInfo]?
    }
    
    private func migrateBookmarks() -> Bool {
        //let chromiumFavourites = Bookmark.allBookmarks.map({ convertToChromiumFormat($0) })
 
        let chromiumBookmarks = Bookmark.allBookmarks//.map({ convertToChromiumFormat($0) })
        
        let rootFolder = bookmarksAPI.mobileNode
        for bookmark in chromiumBookmarks {
            if !migrateChromiumBookmarks(bookmark, chromiumBookmark: rootFolder!) {
                print("Migration Failed somehow..")
                bookmarksAPI.removeAll() //Roll-back everything.. we screwed up..
                return false
            }
        }
        
        print("MIGRATION FINISHED!")
        return true
    }
    
    private func printBookmarks(_ node: BookmarkNode) {
        if node.isFolder {
            print("FOLDER: \(node.titleUrlNodeTitle)")
        } else {
            print("URL: \(node.titleUrlNodeUrl)")
        }
        
        for child in node.children {
            printBookmarks(child)
        }
    }
    
    private func convertToChromiumFormat(_ bookmark: Bookmark) -> BookmarkInfo {
        // Tail recursion to map children..
        return BookmarkInfo(title: bookmark.customTitle ?? bookmark.title, url: bookmark.url, isFolder: bookmark.isFolder, children: bookmark.children?.map({ convertToChromiumFormat($0) }))
    }
    
    //TODO: Possibly change this to throw a specific error to let us know what went wrong..
    private func migrateChromiumBookmarks(_ bookmark: Bookmark, chromiumBookmark: BookmarkNode) -> Bool {
        
        guard let title = bookmark.title else {
            // Can't migrate a bookmark with no title..
            return false
        }
        
        if bookmark.isFolder {
            // Create a folder..
            guard let folder = chromiumBookmark.addChildFolder(withTitle: title) else {
                // Chromium API failed to create a bookmark folder..
                return false
            }
            
            // Recursively migrate all bookmarks and sub-folders in that root folder..
            for childBookmark in bookmark.children ?? [] {
                if !migrateChromiumBookmarks(childBookmark, chromiumBookmark: folder) {
                    return false
                }
            }
        } else if let absoluteUrl = bookmark.url, let url = URL(string: absoluteUrl) {
            // Migrate URLs..
            chromiumBookmark.addChildBookmark(withTitle: title, url: url)
        } else {
            // Possibly something wrong with the bookmark if there is no URL :S..
            // Maybe Javascript? Maybe can't create a URL from the string.. Not sure..
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

class Bookmarkv2 {
    private let coreDataBookmark: Bookmark?
    private let bookmarkNode: BookmarkNode?
    private static let bookmarksAPI = BraveBookmarksAPI()
    
    init(_ coreDataBookmark: Bookmark) {
        self.coreDataBookmark = coreDataBookmark
        self.bookmarkNode = nil
    }
    
    init(_ bookmarkNode: BookmarkNode) {
        self.coreDataBookmark = nil
        self.bookmarkNode = bookmarkNode
    }
    
    public var isFolder: Bool {
        get {
            if let coreDataBookmark = coreDataBookmark {
                return coreDataBookmark.isFolder
            }
            
            return bookmarkNode?.isFolder == true
        }
    }
    
    public var title: String? {
        get {
            if let coreDataBookmark = coreDataBookmark {
                return coreDataBookmark.title
            }
            
            return bookmarkNode?.titleUrlNodeTitle
        }
    }
    
    public var customTitle: String? {
        get {
            if let coreDataBookmark = coreDataBookmark {
                return coreDataBookmark.customTitle
            }
            
            return bookmarkNode?.titleUrlNodeTitle
        }
    }
    
    public var displayTitle: String? {
        return self.customTitle
    }
    
    public var url: String? {
        get {
            if let coreDataBookmark = coreDataBookmark {
                return coreDataBookmark.url
            }
            
            return bookmarkNode?.titleUrlNodeUrl?.absoluteString
        }
    }
    
    public var domain: Domain? {
        if let coreDataBookmark = coreDataBookmark {
            return coreDataBookmark.domain
        }
        
        if let url = bookmarkNode?.url {
            return Domain.getOrCreate(forUrl: url, persistent: true)
        }
        return nil
    }
    
    public var created: Date? {
        get {
            if let coreDataBookmark = coreDataBookmark {
                return coreDataBookmark.created
            }
            
            return bookmarkNode?.dateAdded
        }
        
        set {
            coreDataBookmark?.created = newValue
            bookmarkNode?.dateAdded = newValue ?? Date()
        }
    }
    
    public var parent: Bookmarkv2? {
        get {
            if let coreDataBookmark = coreDataBookmark {
                if let parent = coreDataBookmark.parentFolder {
                    return Bookmarkv2(parent)
                }
                return nil
            }
            
            if let parent = bookmarkNode?.parent {
                return Bookmarkv2(parent)
            }
            return nil
        }
    }
    
    public var children: [Bookmarkv2]? {
        if let coreDataBookmark = self.coreDataBookmark {
            return coreDataBookmark.children?.compactMap({ Bookmarkv2($0) })
        }
        return bookmarkNode?.children.map({ Bookmarkv2($0) })
    }
}

extension Bookmarkv2 {
    
    public class func addFolder(title: String, parentFolder: Bookmarkv2? = nil) {
        if BraveCoreMigrator.chromiumBookmarksMigration_v1 {
            //User is using BraveCore
            if let parentFolder = parentFolder?.bookmarkNode {
                Bookmarkv2.bookmarksAPI.createFolder(withParent: parentFolder, title: title)
            } else {
                Bookmarkv2.bookmarksAPI.createFolder(withTitle: title)
            }
        } else {
            //Fallback to CoreData
            Bookmark.addFolder(title: title, parentFolder: parentFolder?.coreDataBookmark)
        }
    }
    
    public class func add(url: URL, title: String?, parentFolder: Bookmarkv2? = nil) {
        if BraveCoreMigrator.chromiumBookmarksMigration_v1 {
            //User is using BraveCore
            if let parentFolder = parentFolder?.bookmarkNode {
                Bookmarkv2.bookmarksAPI.createBookmark(withParent: parentFolder, title: title ?? "", with: url)
            } else {
                Bookmarkv2.bookmarksAPI.createBookmark(withTitle: title ?? "", url: url)
            }
        } else {
            //Fallback to CoreData
            Bookmark.add(url: url, title: title, parentFolder: parentFolder?.coreDataBookmark)
        }
    }
    
    public func existsInPersistentStore() -> Bool {
        if let coreDataBookmark = self.coreDataBookmark {
            return coreDataBookmark.existsInPersistentStore()
        }
        
        return true //Need a way to tell if a folder already exists in the sync chain..
    }
    
    public static func frc(forFavorites: Bool = false, parent: Bookmarkv2?) -> BookmarksV2FetchResultsController? {
        if !forFavorites {
            if let parent = parent {
                if let coreDataBookmark = parent.coreDataBookmark {
                    let frc = Bookmark.frc(parentFolder: coreDataBookmark)
                    return Bookmarkv2Fetcher(frc)
                }
                
                if let bookmarkNode = parent.bookmarkNode {
                    return Bookmarkv2Fetcher(bookmarkNode, api: Bookmarkv2.bookmarksAPI)
                }
                return nil
            } else {
                if BraveCoreMigrator.chromiumBookmarksMigration_v1 {
                    return Bookmarkv2ExclusiveFetcher(nil, api: Bookmarkv2.bookmarksAPI)
                } else {
                    return Bookmarkv2Fetcher(Bookmark.frc(forFavorites: forFavorites, parentFolder: nil))
                }
            }
        }
        return Bookmarkv2Fetcher(Bookmark.frc(forFavorites: forFavorites, parentFolder: parent?.coreDataBookmark))
    }
    
    public static func foldersFrc(excludedFolder: Bookmarkv2? = nil) -> BookmarksV2FetchResultsController {
        if BraveCoreMigrator.chromiumBookmarksMigration_v1 {
            //Brave Core
            return Bookmarkv2ExclusiveFetcher(excludedFolder?.bookmarkNode, api: Bookmarkv2.bookmarksAPI)
        }
        //Core Data
        return Bookmarkv2Fetcher(Bookmark.foldersFrc(excludedFolder: excludedFolder?.coreDataBookmark))
    }
    
    public static func getChildren(forFolder folder: Bookmarkv2, includeFolders: Bool) -> [Bookmarkv2]? {
        if let coreDataBookmark = folder.coreDataBookmark {
            return Bookmark.getChildren(forFolder: coreDataBookmark, includeFolders: includeFolders)?.map({ Bookmarkv2($0) })
        }
        
        return folder.bookmarkNode?.children.filter({ $0.isFolder == includeFolders }).map({ Bookmarkv2($0) })
    }
    
    public func update(customTitle: String?, url: String?) {
        if let coreDataBookmark = coreDataBookmark {
            coreDataBookmark.update(customTitle: customTitle, url: url)
        } else {
            bookmarkNode?.setTitle(customTitle ?? "")
            bookmarkNode?.url = URL(string: url ?? "")
        }
    }
    
    public func updateWithNewLocation(customTitle: String?, url: String?, location: Bookmarkv2?) {
        if let coreDataBookmark = coreDataBookmark {
            coreDataBookmark.updateWithNewLocation(customTitle: customTitle, url: url, location: location?.coreDataBookmark)
        } else {
            if let location = location?.bookmarkNode {
                bookmarkNode?.move(toParent: location)
            } else {
                if let mobileNode = Bookmarkv2.bookmarksAPI.mobileNode {
                    bookmarkNode?.move(toParent: mobileNode)
                }
            }
            
            if let customTitle = customTitle {
                bookmarkNode?.setTitle(customTitle)
            }
            
            if let url = url {
                bookmarkNode?.url = URL(string: url)
            } else {
                bookmarkNode?.url = nil
            }
        }
    }
    
    public class func reorderBookmarks(frc: BookmarksV2FetchResultsController?, sourceIndexPath: IndexPath,
                                       destinationIndexPath: IndexPath,
                                       isInteractiveDragReorder: Bool = false) {
        fatalError("NOT IMPLEMENTED")
    }
    
    public var isFavorite: Bool {
        if let coreDataBookmark = self.coreDataBookmark {
            return coreDataBookmark.isFavorite
        }
        return false
    }
    
    public var objectID: Int {
        if let coreDataBookmark = self.coreDataBookmark {
            return coreDataBookmark.objectID.hashValue
        }
        return Int(bookmarkNode?.nodeId ?? 0)
    }
    
    public var order: Int16 {
        if let coreDataBookmark = self.coreDataBookmark {
            return coreDataBookmark.order
        }
        
        let children = bookmarkNode?.parent?.children
        return Int16(children?.firstIndex(where: { $0.guid == self.bookmarkNode?.guid }) ?? -1)
    }
    
    public func delete() {
        if let coreDataBookmark = coreDataBookmark {
            coreDataBookmark.delete()
        } else if let bookmarkNode = bookmarkNode {
            Bookmarkv2.bookmarksAPI.removeBookmark(bookmarkNode)
        }
    }
}

protocol BookmarksV2FetchResultsDelegate: class {
    func controllerWillChangeContent(_ controller: BookmarksV2FetchResultsController)
    
    func controllerDidChangeContent(_ controller: BookmarksV2FetchResultsController)
    
    func controller(_ controller: BookmarksV2FetchResultsController, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    
    func noIdeaReloadTable(_ controller: BookmarksV2FetchResultsController)
}

protocol BookmarksV2FetchResultsController {
    /* weak */ var delegate: BookmarksV2FetchResultsDelegate? { get set }
    
    var fetchedObjects: [Bookmarkv2]? { get }
    func performFetch() throws
    func object(at indexPath: IndexPath) -> Bookmarkv2?
}

class Bookmarkv2Fetcher: NSObject, BookmarksV2FetchResultsController {
    weak var delegate: BookmarksV2FetchResultsDelegate?
    private var bookmarkModelListener: BookmarkModelListener?
    
    private let controller: NSFetchedResultsController<Bookmark>?
    private let parentNode: BookmarkNode?
    private var children = [BookmarkNode]()
    
    init(_ controller: NSFetchedResultsController<Bookmark>) {
        self.controller = controller
        self.parentNode = nil
        self.bookmarkModelListener = nil
        super.init()
        
        self.controller?.delegate = self
    }
    
    init(_ parentNode: BookmarkNode, api: BraveBookmarksAPI) {
        self.controller = nil
        self.parentNode = parentNode
        super.init()
        
        self.bookmarkModelListener = api.add(self)
    }
    
    var fetchedObjects: [Bookmarkv2]? {
        if let controller = controller {
            return controller.fetchedObjects?.map({ Bookmarkv2($0) })
        }
        
        return children.map({ Bookmarkv2($0) })
    }
    
    func performFetch() throws {
        if let controller = self.controller {
            try controller.performFetch()
        } else {
            self.children.removeAll()
            if let children = parentNode?.children {
                self.children.append(contentsOf: children)
            }
        }
    }
    
    func object(at indexPath: IndexPath) -> Bookmarkv2? {
        if let controller = self.controller {
            return Bookmarkv2(controller.object(at: indexPath))
        }
        return Bookmarkv2(children[indexPath.row])
    }
}

class Bookmarkv2ExclusiveFetcher: NSObject, BookmarksV2FetchResultsController {
    weak var delegate: BookmarksV2FetchResultsDelegate?
    private var bookmarkModelListener: BookmarkModelListener?
    
    private var excludedFolder: BookmarkNode?
    private var children = [BookmarkNode]()
    private weak var bookmarksAPI: BraveBookmarksAPI?
    
    init(_ excludedFolder: BookmarkNode?, api: BraveBookmarksAPI) {
        self.excludedFolder = excludedFolder
        self.bookmarksAPI = api
        super.init()
        
        self.bookmarkModelListener = api.add(self)
    }
    
    var fetchedObjects: [Bookmarkv2]? {
        return children.map({ Bookmarkv2($0) })
    }
    
    func performFetch() throws {
        self.children = []
        if let node = bookmarksAPI?.mobileNode {
            self.children.append(node)
        }
        
        if let node = bookmarksAPI?.desktopNode {
            self.children.append(node)
        }
        
        if let node = bookmarksAPI?.otherNode {
            self.children.append(node)
        }
        
        if self.children.isEmpty {
            throw NSError(domain: "brave.core.migrator", code: -1, userInfo: [
                NSLocalizedFailureReasonErrorKey: "Invalid Bookmark Nodes"
            ])
        }
    }
    
    func object(at indexPath: IndexPath) -> Bookmarkv2? {
        return Bookmarkv2(children[indexPath.row])
    }
    
    private func recurseNode(_ node: BookmarkNode) -> [BookmarkNode] {
        var result = [BookmarkNode]()
        
        for child in node.children {
            result += recurseNode(child)
            result.append(child)
        }
        return result
    }
}

extension Bookmarkv2Fetcher: NSFetchedResultsControllerDelegate, BookmarkModelObserver {
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.controllerWillChangeContent(self)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.controllerDidChangeContent(self)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let coreDataBookmark = anObject as? Bookmark {
            delegate?.controller(self, didChange: Bookmarkv2(coreDataBookmark), at: indexPath, for: type, newIndexPath: newIndexPath)
        } else if let bookmarkNode = anObject as? BookmarkNode {
            delegate?.controller(self, didChange: Bookmarkv2(bookmarkNode), at: indexPath, for: type, newIndexPath: newIndexPath)
        }
    }
    
    // MARK: - BookmarkModelObserver
    func bookmarkNodeChanged(_ bookmarkNode: BookmarkNode) {
        delegate?.noIdeaReloadTable(self)
    }
    
    func bookmarkNodeFaviconChanged(_ bookmarkNode: BookmarkNode) {
        delegate?.noIdeaReloadTable(self)
    }
    
    func bookmarkNodeChildrenChanged(_ bookmarkNode: BookmarkNode) {
        delegate?.noIdeaReloadTable(self)
    }
    
    func bookmarkNode(_ bookmarkNode: BookmarkNode, movedFromParent oldParent: BookmarkNode, toParent newParent: BookmarkNode) {
        delegate?.noIdeaReloadTable(self)
    }
    
    func bookmarkNodeDeleted(_ node: BookmarkNode, fromFolder folder: BookmarkNode) {
        delegate?.noIdeaReloadTable(self)
    }
    
    func bookmarkModelRemovedAllNodes() {
        delegate?.noIdeaReloadTable(self)
    }
}

extension Bookmarkv2ExclusiveFetcher: NSFetchedResultsControllerDelegate, BookmarkModelObserver {
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.controllerWillChangeContent(self)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.controllerDidChangeContent(self)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let coreDataBookmark = anObject as? Bookmark {
            delegate?.controller(self, didChange: Bookmarkv2(coreDataBookmark), at: indexPath, for: type, newIndexPath: newIndexPath)
        } else if let bookmarkNode = anObject as? BookmarkNode {
            delegate?.controller(self, didChange: Bookmarkv2(bookmarkNode), at: indexPath, for: type, newIndexPath: newIndexPath)
        }
    }
    
    // MARK: - BookmarkModelObserver
    func bookmarkNodeChanged(_ bookmarkNode: BookmarkNode) {
        delegate?.noIdeaReloadTable(self)
    }
    
    func bookmarkNodeFaviconChanged(_ bookmarkNode: BookmarkNode) {
        delegate?.noIdeaReloadTable(self)
    }
    
    func bookmarkNodeChildrenChanged(_ bookmarkNode: BookmarkNode) {
        delegate?.noIdeaReloadTable(self)
    }
    
    func bookmarkNode(_ bookmarkNode: BookmarkNode, movedFromParent oldParent: BookmarkNode, toParent newParent: BookmarkNode) {
        delegate?.noIdeaReloadTable(self)
    }
    
    func bookmarkNodeDeleted(_ node: BookmarkNode, fromFolder folder: BookmarkNode) {
        delegate?.noIdeaReloadTable(self)
    }
    
    func bookmarkModelRemovedAllNodes() {
        delegate?.noIdeaReloadTable(self)
    }
}
