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

public enum FeedContentType: String {
    case article = "article"
    case product = "product"
    case any
}

public protocol Feed {
    // Feed Records
    func getAvailableFeedRecords() -> Deferred<Maybe<[FeedItem]>>
    @discardableResult func deleteFeedRecord(_ record: FeedItem) -> Success
    func deleteAllFeedRecords() -> Success
    @discardableResult func createFeedRecord(publishTime: Timestamp, feedSource: String, url: String, domain: String, img: String, title: String, description: String, contentType: String, publisherId: String, publisherName: String, publisherLogo: String) -> Deferred<Maybe<FeedItem>>
    func getFeedRecords(session: String, limit: Int, requiresImage: Bool, contentType: FeedContentType) -> Deferred<Maybe<[FeedItem]>>
    func getFeedRecords(session: String, publisher: String, limit: Int, requiresImage: Bool, contentType: FeedContentType) -> Deferred<Maybe<[FeedItem]>>
    func getFeedRecordWithURL(_ url: String) -> Deferred<Maybe<FeedItem>>
    @discardableResult func updateFeedRecord(_ id: Int, session: String) -> Deferred<Maybe<FeedItem>>
    @discardableResult func updateFeedRecords(_ id: [Int], session: String) -> Deferred<Maybe<FeedItem>>
    @discardableResult func markFeedRecordAsRead(_ id: Int, read: Bool) -> Deferred<Maybe<FeedItem>>
    @discardableResult func removeFeedRecord(_ id: Int) -> Success
    @discardableResult func removeFeedRecord(_ publisherId: String) -> Success
    
    // Publisher Records
    func getAvailablePublisherRecords() -> Deferred<Maybe<[PublisherItem]>>
    func deleteAllPublisherRecords() -> Success
    @discardableResult func createPublishersRecord(publisherId: String, publisherName: String, publisherLogo: String, show: Bool) -> Deferred<Maybe<PublisherItem>>
    @discardableResult func updatePublisherRecord(_ id: Int, show: Bool) -> Deferred<Maybe<PublisherItem>>
}

public struct FeedItem: Equatable {
    public let id: Int
    public let publishTime: Timestamp
    public let feedSource: String
    public let url: String
    public let domain: String
    public let img: String
    public let title: String
    public let description: String
    public let contentType: String
    public let publisherId: String
    public let publisherName: String
    public let publisherLogo: String
    public let sessionDisplayed: String
    public let removed: Bool
    public let liked: Bool
    public let unread: Bool

    /// Initializer for when a record is loaded from a database row
    public init(id: Int = 0, publishTime: Timestamp, feedSource: String, url: String, domain: String, img: String, title: String, description: String, contentType: String, publisherId: String, publisherName: String, publisherLogo: String, sessionDisplayed: String = "", removed: Bool = false, liked: Bool = false, unread: Bool = true) {
        self.id = id
        self.publishTime = publishTime
        self.feedSource = feedSource
        self.url = url
        self.domain = domain
        self.img = img
        self.title = title
        self.description = description
        self.contentType = contentType
        self.publisherId = publisherId
        self.publisherName = publisherName
        self.publisherLogo = publisherLogo
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
    public let domain: String?
    public let img: String?
    public let title: String?
    public let description: String?
    public let contentType: String?
    public let publisherId: String?
    public let publisherName: String?
    public let publisherLogo: String?
    
    enum CodingKeys: String, CodingKey {
        case publishTime = "publish_time"
        case feedSource = "feed_source"
        case url
        case domain
        case img
        case title
        case description
        case contentType = "content_type"
        case publisherId = "publisher_id"
        case publisherName = "publisher_name"
        case publisherLogo = "publisher_logo"
    }
}

public func ==(lhs: FeedItem, rhs: FeedItem) -> Bool {
    return lhs.id == rhs.id
        && lhs.publishTime == rhs.publishTime
        && lhs.feedSource == rhs.feedSource
        && lhs.url == rhs.url
        && lhs.domain == rhs.domain
        && lhs.img == rhs.img
        && lhs.title == rhs.title
        && lhs.description == rhs.description
        && lhs.contentType == rhs.contentType
        && lhs.publisherId == rhs.publisherId
        && lhs.publisherName == rhs.publisherName
        && lhs.publisherLogo == rhs.publisherLogo
        && lhs.sessionDisplayed == rhs.sessionDisplayed
        && lhs.removed == rhs.removed
        && lhs.liked == rhs.liked
        && lhs.unread == rhs.unread
}

public struct PublisherItem: Equatable {
    public let id: Int
    public let publisherId: String
    public let publisherName: String
    public let publisherLogo: String
    public let show: Bool

    /// Initializer for when a record is loaded from a database row
    public init(id: Int = 0, publisherId: String, publisherName: String, publisherLogo: String, show: Bool = true) {
        self.id = id
        self.publisherId = publisherId
        self.publisherName = publisherName
        self.publisherLogo = publisherLogo
        self.show = show
    }
}

public struct PublisherData: Decodable {
    public let publisherId: String?
    public let publisherName: String?
    public let publisherLogo: String?
    public let show: Bool?
    
    enum CodingKeys: String, CodingKey {
        case publisherId = "publisher_id"
        case publisherName = "publisher_name"
        case publisherLogo = "publisher_logo"
        case show = "default"
    }
}

public func ==(lhs: PublisherItem, rhs: PublisherItem) -> Bool {
    return lhs.id == rhs.id
        && lhs.publisherId == rhs.publisherId
        && lhs.publisherName == rhs.publisherName
        && lhs.publisherLogo == rhs.publisherLogo
        && lhs.show == rhs.show
}
