/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SwiftyJSON

private let log = Logger.syncLogger

public protocol SearchableBookmarks: class {
    func bookmarksByURL(_ url: URL) -> Deferred<Maybe<Cursor<BookmarkItem>>>
}

public protocol SyncableBookmarks: class, ResettableSyncStorage, AccountRemovalDelegate {
    // TODO
    func isUnchanged() -> Deferred<Maybe<Bool>>
    func getLocalBookmarksModifications(limit: Int) -> Deferred<Maybe<(deletions: [GUID], additions: [BookmarkMirrorItem])>>
    func getLocalDeletions() -> Deferred<Maybe<[(GUID, Timestamp)]>>
    func treesForEdges() -> Deferred<Maybe<(local: BookmarkTree, buffer: BookmarkTree)>>
    func treeForMirror() -> Deferred<Maybe<BookmarkTree>>
    func applyLocalOverrideCompletionOp(_ op: LocalOverrideCompletionOp, itemSources: ItemSources) -> Success
    func applyBufferUpdatedCompletionOp(_ op: BufferUpdatedCompletionOp) -> Success
}

public protocol BookmarkBufferStorage: class {
    func isEmpty() -> Deferred<Maybe<Bool>>
    func applyRecords(_ records: [BookmarkMirrorItem]) -> Success
    func doneApplyingRecordsAfterDownload() -> Success

    func validate() -> Success
    func getBufferedDeletions() -> Deferred<Maybe<[(GUID, Timestamp)]>>
    func applyBufferCompletionOp(_ op: BufferCompletionOp, itemSources: ItemSources) -> Success

    // Only use for diagnostics.
    func synchronousBufferCount() -> Int?
    func getUpstreamRecordCount() -> Deferred<Int?>
}

public protocol MirrorItemSource: class {
    func getMirrorItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>>
    func getMirrorItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID
    func prefetchMirrorItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID
}

public protocol BufferItemSource: class {
    func getBufferItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>>
    func getBufferItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID
    func getBufferChildrenGUIDsForParent(_ guid: GUID) -> Deferred<Maybe<[GUID]>>
    func prefetchBufferItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID
}

public protocol LocalItemSource: class {
    func getLocalItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>>
    func getLocalItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID
    func prefetchLocalItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID
}

open class ItemSources {
    public let local: LocalItemSource
    public let mirror: MirrorItemSource
    public let buffer: BufferItemSource

    public init(local: LocalItemSource, mirror: MirrorItemSource, buffer: BufferItemSource) {
        self.local = local
        self.mirror = mirror
        self.buffer = buffer
    }

    open func prefetchWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID {
        return self.local.prefetchLocalItemsWithGUIDs(guids)
         >>> { self.mirror.prefetchMirrorItemsWithGUIDs(guids) }
         >>> { self.buffer.prefetchBufferItemsWithGUIDs(guids) }
    }
}

public struct BookmarkRoots {
    // These match Places on desktop.
    public static let rootGUID =               "root________"
    public static let mobileFolderGUID =       "mobile______"
    public static let menuFolderGUID =         "menu________"
    public static let toolbarFolderGUID =      "toolbar_____"
    public static let unfiledFolderGUID =      "unfiled_____"

    public static let fakeDesktopFolderGUID =  "desktop_____"   // Pseudo. Never mentioned in a real record.

    // This is the order we use.
    public static let rootChildren: [GUID] = [
        BookmarkRoots.menuFolderGUID,
        BookmarkRoots.toolbarFolderGUID,
        BookmarkRoots.unfiledFolderGUID,
        BookmarkRoots.mobileFolderGUID,
    ]

    public static let desktopRoots: [GUID] = [
        BookmarkRoots.menuFolderGUID,
        BookmarkRoots.toolbarFolderGUID,
        BookmarkRoots.unfiledFolderGUID,
    ]

