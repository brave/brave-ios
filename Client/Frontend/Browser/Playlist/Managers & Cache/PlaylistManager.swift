// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation
import Combine
import CoreData

import Shared
import Data
import BraveShared

private let log = Logger.browserLogger

public class PlaylistManager: NSObject {
  public static let shared = PlaylistManager()

  private var assetInformation = [PlaylistAssetFetcher]()
  private let downloadManager = PlaylistDownloadManager()
  private var frc = PlaylistItem.frc()
  private var didRestoreSession = false

  // Observers
  private let onContentWillChange = PassthroughSubject<Void, Never>()
  private let onContentDidChange = PassthroughSubject<Void, Never>()
  private let onObjectChange = PassthroughSubject<
    (
      object: Any,
      indexPath: IndexPath?,
      type: NSFetchedResultsChangeType,
      newIndexPath: IndexPath?
    ), Never
  >()

  private let onDownloadProgressUpdate = PassthroughSubject<
    (
      id: String,
      percentComplete: Double
    ), Never
  >()
  private let onDownloadStateChanged = PassthroughSubject<
    (
      id: String,
      state: PlaylistDownloadManager.DownloadState,
      displayName: String?,
      error: Error?
    ), Never
  >()
  private let onCurrentFolderChanged = PassthroughSubject<(), Never>()
  private let onFolderDeleted = PassthroughSubject<(), Never>()

  private override init() {
    super.init()

    downloadManager.delegate = self
    frc.delegate = self

    // Delete system cache always on startup.
    deleteUserManagedAssets()
  }

  var currentFolder: PlaylistFolder? {
    didSet {
      frc.delegate = nil

      if let currentFolder = currentFolder {
        // Only return an FRC for the specified folder
        frc = PlaylistItem.frc(parentFolder: currentFolder)
      } else {
        // Return every folder, including the "Saved" folder
        frc = PlaylistItem.allFoldersFRC()
      }

      frc.delegate = self
      reloadData()

      onCurrentFolderChanged.send()
    }
  }

  var onFolderRemovedOrUpdated: AnyPublisher<Void, Never> {
    onFolderDeleted.eraseToAnyPublisher()
  }

  var contentWillChange: AnyPublisher<Void, Never> {
    onContentWillChange.eraseToAnyPublisher()
  }

  var contentDidChange: AnyPublisher<Void, Never> {
    onContentDidChange.eraseToAnyPublisher()
  }

  var objectDidChange: AnyPublisher<(object: Any, indexPath: IndexPath?, type: NSFetchedResultsChangeType, newIndexPath: IndexPath?), Never> {
    onObjectChange.eraseToAnyPublisher()
  }

  var downloadProgressUpdated: AnyPublisher<(id: String, percentComplete: Double), Never> {
    onDownloadProgressUpdate.eraseToAnyPublisher()
  }

  var downloadStateChanged: AnyPublisher<(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String?, error: Error?), Never> {
    onDownloadStateChanged.eraseToAnyPublisher()
  }

  var onCurrentFolderDidChange: AnyPublisher<(), Never> {
    onCurrentFolderChanged.eraseToAnyPublisher()
  }

  var allItems: [PlaylistInfo] {
    frc.fetchedObjects?.map({ PlaylistInfo(item: $0) }) ?? []
  }

  var numberOfAssets: Int {
    frc.fetchedObjects?.count ?? 0
  }

  var fetchedObjects: [PlaylistItem] {
    frc.fetchedObjects ?? []
  }

  func itemAtIndex(_ index: Int) -> PlaylistInfo? {
    if index < numberOfAssets {
      return PlaylistInfo(item: frc.object(at: IndexPath(row: index, section: 0)))
    }
    return nil
  }

  func assetAtIndex(_ index: Int) -> AVURLAsset? {
    if let item = itemAtIndex(index) {
      return asset(for: item.tagId, mediaSrc: item.src)
    }
    return nil
  }

  func index(of itemId: String) -> Int? {
    frc.fetchedObjects?.firstIndex(where: { $0.uuid == itemId })
  }

  func reorderItems(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath, completion: (() -> Void)?) {
    guard var objects = frc.fetchedObjects else {
      ensureMainThread {
        completion?()
      }
      return
    }

    frc.managedObjectContext.perform { [weak self] in
      defer {
        ensureMainThread {
          completion?()
        }
      }

      guard let self = self else { return }

      let src = self.frc.object(at: sourceIndexPath)
      objects.remove(at: sourceIndexPath.row)
      objects.insert(src, at: destinationIndexPath.row)

      for (order, item) in objects.enumerated().reversed() {
        item.order = Int32(order)
      }

      do {
        try self.frc.managedObjectContext.save()
      } catch {
        log.error(error)
      }
    }
  }

