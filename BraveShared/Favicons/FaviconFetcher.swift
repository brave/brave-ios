// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveCore
import SDWebImage

/// Handles obtaining favicons for URLs from local files, database or internet
public class FaviconFetcher {
  private static var operations = Set<FaviconOperation>()
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
    // Some websites still only have a favicon for the FULL url including the fragmented parts
    // But they won't have a favicon for their domain
    // In this case, we want to store the favicon for the entire domain regardless of query parameters or fragmented parts
    // Example: `https://app.uniswap.org/` has no favicon, but `https://app.uniswap.org/#/swap?chain=mainnet` does.
    let cacheURL = URLOrigin(url: url).url ?? url
    
    func storeInCache(_ favicon: Favicon, for url: URL) {
      // Do not cache persistent icons
      // Do not cache monogram icons
      if persistent, !favicon.isMonogramImage {
        guard let data = try? JSONEncoder().encode(favicon) else {
          return
        }
        
        SDImageCache.shared.memoryCache.setObject(data, forKey: cacheURL.absoluteString, cost: UInt(data.count))
        SDImageCache.shared.diskCache.setData(data, forKey: cacheURL.absoluteString)
      }
    }
    
    func getFromCache(for url: URL) -> Favicon? {
      let data = SDImageCache.shared.memoryCache.object(forKey: cacheURL.absoluteString) as? Data ??
                 SDImageCache.shared.diskCache.data(forKey: cacheURL.absoluteString)
      
      if let data = data,
          let favicon = try? JSONDecoder().decode(Favicon.self, from: data) {
        return favicon
      }
      
      return nil
    }
    
    var workItem: DispatchWorkItem?
    workItem = DispatchWorkItem {
      guard let task = workItem, !task.isCancelled else {
        workItem = nil
        return
      }
      
      if let favicon = getFromCache(for: url) {
        workItem = nil
        completion?(favicon)
        return
      }
      
      let operation = FaviconOperation(completion: completion)
      operations.insert(operation)

      // Fetch bundled icons or custom icons first
      operation.bundledRenderer.load(url: url) { [weak operation, weak task] favicon in
        guard let operation = operation else { return }
        guard let task = task, !task.isCancelled else {
          workItem = nil
          operations.remove(operation)
          return
        }
        
        // A bundled or custom icon was found
        if let favicon = favicon {
          workItem = nil
          operations.remove(operation)
          storeInCache(favicon, for: url)
          operation.completion?(favicon)
          return
        }
        
        // If there are no bundled or custom icons, fetch the icons from Brave-Core
        operation.faviconRenderer.loadIcon(for: url, persistent: persistent) { [weak operation, weak task] favicon in
          guard let operation = operation else { return }
          guard let task = task, !task.isCancelled else {
            workItem = nil
            operations.remove(operation)
            return
          }
          
          workItem = nil
          operations.remove(operation)
          
          // A favicon was fetched
          if let favicon = favicon {
            storeInCache(favicon, for: url)
          }
          
          operation.completion?(favicon)
        }
      }
    }
    
    if let task = workItem {
      DispatchQueue.main.async(execute: task)
    }
    
    return Cancellable(task: workItem)
  }
  
  public class Cancellable {
    private var task: DispatchWorkItem?
    
    init(task: DispatchWorkItem?) {
      self.task = task
    }
    
    var isCancelled: Bool {
      task?.isCancelled ?? true
    }
    
    public func cancel() {
      task?.cancel()
      task = nil
    }
  }
  
  private class FaviconOperation: Hashable, Equatable {
    let id = UUID().uuidString
    let bundledRenderer = BundledFaviconImageRenderer()
    let faviconRenderer = FaviconRenderer()
    let completion: ((Favicon?) -> Void)?
    
    init(completion: ((Favicon?) -> Void)?) {
      self.completion = completion
    }
    
    static func == (lhs: FaviconFetcher.FaviconOperation, rhs: FaviconFetcher.FaviconOperation) -> Bool {
      return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
  }
}
