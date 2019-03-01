// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import Deferred

private let log = Logger.browserLogger

enum FileType: String { case dat, json, tgz }

enum AdblockerType {
    case general
    case httpse
    case regional(locale: String)
    
    var locale: String? {
        switch self {
        case .regional(let locale): return locale
        default: return nil
        }}
    
    var associatedFiles: [FileType] {
        switch self {
        case .general, .regional: return [.json, .dat]
        case .httpse: return [.json, .tgz]
        }
    }
    
    var identifier: String {
        switch self {
        case .general: return BlocklistName.adFileName
        case .httpse: return BlocklistName.httpseFileName
        case .regional(let locale): return locale
        }
    }
    
    static func type(fromResource name: String) -> AdblockerType? {
        switch name {
        case AdblockResourcesMappings.generalAdblockName:
            return .general
        case AdblockResourcesMappings.generalHttpseName:
            return .httpse
        default: // Regional lists
            if let locale = AdblockResourcesMappings.resourceNameToLocale(name) {
                return .regional(locale: locale)
            }
            
            log.error("No locale was found for resource: \(name)")
            assertionFailure()
            return nil
        }
    }
}

private struct AdBlockNetworkResource {
    let resource: CachedNetworkResource
    let fileType: FileType
    let type: AdblockerType
}

class AdblockResourceDownloader {
    static let shared = AdblockResourceDownloader()
    
    private let networkManager: NetworkManager
    private let locale: String
    
    private let endpoint = "https://adblock-data.s3.brave.com/ios/"
    static let folderName = "abp-data"
    
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
        downloadDatJsonResources(withName: name, type: .regional(locale: locale),
                                 queueName: "Regional adblock setup").uponQueue(.main) {
            log.debug("Regional blocklists download and setup completed.")
        }
    }
    
    private func downloadDatJsonResources(withName name: String, type: AdblockerType,
                                          queueName: String) -> Deferred<()> {
        let completion = Deferred<()>()

        let queue = DispatchQueue(label: queueName)
        let nm = networkManager
        let folderName = AdblockResourceDownloader.folderName
        
        let completedDownloads = type.associatedFiles.map { fileType -> Deferred<AdBlockNetworkResource> in
            let fileExtension = "." + fileType.rawValue
            let etagExtension = fileExtension + ".etag"
            
            guard let url = URL(string: endpoint + name + fileExtension) else {
                return Deferred<AdBlockNetworkResource>()
            }
            
            let etag = fileFromDocumentsAsString(name + etagExtension, inFolder: folderName)
            let request = nm.downloadResource(with: url, resourceType: .cached(etag: etag))
                .mapQueue(queue) { resource in
                    AdBlockNetworkResource(resource: resource, fileType: fileType, type: type)
            }
            
            return request
        }
        
        all(completedDownloads).uponQueue(queue) { resources in
            // json to content rules compilation happens first, otherwise it makes no sense to proceed further
            // and overwrite old files that were working before.
            self.compileContentBlocker(resources: resources)
                .uponQueue(queue) { _ in self.writeFilesTodisk(resources: resources, name: name, queue: queue)
                    .uponQueue(queue) { _ in self.setUpFiles(resources: resources,
                                                             compileJsonRules: false, queue: queue)
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
        guard let jsonResource = resources.first(where: { $0.fileType == .json }),
            let contentBlocker = ContentBlockerRegion.with(localeCode: self.locale) else { return completion }
        completion = contentBlocker.compile(data: jsonResource.resource.data)
        return completion
    }
    
    private func writeFilesTodisk(resources: [AdBlockNetworkResource], name: String, queue: DispatchQueue) -> Deferred<()> {
        let completion = Deferred<()>()
        var fileSaveCompletions = [Deferred<()>]()
        let fm = FileManager.default
        let folderName = AdblockResourceDownloader.folderName
        
        resources.forEach {
            let fileName = name + ".\($0.fileType.rawValue)"
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
    
    private func setUpFiles(resources: [AdBlockNetworkResource], compileJsonRules: Bool, queue: DispatchQueue) -> Deferred<()> {
        let completion = Deferred<()>()
        var resourceSetup = [Deferred<()>]()
        
        resources.forEach {
            switch $0.fileType {
            case .dat:
                resourceSetup.append(AdBlockStats.shared.setDataFile(data: $0.resource.data,
                                                                     id: $0.type.identifier))
            case .json:
                if compileJsonRules {
                    resourceSetup.append(compileContentBlocker(resources: resources))
                }
            case .tgz:
                break // TODO: Add downloadable httpse list
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
