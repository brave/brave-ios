/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import Deferred
import Data

private let log = Logger.browserLogger

// swiftlint:disable:next force_try
private let URLBeforePathRegex = try! NSRegularExpression(pattern: "^https?://([^/]+)/", options: [])

// TODO: Swift currently requires that classes extending generic classes must also be generic.
// This is a workaround until that requirement is fixed.
typealias SearchLoader = _SearchLoader<AnyObject, AnyObject>

/**
 * Shared data source for the SearchViewController and the URLBar domain completion.
 * Since both of these use the same SQL query, we can perform the query once and dispatch the results.
 */
class _SearchLoader<UnusedA, UnusedB>: Loader<[Site], SearchViewController> {
    fileprivate let profile: Profile
    fileprivate let topToolbar: TopToolbarView
    fileprivate var inProgress: Cancellable?

    init(profile: Profile, topToolbar: TopToolbarView) {
        self.profile = profile
        self.topToolbar = topToolbar

        super.init()
    }

    fileprivate lazy var topDomains: [String] = {
        guard let filePath = Bundle.main.path(forResource: "topdomains", ofType: "txt"),
            let domains = try? String(contentsOfFile: filePath).components(separatedBy: "\n") else {
                return []
        }
        return domains
    }()

    // `weak` usage here allows deferred queue to be the owner. The deferred is always filled and this set to nil,
    // this is defensive against any changes to queue (or cancellation) behaviour in future.
    private weak var currentDbQuery: Cancellable?

    var query: String = "" {
        didSet {
            guard let profile = self.profile as? BrowserProfile else {
                assertionFailure("nil profile")
                return
            }

            if query.isEmpty {
                load([])
                return
            }
            
            if let inProgress = inProgress {
                inProgress.cancel()
                self.inProgress = nil
            }

            let deferred = FrecencyQuery.sitesByFrecency(containing: query)
            inProgress = deferred as? Cancellable

            deferred.uponQueue(.main) { result in
                defer {
                    self.inProgress = nil
                }
                
                // First, see if the query matches any URLs from the user's search history.
                self.load(result)
                for site in result {
                    if let completion = self.completionForURL(site.url) {
                        self.topToolbar.setAutocompleteSuggestion(completion)
                        return
                    }
                }
                
                // If there are no search history matches, try matching one of the Alexa top domains.
                for domain in self.topDomains {
                    if let completion = self.completionForDomain(domain) {
                        self.topToolbar.setAutocompleteSuggestion(completion)
                        return
                    }
                }
            }
        }
    }

    fileprivate func completionForURL(_ url: String) -> String? {
        // Extract the pre-path substring from the URL. This should be more efficient than parsing via
        // NSURL since we need to only look at the beginning of the string.
        // Note that we won't match non-HTTP(S) URLs.
        guard let match = URLBeforePathRegex.firstMatch(in: url, options: [], range: NSRange(location: 0, length: url.count)) else {
            return nil
        }

        // If the pre-path component (including the scheme) starts with the query, just use it as is.
        var prePathURL = (url as NSString).substring(with: match.range(at: 0))
        if prePathURL.hasPrefix(query) {
            // Trailing slashes in the autocompleteTextField cause issues with Swype keyboard. Bug 1194714
            if prePathURL.hasSuffix("/") {
                prePathURL.remove(at: prePathURL.index(before: prePathURL.endIndex))
            }
            return prePathURL
        }

        // Otherwise, find and use any matching domain.
        // To simplify the search, prepend a ".", and search the string for ".query".
        // For example, for http://en.m.wikipedia.org, domainWithDotPrefix will be ".en.m.wikipedia.org".
        // This allows us to use the "." as a separator, so we can match "en", "m", "wikipedia", and "org",
        let domain = (url as NSString).substring(with: match.range(at: 1))
        return completionForDomain(domain)
    }

    fileprivate func completionForDomain(_ domain: String) -> String? {
        let domainWithDotPrefix: String = ".\(domain)"
        if let range = domainWithDotPrefix.range(of: ".\(query)", options: .caseInsensitive, range: nil, locale: nil) {
            // We don't actually want to match the top-level domain ("com", "org", etc.) by itself, so
            // so make sure the result includes at least one ".".
            let matchedDomain = String(domainWithDotPrefix.suffix(from: domainWithDotPrefix.index(range.lowerBound, offsetBy: 1)))
            if matchedDomain.contains(".") {
                return matchedDomain
            }
        }

        return nil
    }
}