  func state(for itemId: String) -> PlaylistDownloadManager.DownloadState {
    if downloadManager.downloadTask(for: itemId) != nil {
      return .inProgress
    }

    if let assetUrl = downloadManager.localAsset(for: itemId)?.url {
      if FileManager.default.fileExists(atPath: assetUrl.path) {
        return .downloaded
      }
    }

    return .invalid
  }

  func sizeOfDownloadedItem(for itemId: String) -> String? {
    var isDirectory: ObjCBool = false
    if let asset = downloadManager.localAsset(for: itemId),
      FileManager.default.fileExists(atPath: asset.url.path, isDirectory: &isDirectory) {

      let formatter = ByteCountFormatter().then {
        $0.zeroPadsFractionDigits = true
        $0.countStyle = .file
      }

      if isDirectory.boolValue || asset.url.pathExtension.lowercased() == "movpkg" {
        let properties: [URLResourceKey] = [.isRegularFileKey, .totalFileAllocatedSizeKey]
        guard
          let enumerator = FileManager.default.enumerator(
            at: asset.url,
            includingPropertiesForKeys: properties,
            options: .skipsHiddenFiles,
            errorHandler: nil)
        else {
          return nil
        }

        let sizes = enumerator.compactMap({
          try? ($0 as? URL)?
            .resourceValues(forKeys: Set(properties))
        })
        .filter({ $0.isRegularFile == true })
        .compactMap({ $0.totalFileAllocatedSize })
        .compactMap({ Int64($0) })

        return formatter.string(fromByteCount: Int64(sizes.reduce(0, +)))
      }

      if let size = try? FileManager.default.attributesOfItem(atPath: asset.url.path)[.size] as? Int {
        return formatter.string(fromByteCount: Int64(size))
      }
    }
    return nil
  }

  func reloadData() {
    do {
      try frc.performFetch()
    } catch {
      log.error(error)
    }
  }

  public func restoreSession() {
    if !didRestoreSession {
      didRestoreSession = true

      downloadManager.restoreSession() { [weak self] in
        self?.reloadData()
      }
    }
  }

  func download(item: PlaylistInfo) {
    guard downloadManager.downloadTask(for: item.tagId) == nil, let assetUrl = URL(string: item.src) else { return }

    PlaylistMediaStreamer.getMimeType(assetUrl) { [weak self] mimeType in
      guard let self = self, let mimeType = mimeType?.lowercased() else { return }

      if mimeType.contains("x-mpegurl") || mimeType.contains("application/vnd.apple.mpegurl") || mimeType.contains("mpegurl") {
        DispatchQueue.main.async {
          self.downloadManager.downloadHLSAsset(assetUrl, for: item)
        }
      } else {
        DispatchQueue.main.async {
          self.downloadManager.downloadFileAsset(assetUrl, for: item)
        }
      }
    }
  }

  func cancelDownload(itemId: String) {
    downloadManager.cancelDownload(itemId: itemId)
  }

  func delete(folder: PlaylistFolder, _ completion: ((_ success: Bool) -> Void)? = nil) {
    var success = true
    var itemsToDelete = [PlaylistInfo]()

    folder.playlistItems?.forEach({
      let item = PlaylistInfo(item: $0)
      cancelDownload(itemId: item.tagId)

      if let index = assetInformation.firstIndex(where: { $0.itemId == item.tagId }) {
        let assetFetcher = self.assetInformation.remove(at: index)
        assetFetcher.cancelLoading()
      }

      if !deleteCache(itemId: item.tagId) {
        // If we cannot delete an item's cache for any given reason,
        // Do NOT delete the folder containing the item.
        // Delete all other items.
        success = false
      } else {
        itemsToDelete.append(item)
      }
    })

    if success, currentFolder?.objectID == folder.objectID {
      currentFolder = nil
    }
    
    // Delete items from the folder
    PlaylistItem.removeItems(itemsToDelete)
    
    // Attempt to delete the folder if we can
    if success, folder.uuid != PlaylistFolder.savedFolderUUID {
      PlaylistFolder.removeFolder(folder) { [weak self] in
        guard let self = self else {
          completion?(success)
          return
        }
        
        if self.currentFolder?.isDeleted == true {
          self.currentFolder = nil
        }

        self.onFolderDeleted.send()
        self.reloadData()
        
        completion?(success)
      }
    } else {
      if currentFolder?.isDeleted == true {
        currentFolder = nil
      }

      onFolderDeleted.send()
      reloadData()
      completion?(success)
    }
  }

