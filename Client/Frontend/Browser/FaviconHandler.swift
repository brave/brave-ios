/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import SDWebImage
import BraveShared
import UIKit

class FaviconHandler {
  static let maximumFaviconSize = 1 * 1024 * 1024  // 1 MiB file size limit

  private var tabObservers: TabObservers!
  private let backgroundQueue = OperationQueue()

  init() {
    self.tabObservers = registerFor(.didLoadPageMetadata, queue: backgroundQueue)
  }

  deinit {
    unregister(tabObservers)
  }

  @MainActor func loadFaviconURL(
    _ faviconURL: String,
    forTab tab: Tab
  ) async throws -> Favicon {
    guard let currentURL = tab.url else {
      throw FaviconError.noImageLoaded
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      FaviconFetcher.loadIcon(url: currentURL, kind: .smallIcon, persistent: !tab.isPrivate) { [weak tab] favicon in
        guard let tab = tab else { return }
        
        if let favicon = favicon {
          tab.favicons.append(favicon)
          continuation.resume(with: .success(favicon))
        } else {
          continuation.resume(throwing: FaviconError.noImageLoaded)
        }
      }
    }
  }
}

extension FaviconHandler: TabEventHandler {
  func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
    tab.favicons.removeAll(keepingCapacity: false)
    Task { @MainActor in
      if let iconURL = metadata.largeIconURL {
        let favicon = try await loadFaviconURL(iconURL, forTab: tab)
        TabEvent.post(.didLoadFavicon(favicon, with: nil), for: tab)
      } else if let iconURL = metadata.faviconURL {
        let favicon = try await loadFaviconURL(iconURL, forTab: tab)
        TabEvent.post(.didLoadFavicon(favicon, with: nil), for: tab)
      }
      // No favicon fetched from metadata, trying base domain's standard favicon location.
      else if let baseURL = tab.url?.domainURL {
        let favicon = try await loadFaviconURL(
          baseURL.appendingPathComponent("favicon.ico").absoluteString,
          forTab: tab)
        TabEvent.post(.didLoadFavicon(favicon, with: nil), for: tab)
      }
    }
  }
}

enum FaviconError: Error {
  case noImageLoaded
}
