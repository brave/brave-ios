// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data
import FeedKit
import Fuzi
import Shared

struct RSSFeedLocation: Hashable {
    var title: String?
    var url: URL
    
    var id: String {
        url.absoluteString
    }
}

extension FeedDataSource {
    
    // MARK: - RSS Sources
    
    var rssFeedLocations: [RSSFeedLocation] {
        RSSFeedSource.all().compactMap {
            guard let url = URL(string: $0.feedUrl) else { return nil }
            return RSSFeedLocation(title: $0.title, url: url)
        }
    }
    
    /// Add a users custom RSS feed to the list of sources
    ///
    /// - returns: `true` if the feed is successfully added, `false` if it already exists
    @discardableResult
    func addRSSFeedLocation(_ location: RSSFeedLocation) -> Bool {
        let feedUrl = location.url.absoluteString
        if RSSFeedSource.get(with: feedUrl) != nil {
            return false
        }
        RSSFeedSource.insert(title: location.title,
                             feedUrl: feedUrl)
        setNeedsReloadCards()
        return true
    }
    
    /// Remove a users custom RSS feed to the list of sources
    func removeRSSFeed(with url: URL) {
        let feedUrl = url.absoluteString
        if RSSFeedSource.get(with: feedUrl) == nil {
            return
        }
        RSSFeedSource.delete(with: url.absoluteString)
        setNeedsReloadCards()
    }
    
    /// Whether or not an RSS feed is currently enabled
    ///
    /// - note: RSS Feeds are enabled by default since they are added by the user
    func isRSSFeedEnabled(_ location: RSSFeedLocation) -> Bool {
        FeedSourceOverride.get(fromId: location.id)?.enabled ?? true
    }
    
    /// Toggle an RSS feed enabled state
    func toggleRSSFeedEnabled(_ location: RSSFeedLocation, enabled: Bool) {
        FeedSourceOverride.setEnabled(forId: location.id, enabled: enabled)
        setNeedsReloadCards()
    }
}

extension FeedItem.Content {
    init?(from feedItem: JSONFeedItem, location: RSSFeedLocation) {
        guard let publishTime = feedItem.datePublished,
              let url = feedItem.url?.asURL,
              let title = feedItem.title else {
            return nil
        }
        var description = ""
        var imageURL: URL?
        if let image = feedItem.image {
            imageURL = URL(string: image, relativeTo: location.url.domainURL)
        }
        if let text = feedItem.contentText {
            description = text
        }
        if let html = feedItem.contentHtml {
            let doc = try? HTMLDocument(string: html)
            if imageURL == nil, let src = doc?.firstChild(xpath: "//img[@src]")?.attr("src") {
                imageURL = URL(string: src, relativeTo: location.url.domainURL)
            }
            if description.isEmpty, let text = doc?.root?.childNodes(ofTypes: [.Text, .Element]).map({ node in
                node.stringValue
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: " ")
            }).joined(separator: " ") {
                description = text
            }
        }
        self.init(
            publishTime: publishTime,
            url: url,
            imageURL: imageURL,
            title: title,
            description: description,
            contentType: .article,
            publisherID: location.id,
            urlHash: url.absoluteString,
            baseScore: 0,
            offersCategory: nil
        )
    }
    init?(from feedItem: AtomFeedEntry, location: RSSFeedLocation) {
        guard let publishTime = feedItem.published,
              let href = feedItem.links?.first?.attributes?.href,
              let url = URL(string: href),
              let title = feedItem.title else {
            return nil
        }
        var description = ""
        var imageURL: URL?
        if let thumbnail = feedItem.media?.mediaThumbnails?.first?.attributes?.url {
            imageURL = URL(string: thumbnail, relativeTo: location.url.domainURL)
        }
        if feedItem.summary?.attributes?.type == "text" {
            description = feedItem.summary?.value ?? ""
        } else if feedItem.content?.attributes?.type == "html", let html = feedItem.content?.value {
            // Find one in description?
            let doc = try? HTMLDocument(string: html)
            if imageURL == nil, let src = doc?.firstChild(xpath: "//img[@src]")?.attr("src") {
                imageURL = URL(string: src, relativeTo: location.url.domainURL)
            }
            if let text = doc?.root?.childNodes(ofTypes: [.Text, .Element]).map({ node in
                node.stringValue
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: " ")
            }).joined(separator: " ") {
                description = text
            }
        }
        self.init(
            publishTime: publishTime,
            url: url,
            imageURL: imageURL,
            title: title,
            description: description,
            contentType: .article,
            publisherID: location.id,
            urlHash: url.absoluteString,
            baseScore: 0,
            offersCategory: nil
        )
    }
    init?(from feedItem: RSSFeedItem, location: RSSFeedLocation) {
        guard let publishTime = feedItem.pubDate,
              let href = feedItem.link,
              let url = URL(string: href),
              let title = feedItem.title else {
            return nil
        }
        var description = ""
        var imageURL: URL?
        if let thumbnail = feedItem.media?.mediaThumbnails?.first?.attributes?.url {
            imageURL = URL(string: thumbnail, relativeTo: location.url.domainURL)
        }
        if let html = feedItem.description {
            // Find one in description?
            let doc = try? HTMLDocument(string: html)
            if imageURL == nil, let src = doc?.firstChild(xpath: "//img[@src]")?.attr("src") {
                imageURL = URL(string: src, relativeTo: location.url.domainURL)
            }
            if let text = doc?.root?.childNodes(ofTypes: [.Text, .Element]).map({ node in
                node.stringValue
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: " ")
            }).joined(separator: " ") {
                description = text
            }
        }
        self.init(
            publishTime: publishTime,
            url: url,
            imageURL: imageURL,
            title: title,
            description: description,
            contentType: .article,
            publisherID: location.id,
            urlHash: url.absoluteString,
            baseScore: 0,
            offersCategory: nil
        )
    }
}
extension FeedItem.Source {
    init?(from feed: FeedKit.Feed, location: RSSFeedLocation) {
        let id = location.id
        guard let title = feed.title else { return nil }
        self.init(id: id, isDefault: true, category: "", name: title, isUserSource: true)
    }
}

extension Feed {
    var title: String? {
        switch self {
        case .atom(let feed):
            return feed.title
        case .rss(let feed):
            return feed.title
        case .json(let feed):
            return feed.title
        }
    }
}
