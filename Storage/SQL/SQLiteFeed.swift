/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

private let log = Logger.syncLogger

class FeedStorageError: MaybeErrorType {
    var message: String
    init(_ message: String) {
        self.message = message
    }
    var description: String {
        return message
    }
}

open class SQLiteFeed {
    let db: BrowserDB

    let allFeedColumns = ["i.id", "publish_time", "feed_source", "url", "domain", "img", "title", "description", "content_type", "i.publisher_id", "i.publisher_name", "i.publisher_logo", "session_displayed", "removed", "liked", "unread"].joined(separator: ",")
    
    let allPublisherColumns = ["id", "publisher_id", "publisher_name", "publisher_logo", "show"].joined(separator: ",")

    required public init(db: BrowserDB) {
        self.db = db
    }
}

extension SQLiteFeed: Feed {
    public func getAvailableFeedRecords() -> Deferred<Maybe<[FeedItem]>> {
        let sql = "SELECT * FROM items i ORDER BY publish_time DESC"
        return db.runQuery(sql, args: nil, factory: SQLiteFeed.FeedItemFactory) >>== { cursor in
            return deferMaybe(cursor.asArray())
        }
    }

    public func deleteFeedRecord(_ record: FeedItem) -> Success {
        let sql = "DELETE FROM items WHERE id = ?"
        let args: Args = [record.id]
        return db.run(sql, withArgs: args)
    }

    public func deleteAllFeedRecords() -> Success {
        let sql = "DELETE FROM items"
        return db.run(sql)
    }

    public func createFeedRecord(publishTime: Timestamp, feedSource: String, url: String, domain: String, img: String, title: String, description: String, contentType: String, publisherId: String, publisherName: String, publisherLogo: String) -> Deferred<Maybe<FeedItem>> {
        return db.transaction { connection -> FeedItem in
            let insertSQL = "INSERT INTO items (publish_time, feed_source, url, domain, img, title, description, content_type, publisher_id, publisher_name, publisher_logo, session_displayed) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
            let insertArgs: Args = [publishTime, feedSource, url, domain, img, title, description, contentType, publisherId, publisherName, publisherLogo, ""]
            let lastInsertedRowID = connection.lastInsertedRowID

            try connection.executeChange(insertSQL, withArgs: insertArgs)

            if connection.lastInsertedRowID == lastInsertedRowID {
                throw FeedStorageError("Unable to insert FeedItem")
            }

            let querySQL = "SELECT * FROM items WHERE id = ? LIMIT 1"
            let queryArgs: Args = [connection.lastInsertedRowID]

            let cursor = connection.executeQuery(querySQL, factory: SQLiteFeed.FeedItemFactory, withArgs: queryArgs)

            let items = cursor.asArray()
            if let item = items.first {
                return item
            } else {
                throw FeedStorageError("Unable to get inserted FeedItem")
            }
        }
    }
    
    public func getFeedRecords(session: String, limit: Int, requiresImage: Bool, contentType: FeedContentType) -> Deferred<Maybe<[FeedItem]>> {
        var sql = "SELECT \(allFeedColumns) FROM items i, sources s WHERE s.publisher_id = i.publisher_id AND s.show = 1 AND i.session_displayed != ? AND i.removed = 0"
        
        if requiresImage {
            sql = sql + " AND i.img != ''"
        }
        
        if contentType != .any {
            sql = sql + " AND i.content_type = '\(contentType.rawValue)'"
        }
        
        sql = sql + " ORDER BY i.publish_time DESC LIMIT ?"
        
        let args: Args = [session, limit]
        return db.runQuery(sql, args: args, factory: SQLiteFeed.FeedItemFactory) >>== { cursor in
            return deferMaybe(cursor.asArray())
        }
    }
    
