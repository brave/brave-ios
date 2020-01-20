// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct NTPItemInfo: Codable {
    let logoImageUrl: String
    let logoAltText: String
    let logoDestinationUrl: URL
    let logoCompanyName: String
    let wallpaperImageUrls: [String]
}

class NTPDownloader {
    private static let BASE_URL = "https://brave-ntp-crx-input-dev.s3-us-west-2.amazonaws.com/"
    
    private let isZipped: Bool
    private let defaultLocale = "US"
    private let supportedLocales: [String] = []
    private let currentLocale = Locale.current.regionCode
    
    init(isZipped: Bool = false) {
        self.isZipped = isZipped
    }
    
    func update() {
        // Download the NTP Info to a temporary directory
        self.download { url, error in
            if let error = error {
                print(error)
                return
            }
            
            guard let url = url else {
                print(error)
                return
            }
            
            //Move contents of `url` directory
            //to somewhere more permanent where we'll load the images from..
            guard let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                return
            }
 
            do {
                let downloadsURL = supportDirectory.appendingPathComponent("NTPDownloads")
                if FileManager.default.fileExists(atPath: downloadsURL.absoluteString) {
                    try FileManager.default.removeItem(at: downloadsURL)
                }
                
                try FileManager.default.moveItem(at: url, to: downloadsURL)
            } catch {
                print(error)
            }
        }
    }
    
    func download(_ completion: @escaping (URL?, Error?) -> Void) {
        if self.isZipped {
            self.download(path: nil) { [weak self] data, error in
                guard let self = self else { return }
                
                if let error = error {
                    return completion(nil, error)
                }
                
                guard let data = data else {
                    return completion(nil, "Invalid Photos.json for NTP Download")
                }
                
                self.unzip(data: data) { url, error in
                    completion(url, error)
                }
            }
        } else {
            self.download(path: "photo.json") {[weak self] data, error in
                guard let self = self else { return }
                
                if let error = error {
                    return completion(nil, error)
                }
                
                guard let data = data else {
                    return completion(nil, "Invalid Photos.json for NTP Download")
                }
                
                do {
                    let item = try JSONDecoder().decode(NTPItemInfo.self, from: data)
                    self.unzip(item: item) { url, error in
                        completion(url, error)
                    }
                } catch {
                    completion(nil, error)
                }
            }
        }
    }
    
    private func getBaseURL() -> URL? {
        guard let url = URL(string: NTPDownloader.BASE_URL) else {
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
    
    // Downloads the item at the specified url relative to the BASE_URL
    private func download(path: String?, _ completion: @escaping (Data?, Error?) -> Void) {
        guard var url = self.getBaseURL() else {
            return completion(nil, nil)
        }
        
        if let path = path {
            url = url.appendingPathComponent(path)
        }
        
        let request = URLRequest(url: url)
        URLSession(configuration: .ephemeral).dataRequest(with: request) { data, response, error in
            if let error = error {
                return completion(nil, error)
            }
            
            guard let response = response as? HTTPURLResponse else {
                return completion(nil, error)
            }
            
            if response.statusCode < 200 || response.statusCode > 299 {
                return completion(nil, nil)
            }
            
            completion(data, nil)
        }
    }
    
    // Unzips Data to the temporary directory and returns a URL to the directory
    private func unzip(data: Data, _ completion: @escaping (URL?, Error?) -> Void) {
        let tempDirectory = FileManager.default.temporaryDirectory
        let directory = tempDirectory.appendingPathComponent("NTPDownloads")
        
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        
            let destination = directory.absoluteString.replacingOccurrences(of: "file://", with: "")
            try Unzip.unpack_archive(data: data, to: destination)
            completion(directory, nil)
        } catch {
            completion(nil, error)
        }
    }
    
    // Unzips NTPItemInfo by downloading all of its assets to a temporary directory
    // and returning the URL to the directory
    private func unzip(item: NTPItemInfo, _ completion: @escaping (URL?, Error?) -> Void) {
        let tempDirectory = FileManager.default.temporaryDirectory
        let directory = tempDirectory.appendingPathComponent("NTPDownloads")
        
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            
            var error: Error?
            let group = DispatchGroup()
            let urls = [item.logoImageUrl] + item.wallpaperImageUrls
            
            for itemURL in urls {
                group.enter()
                self.download(path: itemURL) { data, err in
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
                completion(error == nil ? directory : nil, error)
            }
        } catch {
            completion(nil, error)
        }
    }
}
