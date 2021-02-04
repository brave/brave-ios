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
    func onDownloadStateChanged(id: String, state: PlaylistManager.DownloadState, displayName: String)
    
    func controllerDidChange(_ anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    func controllerDidChangeContent()
    func controllerWillChangeContent()
}

class PlaylistManager: NSObject {
    static let shared = PlaylistManager()
    weak var delegate: PlaylistManagerDelegate?
    
    private var session: AVAssetDownloadURLSession!
    private var activeTasks = [AVAggregateAssetDownloadTask: DownloadTask]()
    private var pendingTasks = [AVAggregateAssetDownloadTask: URL]()
    private var frc = Playlist.shared.fetchResultsController()
    
    private override init() {
        super.init()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.brave.playlist.background.session")
        session = AVAssetDownloadURLSession(configuration: configuration,
                                            assetDownloadDelegate: self,
                                            delegateQueue: .main)
        
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
        let src = frc.object(at: sourceIndexPath)
        let dest = frc.object(at: destinationIndexPath)
        
        if src === dest {
            log.error("Source and destination playlist items are the same!")
            return
        }
        
        var destinationNode: NSManagedObjectID?
        let isMovingUp = sourceIndexPath.row > destinationIndexPath.row
        if isMovingUp {
            let isMovingToTop = destinationIndexPath.row == 0
            if !isMovingToTop {
                let previousIndex = IndexPath(row: destinationIndexPath.row - 1,
                                              section: destinationIndexPath.section)
                destinationNode = frc.object(at: previousIndex).objectID
            }
        } else {
            let isMovingToBottom = destinationIndexPath.row + 1 >= numberOfAssets()
            if !isMovingToBottom {
                let nextBookmarkIndex = IndexPath(row: destinationIndexPath.row + 1,
                                                  section: destinationIndexPath.section)
                destinationNode = frc.object(at: nextBookmarkIndex).objectID
            }
        }
        
        let context = frc.managedObjectContext
        context.perform {
            guard let source = context.object(with: src.objectID) as? PlaylistItem,
                let destination = context.object(with: dest.objectID) as? PlaylistItem else {
                    log.error("Could not retrieve source or destination playlist items on background context.")
                    return
            }
            
            
        }
    }
    