    public func getFeedRecords(session: String, publisher: String, limit: Int, requiresImage: Bool, contentType: FeedContentType) -> Deferred<Maybe<[FeedItem]>> {
        var sql = "SELECT \(allFeedColumns) FROM items i, sources s WHERE s.publisher_id = i.publisher_id AND s.show = 1 AND i.session_displayed != ? AND i.publisher_id = ? AND i.removed = 0"
        
        if requiresImage {
            sql = sql + " AND i.img != ''"
        }
        
        if contentType != .any {
            sql = sql + " AND i.content_type = '\(contentType.rawValue)'"
        }
        
        sql = sql + " ORDER BY i.publish_time DESC LIMIT ?"
        
        let args: Args = [session, publisher, limit]
        return db.runQuery(sql, args: args, factory: SQLiteFeed.FeedItemFactory) >>== { cursor in
            return deferMaybe(cursor.asArray())
        }
    }

    public func getFeedRecordWithURL(_ url: String) -> Deferred<Maybe<FeedItem>> {
        let sql = "SELECT * FROM items WHERE url = ? AND removed = 0 LIMIT 1"
        let args: Args = [url]
        return db.runQuery(sql, args: args, factory: SQLiteFeed.FeedItemFactory) >>== { cursor in
            let items = cursor.asArray()
            if let item = items.first {
                return deferMaybe(item)
            } else {
                return deferMaybe(FeedStorageError("Can't create FCR from row"))
            }
        }
    }

    public func updateFeedRecord(_ id: Int, session: String) -> Deferred<Maybe<FeedItem>> {
        return db.transaction { connection -> FeedItem in
            let updateSQL = "UPDATE items SET session_displayed = ? WHERE id = ?"
            let updateArgs: Args = [session, id]

            try connection.executeChange(updateSQL, withArgs: updateArgs)

            let querySQL = "SELECT * FROM items WHERE id = ? LIMIT 1"
            let queryArgs: Args = [id]

            let cursor = connection.executeQuery(querySQL, factory: SQLiteFeed.FeedItemFactory, withArgs: queryArgs)

            let items = cursor.asArray()
            if let item = items.first {
                return item
            } else {
                throw FeedStorageError("Unable to get updated FeedItem")
            }
        }
    }
    
    public func updateFeedRecords(_ ids: [Int], session: String) -> Deferred<Maybe<FeedItem>> {
        return db.transaction { connection -> FeedItem in
            let idsString = ids.map { String($0) }.joined(separator: ",")
            let updateSQL = "UPDATE items SET session_displayed = ? WHERE id IN (\(idsString))"
            let updateArgs: Args = [session]
            
            try connection.executeChange(updateSQL, withArgs: updateArgs)

            let querySQL = "SELECT * FROM items WHERE id IN (\(idsString))"
            let cursor = connection.executeQuery(querySQL, factory: SQLiteFeed.FeedItemFactory, withArgs: nil)

            let items = cursor.asArray()
            if let item = items.first {
                return item
            } else {
                throw FeedStorageError("Unable to get updated FeedItem")
            }
        }
    }
    
    public func markFeedRecordAsRead(_ id: Int, read: Bool) -> Deferred<Maybe<FeedItem>> {
       return db.transaction { connection -> FeedItem in
           let updateSQL = "UPDATE items SET unread = ? WHERE id = ?"
           let updateArgs: Args = [!read, id]

           try connection.executeChange(updateSQL, withArgs: updateArgs)

           let querySQL = "SELECT * FROM items WHERE id = ? LIMIT 1"
           let queryArgs: Args = [id]

           let cursor = connection.executeQuery(querySQL, factory: SQLiteFeed.FeedItemFactory, withArgs: queryArgs)

           let items = cursor.asArray()
           if let item = items.first {
               return item
           } else {
               throw FeedStorageError("Unable to get updated FeedItem")
           }
        }
    }
    
    public func removeFeedRecord(_ id: Int) -> Success {
        let sql = "UPDATE items SET removed = 1 WHERE id = ?"
        let args: Args = [id]
        return db.run(sql, withArgs: args)
    }
    
    public func removeFeedRecord(_ publisherId: String) -> Success {
        let sql = "UPDATE items SET removed = 1 WHERE publisher_id = ?"
        let args: Args = [publisherId]
        return db.run(sql, withArgs: args)
    }

