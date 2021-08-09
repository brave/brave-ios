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

class BookmarkManager: NSObject {
    
    private let bookmarksAPI: BraveBookmarksAPI?
    
    init(bookmarksAPI: BraveBookmarksAPI?) {
        self.bookmarksAPI = bookmarksAPI
        
        super.init()
    }
    
    // Returns the last visited folder
    // If no folder was visited, returns the mobile bookmarks folder
    // If the root folder was visited, returns nil
    public func lastVisitedFolder() -> Bookmarkv2? {
        guard let bookmarksAPI = bookmarksAPI else {
            return nil
        }
        
        guard Preferences.General.showLastVisitedBookmarksFolder.value,
              let nodeId = Preferences.Chromium.lastBookmarksFolderNodeId.value else {
            // Default folder is the mobile node..
            if let mobileNode = bookmarksAPI.mobileNode {
                return Bookmarkv2(mobileNode)
            }
            return nil
        }
        
        // Display root folder instead of mobile node..
        if nodeId == -1 {
            return nil
        }
        
        // Display last visited folder..
        if let folderNode = bookmarksAPI.getNodeById(nodeId),
           folderNode.isVisible {
            return Bookmarkv2(folderNode)
        }
        
        // Default folder is the mobile node..
        if let mobileNode = bookmarksAPI.mobileNode {
            return Bookmarkv2(mobileNode)
        }
        return nil
    }
    
    public func lastFolderPath() -> [Bookmarkv2] {
        guard let bookmarksAPI = bookmarksAPI else {
            return []
        }
        
        if Preferences.General.showLastVisitedBookmarksFolder.value,
           let nodeId = Preferences.Chromium.lastBookmarksFolderNodeId.value,
           var folderNode = bookmarksAPI.getNodeById(nodeId),
           folderNode.isVisible {
            
            // We don't ever display the root node
            // It is the mother of all nodes
            let rootNodeGuid = bookmarksAPI.rootNode?.guid
            
            var nodes = [BookmarkNode]()
            nodes.append(folderNode)
            
            while true {
                if let parent = folderNode.parent, parent.isVisible, parent.guid != rootNodeGuid {
                    nodes.append(parent)
                    folderNode = parent
                    continue
                }
                break
            }
            return nodes.map({ Bookmarkv2($0) }).reversed()
        }
        
        // Default folder is the mobile node..
        if let mobileNode = bookmarksAPI.mobileNode {
            return [Bookmarkv2(mobileNode)]
        }
        
        return []
    }
}