    public static let real = Set<GUID>([
        BookmarkRoots.rootGUID,
        BookmarkRoots.mobileFolderGUID,
        BookmarkRoots.menuFolderGUID,
        BookmarkRoots.toolbarFolderGUID,
        BookmarkRoots.unfiledFolderGUID,
    ])

    public static let all = Set<GUID>([
        BookmarkRoots.rootGUID,
        BookmarkRoots.mobileFolderGUID,
        BookmarkRoots.menuFolderGUID,
        BookmarkRoots.toolbarFolderGUID,
        BookmarkRoots.unfiledFolderGUID,
        BookmarkRoots.fakeDesktopFolderGUID,
    ])

    /**
     * Sync records are a horrible mess of Places-native GUIDs and Sync-native IDs.
     * For example:
     * {"id":"places",
     *  "type":"folder",
     *  "title":"",
     *  "description":null,
     *  "children":["menu________","toolbar_____",
     *              "tags________","unfiled_____",
     *              "jKnyPDrBQSDg","T6XK5oJMU8ih"],
     *  "parentid":"2hYxKgBwvkEH"}"
     *
     * We thus normalize on the extended Places IDs (with underscores) for
     * local storage, and translate to the Sync IDs when creating an outbound
     * record.
     * We translate the record's ID and also its parent. Evidence suggests that
     * we don't need to translate children IDs.
     *
     * TODO: We don't create outbound records yet, so that's why there's no
     * translation in that direction yet!
     */
    public static func translateIncomingRootGUID(_ guid: GUID) -> GUID {
        return [
            "places": rootGUID,
            "root": rootGUID,
            "mobile": mobileFolderGUID,
            "menu": menuFolderGUID,
            "toolbar": toolbarFolderGUID,
            "unfiled": unfiledFolderGUID
        ][guid] ?? guid
    }

    public static func translateOutgoingRootGUID(_ guid: GUID) -> GUID {
        return [
            rootGUID: "places",
            mobileFolderGUID: "mobile",
            menuFolderGUID: "menu",
            toolbarFolderGUID: "toolbar",
            unfiledFolderGUID: "unfiled"
        ][guid] ?? guid
    }

    /*
    public static let tagsFolderGUID =         "tags________"
    public static let pinnedFolderGUID =       "pinned______"
     */

    static let rootID =    0
    static let mobileID =  1
    static let menuID =    2
    static let toolbarID = 3
    static let unfiledID = 4
}

/**
 * This partly matches Places's nsINavBookmarksService, just for sanity.
 *
 * It is further extended to support the types that exist in Sync, so we can use
 * this to store mirrored rows.
 *
 * These are only used at the DB layer.
 */
public enum BookmarkNodeType: Int {
    case bookmark = 1
    case folder = 2
    case separator = 3
    case dynamicContainer = 4

    case livemark = 5
    case query = 6

    // No microsummary: those turn into bookmarks.
}

public func == (lhs: BookmarkMirrorItem, rhs: BookmarkMirrorItem) -> Bool {
    if lhs.type != rhs.type ||
       lhs.guid != rhs.guid ||
       lhs.dateAdded != rhs.dateAdded ||
       lhs.serverModified != rhs.serverModified ||
       lhs.isDeleted != rhs.isDeleted ||
       lhs.hasDupe != rhs.hasDupe ||
       lhs.pos != rhs.pos ||
       lhs.faviconID != rhs.faviconID ||
       lhs.localModified != rhs.localModified ||
       lhs.parentID != rhs.parentID ||
       lhs.parentName != rhs.parentName ||
       lhs.feedURI != rhs.feedURI ||
       lhs.siteURI != rhs.siteURI ||
       lhs.title != rhs.title ||
       lhs.description != rhs.description ||
       lhs.bookmarkURI != rhs.bookmarkURI ||
       lhs.tags != rhs.tags ||
       lhs.keyword != rhs.keyword ||
       lhs.folderName != rhs.folderName ||
       lhs.queryID != rhs.queryID {
        return false
    }

    if let lhsChildren = lhs.children, let rhsChildren = rhs.children {
        return lhsChildren == rhsChildren
    }
    return lhs.children == nil && rhs.children == nil
}

