// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared

private let logger = Logger.browserLogger

struct NTPFocalPoint: Codable {
    let x: Int
    let y: Int
}

struct NTPLogo: Codable {
    let imageUrl: String
    let alt: String
    let companyName: String
    let destinationUrl: URL
}

struct NTPWallpaper: Codable {
    let imageUrl: String
    let focalPoint: NTPFocalPoint?
}

struct NTPItemInfo: Codable {
    let logo: NTPLogo
    let wallpapers: [NTPWallpaper]
}

class NTPDownloader {
    private static let etagFile = "crc.etag"
    private static let metadataFile = "photo.json"
    private static let ntpDownloadsFolder = "NTPDownloads"
    private static let baseURL = "https://brave-ntp-crx-input-dev.s3-us-west-2.amazonaws.com/"
    
    private let isZipped: Bool
    private let defaultLocale = "US"
    private let supportedLocales: [String] = []
    private let currentLocale = Locale.current.regionCode
    
    init(isZipped: Bool) {
        self.isZipped = isZipped
    }
    
    func getNTPInfo(_ completion: @escaping (NTPItemInfo?) -> Void) {
        // Download the NTP Info to a temporary directory
        self.downloadMetadata { [weak self] url, cacheInfo, error in
            guard let self = self else { return }
            
            if case .campaignEnded = error {
                do {
                    try self.removeCampaign()
                } catch {
                    logger.error(error)
                }
                
                return completion(nil)
            }
            
            if let error = error?.underlyingError() {
                logger.error(error)
                return completion(self.loadNTPInfo())
            }
            
            if let cacheInfo = cacheInfo, cacheInfo.statusCode == 304 {
                logger.debug("NTPDownloader Cache is still valid")
                return completion(self.loadNTPInfo())
            }
            
            guard let url = url else {
                logger.error("Invalid NTP Temporary Downloads URL")
                return completion(self.loadNTPInfo())
            }
            
            //Move contents of `url` directory
            //to somewhere more permanent where we'll load the images from..
 
            do {
                let downloadsFolderURL = try self.ntpDownloadsURL()
                if FileManager.default.fileExists(atPath: downloadsFolderURL.path) {
                    try FileManager.default.removeItem(at: downloadsFolderURL)
                }
                
                try FileManager.default.moveItem(at: url, to: downloadsFolderURL)
                
                //Store the ETag
                if let cacheInfo = cacheInfo {
                    self.setETag(cacheInfo.etag)
                }
                
                completion(self.loadNTPInfo())
            } catch {
                logger.error(error)
                completion(self.loadNTPInfo())
            }
        }
    }
    
    private func loadNTPInfo() -> NTPItemInfo? {
        
        do {
            let metadataFileURL = try self.ntpMetadataFileURL()
            if !FileManager.default.fileExists(atPath: metadataFileURL.path) {
                return nil
            }
            
            let metadata = try Data(contentsOf: metadataFileURL)
            if self.isCampaignEnded(data: metadata) {
                try self.removeCampaign()
                return nil
            }
            
            let downloadsFolderURL = try self.ntpDownloadsURL()
            let itemInfo = try JSONDecoder().decode(NTPItemInfo.self, from: metadata)
            
            let logo = NTPLogo(imageUrl: downloadsFolderURL.appendingPathComponent(itemInfo.logo.imageUrl).path,
                               alt: itemInfo.logo.alt,
                               companyName: itemInfo.logo.companyName,
                               destinationUrl: itemInfo.logo.destinationUrl)
            
            let wallpapers = itemInfo.wallpapers.map {
                NTPWallpaper(imageUrl: downloadsFolderURL.appendingPathComponent($0.imageUrl).path,
                             focalPoint: $0.focalPoint)
            }
            
            return NTPItemInfo(logo: logo, wallpapers: wallpapers)
        } catch {
            logger.error(error)
        }
        
        return nil
    }
    
    private func getETag() -> String? {
        do {
            let etagFileURL = try self.ntpETagFileURL()
            if !FileManager.default.fileExists(atPath: etagFileURL.path) {
                return nil
            }
            
            return try? String(contentsOfFile: etagFileURL.path, encoding: .utf8)
        } catch {
            logger.error(error)
            return nil
        }
    }
    
