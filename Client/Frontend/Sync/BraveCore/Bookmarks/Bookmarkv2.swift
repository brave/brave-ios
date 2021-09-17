// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data
import BraveCore
import BraveShared
import CoreData
import Shared

private let log = Logger.browserLogger

// A Lightweight wrapper around BraveCore bookmarks
// with the same layout/interface as `Bookmark (from CoreData)`
class Bookmarkv2: WebsitePresentable {
    
    let bookmarkNode: BookmarkNode
    private var bookmarkFavIconObserver: BookmarkModelListener?
    
    private static var bookmarkModelLoadedObserver: BookmarkModelListener?
    private static let bookmarksAPI = (UIApplication.shared.delegate as? AppDelegate)?.braveCore?.bookmarksAPI

    init(_ bookmarkNode: BookmarkNode) {
        self.bookmarkNode = bookmarkNode
    }
    
    public var isFolder: Bool {
        return bookmarkNode.isFolder == true
    }
    
    public var title: String? {
        return bookmarkNode.titleUrlNodeTitle
    }
    
    public var customTitle: String? {
        return self.title
    }
    
    public var displayTitle: String? {
        return self.customTitle
    }
    
    public var url: String? {
        bookmarkNode.titleUrlNodeUrl?.absoluteString
    }
    
    public var domain: Domain? {
        if let url = bookmarkNode.titleUrlNodeUrl {
            return Domain.getOrCreate(forUrl: url, persistent: true)
        }
        return nil
    }
    
    public var created: Date? {
        get {
            return bookmarkNode.dateAdded
        }
        
        set {
            bookmarkNode.dateAdded = newValue ?? Date()
        }
    }
    
    public var parent: Bookmarkv2? {
        guard let bookmarksAPI = Bookmarkv2.bookmarksAPI else {
            return nil
        }
        
        if let parent = bookmarkNode.parent {
            // Return nil if the parent is the ROOT node
            // because AddEditBookmarkTableViewController.sortFolders
            // sorts root folders by having a nil parent.
            // If that code changes, we should change here to match.
            if bookmarkNode.parent?.guid != bookmarksAPI.rootNode?.guid {
                return Bookmarkv2(parent)
            }
        }
        return nil
    }
    
    public var children: [Bookmarkv2]? {
        return bookmarkNode.children.map({ Bookmarkv2($0) })
    }
    
    public var canBeDeleted: Bool {
        return bookmarkNode.isPermanentNode == false
    }
    
    public var objectID: Int {
        return Int(bookmarkNode.nodeId)
    }
    
    public var order: Int16 {
        let defaultOrder = 0 // taken from CoreData

        // MUST Use childCount instead of children.count! for performance
        guard let childCount = bookmarkNode.parent?.childCount, childCount > 0 else {
            return Int16(defaultOrder)
        }

        // Do NOT change this to self.parent.children.indexOf(where: { self.id == $0.id })
        // Swift's performance on `Array` is abominable!
        // Therefore we call a native function `index(ofChild:)` to return the index.
        return Int16(self.parent?.bookmarkNode.index(ofChild: self.bookmarkNode) ?? defaultOrder)
    }
    
    public func delete() {
        guard let bookmarksAPI = Bookmarkv2.bookmarksAPI else {
            return
        }
        
        if self.canBeDeleted {
            bookmarksAPI.removeBookmark(bookmarkNode)
        }
    }
    
}

class BraveBookmarkFolder: Bookmarkv2 {
    public let indentationLevel: Int
    
    private override init(_ bookmarkNode: BookmarkNode) {
        self.indentationLevel = 0
        super.init(bookmarkNode)
    }
    
    public init(_ bookmarkFolder: BookmarkFolder) {
        self.indentationLevel = bookmarkFolder.indentationLevel
        super.init(bookmarkFolder.bookmarkNode)
    }
}

// Bookmarks Fetching
extension Bookmarkv2 {
    
    public class func mobileNode() -> Bookmarkv2? {
        guard let bookmarksAPI = Bookmarkv2.bookmarksAPI else {
            return nil
        }
        
        if let node = bookmarksAPI.mobileNode {
            return Bookmarkv2(node)
        }
        return nil
    }
    
    @discardableResult
    public class func addFolder(title: String, parentFolder: Bookmarkv2? = nil) -> BookmarkNode? {
        guard let bookmarksAPI = Bookmarkv2.bookmarksAPI else {
            return nil
        }
        
        if let parentFolder = parentFolder?.bookmarkNode {
            return bookmarksAPI.createFolder(withParent: parentFolder, title: title)
        } else {
            return bookmarksAPI.createFolder(withTitle: title)
        }
    }
    
    public class func add(url: URL, title: String?, parentFolder: Bookmarkv2? = nil) {
        guard let bookmarksAPI = Bookmarkv2.bookmarksAPI else {
            return
        }
        
        if let parentFolder = parentFolder?.bookmarkNode {
            bookmarksAPI.createBookmark(withParent: parentFolder, title: title ?? "", with: url)
        } else {
            bookmarksAPI.createBookmark(withTitle: title ?? "", url: url)
        }
    }
    
    public func existsInPersistentStore() -> Bool {
        return bookmarkNode.isValid && bookmarkNode.parent != nil
    }
    
