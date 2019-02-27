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
    let resource: CachedNetworkResource
    let type: AdblockResourceType
    let locale: String
}

class AdblockResourceDownloader {
    static let shared = AdblockResourceDownloader()
    
    private let networkManager: NetworkManager
    private let locale: String
    
    private let endpoint = "https://adblock-data.s3.brave.com/ios/"
    static let folderName = "abp-data"
    private let queue = DispatchQueue(label: "RegionalAdblockSetup")
    
    init(networkManager: NetworkManager = NetworkManager(), locale: String? = Locale.current.languageCode) {
        if locale == nil {
            log.warning("No locale provided, using default one(\"en\")")
        }
        self.locale = locale ?? "en"
        self.networkManager = networkManager
        
        Preferences.Shields.useRegionAdBlock.observe(from: self)
    }
    
    func regionalAdblockResourcesSetup() {
        if !Preferences.Shields.useRegionAdBlock.value {
            log.debug("Regional adblocking disabled, aborting attempt to download regional resources")
            return
        }
        
        guard let name = ContentBlockerRegion.with(localeCode: locale)?.filename else { return }
        downloadDatJsonResources(withName: name, locale: locale,
                                 queueName: "Regional adblock setup").uponQueue(.main) {
            log.debug("Regional blocklists download and setup completed.")
        }
    }
    
    private func downloadDatJsonResources(withName name: String, locale: String,
                                          queueName: String) -> Deferred<()> {
        let completion = Deferred<()>()
        
        guard let datResourceUrl = URL(string: endpoint + name + ".dat") else {
            log.error("Could not parse url for getting an adblocker dat resource")
            return completion
        }
        
        guard let jsonResourceUrl = URL(string: endpoint + name + ".json") else {
            log.error("Could not parse url for getting an adblocker json resource")
            return completion
        }
        
        let queue = DispatchQueue(label: queueName)
        let nm = networkManager
        
        let datEtag = fileFromDocumentsAsString(name + ".dat.etag", inFolder: folderName)
        let datRequest = nm.downloadResource(with: datResourceUrl, resourceType: .cached(etag: datEtag))
            .mapQueue(queue) { res in
                AdBlockNetworkResource(resource: res, type: .dat, locale: locale)
        }
        
        let jsonEtag = fileFromDocumentsAsString(name + ".json.etag", inFolder: folderName)
        let jsonRequest = nm.downloadResource(with: jsonResourceUrl, resourceType: .cached(etag: jsonEtag))
            .mapQueue(queue) { res in
                AdBlockNetworkResource(resource: res, type: .json, locale: locale)
        }
        
        let downloadResources = all([datRequest, jsonRequest])
        
        downloadResources.uponQueue(queue) { resources in
            // json to content rules compilation happens first, otherwise it makes no sense to proceed further
            // and overwrite old files that were working before.
            self.compileContentBlocker(resources: resources)
                .uponQueue(queue) { _ in self.writeFilesTodisk(resources: resources, name: name)
                    .uponQueue(queue) { _ in self.setUpFiles(resources: resources, compileJsonRules: false)
                        .uponQueue(queue) { completion.fill(()) }
                    }
            }
        }
        
        return completion
    }
    
    private func fileFromDocumentsAsString(_ name: String, inFolder folder: String) -> String? {
        guard let documentsDir = FileManager.documentsDirectory else {
            log.error("Failed to get documents directory")
            return nil
        }
        
        let dir = documentsDir + "/\(folder)/"
        guard let data = FileManager.default.contents(atPath: dir + name) else { return nil }
        
        return String(data: data, encoding: .utf8)
    }
    
    private func compileContentBlocker(resources: [AdBlockNetworkResource]) -> Deferred<()> {
        var completion = Deferred<()>()
        guard let jsonResource = resources.first(where: { $0.type == .json }),
            let contentBlocker = ContentBlockerRegion.with(localeCode: self.locale) else { return completion }
        completion = contentBlocker.compile(data: jsonResource.resource.data)
        return completion
    }
    
    private func writeFilesTodisk(resources: [AdBlockNetworkResource], name: String) -> Deferred<()> {
        let completion = Deferred<()>()
        var fileSaveCompletions = [Deferred<()>]()
        let fm = FileManager.default
        let folderName = AdblockResourceDownloader.folderName
        
        resources.forEach {
            let fileName = name + ".\($0.type.rawValue)"
            fileSaveCompletions.append(fm.writeToDiskInFolder($0.resource.data, fileName: fileName,
                                                              folderName: folderName))
            
            if let etag = $0.resource.etag, let data = etag.data(using: .utf8) {
                let etagFileName = fileName + ".etag"
                fileSaveCompletions.append(fm.writeToDiskInFolder(data, fileName: etagFileName,
                                                                  folderName: folderName))
            }
            
        }
        all(fileSaveCompletions).uponQueue(queue) { _ in completion.fill(()) }
        return completion
    }
    
    private func setUpFiles(resources: [AdBlockNetworkResource], compileJsonRules: Bool) -> Deferred<()> {
        let completion = Deferred<()>()
        var resourceSetup = [Deferred<()>]()
        
        resources.forEach {
            switch $0.type {
            case .dat:
                resourceSetup.append(AdBlockStats.shared.setDataFile(data: $0.resource.data, locale: $0.locale, type: .fromNetwork))
            case .json:
                if compileJsonRules {
                    resourceSetup.append(compileContentBlocker(resources: resources))
                }
            }
        }
        all(resourceSetup).uponQueue(queue) { _ in completion.fill(()) }
        return completion
    }
}

extension AdblockResourceDownloader: PreferencesObserver {
    func preferencesDidChange(for key: String) {
        let regionalAdblockPref = Preferences.Shields.useRegionAdBlock
        if key == regionalAdblockPref.key {
            regionalAdblockResourcesSetup()
        }
    }
}
