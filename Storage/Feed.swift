/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred

func FeedNow() -> Timestamp {
    return Timestamp(Date.timeIntervalSinceReferenceDate * 1000.0)
}

let FeedDefaultUnread: Bool = true
let FeedDefaultArchived: Bool = false
let FeedDefaultFavorite: Bool = false

public protocol Feed {
    func getAvailableRecords() -> Deferred<Maybe<[FeedItem]>>
    @discardableResult func deleteRecord(_ record: FeedItem) -> Success
    func deleteAllRecords() -> Success
    @discardableResult func createRecord(publishTime: Timestamp, feedSource: String, url: String, img: String, title: String, description: String) -> Deferred<Maybe<FeedItem>>
    func getRecords(session: String, limit: Int) -> Deferred<Maybe<[FeedItem]>>
    func getRecords(session: String, publisher: String, limit: Int) -> Deferred<Maybe<[FeedItem]>>
    func getRecordWithURL(_ url: String) -> Deferred<Maybe<FeedItem>>
    @discardableResult func updateRecord(_ id: Int, session: String) -> Deferred<Maybe<FeedItem>>
    @discardableResult func updateRecords(_ id: [Int], session: String) -> Deferred<Maybe<FeedItem>>
    @discardableResult func updateRecord(_ id: Int, read: Bool) -> Deferred<Maybe<FeedItem>>
}

public struct FeedItem: Equatable {
    public let id: Int
    public let publishTime: Timestamp
    public let feedSource: String
    public let url: String
    public let img: String
    public let title: String
    public let description: String
    public let sessionDisplayed: String
    public let removed: Bool
    public let liked: Bool
    public let unread: Bool

    /// Initializer for when a record is loaded from a database row
    public init(id: Int = 0, publishTime: Timestamp, feedSource: String, url: String, img: String, title: String, description: String, sessionDisplayed: String = "", removed: Bool = false, liked: Bool = false, unread: Bool = true) {
        self.id = id
        self.publishTime = publishTime
        self.feedSource = feedSource
        self.url = url
        self.img = img
        self.title = title
        self.description = description
        self.sessionDisplayed = sessionDisplayed
        self.removed = removed
        self.liked = liked
        self.unread = unread
    }
}

public struct FeedData: Decodable {
    public let publishTime: String?
    public let feedSource: String?
    public let url: String?
    public let img: String?
    public let title: String?
    public let description: String?
    
    enum CodingKeys: String, CodingKey {
        case publishTime = "publish_time"
        case feedSource = "feed_source"
        case url
        case img
        case title
        case description
    }
}

public func ==(lhs: FeedItem, rhs: FeedItem) -> Bool {
    return lhs.id == rhs.id
        && lhs.publishTime == rhs.publishTime
        && lhs.feedSource == rhs.feedSource
        && lhs.url == rhs.url
        && lhs.img == rhs.img
        && lhs.title == rhs.title
        && lhs.description == rhs.description
        && lhs.sessionDisplayed == rhs.sessionDisplayed
        && lhs.removed == rhs.removed
        && lhs.liked == rhs.liked
        && lhs.unread == rhs.unread
}