    public static func frc(parent: Bookmarkv2?) -> BookmarksV2FetchResultsController? {
        guard let bookmarksAPI = Bookmarkv2.bookmarksAPI else {
            return nil
        }
        
        return Bookmarkv2Fetcher(parent?.bookmarkNode, api: bookmarksAPI)
    }
    
    public static func foldersFrc(excludedFolder: Bookmarkv2? = nil) -> BookmarksV2FetchResultsController? {
        guard let bookmarksAPI = Bookmarkv2.bookmarksAPI else {
            return nil
        }
        
        return Bookmarkv2ExclusiveFetcher(excludedFolder?.bookmarkNode, api: bookmarksAPI)
    }
    
    public static func getChildren(forFolder folder: Bookmarkv2, includeFolders: Bool) -> [Bookmarkv2]? {
        let result = folder.bookmarkNode.children.map({ Bookmarkv2($0) })
        return includeFolders ? result : result.filter({ $0.isFolder == false })
    }
    
    public static func byFrequency(query: String? = nil, completion: @escaping ([WebsitePresentable]) -> Void) {
        // Invalid query.. BraveCore doesn't store bookmarks based on last visited.
        // Any last visited bookmarks would show up in `History` anyway.
        // BraveCore automatically sorts them by date as well.
        guard let query = query, !query.isEmpty, let bookmarksAPI = Bookmarkv2.bookmarksAPI else {
            completion([])
            return
        }
        
        return bookmarksAPI.search(withQuery: query, maxCount: 200, completion: { nodes in
            completion(nodes.compactMap({ return !$0.isFolder ? Bookmarkv2($0) : nil }))
        })
    }
    
    public func update(customTitle: String?, url: URL?) {
        bookmarkNode.setTitle(customTitle ?? "")
        bookmarkNode.url = url
    }
    
    public func updateWithNewLocation(customTitle: String?, url: URL?, location: Bookmarkv2?) {
        guard let bookmarksAPI = Bookmarkv2.bookmarksAPI else {
            return
        }
        
        if let location = location?.bookmarkNode ?? bookmarksAPI.mobileNode {
            if location.guid != bookmarkNode.parent?.guid {
                bookmarkNode.move(toParent: location)
            }
            
            if let customTitle = customTitle {
                bookmarkNode.setTitle(customTitle)
            }
            
            if let url = url, !bookmarkNode.isFolder {
                bookmarkNode.url = url
            } else if url != nil {
                log.error("Error: Moving bookmark - Cannot convert a folder into a bookmark with url.")
            }
        } else {
            log.error("Error: Moving bookmark - Cannot move a bookmark to Root.")
        }
    }
    
    public class func reorderBookmarks(frc: BookmarksV2FetchResultsController?, sourceIndexPath: IndexPath,
                                       destinationIndexPath: IndexPath) {
        guard let frc = frc, let bookmarksAPI = Bookmarkv2.bookmarksAPI else {
            return
        }
        
        if let node = frc.object(at: sourceIndexPath)?.bookmarkNode,
           let parent = node.parent ?? bookmarksAPI.mobileNode {
            
            // Moving to the very last index.. same as appending..
            if destinationIndexPath.row == parent.children.count - 1 {
                node.move(toParent: parent)
            } else {
                node.move(toParent: parent, index: UInt(destinationIndexPath.row))
            }
            
            // Notify the delegate that items did move..
            // This is already done automatically in `Bookmarkv2Fetcher` listener.
            // However, the Brave-Core delegate is being called before the move is actually complete OR too quickly
            // So to fix it, we reload here AFTER the move is done so the UI can update accordingly.
            frc.delegate?.controllerDidReloadContents(frc)
        }
    }
}

// Brave-Core only
extension Bookmarkv2 {
    public var icon: UIImage? {
        return bookmarkNode.icon
    }
    
    public var isFavIconLoading: Bool {
        return bookmarkNode.isFavIconLoading
    }
    
    public var isFavIconLoaded: Bool {
        return bookmarkNode.isFavIconLoaded
    }
    
    public func addFavIconObserver(_ observer: @escaping () -> Void) {
        guard let bookmarksAPI = Bookmarkv2.bookmarksAPI else {
            return
        }
        
        let observer = BookmarkModelStateObserver { [weak self] state in
            guard let self = self else { return }
            
            if case .favIconChanged(let node) = state {
                if node.isValid && self.bookmarkNode.isValid
                    && node.guid == self.bookmarkNode.guid {
                    observer()
                }
            }
        }
        
        self.bookmarkFavIconObserver = bookmarksAPI.add(observer)
    }
    
    public func removeFavIconObserver() {
        bookmarkFavIconObserver = nil
    }
    
    public static func waitForBookmarkModelLoaded(_ completion: @escaping () -> Void) {
        guard let bookmarksAPI = Bookmarkv2.bookmarksAPI else {
            return
        }
        
        if bookmarksAPI.isLoaded {
            DispatchQueue.main.async {
                completion()
            }
        } else {
            bookmarkModelLoadedObserver = bookmarksAPI.add(BookmarkModelStateObserver({
                if case .modelLoaded = $0 {
                    bookmarkModelLoadedObserver?.destroy()
                    bookmarkModelLoadedObserver = nil
                    
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }))
        }
    }
}
