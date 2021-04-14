// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation
import Shared
import CoreData

private let log = Logger.browserLogger

protocol PlaylistManagerDelegate: class {
    func onDownloadProgressUpdate(id: String, percentComplete: Double)
    func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String)
    
    func controllerDidChange(_ anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    func controllerDidChangeContent()
    func controllerWillChangeContent()
}

class PlaylistManager: NSObject {
    static let shared = PlaylistManager()
    weak var delegate: PlaylistManagerDelegate?
    
    private let downloadManager = PlaylistDownloadManager()
    private var frc = Playlist.shared.fetchResultsController()
    private var didRestoreSession = false
    
    private override init() {
        super.init()
        
        downloadManager.delegate = self
        frc.delegate = self
    }
    
    func numberOfAssets() -> Int {
        return frc.fetchedObjects?.count ?? 0
    }
    
    func itemAtIndex(_ index: Int) -> PlaylistInfo {
        return PlaylistInfo(item: frc.object(at: IndexPath(row: index, section: 0)))
    }
    
    func assetAtIndex(_ index: Int) -> AVURLAsset {
        return asset(for: itemAtIndex(index).pageSrc)
    }
    
    func index(of pageSrc: String) -> Int? {
        return frc.fetchedObjects?.firstIndex(where: { $0.pageSrc == pageSrc })
    }
    
    func reorderItems(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if var objects = frc.fetchedObjects {
            frc.delegate = nil
            
            let src = frc.object(at: sourceIndexPath)
            objects.remove(at: sourceIndexPath.row)
            objects.insert(src, at: destinationIndexPath.row)
            
            for (order, item) in objects.enumerated().reversed() {
                item.order = Int32(order)
            }
            
            do {
                try frc.managedObjectContext.save()
            } catch {
                log.error(error)
            }
            
            frc.delegate = self
        }
    }
    
    func state(for pageSrc: String) -> PlaylistDownloadManager.DownloadState {
        if let assetUrl = downloadManager.localAsset(for: pageSrc)?.url {
            if FileManager.default.fileExists(atPath: assetUrl.path) {
                return .downloaded
            }
        }
        
        if downloadManager.downloadTask(for: pageSrc) != nil {
            return .inProgress
        }

        return .invalid
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
            guard let self = self else { return }

            if mimeType.contains("x-mpegURL") || mimeType.contains("application/vnd.apple.mpegurl") || mimeType.lowercased().contains("mpegurl") {
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
            if let assetUrl = localAsset(for: item.pageSrc)?.url {
                try FileManager.default.removeItem(at: assetUrl)
                Playlist.shared.removeItem(item: item)
                
                delegate?.onDownloadStateChanged(id: item.pageSrc, state: .invalid, displayName: "")
            } else {
                Playlist.shared.removeItem(item: item)
            }
        } catch {
            log.error("An error occured deleting Playlist Item \(item.name): \(error)")
        }
    }
    
    func deleteCache(item: PlaylistInfo) {
        do {
            if let assetUrl = localAsset(for: item.pageSrc)?.url {
                try FileManager.default.removeItem(at: assetUrl)
                Playlist.shared.updateCache(pageSrc: item.pageSrc, cachedData: nil)
                delegate?.onDownloadStateChanged(id: item.pageSrc, state: .invalid, displayName: "")
            }
        } catch {
            log.error("An error occured deleting Playlist Cached Item \(item.name): \(error)")
        }
    }
    
    // MARK: - Private
    
    private struct MediaDownloadTask {
        let id: String
        let name: String
        let asset: AVURLAsset
        
        enum Keys: String {
            case id
            case state
            case displayName
        }
    }
}

extension PlaylistManager {
    private func displayNames(for mediaSelection: AVMediaSelection) -> String {
        guard let asset = mediaSelection.asset else {
            return ""
        }
        
        var names = ""
        for mediaCharacteristic in asset.availableMediaCharacteristicsWithMediaSelectionOptions {
            guard let mediaSelectionGroup = asset.mediaSelectionGroup(forMediaCharacteristic: mediaCharacteristic),
                  let option = mediaSelection.selectedMediaOption(in: mediaSelectionGroup) else { continue }

            if names.isEmpty {
                names += " " + option.displayName
            } else {
                names += ", " + option.displayName
            }
        }

        return names
    }
    
    private func localAsset(for pageSrc: String) -> AVURLAsset? {
        guard let item = Playlist.shared.getItem(pageSrc: pageSrc),
              let cachedData = item.cachedData else { return nil }

        var bookmarkDataIsStale = false
        do {
            let url = try URL(resolvingBookmarkData: cachedData,
                              bookmarkDataIsStale: &bookmarkDataIsStale)

            if bookmarkDataIsStale {
                return nil
            }
            
            return AVURLAsset(url: url)
        } catch {
            log.error(error)
            return nil
        }
    }
    
    private func asset(for pageSrc: String) -> AVURLAsset {
        if let task = downloadManager.downloadTask(for: pageSrc) {
            return task.asset
        }
        
        if let asset = self.localAsset(for: pageSrc) {
            return asset
        }
        
        return AVURLAsset(url: URL(string: pageSrc)!)
    }
}

extension PlaylistManager: PlaylistDownloadManagerDelegate {
    func onDownloadProgressUpdate(id: String, percentComplete: Double) {
        delegate?.onDownloadProgressUpdate(id: id, percentComplete: percentComplete)
    }
    
    func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String) {
        delegate?.onDownloadStateChanged(id: id, state: state, displayName: displayName)
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
