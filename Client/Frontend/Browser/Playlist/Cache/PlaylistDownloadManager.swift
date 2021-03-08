// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation
import Shared

private let log = Logger.browserLogger

protocol PlaylistDownloadManagerDelegate: class {
    func onDownloadProgressUpdate(id: String, percentComplete: Double)
    func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String)
}

private protocol PlaylistStreamDownloadManagerDelegate: class {
    func localAsset(for pageSrc: String) -> AVURLAsset?
    func displayNames(for mediaSelection: AVMediaSelection) -> String
    func onDownloadProgressUpdate(id: String, percentComplete: Double)
    func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String)
}

struct MediaDownloadTask {
    let id: String
    let name: String
    let asset: AVURLAsset
    
    enum Keys: String {
        case id
        case state
        case displayName
    }
}

public class PlaylistDownloadManager: PlaylistStreamDownloadManagerDelegate {
    private let hlsSession: AVAssetDownloadURLSession
    private let fileSession: URLSession
    private let hlsDelegate: PlaylistHLSDownloadManager
    private let fileDelegate: PlaylistFileDownloadManager
    private var didRestoreSession = false
    
    weak var delegate: PlaylistDownloadManagerDelegate?
    
    public enum DownloadState: String {
        case downloaded
        case inProgress
        case invalid
    }
    
    init() {
        hlsDelegate = PlaylistHLSDownloadManager()
        fileDelegate = PlaylistFileDownloadManager()
        
        let hlsConfiguration = URLSessionConfiguration.background(withIdentifier: "com.brave.playlist.hls.background.session")
        hlsSession = AVAssetDownloadURLSession(configuration: hlsConfiguration,
                                               assetDownloadDelegate: hlsDelegate,
                                               delegateQueue: OperationQueue())
        
        let fileConfiguration = URLSessionConfiguration.background(withIdentifier: "com.brave.playlist.file.background.session")
        fileSession = URLSession(configuration: fileConfiguration,
                                 delegate: fileDelegate,
                                 delegateQueue: OperationQueue())
        
        hlsDelegate.delegate = self
        fileDelegate.delegate = self
    }
    
