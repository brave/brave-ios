/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

final class SyncBookmark: SyncRecord {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private enum SerializationKeys: String, CodingKey {
        case isFolder
        case parentFolderObjectId
        case site
        case syncOrder
    }
    
    // MARK: Properties
    var isFavorite: Bool = false
    var isFolder: Bool? = false
    var parentFolderObjectId: [Int]?
    var site: SyncSite?
    var syncOrder: String?
    
    convenience init() {
        self.init(object: [:])
    }
    
    required init(record: Syncable?, deviceId: [Int]?, action: Int?) {
        super.init(record: record, deviceId: deviceId, action: action)
        
        let bm = record as? Bookmark
        
        let unixCreated = Int(bm?.created?.toTimestamp() ?? 0)
        let unixAccessed = Int(bm?.lastVisited?.toTimestamp() ?? 0)
        
        let site = SyncSite()
        site.title = bm?.title
        site.customTitle = bm?.customTitle
        site.location = bm?.url
        site.creationTime = unixCreated
        site.lastAccessedTime = unixAccessed
        // FIXME: This sometimes crashes the app. See issue #1760.
        // site.favicon = bm?.domain?.favicon?.url
        
        self.isFavorite = bm?.isFavorite ?? false
        self.isFolder = bm?.isFolder
        self.parentFolderObjectId = bm?.syncParentUUID
        self.site = site
        syncOrder = bm?.syncOrder
    }
    
    required init(object: [String: AnyObject]) {
        super.init(object: object)
        
        guard let objectData = self.objectData else { return }
        
        let bookmark = object[objectData.rawValue]
        isFolder = bookmark?[SerializationKeys.isFolder.rawValue] as? Bool
        syncOrder = bookmark?[SerializationKeys.syncOrder.rawValue] as? String
        parentFolderObjectId = bookmark?[SerializationKeys.parentFolderObjectId.rawValue] as? [Int]
        site = SyncSite(object: bookmark?[SerializationKeys.site.rawValue] as? [String: AnyObject] ?? [:])
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    override func dictionaryRepresentation() -> [String: Any] {
        guard let objectData = self.objectData else { return [:] }
        
        // Create nested bookmark dictionary
        var bookmarkDict = [String: Any]()
        bookmarkDict[SerializationKeys.isFolder.rawValue] = isFolder
        bookmarkDict[SerializationKeys.syncOrder.rawValue] = syncOrder
        if let value = parentFolderObjectId { bookmarkDict[SerializationKeys.parentFolderObjectId.rawValue] = value }
        if let value = site { bookmarkDict[SerializationKeys.site.rawValue] = value.dictionaryRepresentation() }
        
        // Fetch parent, and assign bookmark
        var dictionary = super.dictionaryRepresentation()
        dictionary[objectData.rawValue] = bookmarkDict
        
        return dictionary
    }
    
}
