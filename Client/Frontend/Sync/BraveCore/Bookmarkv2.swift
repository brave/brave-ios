// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data
import BraveRewards
import CoreData

// A Lightweight wrapper around BraveCore bookmarks
// with the same layout/interface as `Bookmark (from CoreData)`
class Bookmarkv2 {
    private let bookmarkNode: BookmarkNode?
    private static let bookmarksAPI = BraveBookmarksAPI()
    
    init(_ bookmarkNode: BookmarkNode) {
        self.bookmarkNode = bookmarkNode
    }
    
    public var isFolder: Bool {
        return bookmarkNode?.isFolder == true
    }
    
    public var title: String? {
        return bookmarkNode?.titleUrlNodeTitle
    }
    
    public var customTitle: String? {
        return bookmarkNode?.titleUrlNodeTitle
    }
    
    public var displayTitle: String? {
        return self.customTitle
    }
    
    public var url: String? {
        return bookmarkNode?.titleUrlNodeUrl?.absoluteString
    }
    
    public var domain: Domain? {
        if let url = bookmarkNode?.url {
            return Domain.getOrCreate(forUrl: url, persistent: true)
        }
        return nil
    }
    
    public var created: Date? {
        get {
            return bookmarkNode?.dateAdded
        }
        
        set {
            bookmarkNode?.dateAdded = newValue ?? Date()
        }
    }
    
    public var parent: Bookmarkv2? {
        get {
            if let parent = bookmarkNode?.parent {
                return Bookmarkv2(parent)
            }
            return nil
        }
    }
    
    public var children: [Bookmarkv2]? {
        return bookmarkNode?.children.map({ Bookmarkv2($0) })
    }
    
    public var canBeDeleted: Bool {
        return bookmarkNode?.isPermanentNode == false
    }
    
    public var objectID: Int {
        return Int(bookmarkNode?.nodeId ?? 0)
    }
    
    public var order: Int16 {
        let children = bookmarkNode?.parent?.children
        return Int16(children?.firstIndex(where: { $0.guid == self.bookmarkNode?.guid }) ?? -1)
    }
    
    public func delete() {
        if let bookmarkNode = bookmarkNode, self.canBeDeleted {
            Bookmarkv2.bookmarksAPI.removeBookmark(bookmarkNode)
        }
    }
}

extension Bookmarkv2 {
    
    public class func addFolder(title: String, parentFolder: Bookmarkv2? = nil) {
        if let parentFolder = parentFolder?.bookmarkNode {
            Bookmarkv2.bookmarksAPI.createFolder(withParent: parentFolder, title: title)
        } else {
            Bookmarkv2.bookmarksAPI.createFolder(withTitle: title)
        }
    }
    
    public class func add(url: URL, title: String?, parentFolder: Bookmarkv2? = nil) {
        if let parentFolder = parentFolder?.bookmarkNode {
            Bookmarkv2.bookmarksAPI.createBookmark(withParent: parentFolder, title: title ?? "", with: url)
        } else {
            Bookmarkv2.bookmarksAPI.createBookmark(withTitle: title ?? "", url: url)
        }
    }
    
    public func existsInPersistentStore() -> Bool {
        return true //Need a way to tell if a folder already exists in the sync chain..
    }
    
    public static func frc(parent: Bookmarkv2?) -> BookmarksV2FetchResultsController? {
        if let parent = parent, let bookmarkNode = parent.bookmarkNode {
            return Bookmarkv2Fetcher(bookmarkNode, api: Bookmarkv2.bookmarksAPI)
        }
        return Bookmarkv2ExclusiveFetcher(nil, api: Bookmarkv2.bookmarksAPI)
    }
    
    public static func foldersFrc(excludedFolder: Bookmarkv2? = nil) -> BookmarksV2FetchResultsController {
        return Bookmarkv2ExclusiveFetcher(excludedFolder?.bookmarkNode, api: Bookmarkv2.bookmarksAPI)
    }
    
