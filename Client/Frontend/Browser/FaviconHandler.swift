/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import SDWebImage
import Deferred
import class Data.FaviconMO

class FaviconHandler {
    static let MaximumFaviconSize = 1 * 1024 * 1024 // 1 MiB file size limit

    private var tabObservers: TabObservers!
    private let backgroundQueue = OperationQueue()

    init() {
        self.tabObservers = registerFor(.didLoadPageMetadata, queue: backgroundQueue)
    }

    deinit {
        unregister(tabObservers)
    }

    func loadFaviconURL(_ faviconURL: String, forTab tab: Tab) -> Deferred<Maybe<(Favicon, Data?)>> {
        guard let iconURL = URL(string: faviconURL), let currentURL = tab.url else {
            return deferMaybe(FaviconError())
        }

        let deferred = Deferred<Maybe<(Favicon, Data?)>>()
        let manager = SDWebImageManager.shared()
        let options: SDWebImageOptions = tab.isPrivate ? SDWebImageOptions([.lowPriority, .cacheMemoryOnly]) : SDWebImageOptions([.lowPriority])

        var fetch: SDWebImageOperation? = nil

        let onProgress: SDWebImageDownloaderProgressBlock = { (receivedSize, expectedSize, _) -> Void in
            if receivedSize > FaviconHandler.MaximumFaviconSize || expectedSize > FaviconHandler.MaximumFaviconSize {
                fetch?.cancel()
            }
        }

        let onSuccess: (Favicon, Data?) -> Void = { [weak tab] (favicon, data) -> Void in
            defer { deferred.fill(Maybe(success: (favicon, data))) }
            
            guard let tab = tab else { return }
            
            tab.favicons.append(favicon)
            if !tab.isPrivate {
                FaviconMO.add(favicon, forSiteUrl: currentURL)
            }
        }

        let onCompletedSiteFavicon: SDInternalCompletionBlock = { (img, data, _, _, _, url) -> Void in
            guard let urlString = url?.absoluteString else {
                deferred.fill(Maybe(failure: FaviconError()))
                return
            }

            let favicon = Favicon(url: urlString, date: Date())

            guard let img = img else {
                favicon.width = 0
                favicon.height = 0

                onSuccess(favicon, data)
                return
            }

            favicon.width = Int(img.size.width)
            favicon.height = Int(img.size.height)

            onSuccess(favicon, data)
        }

        let onCompletedPageFavicon: SDInternalCompletionBlock = { (img, data, _, _, _, url) -> Void in
            guard let img = img, let urlString = url?.absoluteString else {
                // If we failed to download a page-level icon, try getting the domain-level icon
                // instead before ultimately failing.
                let siteIconURL = currentURL.domainURL.appendingPathComponent("favicon.ico")
                fetch = manager.loadImage(with: siteIconURL, options: options, progress: onProgress, completed: onCompletedSiteFavicon)

                return
            }

            let favicon = Favicon(url: urlString, date: Date())
            favicon.width = Int(img.size.width)
            favicon.height = Int(img.size.height)

            onSuccess(favicon, data)
        }

        fetch = manager.loadImage(with: iconURL, options: options, progress: onProgress, completed: onCompletedPageFavicon)
        return deferred
    }
}

extension FaviconHandler: TabEventHandler {
    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        tab.favicons.removeAll(keepingCapacity: false)
        guard let faviconURL = metadata.faviconURL else {
            return
        }

        loadFaviconURL(faviconURL, forTab: tab) >>== { (favicon, data) in
            TabEvent.post(.didLoadFavicon(favicon, with: data), for: tab)
        }
    }
}

class FaviconError: MaybeErrorType {
    internal var description: String {
        return "No Image Loaded"
    }
}
