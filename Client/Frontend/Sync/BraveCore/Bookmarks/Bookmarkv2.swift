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

// A Lightweight wrapper around BraveCore bookmarks
// with the same layout/interface as `Bookmark (from CoreData)`
class Bookmarkv2: WebsitePresentable {
        
    // MARK: Lifecycle
    
    init(_ bookmarkNode: BookmarkNode) {
        self.bookmarkNode = bookmarkNode
    }
    
    // MARK: Internal
    
    public let bookmarkNode: BookmarkNode
    
    public var bookmarkFavIconObserver: BookmarkModelListener?

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
        if let parent = bookmarkNode.parent {
            // Return nil if the parent is the ROOT node
            // because AddEditBookmarkTableViewController.sortFolders
            // sorts root folders by having a nil parent.
            // If that code changes, we should change here to match.
            if bookmarkNode.parent?.guid != BookmarkManager.rootNodeId {
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
    
    public var icon: UIImage? {
        return bookmarkNode.icon
    }
    
    public var isFavIconLoading: Bool {
        return bookmarkNode.isFavIconLoading
    }
    
    public var isFavIconLoaded: Bool {
        return bookmarkNode.isFavIconLoaded
    }
    
    public func update(customTitle: String?, url: URL?) {
        bookmarkNode.setTitle(customTitle ?? "")
        bookmarkNode.url = url
    }
    
    public func existsInPersistentStore() -> Bool {
        return bookmarkNode.isValid && bookmarkNode.parent != nil
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