    func state(for pageSrc: String) -> DownloadState {
        if let assetUrl = self.localAsset(for: pageSrc)?.url {
            if FileManager.default.fileExists(atPath: assetUrl.path) {
                return .downloaded
            }
        }
        
        if task(for: pageSrc) != nil {
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
        session.getAllTasks { [weak self] tasks in
            guard let self = self else { return }
            
            for task in tasks {
                guard let downloadTask = task as? AVAggregateAssetDownloadTask,
                      let pageSrc = task.taskDescription else { break }
                
                if let item = Playlist.shared.getItem(pageSrc: pageSrc) {
                    let info = PlaylistInfo(item: item)
                    let asset = DownloadTask(id: info.pageSrc, name: info.name, asset: downloadTask.urlAsset)
                    self.activeTasks[downloadTask] = asset
                }
            }
            
            DispatchQueue.main.async {
                self.onStateRestored()
            }
        }
    }
    
    func download(item: PlaylistInfo) {
        guard self.task(for: item.pageSrc) == nil, let assetUrl = URL(string: item.src) else { return }
        
        MediaResourceManager.getMimeType(assetUrl) { [weak self] mimeType in
            guard let self = self else { return }

            if mimeType.contains("x-mpegURL") || mimeType.contains("application/vnd.apple.mpegurl") || mimeType.lowercased().contains("mpegurl") {
                DispatchQueue.main.async {
                    self.downloadHLSAsset(assetUrl, for: item)
                }
            } else {
                DispatchQueue.main.async {
                    self.downloadFileAsset(assetUrl, for: item)
                }
            }
        }
    }
    
    func cancelDownload(item: PlaylistInfo) {
        for (task, value) in activeTasks where item.pageSrc == value.id {
            task.cancel()
            break
        }
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
    
    private func downloadFileAsset(_ assetUrl: URL, for item: PlaylistInfo) {
        self.delegate?.onDownloadStateChanged(id: item.pageSrc, state: .inProgress, displayName: "")
        
        MediaResourceManager.downloadAsset(assetUrl, name: item.name) { location in
            DispatchQueue.main.async {
                do {
                    let bookmarkData = try URL(string: location)?.bookmarkData()
                    Playlist.shared.updateCache(pageSrc: item.pageSrc, cachedData: bookmarkData)
                    
                    if let url = URL(string: location) {
                        let asset = AVURLAsset(url: url)
                        self.delegate?.onDownloadStateChanged(id: item.pageSrc, state: .inProgress, displayName: self.displayNames(for: asset.preferredMediaSelection))
                    } else {
                        self.delegate?.onDownloadStateChanged(id: item.pageSrc, state: .inProgress, displayName: "")
                    }
                } catch {
                    log.error(error)
                    try? FileManager.default.removeItem(atPath: location)
                }
            }
        }
    }
    
    private func downloadHLSAsset(_ assetUrl: URL, for item: PlaylistInfo) {
        let asset = AVURLAsset(url: assetUrl)

        guard let task =
            session.aggregateAssetDownloadTask(with: asset,
                                               mediaSelections: [asset.preferredMediaSelection],
                                               assetTitle: item.name,
                                               assetArtworkData: nil,
                                               options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]) else { return }

        task.taskDescription = item.pageSrc
        activeTasks[task] = DownloadTask(id: item.pageSrc, name: item.name, asset: asset)
        task.resume()

        delegate?.onDownloadStateChanged(id: item.pageSrc, state: .inProgress, displayName: self.displayNames(for: asset.preferredMediaSelection))
    }
    
    private func task(for pageSrc: String) -> DownloadTask? {
        for (_, asset) in activeTasks where pageSrc == asset.id {
            return asset
        }

        return nil
    }
    
    private struct DownloadTask {
        let id: String
        let name: String
        let asset: AVURLAsset
        
        enum Keys: String {
            case id
            case state
            case displayName
        }
    }
    
    public enum DownloadState: String {
        case downloaded
        case inProgress
        case invalid
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
    
    private func onStateRestored() {
        self.reloadData()
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
        if let task = self.task(for: pageSrc) {
            return task.asset
        }
        
        if let asset = self.localAsset(for: pageSrc) {
            return asset
        }
        
        return AVURLAsset(url: URL(string: pageSrc)!)
    }
}

extension PlaylistManager: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let task = task as? AVAggregateAssetDownloadTask,
              let asset = activeTasks.removeValue(forKey: task),
              let assetUrl = pendingTasks.removeValue(forKey: task) else { return }

        if let error = error as NSError? {
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                guard let cacheLocation = self.localAsset(for: asset.id)?.url else { return }

                do {
                    try FileManager.default.removeItem(at: cacheLocation)
                    Playlist.shared.updateCache(pageSrc: asset.id, cachedData: nil)
                } catch {
                    log.error("Could not delete asset cache \(asset.name): \(error)")
                }

            case (NSURLErrorDomain, NSURLErrorUnknown):
                fatalError("Downloading HLS streams is not supported on the simulator.")

            default:
                fatalError("Fatal Error: \(error.domain)")
            }
            
            delegate?.onDownloadStateChanged(id: asset.id, state: .invalid, displayName: "")
        } else {
            do {
                let cachedData = try assetUrl.bookmarkData()
                Playlist.shared.updateCache(pageSrc: asset.id, cachedData: cachedData)
            } catch {
                print("Failed to create bookmarkData for download URL.")
            }
            
            delegate?.onDownloadStateChanged(id: asset.id, state: .downloaded, displayName: "")
        }
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
        
        pendingTasks[aggregateAssetDownloadTask] = location
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didCompleteFor mediaSelection: AVMediaSelection) {
        
        guard let asset = activeTasks[aggregateAssetDownloadTask] else { return }
        aggregateAssetDownloadTask.taskDescription = asset.id
        aggregateAssetDownloadTask.resume()
        
        delegate?.onDownloadStateChanged(id: asset.id, state: .inProgress, displayName: self.displayNames(for: mediaSelection))
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
        
        guard let asset = activeTasks[aggregateAssetDownloadTask] else { return }

        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete +=
                loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        
        delegate?.onDownloadProgressUpdate(id: asset.id, percentComplete: percentComplete)
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
