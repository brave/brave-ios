// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import OrderedCollections
import Strings
import AVFoundation
import Preferences
import Shared

public actor PlaylistService: ObservableObject {
  
  @Published private(set) var playlists: [Playlist] = []
  @Published private(set) var offlineMediaStates: [Item.ID: OfflineMediaCache.State] = [:]
  
  public struct Storage<Element: Identifiable> {
    var create: @Sendable (Element) async throws -> Element.ID
    var readMany: @Sendable () async -> [Element]
    var readOne: @Sendable (Element.ID) async -> Element?
    var update: @Sendable (Element) async throws -> Void
    var delete: @Sendable (Element.ID) async throws -> Void
  }
  
  private var storage: Storage<Playlist>
  private var itemStorage: Storage<Item>
  private var offlineMediaCache: OfflineMediaCache
  
  /// Creates a playlist service and sets up a default playlist if it doesn't already exist
  public init(
    storage: Storage<Playlist> = .coreData,
    itemStorage: Storage<Item> = .coreData,
    offlineMediaCache: OfflineMediaCache/* = .live*/
  ) async {
    self.storage = storage
    self.itemStorage = itemStorage
    self.offlineMediaCache = offlineMediaCache
    
    // Handle setup around the default playlist, calls storage methods directly since we haven't
    // set `playlists` yet.
    if var defaultPlaylist = await storage.readOne(.defaultPlaylistID) {
      if defaultPlaylist.title != Strings.Playlist.defaultPlaylistTitle {
        // This title may change so we should update it
        defaultPlaylist.title = Strings.Playlist.defaultPlaylistTitle
        try? await storage.update(defaultPlaylist)
      }
    } else {
      do {
        _ = try await storage.create(
          .init(id: .defaultPlaylistID, title: Strings.Playlist.defaultPlaylistTitle, items: [])
        )
      } catch {}
    }
    self.playlists = await storage.readMany()
  }
  
  // MARK: - Playlist
  
  /// Creates an empty playlist with a given title and optionally moves a set of items that exist
  /// in the default playlist.
  public func createPlaylist(
    title: String,
    movingDefaultPlaylistItems items: [Item.ID] = []
  ) async throws -> Playlist.ID {
    var playlist = Playlist(id: UUID().uuidString, title: title, items: [])
    let id = try await storage.create(playlist)
    if !items.isEmpty {
      await moveItems(items, from: .defaultPlaylistID, to: id)
    }
    // FIXME: Update `playlists`
    return id
  }
  
  public func renamePlaylist(_ playlistId: Playlist.ID, title: String) async {
    if var playlist = await storage.readOne(playlistId) {
      playlist.title = title
      do {
        try await storage.update(playlist)
        // FIXME: Update `playlists`
      } catch {
      }
    }
  }
  
  /// Deletes a playlist and all the items associated with it
  public func deletePlaylist(_ playlistID: Playlist.ID) async {
    do {
      guard let playlist = await storage.readOne(playlistID) else {
        // Nothing to delete
        return
      }
      // FIXME: Consider CoreData where cascading deletes exist and this step isn't neccessary?
      for item in playlist.items {
        await deleteItem(item.id)
      }
      try await storage.delete(playlistID)
      // FIXME: Update `playlists`
    } catch {
      
    }
  }
  
  // MARK: - Items
  
  /// Adds a playlist item that was discovered on a webpage to specific playlist.
  ///
  /// Upon successfully adding to the playlist, a download will begin if the user has offline
  /// downloads enabled.
  public func addItem(_ item: Item, to playlistID: Playlist.ID) async {
    guard var playlist = await storage.readOne(playlistID) else {
      return
    }
    playlist.items.append(item)
    do {
      // FIXME: Fetch asset duration first?
      _ = try await itemStorage.create(item)
      let cacheRule = OfflineMediaCache.AutomaticCacheRule(rawValue: Preferences.Playlist.automaticCacheRule.value) ?? .on
      if cacheRule == .on || (cacheRule == .wifi && isReachableByWifi()) {
        await self.enqueueDownload(for: item)
      }
      // FIXME: Update `playlists`
    } catch {
      
    }
    
    func isReachableByWifi() -> Bool {
      if case .online(.wiFi) = Reach().connectionStatus() {
        return true
      }
      return false
    }
  }
  
  public func deleteItem(_ item: Item.ID) async {
    do {
      try await itemStorage.delete(item)
      // FIXME: Cancel any active downloads, delete any cache
    } catch {
      
    }
  }
  
  /// Updates a playlist item
  public func updateItem(_ item: Item) async {
    do {
      try await itemStorage.update(item)
      // FIXME: Update `playlists`
    } catch {
      
    }
  }
  
  /// Moves a set of items from one playlist to another
  public func moveItems(
    _ items: [Item.ID],
    from sourcePlaylistID: Playlist.ID,
    to playlistID: Playlist.ID
  ) async {
    for item in items {
      if var item = await itemStorage.readOne(item) {
        item.parent = playlistID
        do {
          try await itemStorage.update(item)
        } catch { 
          continue
        }
      }
    }
    // FIXME: Update `playlists`
  }
  
  // MARK: - Shared Playlists
  
  public func updateItemsInSharedPlaylist(_ playlist: Playlist.ID) async {
    
  }
  
  // MARK: - Offline Cache
  
  public var isDiskSpaceEmcumbered: Bool {
    let availableDiskSpace = offlineMediaCache.availableDiskSpace()
    let totalDiskSpace = offlineMediaCache.totalDiskSpace()
    let usedDiskSpace = totalDiskSpace - availableDiskSpace
    // If disk space is 90% used
    return totalDiskSpace == 0 || (Double(usedDiskSpace) / Double(totalDiskSpace)) >= 0.9
  }
  
  /// Adds an item to the queue
  public func enqueueDownload(for item: Item) async {
    
  }
  
  /// Removes offline cache for a given item if it exists
  public func removeOfflineCache(for item: Item) async {
    
  }
  
  /// Removes all stored offline cache
  public func removeAllOfflineMedia() async {
    
  }
  
  // MARK: - Assets
  
  // FIXME: Consider returning a Player directly instead?
  public func asset(for item: Item) async -> AVURLAsset {
    // FIXME: Look for offline cache first, then get updated stream URL if needed
    return .init(url: item.source)
  }
}