public struct BookmarkMirrorItem: Equatable {
    public let guid: GUID
    public let type: BookmarkNodeType
    public let dateAdded: Timestamp?
    public var serverModified: Timestamp
    public let isDeleted: Bool
    public let hasDupe: Bool
    public let parentID: GUID?
    public let parentName: String?

    // Livemarks.
    public let feedURI: String?
    public let siteURI: String?

    // Separators.
    let pos: Int?

    // Folders, livemarks, bookmarks and queries.
    public let title: String?
    let description: String?

    // Bookmarks and queries.
    let bookmarkURI: String?
    let tags: String?
    let keyword: String?

    // Queries.
    let folderName: String?
    let queryID: String?

    // Folders.
    public let children: [GUID]?

    // Internal stuff.
    let faviconID: Int?
    public let localModified: Timestamp?
    let syncStatus: SyncStatus?

    public func copyWithDateAdded(_ dateAdded: Timestamp) -> BookmarkMirrorItem {
        return BookmarkMirrorItem(
            guid: self.guid,
            type: self.type,
            dateAdded: dateAdded,
            serverModified: self.serverModified,
            isDeleted: self.isDeleted,
            hasDupe: self.hasDupe,
            parentID: self.parentID,
            parentName: self.parentName,
            feedURI: self.feedURI,
            siteURI: self.siteURI,
            pos: self.pos,
            title: self.title,
            description: self.description,
            bookmarkURI: self.bookmarkURI,
            tags: self.tags,
            keyword: self.keyword,
            folderName: self.folderName,
            queryID: self.queryID,
            children: self.children,
            faviconID: self.faviconID,
            localModified: self.localModified,
            syncStatus: self.syncStatus)
    }

    public func copyWithParentID(_ parentID: GUID, parentName: String?) -> BookmarkMirrorItem {
        return BookmarkMirrorItem(
            guid: self.guid,
            type: self.type,
            dateAdded: self.dateAdded,
            serverModified: self.serverModified,
            isDeleted: self.isDeleted,
            hasDupe: self.hasDupe,
            parentID: parentID,
            parentName: parentName,
            feedURI: self.feedURI,
            siteURI: self.siteURI,
            pos: self.pos,
            title: self.title,
            description: self.description,
            bookmarkURI: self.bookmarkURI,
            tags: self.tags,
            keyword: self.keyword,
            folderName: self.folderName,
            queryID: self.queryID,
            children: self.children,
            faviconID: self.faviconID,
            localModified: self.localModified,
            syncStatus: self.syncStatus)
    }

    // Ignores internal metadata and GUID; a pure value comparison.
    // Does compare child GUIDs!
    public func sameAs(_ rhs: BookmarkMirrorItem) -> Bool {
        if self.type != rhs.type ||
           self.dateAdded != rhs.dateAdded ||
           self.isDeleted != rhs.isDeleted ||
           self.pos != rhs.pos ||
           self.parentID != rhs.parentID ||
           self.parentName != rhs.parentName ||
           self.feedURI != rhs.feedURI ||
           self.siteURI != rhs.siteURI ||
           self.title != rhs.title ||
           (self.description ?? "") != (rhs.description ?? "") ||
           self.bookmarkURI != rhs.bookmarkURI ||
           self.tags != rhs.tags ||
           self.keyword != rhs.keyword ||
           self.folderName != rhs.folderName ||
           self.queryID != rhs.queryID {
            return false
        }

        if let lhsChildren = self.children, let rhsChildren = rhs.children {
            return lhsChildren == rhsChildren
        }
        return self.children == nil && rhs.children == nil
    }