  @discardableResult
  func delete(itemId: String) -> Bool {
    cancelDownload(itemId: itemId)

    if let index = assetInformation.firstIndex(where: { $0.itemId == itemId }) {
      let assetFetcher = self.assetInformation.remove(at: index)
      assetFetcher.cancelLoading()
    }

    if let cacheItem = PlaylistItem.getItem(uuid: itemId),
      cacheItem.cachedData != nil {
      // Do NOT delete the item if we can't delete it's local cache.
      // That will cause zombie items.
      if deleteCache(itemId: itemId) {
        PlaylistItem.removeItem(uuid: itemId)
        onDownloadStateChanged(id: itemId, state: .invalid, displayName: nil, error: nil)
        return true
      }
      return false
    } else {
      PlaylistItem.removeItem(uuid: itemId)
      onDownloadStateChanged(id: itemId, state: .invalid, displayName: nil, error: nil)
      return true
    }
  }

  @discardableResult
  func deleteCache(itemId: String) -> Bool {
    cancelDownload(itemId: itemId)

    if let cacheItem = PlaylistItem.getItem(uuid: itemId),
      let cachedData = cacheItem.cachedData,
      !cachedData.isEmpty {
      var isStale = false

      do {
        let url = try URL(resolvingBookmarkData: cachedData, bookmarkDataIsStale: &isStale)
        if FileManager.default.fileExists(atPath: url.path) {
          try FileManager.default.removeItem(atPath: url.path)
          PlaylistItem.updateCache(uuid: itemId, cachedData: nil)
          onDownloadStateChanged(id: itemId, state: .invalid, displayName: nil, error: nil)
        }
        return true
      } catch {
        log.error("An error occured deleting Playlist Cached Item \(cacheItem.name ?? itemId): \(error)")
        return false
      }
    }
    return true
  }

  func deleteAllItems(cacheOnly: Bool) {
    // This is the only way to have the system kill picture in picture as the restoration controller is deallocated
    // And that means the video is deallocated, its AudioSession is stopped, and the Picture-In-Picture controller is deallocated.
    // This is because `AVPictureInPictureController` is NOT a view controller and there is no way to dismiss it
    // other than to deallocate the restoration controller.
    // We could also call `AVPictureInPictureController.stopPictureInPicture` BUT we'd still have to deallocate all resources.
    // At least this way, we deallocate both AND pip is stopped in the destructor of `PlaylistViewController->ListController`
    PlaylistCarplayManager.shared.playlistController = nil

    guard let playlistItemIds = frc.fetchedObjects?.compactMap({ $0.uuid }) else {
      log.error("An error occured while fetching Playlist Objects")
      return
    }

    for itemId in playlistItemIds {
      if !deleteCache(itemId: itemId) {
        continue
      }

      if !cacheOnly {
        PlaylistItem.removeItem(uuid: itemId)
      }
    }

    if !cacheOnly {
      assetInformation.forEach({ $0.cancelLoading() })
      assetInformation.removeAll()
    }

    // Delete playlist directory.
    // Though it should already be empty
    if let playlistDirectory = PlaylistDownloadManager.playlistDirectory {
      do {
        try FileManager.default.removeItem(at: playlistDirectory)
      } catch {
        log.error("Failed to delete Playlist Directory: \(error)")
      }
    }

    // Delete system cache
    deleteUserManagedAssets()
  }

  private func deleteUserManagedAssets() {
    // Cleanup System Cache Folder com.apple.UserManagedAssets*
    if let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first {
      do {
        let urls = try FileManager.default.contentsOfDirectory(
          at: libraryPath,
          includingPropertiesForKeys: nil,
          options: [.skipsHiddenFiles])
        for url in urls where url.absoluteString.contains("com.apple.UserManagedAssets") {
          do {
            let assets = try FileManager.default.contentsOfDirectory(
              at: url,
              includingPropertiesForKeys: nil,
              options: [.skipsHiddenFiles])
            assets.forEach({
              if let item = PlaylistItem.cachedItem(cacheURL: $0),
                 let itemId = item.uuid {
                self.cancelDownload(itemId: itemId)
                PlaylistItem.updateCache(uuid: itemId, cachedData: nil)
              }
            })
          } catch {
            log.error("Failed to update Playlist item cached state: \(error)")
          }

          do {
            try FileManager.default.removeItem(at: url)
          } catch {
            log.error("Deleting Playlist Item for \(url.absoluteString) failed: \(error)")
          }
        }
      } catch {
        log.error("Deleting Playlist Incomplete Items failed: \(error)")
      }
    }
  }