    func restoreSession(_ completion: @escaping () -> Void) {
        // Called from AppDelegate to restore pending downloads
        guard !didRestoreSession else { return }
        didRestoreSession = true
        
        let group = DispatchGroup()
        group.enter()
        hlsDelegate.restoreSession(hlsSession) {
            group.leave()
        }
        
        group.enter()
        fileDelegate.restoreSession(fileSession) {
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    func downloadHLSAsset(_ assetUrl: URL, for item: PlaylistInfo) {
        hlsDelegate.downloadAsset(hlsSession, assetUrl: assetUrl, for: item)
    }
    
    func downloadFileAsset(_ assetUrl: URL, for item: PlaylistInfo) {
        fileDelegate.downloadAsset(fileSession, assetUrl: assetUrl, for: item)
    }
    
    func cancelDownload(item: PlaylistInfo) {
        hlsDelegate.cancelDownload(item: item)
        fileDelegate.cancelDownload(item: item)
    }
    
    func downloadTask(for pageSrc: String) -> MediaDownloadTask? {
        return hlsDelegate.downloadTask(for: pageSrc) ?? fileDelegate.downloadTask(for: pageSrc)
    }
    
    // MARK: - PlaylistStreamDownloadManagerDelegate
    
    func localAsset(for pageSrc: String) -> AVURLAsset? {
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
    
    fileprivate func displayNames(for mediaSelection: AVMediaSelection) -> String {
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
    
    fileprivate func onDownloadProgressUpdate(id: String, percentComplete: Double) {
        delegate?.onDownloadProgressUpdate(id: id, percentComplete: percentComplete)
    }
    
    fileprivate func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String) {
        delegate?.onDownloadStateChanged(id: id, state: state, displayName: displayName)
    }
}

private class PlaylistHLSDownloadManager: NSObject, AVAssetDownloadDelegate {
    private var activeDownloadTasks = [URLSessionTask: MediaDownloadTask]()
    private var pendingDownloadTasks = [URLSessionTask: URL]()
    
    weak var delegate: PlaylistStreamDownloadManagerDelegate?
    
    func restoreSession(_ session: AVAssetDownloadURLSession, completion: @escaping () -> Void) {
        session.getAllTasks { [weak self] tasks in
            guard let self = self else { return }
            
            for task in tasks {
                guard let downloadTask = task as? AVAggregateAssetDownloadTask,
                      let pageSrc = task.taskDescription else { break }
                
                if let item = Playlist.shared.getItem(pageSrc: pageSrc) {
                    let info = PlaylistInfo(item: item)
                    let asset = MediaDownloadTask(id: info.pageSrc, name: info.name, asset: downloadTask.urlAsset)
                    self.activeDownloadTasks[downloadTask] = asset
                }
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func downloadAsset(_ session: AVAssetDownloadURLSession, assetUrl: URL, for item: PlaylistInfo) {
        let asset = AVURLAsset(url: assetUrl)

        guard let task =
                session.aggregateAssetDownloadTask(with: asset,
                                                  mediaSelections: [asset.preferredMediaSelection],
                                                  assetTitle: item.name,
                                                  assetArtworkData: nil,
                                                  options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]) else { return }

        task.taskDescription = item.pageSrc
        activeDownloadTasks[task] = MediaDownloadTask(id: item.pageSrc, name: item.name, asset: asset)
        task.resume()

        delegate?.onDownloadStateChanged(id: item.pageSrc, state: .inProgress, displayName: delegate?.displayNames(for: asset.preferredMediaSelection) ?? "")
    }
    
    func cancelDownload(item: PlaylistInfo) {
        for (task, value) in activeDownloadTasks where item.pageSrc == value.id {
            task.cancel()
            activeDownloadTasks.removeValue(forKey: task)
            pendingDownloadTasks.removeValue(forKey: task)
            break
        }
    }
    
    func downloadTask(for pageSrc: String) -> MediaDownloadTask? {
        for (_, asset) in activeDownloadTasks where pageSrc == asset.id {
            return asset
        }

        return nil
    }
    
    // MARK: - AVAssetDownloadDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let task = task as? AVAggregateAssetDownloadTask,
              let asset = activeDownloadTasks.removeValue(forKey: task),
              let assetUrl = pendingDownloadTasks.removeValue(forKey: task) else { return }

        if let error = error as NSError? {
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                guard let cacheLocation = delegate?.localAsset(for: asset.id)?.url else { return }

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
            
            DispatchQueue.main.async {
                self.delegate?.onDownloadStateChanged(id: asset.id, state: .invalid, displayName: "")
            }
        } else {
            do {
                let cachedData = try assetUrl.bookmarkData()
                Playlist.shared.updateCache(pageSrc: asset.id, cachedData: cachedData)
            } catch {
                log.error("Failed to create bookmarkData for download URL.")
            }
            
            DispatchQueue.main.async {
                self.delegate?.onDownloadStateChanged(id: asset.id, state: .downloaded, displayName: "")
            }
        }
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
        
        pendingDownloadTasks[aggregateAssetDownloadTask] = location
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didCompleteFor mediaSelection: AVMediaSelection) {
        
        guard let asset = activeDownloadTasks[aggregateAssetDownloadTask] else { return }
        aggregateAssetDownloadTask.taskDescription = asset.id
        aggregateAssetDownloadTask.resume()
        
        DispatchQueue.main.async {
            self.delegate?.onDownloadStateChanged(id: asset.id, state: .inProgress, displayName: self.delegate?.displayNames(for: mediaSelection) ?? "")
        }
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
        
        guard let asset = activeDownloadTasks[aggregateAssetDownloadTask] else { return }

        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete +=
                loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        
        DispatchQueue.main.async {
            self.delegate?.onDownloadProgressUpdate(id: asset.id, percentComplete: percentComplete * 100.0)
        }
    }
}

private class PlaylistFileDownloadManager: NSObject, URLSessionDownloadDelegate {
    private var activeDownloadTasks = [URLSessionTask: MediaDownloadTask]()
    
    weak var delegate: PlaylistStreamDownloadManagerDelegate?
    
    func restoreSession(_ session: URLSession, completion: @escaping () -> Void) {
        session.getAllTasks { [weak self] tasks in
            guard let self = self else { return }
            
            for task in tasks {
                guard let pageSrc = task.taskDescription else { break }
                
                if let item = Playlist.shared.getItem(pageSrc: pageSrc),
                   let mediaSrc = item.mediaSrc,
                   let assetUrl = URL(string: mediaSrc) {
                    let info = PlaylistInfo(item: item)
                    let asset = MediaDownloadTask(id: info.pageSrc, name: info.name, asset: AVURLAsset(url: assetUrl))
                    self.activeDownloadTasks[task] = asset
                }
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func downloadAsset(_ session: URLSession, assetUrl: URL, for item: PlaylistInfo) {
        let asset = AVURLAsset(url: assetUrl)
        
        let request: URLRequest = {
            var request = URLRequest(url: assetUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
            request.addValue("bytes=0-", forHTTPHeaderField: "Range")
            request.addValue(UUID().uuidString, forHTTPHeaderField: "X-Playback-Session-Id")
            request.addValue("AppleCoreMedia/1.0.0.17E255 (iPhone; U; CPU OS 13_4 like Mac OS X; en_ca)", forHTTPHeaderField: "User-Agent")
            return request
        }()
        
        let task = session.downloadTask(with: request)
        
        task.taskDescription = item.pageSrc
        activeDownloadTasks[task] = MediaDownloadTask(id: item.pageSrc, name: item.name, asset: asset)
        task.resume()
        
        delegate?.onDownloadStateChanged(id: item.pageSrc, state: .inProgress, displayName: delegate?.displayNames(for: asset.preferredMediaSelection) ?? "")
    }
    
    func cancelDownload(item: PlaylistInfo) {
        for (task, value) in activeDownloadTasks where item.pageSrc == value.id {
            task.cancel()
            activeDownloadTasks.removeValue(forKey: task)
            break
        }
    }
    
    func downloadTask(for pageSrc: String) -> MediaDownloadTask? {
        for (_, asset) in activeDownloadTasks where pageSrc == asset.id {
            return asset
        }

        return nil
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let task = task as? URLSessionDownloadTask,
              let asset = activeDownloadTasks.removeValue(forKey: task) else { return }

        if let error = error as NSError? {
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                guard let cacheLocation = delegate?.localAsset(for: asset.id)?.url else { return }

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
            
            DispatchQueue.main.async {
                self.delegate?.onDownloadStateChanged(id: asset.id, state: .invalid, displayName: "")
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        guard let asset = activeDownloadTasks[downloadTask] else { return }
        let percentage = (Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) * 100.0
        
        DispatchQueue.main.async {
            self.delegate?.onDownloadProgressUpdate(id: asset.id, percentComplete: percentage)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let asset = activeDownloadTasks.removeValue(forKey: downloadTask) else { return }
        
        if let response = downloadTask.response as? HTTPURLResponse, response.statusCode == 302 || response.statusCode >= 200 && response.statusCode <= 299 {
            
            var fileExtension = ""
            
            // Detect based on Content-Type header.
            if let contentType = response.allHeaderFields["Content-Type"] as? String {
                let detectedExtension = PlaylistMimeTypeDetector(mimeType: contentType).fileExtension
                if !detectedExtension.isEmpty {
                    fileExtension = detectedExtension
                }
            }
            
            // Detect based on Data.
            if fileExtension.isEmpty {
                if let data = try? Data(contentsOf: location, options: .mappedIfSafe) {
                    let detectedExtension = PlaylistMimeTypeDetector(data: data).fileExtension
                    if !detectedExtension.isEmpty {
                        fileExtension = detectedExtension
                    }
                }
            }
            
            // Couldn't determine file type so we assume mp4 which is the most widely used container.
            // If it doesn't work, the video/audio just won't play anyway.
            if fileExtension.isEmpty {
                fileExtension = "mp4"
            }
            
            do {
                if let path = try? uniqueDownloadPathForFilename(asset.name + ".\(fileExtension)") {
                    try FileManager.default.moveItem(at: location, to: path)
                    do {
                        let cachedData = try path.bookmarkData()
                        
                        DispatchQueue.main.async {
                            Playlist.shared.updateCache(pageSrc: asset.id, cachedData: cachedData)
                            self.delegate?.onDownloadStateChanged(id: asset.id, state: .downloaded, displayName: "")
                        }
                        return
                    } catch {
                        log.error("Failed to create bookmarkData for download URL.")
                    }
                    
                    try FileManager.default.removeItem(at: path)
                }
            } catch {
                log.error(error)
            }
        }
        
        DispatchQueue.main.async {
            Playlist.shared.updateCache(pageSrc: asset.id, cachedData: nil)
            self.delegate?.onDownloadStateChanged(id: asset.id, state: .invalid, displayName: "")
        }
    }
    
    // MARK: - Internal
    
    private func playlistPath() throws -> URL {
        FileManager.default.getOrCreateFolder(name: "Playlist", excludeFromBackups: true, location: .documentDirectory)
        return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                       appropriateFor: nil, create: false).appendingPathComponent("Playlist")
    }
    
    private func uniqueDownloadPathForFilename(_ filename: String) throws -> URL {
        let filename = HTTPDownload.stripUnicode(fromFilename: filename)
        let downloadsPath = try playlistPath()
        let basePath = downloadsPath.appendingPathComponent(filename)
        let fileExtension = basePath.pathExtension
        let filenameWithoutExtension = fileExtension.count > 0 ? String(filename.dropLast(fileExtension.count + 1)) : filename
        
        var proposedPath = basePath
        var count = 0
        
        while FileManager.default.fileExists(atPath: proposedPath.path) {
            count += 1
            
            let proposedFilenameWithoutExtension = "\(filenameWithoutExtension) (\(count))"
            proposedPath = downloadsPath.appendingPathComponent(proposedFilenameWithoutExtension).appendingPathExtension(fileExtension)
        }
        
        return proposedPath
    }
}