    private func setETag(_ etag: String) {
        do {
            let downloadsFolderURL = try self.ntpDownloadsURL()
            try FileManager.default.createDirectory(at: downloadsFolderURL, withIntermediateDirectories: true, attributes: nil)
            
            let etagFileURL = try self.ntpETagFileURL()
            let etag = etag.replacingOccurrences(of: "\"", with: "")
            try etag.write(to: etagFileURL, atomically: true, encoding: .utf8)
        } catch {
            logger.error(error)
        }
    }
    
    private func removeETag() throws {
        let etagFileURL = try self.ntpETagFileURL()
        if FileManager.default.fileExists(atPath: etagFileURL.path) {
            try FileManager.default.removeItem(at: etagFileURL)
        }
    }
    
    private func removeCampaign() throws {
        try self.removeETag()
        let downloadsFolderURL = try self.ntpDownloadsURL()
        if FileManager.default.fileExists(atPath: downloadsFolderURL.path) {
            try FileManager.default.removeItem(at: downloadsFolderURL)
        }
    }
    
    private func downloadMetadata(_ completion: @escaping (URL?, CacheResponse?, NTPError?) -> Void) {
        if self.isZipped {
            self.download(path: nil, etag: self.getETag()) { [weak self] data, cacheInfo, error in
                guard let self = self else { return }
                
                if let error = error {
                    return completion(nil, nil, .metadataError(error))
                }
                
                if let cacheInfo = cacheInfo, cacheInfo.statusCode == 304 {
                    return completion(nil, cacheInfo, nil)
                }
                
                guard let data = data else {
                    return completion(nil, nil, .metadataError("Invalid \(NTPDownloader.metadataFile) for NTP Download"))
                }
                
                self.unzip(data: data) { url, error in
                    completion(url, cacheInfo, error)
                }
            }
        } else {
            self.download(path: NTPDownloader.metadataFile, etag: self.getETag()) { [weak self] data, cacheInfo, error in
                guard let self = self else { return }
                
                if let error = error {
                    return completion(nil, nil, .metadataError(error))
                }
                
                if let cacheInfo = cacheInfo, cacheInfo.statusCode == 304 {
                    return completion(nil, cacheInfo, nil)
                }
                
                guard let data = data else {
                    return completion(nil, nil, .metadataError("Invalid \(NTPDownloader.metadataFile) for NTP Download"))
                }
                
                if self.isCampaignEnded(data: data) {
                    return completion(nil, nil, .campaignEnded)
                }
                
                do {
                    let item = try JSONDecoder().decode(NTPItemInfo.self, from: data)
                    self.unzip(item: item) { url, error in
                        completion(url, cacheInfo, error)
                    }
                } catch {
                    completion(nil, nil, .unzipError(error))
                }
            }
        }
    }
    
    private func getBaseURL() -> URL? {
        guard let url = URL(string: NTPDownloader.baseURL) else {
            return nil
        }
        
        if self.isZipped {
            return url.appendingPathComponent(getSupportedLocale())
                      .appendingPathExtension("zip")
        }
        
        return url.appendingPathComponent(getSupportedLocale())
    }
    
    private func getSupportedLocale() -> String {
        guard let region = Locale.current.regionCode else {
            return self.defaultLocale
        }
        
        if supportedLocales.contains(region) {
            return region
        }
        
        return self.defaultLocale
    }
    
    //MARK: - Download & Unzipping
    
    private func parseETagResponseInfo(_ response: HTTPURLResponse) -> CacheResponse {
        if let etag = response.allHeaderFields["Etag"] as? String {
            return CacheResponse(statusCode: response.statusCode, etag: etag)
        }
        
        if let etag = response.allHeaderFields["ETag"] as? String {
            return CacheResponse(statusCode: response.statusCode, etag: etag)
        }
        
        return CacheResponse(statusCode: response.statusCode, etag: "")
    }
    