  func autoDownload(item: PlaylistInfo) {
    guard let downloadType = PlayListDownloadType(rawValue: Preferences.Playlist.autoDownloadVideo.value) else {
      return
    }

    switch downloadType {
    case .on:
      PlaylistManager.shared.download(item: item)
    case .wifi:
      if DeviceInfo.hasWifiConnection() {
        PlaylistManager.shared.download(item: item)
      }
    case .off:
      break
    }
  }

  func isDiskSpaceEncumbered() -> Bool {
    let freeSpace = availableDiskSpace() ?? 0
    let totalSpace = totalDiskSpace() ?? 0
    let usedSpace = totalSpace - freeSpace

    // If disk space is 90% used
    return totalSpace == 0 || (Double(usedSpace) / Double(totalSpace)) * 100.0 >= 90.0
  }

  private func availableDiskSpace() -> Int64? {
    do {
      return try URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage
    } catch {
      log.error("Error Retrieving Disk Space: \(error)")
    }
    return nil
  }

  private func totalDiskSpace() -> Int64? {
    do {
      if let result = try URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [.volumeTotalCapacityKey]).volumeTotalCapacity {
        return Int64(result)
      }
    } catch {
      log.error("Error Retrieving Disk Space: \(error)")
    }
    return nil
  }
}

extension PlaylistManager {
  private func asset(for itemId: String, mediaSrc: String) -> AVURLAsset {
    if let task = downloadManager.downloadTask(for: itemId) {
      return task.asset
    }

    if let asset = downloadManager.localAsset(for: itemId) {
      return asset
    }

    return AVURLAsset(url: URL(string: mediaSrc)!)
  }
}

extension PlaylistManager: PlaylistDownloadManagerDelegate {
  func onDownloadProgressUpdate(id: String, percentComplete: Double) {
    onDownloadProgressUpdate.send((id: id, percentComplete: percentComplete))
  }

  func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String?, error: Error?) {
    onDownloadStateChanged.send((id: id, state: state, displayName: displayName, error: error))
  }
}

extension PlaylistManager: NSFetchedResultsControllerDelegate {
  public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

    onObjectChange.send((object: anObject, indexPath: indexPath, type: type, newIndexPath: newIndexPath))
  }

  public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    onContentDidChange.send(())
  }

  public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    onContentWillChange.send(())
  }
}

extension PlaylistManager {
  func getAssetDuration(item: PlaylistInfo, _ completion: @escaping (TimeInterval?) -> Void) {
    if assetInformation.contains(where: { $0.itemId == item.tagId }) {
      return
    }

    fetchAssetDuration(item: item) { [weak self] duration in
      guard let self = self else { return }

      if let index = self.assetInformation.firstIndex(where: { $0.itemId == item.tagId }) {
        let assetFetcher = self.assetInformation.remove(at: index)
        assetFetcher.cancelLoading()
      }

      completion(duration)
    }
  }

