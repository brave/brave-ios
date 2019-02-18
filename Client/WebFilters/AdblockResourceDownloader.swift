// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import Deferred

private let log = Logger.browserLogger

enum AdblockResourceType: String {
    case dat = "dat"
    case json = "json"
}

struct AdBlockNetworkResource {
    let data: Data
    let etag: String
    let type: AdblockResourceType
}

struct AdblockResourceManager {
    let endpoint: String
    let folderName: String
    
    // temporary
    // static let defaultEndpoint = "https://adblock-data.s3.brave.com/"
    private static let defaultEndpoint = "https://github.com/iccub/brave-blocklists-test/raw/master/ios/"
    private static let defaultFolderName = "abp-data"
    
    init(endpoint: String = defaultEndpoint, folderName: String = defaultFolderName) {
        self.endpoint = endpoint
        self.folderName = folderName
    }
}

class AdblockResourceDownloader {
    static let shared = AdblockResourceDownloader()
    
    let session: URLSession
    let locale: String
    
    private let endpoint = "https://github.com/iccub/brave-blocklists-test/raw/master/ios/"
    private let folderName = "abp-data"
    
    init(session: URLSession = URLSession.shared, locale: String? = Locale.current.languageCode,
          resourceManager: AdblockResourceManager = AdblockResourceManager()) {
        if locale == nil {
            log.warning("No locale provided, using default one(\"en\")")
        }
        self.locale = locale ?? "en"
        self.session = session
    }
    
    func regionalAdblockResourcesSetup() {
        if !Preferences.Shields.useRegionAdBlock.value {
            log.debug("Regional adblocking disabled, aborting attempt to download regional resources")
            return
        }
        
        downloadRegionalAdblockResources().uponQueue(.main) {
            log.debug("Regional blocklists download and setup completed.")
        }
    }
    
    func downloadRegionalAdblockResources() -> Deferred<()> {
        let completion = Deferred<()>()
        
        guard let name = ContentBlockerRegion.with(localeCode: locale)?.filename else { return completion }
        
        guard let datResourceUrl = URL(string: endpoint + name + ".dat") else {
            log.error("Could not parse url for getting an adblocker resource")
            return completion
        }
        
        guard let jsonResourceUrl = URL(string: endpoint + name + ".json") else {
            log.error("Could not parse url for getting an adblocker resource")
            return completion
        }
        
        let datRequest = networkRequest(url: datResourceUrl, type: .dat)
        let jsonRequest = networkRequest(url: jsonResourceUrl, type: .json)
        
        all([datRequest, jsonRequest]).upon { resources in
            var fileSaveCompletions = [Deferred<()>]()
            resources.forEach {
                fileSaveCompletions.append(self.writeToDisk($0.data, name: name, type: $0.type))
            }
            
            all(fileSaveCompletions).upon { _ in
                
                var resourceSetup = [Deferred<()>]()
                
                resources.forEach {
                    switch $0.type {
                    case .dat:
                        Preferences.Shields.regionalAdblockDatEtag.value = $0.etag
                        resourceSetup.append(AdBlockStats.shared.setDataFile(data: $0.data))
                    case .json:
                        Preferences.Shields.regionalAdblockJsonEtag.value = $0.etag
                        guard let contentBlocker = ContentBlockerRegion.with(localeCode: self.locale) else { return }
                        resourceSetup.append(contentBlocker.compile(data: $0.data))
                    }
                }
                
                all(resourceSetup).upon { _ in
                    completion.fill(())
                }
            }
        }
        
        return completion
    }
    
    private func networkRequest(url: URL, type: AdblockResourceType) -> Deferred<AdBlockNetworkResource> {
        var completion = Deferred<AdBlockNetworkResource>()
        
        var request = URLRequest(url: url)
        
        var etag: String?
        switch type {
        case .dat: etag = Preferences.Shields.regionalAdblockDatEtag.value
        case .json: etag = Preferences.Shields.regionalAdblockJsonEtag.value
        }
        
        guard let requestEtag = etag else { return completion }

        // This cache policy is required to support `If-None-Match` header.
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.addValue(requestEtag, forHTTPHeaderField: "If-None-Match")
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            if let err = error {
                log.error(err.localizedDescription)
                DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                    completion = self.networkRequest(url: url, type: type)
                }
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse else {
                return
            }
            
            switch response.statusCode {
            case 400...499:
                log.error("""
                    Failed to download, status code: \(response.statusCode),\
                    URL:\(String(describing: response.url))
                    """)
            case 304:
                log.info("File already exists")
            default:
                guard let responseEtag = response.allHeaderFields["Etag"] as? String else {
                    return
                }
                completion.fill(AdBlockNetworkResource(data: data, etag: responseEtag, type: type))
            }
        })
        task.resume()
        
        return completion
    }
    
    private func writeToDisk(_ data: Data, name: String, type: AdblockResourceType) -> Deferred<()> {
        let completion = Deferred<()>()
        let (dir, _) = createAndGetDataDirPath()
        
        let fileName = name + ".\(type.rawValue)"
        
        let path = dir + "/" + fileName
        if !((try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])) != nil) { // will overwrite
            log.error("Failed to write data to \(path)")
        }
        
        addSkipBackupAttributeToItemAtURL(URL(fileURLWithPath: dir, isDirectory: true))
        
        completion.fill(())
        return completion
        
        // delegate?.fileLoader(self, setDataFile: data)
    }
    
    func addSkipBackupAttributeToItemAtURL(_ url: URL) {
        do {
            try (url as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
        } catch {
            log.error("Error excluding \(url.lastPathComponent) from backup \(error)")
        }
    }
    
    func createAndGetDataDirPath() -> (String, Bool) {
        if let dir = NetworkDataFileLoader.directoryPath {
            let path = dir + "/" + folderName
            var wasCreated = false
            if !FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    log.error("NetworkDataFileLoader error: \(error)")
                }
                wasCreated = true
            }
            return (path, wasCreated)
        } else {
            log.error("Can't get documents dir.")
            return ("", false)
        }
    }
}