    public static func getChildren(forFolder folder: Bookmarkv2, includeFolders: Bool) -> [Bookmarkv2]? {
        return folder.bookmarkNode?.children.filter({ $0.isFolder == includeFolders }).map({ Bookmarkv2($0) })
    }
    
    public func update(customTitle: String?, url: String?) {
        bookmarkNode?.setTitle(customTitle ?? "")
        bookmarkNode?.url = URL(string: url ?? "")
    }
    
    public func updateWithNewLocation(customTitle: String?, url: String?, location: Bookmarkv2?) {
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
    
    public class func reorderBookmarks(frc: BookmarksV2FetchResultsController?, sourceIndexPath: IndexPath,
                                       destinationIndexPath: IndexPath,
                                       isInteractiveDragReorder: Bool = false) {
        if let node = frc?.object(at: sourceIndexPath)?.bookmarkNode,
           let parent = node.parent ?? bookmarksAPI.mobileNode {
            
            //Moving to the very last index.. same as appending..
            if destinationIndexPath.row == parent.children.count - 1 {
                node.move(toParent: parent)
            } else {
                node.move(toParent: parent, index: UInt(destinationIndexPath.row))
            }
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
    
    private let parentNode: BookmarkNode
    private var children = [BookmarkNode]()
    
    init(_ parentNode: BookmarkNode, api: BraveBookmarksAPI) {
        self.parentNode = parentNode
        super.init()
        
        self.bookmarkModelListener = api.add(BookmarkModelStateChangeObserver { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.noIdeaReloadTable(self)
        })
    }
    
    var fetchedObjects: [Bookmarkv2]? {
        return children.map({ Bookmarkv2($0) })
    }
    
    func performFetch() throws {
        self.children.removeAll()
        self.children.append(contentsOf: parentNode.children)
    }
    
    func object(at indexPath: IndexPath) -> Bookmarkv2? {
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
        
        self.bookmarkModelListener = api.add(BookmarkModelStateChangeObserver { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.noIdeaReloadTable(self)
        })
    }
    
    var fetchedObjects: [Bookmarkv2]? {
        return children.map({ Bookmarkv2($0) })
    }
    
    func performFetch() throws {
        self.children = []
        if let node = bookmarksAPI?.mobileNode {
            self.children.append(node)
        }
        
        if let node = bookmarksAPI?.desktopNode, !node.children.isEmpty {
            self.children.append(node)
        }
        
        if let node = bookmarksAPI?.otherNode, !node.children.isEmpty {
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

class BookmarkModelStateChangeObserver: NSObject, BookmarkModelObserver {
    private let listener: (StateChange) -> Void
    
    enum StateChange {
        case nodeChanged(BookmarkNode)
        case favIconChanged(BookmarkNode)
        case childrenChanged(BookmarkNode)
        case nodeMoved(_ node: BookmarkNode, _ from: BookmarkNode, _ to: BookmarkNode)
        case nodeDeleted(_ node: BookmarkNode, _ from: BookmarkNode)
        case allRemoved
    }
    
    init(_ listener: @escaping (StateChange) -> Void) {
        self.listener = listener
    }
    
    func bookmarkNodeChanged(_ bookmarkNode: BookmarkNode) {
        self.listener(.nodeChanged(bookmarkNode))
    }
    
    func bookmarkNodeFaviconChanged(_ bookmarkNode: BookmarkNode) {
        self.listener(.favIconChanged(bookmarkNode))
    }
    
    func bookmarkNodeChildrenChanged(_ bookmarkNode: BookmarkNode) {
        self.listener(.childrenChanged(bookmarkNode))
    }
    
    func bookmarkNode(_ bookmarkNode: BookmarkNode, movedFromParent oldParent: BookmarkNode, toParent newParent: BookmarkNode) {
        self.listener(.nodeMoved(bookmarkNode, oldParent, newParent))
    }
    
    func bookmarkNodeDeleted(_ node: BookmarkNode, fromFolder folder: BookmarkNode) {
        self.listener(.nodeDeleted(node, folder))
    }
    
    func bookmarkModelRemovedAllNodes() {
        self.listener(.allRemoved)
    }
}