    fileprivate class func FeedItemFactory(_ row: SDRow) -> FeedItem {
        let id = row["id"] as! Int
        let publishTime = row.getTimestamp("publish_time")!
        let feedSource = row["feed_source"] as! String
        let url = row["url"] as! String
        let domain = row["domain"] as! String
        let img = row["img"] as! String
        let title = row["title"] as! String
        let description = row["description"] as! String
        let contentType = row["content_type"] as! String
        let publisherId = row["publisher_id"] as! String
        let publisherName = row["publisher_name"] as! String
        let publisherLogo = row["publisher_logo"] as! String
        let sessionDisplayed = row["session_displayed"] as! String
        let removed = row.getBoolean("removed")
        let liked = row.getBoolean("liked")
        let unread = row.getBoolean("unread")
        return FeedItem(id: id, publishTime: publishTime, feedSource: feedSource, url: url, domain: domain, img: img, title: title, description: description, contentType: contentType, publisherId: publisherId, publisherName: publisherName, publisherLogo: publisherLogo, sessionDisplayed: sessionDisplayed, removed: removed, liked: liked, unread: unread)
    }
    
    // Publishers
    
    public func getAvailablePublisherRecords() -> Deferred<Maybe<[PublisherItem]>> {
        let sql = "SELECT \(allPublisherColumns) FROM sources ORDER BY publisher_name"
        return db.runQuery(sql, args: nil, factory: SQLiteFeed.PublisherItemFactory) >>== { cursor in
            return deferMaybe(cursor.asArray())
        }
    }
    
    public func deleteAllPublisherRecords() -> Success {
        let sql = "DELETE FROM sources"
        return db.run(sql)
    }
    
    public func createPublishersRecord(publisherId: String, publisherName: String, publisherLogo: String, show: Bool) -> Deferred<Maybe<PublisherItem>> {
        return db.transaction { connection -> PublisherItem in
            let insertSQL = "INSERT INTO sources (publisher_id, publisher_name, publisher_logo, show) VALUES (?, ?, ?, ?)"
            let insertArgs: Args = [publisherId, publisherName, publisherLogo, show]
            let lastInsertedRowID = connection.lastInsertedRowID

            try connection.executeChange(insertSQL, withArgs: insertArgs)

            if connection.lastInsertedRowID == lastInsertedRowID {
                throw FeedStorageError("Unable to insert PublisherItem")
            }

            let querySQL = "SELECT \(self.allPublisherColumns) FROM sources WHERE id = ? LIMIT 1"
            let queryArgs: Args = [connection.lastInsertedRowID]

            let cursor = connection.executeQuery(querySQL, factory: SQLiteFeed.PublisherItemFactory, withArgs: queryArgs)

            let items = cursor.asArray()
            if let item = items.first {
                return item
            } else {
                throw FeedStorageError("Unable to get inserted PublisherItem")
            }
        }
    }
    
    public func updatePublisherRecord(_ id: Int, show: Bool) -> Deferred<Maybe<PublisherItem>> {
        return db.transaction { connection -> PublisherItem in
           let updateSQL = "UPDATE sources SET show = ? WHERE id = ?"
           let updateArgs: Args = [show, id]

           try connection.executeChange(updateSQL, withArgs: updateArgs)

           let querySQL = "SELECT \(self.allPublisherColumns) FROM sources WHERE id = ? LIMIT 1"
           let queryArgs: Args = [id]

           let cursor = connection.executeQuery(querySQL, factory: SQLiteFeed.PublisherItemFactory, withArgs: queryArgs)

           let items = cursor.asArray()
           if let item = items.first {
               return item
           } else {
               throw FeedStorageError("Unable to get updated PublisherItem")
           }
        }
    }
    
    fileprivate class func PublisherItemFactory(_ row: SDRow) -> PublisherItem {
        let id = row["id"] as! Int
        let publisherId = row["publisher_id"] as! String
        let publisherName = row["publisher_name"] as! String
        let publisherLogo = row["publisher_logo"] as! String
        let show = row.getBoolean("show")
        return PublisherItem(id: id, publisherId: publisherId, publisherName: publisherName, publisherLogo: publisherLogo, show: show)
    }
}
