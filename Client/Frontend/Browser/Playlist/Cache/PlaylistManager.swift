// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation
import Shared
import CoreData
import Data
import BraveShared

private let log = Logger.browserLogger

protocol PlaylistManagerDelegate: AnyObject {
    func onDownloadProgressUpdate(id: String, percentComplete: Double)
    func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String?, error: Error?)
    
    func controllerDidChange(_ anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    func controllerDidChangeContent()
    func controllerWillChangeContent()
}

class PlaylistManager: NSObject {
    static let shared = PlaylistManager()
    weak var delegate: PlaylistManagerDelegate?
    
    private let downloadManager = PlaylistDownloadManager()
    private let frc = PlaylistItem.frc()
    private var didRestoreSession = false
    
    private override init() {
        super.init()
        
        downloadManager.delegate = self
        frc.delegate = self
    }
    
    func numberOfAssets() -> Int {
        frc.fetchedObjects?.count ?? 0
    }
    
    func itemAtIndex(_ index: Int) -> PlaylistInfo {
        PlaylistInfo(item: frc.object(at: IndexPath(row: index, section: 0)))
    }
    
    func assetAtIndex(_ index: Int) -> AVURLAsset {
        let item = itemAtIndex(index)
        return asset(for: item.pageSrc, mediaSrc: item.src)
    }
    
    func index(of pageSrc: String) -> Int? {
        frc.fetchedObjects?.firstIndex(where: { $0.pageSrc == pageSrc })
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
    
    func state(for pageSrc: String) -> PlaylistDownloadManager.DownloadState {
        if downloadManager.downloadTask(for: pageSrc) != nil {
            return .inProgress
        }
        
        if let assetUrl = downloadManager.localAsset(for: pageSrc)?.url {
            if FileManager.default.fileExists(atPath: assetUrl.path) {
                return .downloaded
            }
        }

        return .invalid
    }
    
    func sizeOfDownloadedItem(for pageSrc: String) -> String? {
        if let assetUrl = downloadManager.localAsset(for: pageSrc)?.url, FileManager.default.fileExists(atPath: assetUrl.path), let size = try? FileManager.default.attributesOfItem(atPath: assetUrl.path)[.size] as? Int {
            let formatter = ByteCountFormatter()
            formatter.zeroPadsFractionDigits = true
            formatter.countStyle = .file
            return formatter.string(fromByteCount: Int64(size))
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
    
    func restoreSession() {
        downloadManager.restoreSession() { [weak self] in
            self?.reloadData()
        }
    }
    
    func download(item: PlaylistInfo) {
        guard downloadManager.downloadTask(for: item.pageSrc) == nil, let assetUrl = URL(string: item.src) else { return }
        
        MediaResourceManager.getMimeType(assetUrl) { [weak self] mimeType in
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
    
    func cancelDownload(item: PlaylistInfo) {
        downloadManager.cancelDownload(item: item)
    }
    
    func delete(item: PlaylistInfo) {
        do {
            if let assetUrl = downloadManager.localAsset(for: item.pageSrc)?.url {
                try FileManager.default.removeItem(at: assetUrl)
                PlaylistItem.removeItem(item)
                
                delegate?.onDownloadStateChanged(id: item.pageSrc, state: .invalid, displayName: nil, error: nil)
            } else {
                PlaylistItem.removeItem(item)
            }
        } catch {
            log.error("An error occured deleting Playlist Item \(item.name): \(error)")
        }
    }
    
    func deleteCache(item: PlaylistInfo) {
        do {
            if let assetUrl = downloadManager.localAsset(for: item.pageSrc)?.url {
                try FileManager.default.removeItem(at: assetUrl)
                PlaylistItem.updateCache(pageSrc: item.pageSrc, cachedData: nil)
                delegate?.onDownloadStateChanged(id: item.pageSrc, state: .invalid, displayName: nil, error: nil)
            }
        } catch {
            log.error("An error occured deleting Playlist Cached Item \(item.name): \(error)")
        }
    }
    
    func deleteAllItems(cacheOnly: Bool = false) {
        // This is the only way to have the system kill picture in picture as the restoration controller is deallocated
        // And that means the video is deallocated, its AudioSession is stopped, and the Picture-In-Picture controller is deallocated.
        // This is because `AVPictureInPictureController` is NOT a view controller and there is no way to dismiss it
        // other than to deallocate the restoration controller.
        // We could also call `AVPictureInPictureController.stopPictureInPicture` BUT we'd still have to deallocate all resources.
        // At least this way, we deallocate both AND pip is stopped in the destructor of `PlaylistViewController->ListController`
        (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController = nil
        
        func clearCache(item: PlaylistInfo) throws {
            if let assetUrl = downloadManager.localAsset(for: item.pageSrc)?.url {
                try FileManager.default.removeItem(at: assetUrl)
                PlaylistItem.updateCache(pageSrc: item.pageSrc, cachedData: nil)
            }
        }
        
        guard let playlistItems = frc.fetchedObjects else {
            log.error("An error occured while fetching Playlist Objects")
            return
        }
        
        for playlistItem in playlistItems {
            let item = PlaylistInfo(item: playlistItem)
            
            do {
                try clearCache(item: item)
                if !cacheOnly {
                    PlaylistItem.removeItem(item)
                }
            } catch {
                log.error("An error occured deleting Playlist Cached Item \(item.name): \(error)")
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
}

extension PlaylistManager {
    private func asset(for pageSrc: String, mediaSrc: String) -> AVURLAsset {
        if let task = downloadManager.downloadTask(for: pageSrc) {
            return task.asset
        }
        
        if let asset = downloadManager.localAsset(for: pageSrc) {
            return asset
        }
        
        return AVURLAsset(url: URL(string: mediaSrc)!)
    }
}

extension PlaylistManager: PlaylistDownloadManagerDelegate {
    func onDownloadProgressUpdate(id: String, percentComplete: Double) {
        delegate?.onDownloadProgressUpdate(id: id, percentComplete: percentComplete)
    }
    
    func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String?, error: Error?) {
        delegate?.onDownloadStateChanged(id: id, state: state, displayName: displayName, error: error)
    }
}

extension PlaylistManager: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        delegate?.controllerDidChange(anObject, at: indexPath, for: type, newIndexPath: newIndexPath)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.controllerDidChangeContent()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.controllerWillChangeContent()
    }
}

extension AVAsset {
    func displayNames(for mediaSelection: AVMediaSelection) -> String? {
        var names = ""
        for mediaCharacteristic in availableMediaCharacteristicsWithMediaSelectionOptions {
            guard let mediaSelectionGroup = mediaSelectionGroup(forMediaCharacteristic: mediaCharacteristic),
                  let option = mediaSelection.selectedMediaOption(in: mediaSelectionGroup) else { continue }

            if names.isEmpty {
                names += " " + option.displayName
            } else {
                names += ", " + option.displayName
            }
        }

        return names.isEmpty ? nil : names
    }
}
