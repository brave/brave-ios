// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveCore
import SDWebImage
import Shared

private let log = Logger.browserLogger

/// Handles obtaining favicons for URLs from local files, database or internet
public class FaviconFetcher {
  public static let defaultFaviconImage = UIImage(named: "defaultFavicon", in: .current, compatibleWith: nil)!

  /// The size requirement for the favicon
  public enum Kind {
    /// Load favicons marked as `apple-touch-icon`.
    ///
    /// Usage: NTP, Favorites
    case largeIcon
    /// Load smaller favicons
    ///
    /// Usage: History, Search, Tab Tray
    case smallIcon
  }
  
  public static func clearCache() {
    SDImageCache.shared.memoryCache.removeAllObjects()
    SDImageCache.shared.diskCache.removeAllData()
  }
  
  @discardableResult
  public static func loadIcon(url: URL, kind: FaviconFetcher.Kind = .smallIcon, persistent: Bool, completion: ((Favicon?) -> Void)?) -> Cancellable {
    let cancellable = Cancellable { (task, bundledRenderer, faviconRenderer) in
      guard let task = task, !task.isCancelled else {
        completion?(nil)
        return
      }
      
      if let favicon = getFromCache(for: url) {
        completion?(favicon)
        return
      }

      // Fetch bundled icons or custom icons first
      bundledRenderer?.loadIcon(url: url) { [weak task] favicon in
        guard let task = task, !task.isCancelled else {
          completion?(nil)
          return
        }
        
        // A bundled or custom icon was found
        if let favicon = favicon {
          storeInCache(favicon, for: url, persistent: persistent)
          completion?(favicon)
          return
        }
        
        // If there are no bundled or custom icons, fetch the icons from Brave-Core
        faviconRenderer?.loadIcon(for: url, persistent: persistent) { [weak task] favicon in
          guard let task = task, !task.isCancelled else {
            completion?(nil)
            return
          }
          
          // A favicon was fetched
          if let favicon = favicon {
            storeInCache(favicon, for: url, persistent: persistent)
          }
          
          completion?(favicon)
        }
      }
    }
    
    cancellable.execute(on: .main)
    return cancellable
  }
  
  public class Cancellable {
    private var workItem: DispatchWorkItem?
    private var task: (Cancellable, BundledFaviconImageRenderer, FaviconRenderer) -> Void
    private var bundledRenderer: BundledFaviconImageRenderer?
    private var faviconRenderer: FaviconRenderer?
    
    public var isCancelled: Bool {
      workItem?.isCancelled ?? true
    }
    
    public func cancel() {
      workItem?.cancel()
      workItem = nil
    }
    
    fileprivate init(task: @escaping (Cancellable?, BundledFaviconImageRenderer?, FaviconRenderer?) -> Void) {
      self.task = task
      self.bundledRenderer = BundledFaviconImageRenderer()
      self.faviconRenderer = FaviconRenderer()
      
      self.workItem = DispatchWorkItem { [weak self] in
        task(self, self?.bundledRenderer, self?.faviconRenderer)
      }
    }
    
    fileprivate func execute(on queue: DispatchQueue) {
      if let workItem = workItem {
        queue.async(execute: workItem)
      }
    }
  }
  
  private static func cacheURL(for url: URL) -> URL {
    // Some websites still only have a favicon for the FULL url including the fragmented parts
    // But they won't have a favicon for their domain
    // In this case, we want to store the favicon for the entire domain regardless of query parameters or fragmented parts
    // Example: `https://app.uniswap.org/` has no favicon, but `https://app.uniswap.org/#/swap?chain=mainnet` does.
    return URLOrigin(url: url).url ?? url
  }
  
  private static func storeInCache(_ favicon: Favicon, for url: URL, persistent: Bool) {
    // Do not cache non-persistent icons
    // Do not cache monogram icons
    if persistent && !favicon.isMonogramImage {
      do {
        let data = try JSONEncoder().encode(favicon)
        let cachedURL = cacheURL(for: url)
        SDImageCache.shared.memoryCache.setObject(data, forKey: cachedURL.absoluteString, cost: UInt(data.count))
        SDImageCache.shared.diskCache.setData(data, forKey: cachedURL.absoluteString)
      } catch {
        log.error(error)
      }
    }
  }
  
  private static func getFromCache(for url: URL) -> Favicon? {
    let cachedURL = cacheURL(for: url)
    guard let data = SDImageCache.shared.memoryCache.object(forKey: cachedURL.absoluteString) as? Data ??
            SDImageCache.shared.diskCache.data(forKey: cachedURL.absoluteString) else {
      return nil
    }
    
    do {
      return try JSONDecoder().decode(Favicon.self, from: data)
    } catch {
      log.error(error)
    }
    return nil
  }
}