    public func asJSON() -> JSON {
        return self.asJSONWithChildren(self.children)
    }

    public func asJSONWithChildren(_ children: [GUID]?) -> JSON {
        var out: [String: Any] = [:]

        out["id"] = BookmarkRoots.translateOutgoingRootGUID(self.guid)

        func take(_ key: String, _ val: String?) {
            guard let val = val else {
                return
            }
            out[key] = val
        }

        if self.isDeleted {
            out["deleted"] = true
            return JSON(out)
        }

        out["dateAdded"] = self.dateAdded
        out["hasDupe"] = self.hasDupe

        // TODO: this should never be nil!
        if let parentID = self.parentID {
            out["parentid"] = BookmarkRoots.translateOutgoingRootGUID(parentID)
            take("parentName", titleForSpecialGUID(parentID) ?? self.parentName ?? "")
        }

        func takeBookmarkFields() {
            take("title", self.title)
            take("bmkUri", self.bookmarkURI)
            take("description", self.description)
            if let tags = self.tags {
                let tagsJSON = JSON(parseJSON: tags)
                if let tagsArray = tagsJSON.array, tagsArray.every({ $0.type == SwiftyJSON.Type.string }) {
                    out["tags"] = tagsArray
                } else {
                    out["tags"] = []
                }
            } else {
                out["tags"] = []
            }
            take("keyword", self.keyword)
        }

        func takeFolderFields() {
            take("title", titleForSpecialGUID(self.guid) ?? self.title)
            take("description", self.description)
            if let children = children {
                if BookmarkRoots.rootGUID == self.guid {
                    // Only the root contains roots, and so only its children
                    // need to be translated.
                    out["children"] = children.map(BookmarkRoots.translateOutgoingRootGUID)
                } else {
                    out["children"] = children
                }
            }
        }

        switch self.type {

        case .query:
            out["type"] = "query"
            take("folderName", self.folderName)
            take("queryId", self.queryID)
            takeBookmarkFields()

        case .bookmark:
            out["type"] = "bookmark"
            takeBookmarkFields()

        case .livemark:
            out["type"] = "livemark"
            take("siteUri", self.siteURI)
            take("feedUri", self.feedURI)
            takeFolderFields()

        case .folder:
            out["type"] = "folder"
            takeFolderFields()

        case .separator:
            out["type"] = "separator"
            if let pos = self.pos {
                out["pos"] = pos
            }

        case .dynamicContainer:
            // Sigh.
            preconditionFailure("DynamicContainer not supported.")
        }

        return JSON(out)
    }

    // The places root is a folder but has no parentName.
    public static func folder(_ guid: GUID, dateAdded: Timestamp?, modified: Timestamp, hasDupe: Bool, parentID: GUID, parentName: String?, title: String, description: String?, children: [GUID]) -> BookmarkMirrorItem {
        let id = BookmarkRoots.translateIncomingRootGUID(guid)
        let parent = BookmarkRoots.translateIncomingRootGUID(parentID)

        return BookmarkMirrorItem(guid: id, type: .folder, dateAdded: dateAdded, serverModified: modified,
            isDeleted: false, hasDupe: hasDupe, parentID: parent, parentName: parentName,
            feedURI: nil, siteURI: nil,
            pos: nil,
            title: title, description: description,
            bookmarkURI: nil, tags: nil, keyword: nil,
            folderName: nil, queryID: nil,
            children: children,
            faviconID: nil, localModified: nil, syncStatus: nil)
    }

