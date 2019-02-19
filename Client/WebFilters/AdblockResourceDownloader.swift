// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import Deferred

private let log = Logger.browserLogger

private enum AdblockResourceType: String { case dat, json }

private struct AdBlockNetworkResource {
    let data: Data
    let etag: String
    let type: AdblockResourceType
}

class AdblockResourceDownloader {
    static let shared = AdblockResourceDownloader()
    
    private let session: URLSession
    private let locale: String
    
    private let endpoint = "https://github.com/iccub/brave-blocklists-test/raw/master/ios/"
    private let folderName = "abp-data"
    
    init(session: URLSession = URLSession.shared, locale: String? = Locale.current.languageCode) {
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
    
    private func downloadRegionalAdblockResources() -> Deferred<()> {
        let completion = Deferred<()>()
        
        guard let name = ContentBlockerRegion.with(localeCode: locale)?.filename else { return completion }
        
        guard let datResourceUrl = URL(string: endpoint + name + ".dat") else {
            log.error("Could not parse url for getting an adblocker dat resource")
            return completion
        }
        
        guard let jsonResourceUrl = URL(string: endpoint + name + ".json") else {
            log.error("Could not parse url for getting an adblocker json resource")
            return completion
        }
        
        // Successful setup of regional blocking has 4 steps:
        // 1. Both .dat and .json files must be download
        // 2. Downloaded files needs to be saved to disk and eventually overwrite existing files
        // 3. Preferences storing etag values for these files is saved
        // 4. Proper configuration, .dat file needs to be added to adblock lib and .json has
        // to be compiled to content blocker rules.
        // Each step must be completed before next step is performed.
        
        // 1
        let datRequest = downloadResource(atUrl: datResourceUrl, type: .dat)
        let jsonRequest = downloadResource(atUrl: jsonResourceUrl, type: .json)
        
        
        all([datRequest, jsonRequest]).upon { resources in
            var fileSaveCompletions = [Deferred<()>]()
            let fm = FileManager.default
            
            resources.forEach { // 2
                let fileName = name + ".\($0.type.rawValue)"
                fileSaveCompletions.append(fm.writeToDiskInFolder($0.data, fileName: fileName,
                                                                  folderName: self.folderName))
            }
            
            all(fileSaveCompletions).upon { _ in
                
                var resourceSetup = [Deferred<()>]()
                
                resources.forEach { // 3, 4
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
    
    private func downloadResource(atUrl url: URL, type: AdblockResourceType, checkEtags: Bool = true) -> Deferred<AdBlockNetworkResource> {
        var completion = Deferred<AdBlockNetworkResource>()
        
        var request = URLRequest(url: url)
        
        // Makes the request conditional, returns 304 if Etag value did not change.
        let ifNoneMatchHeader = "If-None-Match"
        let fileNotModifiedStatusCode = 304
        
        // Identifier for a specific version of a resource for a HTTP request
        let etagHeader = "Etag"
        
        var etag: String?
        switch type {
        case .dat: etag = Preferences.Shields.regionalAdblockDatEtag.value
        case .json: etag = Preferences.Shields.regionalAdblockJsonEtag.value
        }
        
        if checkEtags {
            // No etag means this is first download of the resource, putting a random string to make sure
            // the resource will be downloaded.
            let requestEtag = etag ?? UUID().uuidString

            // This cache policy is required to support `If-None-Match` header.
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.addValue(requestEtag, forHTTPHeaderField: ifNoneMatchHeader)
        }
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            if let err = error {
                log.error(err.localizedDescription)
                DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                    completion = self.downloadResource(atUrl: url, type: type)
                }
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse else {
                log.error("Failed to unwrap http response or data")
                return
            }
            
            switch response.statusCode {
            case 400...499:
                log.error("""
                    Failed to download, status code: \(response.statusCode),\
                    URL:\(String(describing: response.url))
                    """)
            case fileNotModifiedStatusCode:
                log.info("File not modified")
            default:
                guard let responseEtag = response.allHeaderFields[etagHeader] as? String else {
                    log.error("Could not find Etag header in the response. Headers: \(response.allHeaderFields)")
                    return
                }
                completion.fill(AdBlockNetworkResource(data: data, etag: responseEtag, type: type))
            }
        })
        task.resume()
        
        return completion
    }
}
