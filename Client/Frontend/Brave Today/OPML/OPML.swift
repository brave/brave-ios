// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Fuzi
import Shared

private let log = Logger.browserLogger

/// A set of subscription RSS feed URLs defined through Outline Processor Markup Language
struct OPML: Equatable {
    /// A node contains a set of named attributes describing an XML feed
    struct Outline: Equatable {
        /// Some text describing the feed
        var text: String?
        /// The URL of this feed
        var xmlUrl: String?
    }
    /// The title of the subscription list
    var title: String?
    /// A list of all the feeds contained in the list
    var outlines: [Outline]
}

/// A simple parser to read part of an OPML files contents
///
/// In our case, we only care about obtaining a subset of data from an OPML file:
///     - The main OPML's title (for UI purposes)
///     - The set of "outlines", or feed entries, whos type is "rss" and aren't commented out
class OPMLParser {
    /// Parses the data passed and returns an OPML object
    static func parse(data: Data) -> OPML? {
        guard let document = try? XMLDocument(data: data),
              let _ = document.firstChild(xpath: "//opml") else {
            log.info("Failed to parse XML document")
            return nil
        }
        let title = document.firstChild(xpath: "//head/title")?.stringValue
        let outlines = document.xpath("//outline[contains(@type, \"rss\") and not(contains(@isComment, \"true\"))]").map { element in
            OPML.Outline(
                text: element["text"],
                xmlUrl: element["xmlUrl"]
            )
        }
        return OPML(title: title, outlines: outlines)
    }
}