    public static func livemark(_ guid: GUID, dateAdded: Timestamp?, modified: Timestamp, hasDupe: Bool, parentID: GUID, parentName: String?, title: String?, description: String?, feedURI: String, siteURI: String) -> BookmarkMirrorItem {
        let id = BookmarkRoots.translateIncomingRootGUID(guid)
        let parent = BookmarkRoots.translateIncomingRootGUID(parentID)

        return BookmarkMirrorItem(guid: id, type: .livemark, dateAdded: dateAdded, serverModified: modified,
            isDeleted: false, hasDupe: hasDupe, parentID: parent, parentName: parentName,
            feedURI: feedURI, siteURI: siteURI,
            pos: nil,
            title: title, description: description,
            bookmarkURI: nil, tags: nil, keyword: nil,
            folderName: nil, queryID: nil,
            children: nil,
            faviconID: nil, localModified: nil, syncStatus: nil)
    }

    public static func separator(_ guid: GUID, dateAdded: Timestamp?, modified: Timestamp, hasDupe: Bool, parentID: GUID, parentName: String?, pos: Int) -> BookmarkMirrorItem {
        let id = BookmarkRoots.translateIncomingRootGUID(guid)
        let parent = BookmarkRoots.translateIncomingRootGUID(parentID)

        return BookmarkMirrorItem(guid: id, type: .separator, dateAdded: dateAdded, serverModified: modified,
            isDeleted: false, hasDupe: hasDupe, parentID: parent, parentName: parentName,
            feedURI: nil, siteURI: nil,
            pos: pos,
            title: nil, description: nil,
            bookmarkURI: nil, tags: nil, keyword: nil,
            folderName: nil, queryID: nil,
            children: nil,
            faviconID: nil, localModified: nil, syncStatus: nil)
    }

    public static func bookmark(_ guid: GUID, dateAdded: Timestamp?, modified: Timestamp, hasDupe: Bool, parentID: GUID, parentName: String?, title: String, description: String?, URI: String, tags: String, keyword: String?) -> BookmarkMirrorItem {
        let id = BookmarkRoots.translateIncomingRootGUID(guid)
        let parent = BookmarkRoots.translateIncomingRootGUID(parentID)

        return BookmarkMirrorItem(guid: id, type: .bookmark, dateAdded: dateAdded, serverModified: modified,
            isDeleted: false, hasDupe: hasDupe, parentID: parent, parentName: parentName,
            feedURI: nil, siteURI: nil,
            pos: nil,
            title: title, description: description,
            bookmarkURI: URI, tags: tags, keyword: keyword,
            folderName: nil, queryID: nil,
            children: nil,
            faviconID: nil, localModified: nil, syncStatus: nil)
    }

    public static func query(_ guid: GUID, dateAdded: Timestamp?, modified: Timestamp, hasDupe: Bool, parentID: GUID, parentName: String?, title: String, description: String?, URI: String, tags: String, keyword: String?, folderName: String?, queryID: String?) -> BookmarkMirrorItem {
        let id = BookmarkRoots.translateIncomingRootGUID(guid)
        let parent = BookmarkRoots.translateIncomingRootGUID(parentID)

        return BookmarkMirrorItem(guid: id, type: .query, dateAdded: dateAdded, serverModified: modified,
            isDeleted: false, hasDupe: hasDupe, parentID: parent, parentName: parentName,
            feedURI: nil, siteURI: nil,
            pos: nil,
            title: title, description: description,
            bookmarkURI: URI, tags: tags, keyword: keyword,
            folderName: folderName, queryID: queryID,
            children: nil,
            faviconID: nil, localModified: nil, syncStatus: nil)
    }

    public static func deleted(_ type: BookmarkNodeType, guid: GUID, modified: Timestamp) -> BookmarkMirrorItem {
        let id = BookmarkRoots.translateIncomingRootGUID(guid)

        return BookmarkMirrorItem(guid: id, type: type, dateAdded: nil, serverModified: modified,
            isDeleted: true, hasDupe: false, parentID: nil, parentName: nil,
            feedURI: nil, siteURI: nil,
            pos: nil,
            title: nil, description: nil,
            bookmarkURI: nil, tags: nil, keyword: nil,
            folderName: nil, queryID: nil,
            children: nil,
            faviconID: nil, localModified: nil, syncStatus: nil)
    }
}