    // Downloads the item at the specified url relative to the baseUrl
    private func download(path: String?, etag: String?, _ completion: @escaping (Data?, CacheResponse?, Error?) -> Void) {
        guard var url = self.getBaseURL() else {
            return completion(nil, nil, nil)
        }
        
        if let path = path {
            url = url.appendingPathComponent(path)
        }
        
        var request = URLRequest(url: url)
        if let etag = etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        
        URLSession(configuration: .ephemeral).dataRequest(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                return completion(nil, nil, error)
            }
            
            guard let response = response as? HTTPURLResponse else {
                return completion(nil, nil, "Response is not an HTTP Response")
            }
            
            if response.statusCode != 304 && (response.statusCode < 200 || response.statusCode > 299) {
                completion(nil, nil, "Invalid Response Status Code: \(response.statusCode)")
            }
            
            completion(data, self.parseETagResponseInfo(response), nil)
        }
    }
    
    // Unzips Data to the temporary directory and returns a URL to the directory
    private func unzip(data: Data, _ completion: @escaping (URL?, NTPError?) -> Void) {
        let tempDirectory = FileManager.default.temporaryDirectory
        let directory = tempDirectory.appendingPathComponent(NTPDownloader.ntpDownloadsFolder)
        
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            try Unzip.unpack_archive(data: data, to: directory.path)
            completion(directory, nil)
        } catch {
            completion(nil, .unzipError(error))
        }
    }
    
    // Unzips NTPItemInfo by downloading all of its assets to a temporary directory
    // and returning the URL to the directory
    private func unzip(item: NTPItemInfo, _ completion: @escaping (URL?, NTPError?) -> Void) {
        let tempDirectory = FileManager.default.temporaryDirectory
        let directory = tempDirectory.appendingPathComponent(NTPDownloader.ntpDownloadsFolder)
        
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)

            let metadataFileURL = directory.appendingPathComponent(NTPDownloader.metadataFile)
            try JSONEncoder().encode(item).write(to: metadataFileURL, options: .atomic)
            
            var error: Error?
            let group = DispatchGroup()
            let urls = [item.logo.imageUrl] + item.wallpapers.map { $0.imageUrl }
            
            for itemURL in urls {
                group.enter()
                self.download(path: itemURL, etag: nil) { data, _, err in
                    if let err = err {
                        error = err
                        return group.leave()
                    }
                    
                    guard let data = data else {
                        error = "No Data Available for NTP-Download: \(itemURL)"
                        return group.leave()
                    }
                    
                    do {
                        let file = directory.appendingPathComponent(itemURL)
                        try data.write(to: file, options: .atomicWrite)
                    } catch let err {
                        error = err
                    }
                    
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                if let error = error {
                    return completion(nil, .unzipError(error))
                }
                
                completion(directory, nil)
            }
        } catch {
            completion(nil, .unzipError(error))
        }
    }
    
    private func ntpETagFileURL() throws -> URL {
        return try self.ntpDownloadsURL().appendingPathComponent(NTPDownloader.etagFile)
    }
    
    private func ntpMetadataFileURL() throws -> URL {
        return try self.ntpDownloadsURL().appendingPathComponent(NTPDownloader.metadataFile)
    }
    
    private func ntpDownloadsURL() throws -> URL {
        guard let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw "NTPDownloader - Cannot find Support Directory"
        }
        
        return supportDirectory.appendingPathComponent(NTPDownloader.ntpDownloadsFolder)
    }
    
    private func isCampaignEnded(data: Data) -> Bool {
        return data.count <= 5 || String(data: data, encoding: .utf8) == "{\n}\n"
    }
    
    private struct CacheResponse {
        let statusCode: Int
        let etag: String
    }
    
    private enum NTPError: Error {
        case campaignEnded
        case metadataError(Error)
        case unzipError(Error)
        case loadingError(Error)
        
        func underlyingError() -> Error? {
            switch self {
            case .campaignEnded:
                return nil
                
            case .metadataError(let error),
                 .unzipError(let error),
                 .loadingError(let error):
                return error
            }
        }
    }
}
