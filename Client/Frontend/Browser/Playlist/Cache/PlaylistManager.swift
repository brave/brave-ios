// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation
import Shared

private let log = Logger.browserLogger

protocol PlaylistManagerDelegate: class {
    func onDownloadProgressUpdate(id: String, percentComplete: Double)
    func onDownloadStateChanged(id: String, state: PlaylistManager.DownloadState, displayName: String)
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
    }
    
    func numberOfAssets() -> Int {
        return frc.fetchedObjects?.count ?? 0
    }
    
    func itemAtIndex(_ index: Int) -> PlaylistInfo {
        return PlaylistInfo(item: frc.object(at: IndexPath(row: index, section: 0)))
    }
    
    func assetAtIndex(_ index: Int) -> AVURLAsset {
        return asset(for: itemAtIndex(index).src)
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
        guard self.task(for: item.pageSrc) == nil else { return }
        
        let asset = AVURLAsset(url: URL(string: item.src)!)
        
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
