// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation
import Shared
import Data

private let log = Logger.browserLogger

protocol PlaylistDownloadManagerDelegate: AnyObject {
    func onDownloadProgressUpdate(id: String, percentComplete: Double)
    func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String, error: Error?)
}

private protocol PlaylistStreamDownloadManagerDelegate: AnyObject {
    func localAsset(for pageSrc: String) -> AVURLAsset?
    func onDownloadProgressUpdate(id: String, percentComplete: Double)
    func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String, error: Error?)
}

struct MediaDownloadTask {
    let id: String
    let name: String
    let asset: AVURLAsset
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
        hlsDelegate.downloadTask(for: pageSrc) ?? fileDelegate.downloadTask(for: pageSrc)
    }
    
    // MARK: - PlaylistStreamDownloadManagerDelegate
    
    func localAsset(for pageSrc: String) -> AVURLAsset? {
        guard let item = PlaylistItem.getItem(pageSrc: pageSrc),
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
    
    fileprivate func onDownloadProgressUpdate(id: String, percentComplete: Double) {
        delegate?.onDownloadProgressUpdate(id: id, percentComplete: percentComplete)
    }
    
    fileprivate func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String, error: Error?) {
        delegate?.onDownloadStateChanged(id: id, state: state, displayName: displayName, error: error)
    }
    
    fileprivate static func playlistPath() throws -> URL {
        FileManager.default.getOrCreateFolder(name: "Playlist", excludeFromBackups: true, location: .applicationSupportDirectory)
        return try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                       appropriateFor: nil, create: false).appendingPathComponent("Playlist")
    }
    
    fileprivate static func uniqueDownloadPathForFilename(_ filename: String) throws -> URL {
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

private class PlaylistHLSDownloadManager: NSObject, AVAssetDownloadDelegate {
    private var activeDownloadTasks = [URLSessionTask: MediaDownloadTask]()
    private var pendingDownloadTasks = [URLSessionTask: URL]()
    
    weak var delegate: PlaylistStreamDownloadManagerDelegate?
    
    func restoreSession(_ session: AVAssetDownloadURLSession, completion: @escaping () -> Void) {
        session.getAllTasks { [weak self] tasks in
            guard let self = self else { return }
            
            for task in tasks {
                // TODO: Investigate progress calculation of AVAggregateAssetDownloadTask
                guard let downloadTask = task as? AVAssetDownloadTask,
                      let pageSrc = task.taskDescription else { break }
                
                if let item = PlaylistItem.getItem(pageSrc: pageSrc) {
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

        // TODO: In the future switch back to AVAggregateAssetDownloadTask after investigating progress calculation
//        guard let task =
//                session.aggregateAssetDownloadTask(with: asset,
//                                                  mediaSelections: [asset.preferredMediaSelection],
//                                                  assetTitle: item.name,
//                                                  assetArtworkData: nil,
//                                                  options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]) else { return }
        
        guard let task =
                session.makeAssetDownloadTask(asset: asset,
                                              assetTitle: item.name,
                                              assetArtworkData: nil,
                                              options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]) else { return }

        task.taskDescription = item.pageSrc
        activeDownloadTasks[task] = MediaDownloadTask(id: item.pageSrc, name: item.name, asset: asset)
        task.resume()

        delegate?.onDownloadStateChanged(id: item.pageSrc, state: .inProgress, displayName: asset.displayNames(for: asset.preferredMediaSelection), error: nil)
    }
    
    func cancelDownload(item: PlaylistInfo) {
        if let task = activeDownloadTasks.first(where: { $0.value.id == item.pageSrc })?.key {
            task.cancel()
            activeDownloadTasks.removeValue(forKey: task)
            pendingDownloadTasks.removeValue(forKey: task)
        }
    }
    
    func downloadTask(for pageSrc: String) -> MediaDownloadTask? {
        activeDownloadTasks.first(where: { $0.value.id == pageSrc })?.value
    }
    
    // MARK: - AVAssetDownloadTask
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        pendingDownloadTasks[assetDownloadTask] = location
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        
        self.urlSession(session, downloadTask: assetDownloadTask, didLoad: timeRange, totalTimeRangesLoaded: loadedTimeRanges, timeRangeExpectedToLoad: timeRangeExpectedToLoad)
    }
    
    // MARK: - AVAggregateAssetDownloadTask
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
        
        pendingDownloadTasks[aggregateAssetDownloadTask] = location
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
        
        self.urlSession(session, downloadTask: aggregateAssetDownloadTask, didLoad: timeRange, totalTimeRangesLoaded: loadedTimeRanges, timeRangeExpectedToLoad: timeRangeExpectedToLoad)
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didCompleteFor mediaSelection: AVMediaSelection) {
        
        guard let asset = activeDownloadTasks[aggregateAssetDownloadTask] else { return }
        aggregateAssetDownloadTask.taskDescription = asset.id
        aggregateAssetDownloadTask.resume()
        
        DispatchQueue.main.async {
            self.delegate?.onDownloadStateChanged(id: asset.id, state: .inProgress, displayName: mediaSelection.asset?.displayNames(for: mediaSelection) ?? "", error: nil)
        }
    }
    
    // MARK: - AVAssetDownloadDelegate - Commonly shared code with AVAggregateAssetDownloadTask and AVAssetDownloadTask
    
    private func urlSession(_ session: URLSession, downloadTask: URLSessionTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        guard let asset = activeDownloadTasks[downloadTask] else { return }

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
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Guard against other possible rogue tasks that aren't AVAsset download tasks
        if !(task is AVAssetDownloadTask || task is AVAggregateAssetDownloadTask) {
            return
        }
        
        guard let asset = activeDownloadTasks.removeValue(forKey: task),
              let assetUrl = pendingDownloadTasks.removeValue(forKey: task) else { return }

        if let error = error as NSError? {
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                guard let cacheLocation = delegate?.localAsset(for: asset.id)?.url else { return }

                do {
                    try FileManager.default.removeItem(at: cacheLocation)
                    PlaylistItem.updateCache(pageSrc: asset.id, cachedData: nil)
                } catch {
                    log.error("Could not delete asset cache \(asset.name): \(error)")
                }

            case (NSURLErrorDomain, NSURLErrorUnknown):
                assertionFailure("Downloading HLS streams is not supported on the simulator.")

            default:
                assertionFailure("An unknown error occured while attempting to download the playlist item: \(error)")
            }
            
            DispatchQueue.main.async {
                self.delegate?.onDownloadStateChanged(id: asset.id, state: .invalid, displayName: "", error: error)
            }
        } else {
            do {
                let cachedData = try assetUrl.bookmarkData()
                DispatchQueue.main.async {
                    PlaylistItem.updateCache(pageSrc: asset.id, cachedData: cachedData)
                    self.delegate?.onDownloadStateChanged(id: asset.id, state: .downloaded, displayName: "", error: nil)
                }
            } catch {
                log.error("Failed to create bookmarkData for download URL.")
                
                DispatchQueue.main.async {
                    self.delegate?.onDownloadStateChanged(id: asset.id, state: .downloaded, displayName: "", error: error)
                }
                
                do {
                    try FileManager.default.removeItem(at: assetUrl)
                } catch {
                    log.error("Error Deleting Playlist Item: \(error)")
                }
            }
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
                
                if let item = PlaylistItem.getItem(pageSrc: pageSrc),
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
            request.addValue(UserAgent.shouldUseDesktopMode ? UserAgent.desktop : UserAgent.mobile, forHTTPHeaderField: "User-Agent")
            return request
        }()
        
        let task = session.downloadTask(with: request)
        
        task.taskDescription = item.pageSrc
        activeDownloadTasks[task] = MediaDownloadTask(id: item.pageSrc, name: item.name, asset: asset)
        task.resume()
        
        delegate?.onDownloadStateChanged(id: item.pageSrc, state: .inProgress, displayName: asset.displayNames(for: asset.preferredMediaSelection), error: nil)
    }
    
    func cancelDownload(item: PlaylistInfo) {
        if let task = activeDownloadTasks.first(where: { item.pageSrc == $0.value.id })?.key {
            task.cancel()
            activeDownloadTasks.removeValue(forKey: task)
        }
    }
    
    func downloadTask(for pageSrc: String) -> MediaDownloadTask? {
        return activeDownloadTasks.first(where: { $0.value.id == pageSrc })?.value
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
                    PlaylistItem.updateCache(pageSrc: asset.id, cachedData: nil)
                } catch {
                    log.error("Could not delete asset cache \(asset.name): \(error)")
                }

            case (NSURLErrorDomain, NSURLErrorUnknown):
                assertionFailure("Downloading HLS streams is not supported on the simulator.")

            default:
                assertionFailure("An unknown error occurred while attempting to download the playlist item: \(error.domain)")
            }
            
            DispatchQueue.main.async {
                self.delegate?.onDownloadStateChanged(id: asset.id, state: .invalid, displayName: "", error: error)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let asset = activeDownloadTasks[downloadTask] else { return }
        
        if totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown || totalBytesExpectedToWrite == 0 {
            DispatchQueue.main.async {
                self.delegate?.onDownloadProgressUpdate(id: asset.id, percentComplete: 0.0)
            }
        } else {
            let percentage = (Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) * 100.0
            
            DispatchQueue.main.async {
                self.delegate?.onDownloadProgressUpdate(id: asset.id, percentComplete: percentage)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let asset = activeDownloadTasks.removeValue(forKey: downloadTask) else { return }
        
        if let response = downloadTask.response as? HTTPURLResponse, response.statusCode == 302 || response.statusCode >= 200 && response.statusCode <= 299 {
            
            var detectedFileExtension: String?
            
            // Detect based on File Extension.
            if let url = downloadTask.originalRequest?.url,
               let detectedExtension = PlaylistMimeTypeDetector(url: url).fileExtension {
                detectedFileExtension = detectedExtension
            }
            
            // Detect based on Content-Type header.
            if detectedFileExtension == nil,
               let contentType = response.allHeaderFields["Content-Type"] as? String,
               let detectedExtension = PlaylistMimeTypeDetector(mimeType: contentType).fileExtension {
                detectedFileExtension = detectedExtension
            }
            
            // Detect based on Data.
            if detectedFileExtension == nil {
                do {
                    let data = try Data(contentsOf: location, options: .mappedIfSafe)
                    if let detectedExtension = PlaylistMimeTypeDetector(data: data).fileExtension {
                        detectedFileExtension = detectedExtension
                    }
                } catch {
                    log.error("Error mapping downloaded playlist file to virtual memory: \(error)")
                }
            }
            
            // Couldn't determine file type so we assume mp4 which is the most widely used container.
            // If it doesn't work, the video/audio just won't play anyway.
            
            var fileExtension = "mp4"
            if let detectedFileExtension = detectedFileExtension {
                fileExtension = detectedFileExtension
            }
            
            do {
                let path = try PlaylistDownloadManager.uniqueDownloadPathForFilename(asset.name + ".\(fileExtension)")
                try FileManager.default.moveItem(at: location, to: path)
                do {
                    let cachedData = try path.bookmarkData()
                    
                    DispatchQueue.main.async {
                        PlaylistItem.updateCache(pageSrc: asset.id, cachedData: cachedData)
                        self.delegate?.onDownloadStateChanged(id: asset.id, state: .downloaded, displayName: "", error: nil)
                    }
                } catch {
                    log.error("Failed to create bookmarkData for download URL.")
                    
                    do {
                        try FileManager.default.removeItem(at: path)
                    } catch {
                        log.error("Error Deleting Playlist Item: \(error)")
                    }
                    
                    DispatchQueue.main.async {
                        self.delegate?.onDownloadStateChanged(id: asset.id, state: .downloaded, displayName: "", error: error)
                    }
                }
            } catch {
                log.error("An error occurred attempting to download a playlist item: \(error)")
                
                do {
                    try FileManager.default.removeItem(at: location)
                } catch {
                    log.error("Error Deleting Playlist Item: \(error)")
                }
                
                DispatchQueue.main.async {
                    PlaylistItem.updateCache(pageSrc: asset.id, cachedData: nil)
                    self.delegate?.onDownloadStateChanged(id: asset.id, state: .invalid, displayName: "", error: error)
                }
            }
        } else {
            DispatchQueue.main.async {
                PlaylistItem.updateCache(pageSrc: asset.id, cachedData: nil)
                
                if let response = downloadTask.response as? HTTPURLResponse {
                    self.delegate?.onDownloadStateChanged(id: asset.id, state: .invalid, displayName: "", error: "Invalid Status Code: \(response.statusCode)")
                } else if let response = downloadTask.response {
                    self.delegate?.onDownloadStateChanged(id: asset.id, state: .invalid, displayName: "", error: "Invalid Response: \(response)")
                } else {
                    self.delegate?.onDownloadStateChanged(id: asset.id, state: .invalid, displayName: "", error: "Unknown Error")
                }
            }
        }
    }
}
