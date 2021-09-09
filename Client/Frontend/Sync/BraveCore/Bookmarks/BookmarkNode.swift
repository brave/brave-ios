// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data
import BraveCore
import BraveShared
import CoreData
import Shared

extension BookmarkNode {
        
    // MARK: Internal
        
    //public var bookmarkFavIconObserver: BookmarkModelListener?

    public var title: String? {
        return titleUrlNodeTitle
    }
    
    public var customTitle: String? {
        return title
    }
    
    public var displayTitle: String? {
        return self.customTitle
    }
    
    public var absoluteUrl: String? {
        titleUrlNodeUrl?.absoluteString
    }
    
    public var domain: Domain? {
        if let url = titleUrlNodeUrl {
            return Domain.getOrCreate(forUrl: url, persistent: true)
        }
        return nil
    }
    
    public var created: Date? {
        get {
            return dateAdded
        }
        
        set {
            dateAdded = newValue ?? Date()
        }
    }
    
    public var parentNode: BookmarkNode? {
        // Return nil if the parent is the ROOT node
        // because AddEditBookmarkTableViewController.sortFolders
        // sorts root folders by having a nil parent.
        // If that code changes, we should change here to match.
        guard parent?.guid != BookmarkManager.rootNodeId else {
            return nil
        }
        
        return parent
    }
    
    public var canBeDeleted: Bool {
        return isPermanentNode == false
    }
    
    public var objectID: Int {
        return Int(nodeId)
    }
    
    public var order: Int16 {
        let defaultOrder = 0 // taken from CoreData

        // MUST Use childCount instead of children.count! for performance
        guard let childCount = parent?.childCount, childCount > 0 else {
            return Int16(defaultOrder)
        }

        // Do NOT change this to self.parent.children.indexOf(where: { self.id == $0.id })
        // Swift's performance on `Array` is abominable!
        // Therefore we call a native function `index(ofChild:)` to return the index.
        return Int16(self.parentNode?.index(ofChild: self) ?? defaultOrder)
    }
    
    public func update(customTitle: String?, url: URL?) {
        setTitle(customTitle ?? "")
        self.url = url
    }
    
    public func existsInPersistentStore() -> Bool {
        return isValid && parent != nil
    }
}

class BraveBookmarkFolderX: BookmarkNode {
    public let indentationLevel: Int
    
    private init(_ bookmarkNode: BookmarkNode) {
        self.indentationLevel = 0
        super.init()
    }
    
    public init(_ bookmarkFolder: BookmarkFolder) {
        self.indentationLevel = bookmarkFolder.indentationLevel
        super.init()
    }
}