  private func fetchAssetDuration(item: PlaylistInfo, _ completion: @escaping (TimeInterval?) -> Void) {
    let tolerance: Double = 0.00001
    let distance = abs(item.duration.distance(to: 0.0))

    // If the database duration is live/indefinite
    if item.duration.isInfinite || abs(item.duration.distance(to: TimeInterval.greatestFiniteMagnitude)) < tolerance {
      completion(TimeInterval.infinity)
      return
    }

    // If the database duration is 0.0
    if distance >= tolerance {
      // Return the database duration
      completion(item.duration)
      return
    }

    // Attempt to retrieve the duration from the Asset file
    let asset: AVURLAsset
    if item.src.isEmpty || item.pageSrc.isEmpty {
      if let index = index(of: item.tagId), let urlAsset = assetAtIndex(index) {
        asset = urlAsset
      } else {
        // Return the database duration
        completion(item.duration)
        return
      }
    } else {
      asset = self.asset(for: item.tagId, mediaSrc: item.src)
    }

    // Accessing tracks blocks the main-thread if not already loaded
    // So we first need to check the track status before attempting to access it!
    var error: NSError?
    let trackStatus = asset.statusOfValue(forKey: "tracks", error: &error)
    if let error = error {
      log.error("AVAsset.statusOfValue error occurred: \(error)")
    }

    if trackStatus == .loaded {
      if !asset.tracks.isEmpty,
        let track = asset.tracks(withMediaType: .video).first ?? asset.tracks(withMediaType: .audio).first {
        if track.timeRange.duration.isIndefinite {
          completion(TimeInterval.infinity)
        } else {
          completion(track.timeRange.duration.seconds)
        }
        return
      }
    } else if trackStatus != .loading {
      log.debug("AVAsset.statusOfValue not loaded. Status: \(trackStatus)")
    }

    // Accessing duration or commonMetadata blocks the main-thread if not already loaded
    // So we first need to check the track status before attempting to access it!
    let durationStatus = asset.statusOfValue(forKey: "duration", error: &error)
    if let error = error {
      log.error("AVAsset.statusOfValue error occurred: \(error)")
    }

    if durationStatus == .loaded {
      // If it's live/indefinite
      if asset.duration.isIndefinite {
        completion(TimeInterval.infinity)
        return
      }

      // If it's a valid duration
      if abs(asset.duration.seconds.distance(to: 0.0)) >= tolerance {
        completion(asset.duration.seconds)
        return
      }
    } else if durationStatus != .loading {
      log.debug("AVAsset.statusOfValue not loaded. Status: \(durationStatus)")
    }

    switch Reach().connectionStatus() {
    case .offline, .unknown:
      completion(item.duration)  // Return the database duration
      return
    case .online:
      break
    }

    // We can't get the duration synchronously so we need to let the AVAsset load the media item
    // and hopefully we get a valid duration from that.
    DispatchQueue.global(qos: .userInitiated).async {
      asset.loadValuesAsynchronously(forKeys: ["playable", "tracks", "duration"]) {
        var error: NSError?
        let trackStatus = asset.statusOfValue(forKey: "tracks", error: &error)
        if let error = error {
          log.error("AVAsset.statusOfValue error occurred: \(error)")
        }

        let durationStatus = asset.statusOfValue(forKey: "tracks", error: &error)
        if let error = error {
          log.error("AVAsset.statusOfValue error occurred: \(error)")
        }

        if trackStatus == .cancelled || durationStatus == .cancelled {
          log.error("Asset Duration Fetch Cancelled")

          ensureMainThread {
            completion(nil)
          }
          return
        }

        if trackStatus == .failed && durationStatus == .failed, let error = error {
          if error.code == NSURLErrorNoPermissionsToReadFile {
            // Media item is expired.. permission is denied
            log.debug("Playlist Media Item Expired: \(item.pageSrc)")

            ensureMainThread {
              completion(nil)
            }
          } else {
            log.error("An unknown error occurred while attempting to fetch track and duration information: \(error)")

            ensureMainThread {
              completion(nil)
            }
          }

          return
        }

        var duration: CMTime = .zero
        if trackStatus == .loaded {
          if let track = asset.tracks(withMediaType: .video).first ?? asset.tracks(withMediaType: .audio).first {
            duration = track.timeRange.duration
          } else {
            duration = asset.duration
          }
        } else if durationStatus == .loaded {
          duration = asset.duration
        }

        ensureMainThread {
          if duration.isIndefinite {
            completion(TimeInterval.infinity)
          } else if abs(duration.seconds.distance(to: 0.0)) > tolerance {
            let newItem = PlaylistInfo(
              name: item.name,
              src: item.src,
              pageSrc: item.pageSrc,
              pageTitle: item.pageTitle,
              mimeType: item.mimeType,
              duration: duration.seconds,
              detected: item.detected,
              dateAdded: item.dateAdded,
              tagId: item.tagId)

            if PlaylistItem.itemExists(uuid: item.tagId) || PlaylistItem.itemExists(pageSrc: item.pageSrc) {
              PlaylistItem.updateItem(newItem) {
                completion(duration.seconds)
              }
            } else {
              completion(duration.seconds)
            }
          } else {
            completion(duration.seconds)
          }
        }
      }
    }

    assetInformation.append(PlaylistAssetFetcher(itemId: item.tagId, asset: asset))
  }
}

extension AVAsset {
  func displayNames(for mediaSelection: AVMediaSelection) -> String? {
    var names = ""
    for mediaCharacteristic in availableMediaCharacteristicsWithMediaSelectionOptions {
      guard let mediaSelectionGroup = mediaSelectionGroup(forMediaCharacteristic: mediaCharacteristic),
        let option = mediaSelection.selectedMediaOption(in: mediaSelectionGroup)
      else { continue }

      if names.isEmpty {
        names += " " + option.displayName
      } else {
        names += ", " + option.displayName
      }
    }

    return names.isEmpty ? nil : names
  }
}
