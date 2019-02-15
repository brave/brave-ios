/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import BraveShared

private let log = Logger.browserLogger

class AdBlockStats {
    static let shared = AdBlockStats()
    
    typealias LocaleCode = String
    
    class AdblockNetworkDataFileLoader: NetworkDataFileLoader {
        var lang = AdBlockStats.defaultLocale
    }
    
    static let dataVersion = 4
    
    static let dataVersionPrefKey = "dataVersionPrefKey"
    static let defaultLocale = "en"
    
    let adBlockDataFolderName = "abp-data"
    let adBlockRegionFilePath = Bundle.main.path(forResource: "adblock-regions", ofType: "txt")
    let adBlockDataUrlPath = "https://adblock-data.s3.brave.com/"
    
    private let blockListFileName = "ABPFilterParserData"
    
    fileprivate var fifoCacheOfUrlsChecked = FifoDict()
    fileprivate var regionToS3FileName = [LocaleCode: String]()
    
    fileprivate var regionalNetworkLoaders = [LocaleCode: AdblockNetworkDataFileLoader]()
    fileprivate lazy var abpFilterLibWrappers: [LocaleCode: ABPFilterLibWrapper] = {
        return [AdBlockStats.defaultLocale: ABPFilterLibWrapper()]
    }()
    
    let currentLocaleCode: LocaleCode
    
    fileprivate var isRegionalAdblockEnabled: Bool { return Preferences.Shields.useRegionAdBlock.value }
    
    fileprivate init() {
        currentLocaleCode = Locale.current.languageCode ?? AdBlockStats.defaultLocale
        updateRegionalAdblockEnabledState()
        
        setDataVersionPreference()
        parseAdblockRegionsFile()
        
        Preferences.Shields.useRegionAdBlock.observe(from: self)
    }
    
    private func parseAdblockRegionsFile() {
        guard let filePath = adBlockRegionFilePath,
            let regional = try? String(contentsOfFile: filePath, encoding: String.Encoding.utf8) else {
                log.error("Could not find adblock regions file")
                return
        }
        
        regional.components(separatedBy: "\n").forEach {
            let parts = $0.components(separatedBy: ",")
            guard let filename = parts.last, parts.count > 1 else {
                return
            }
            
            for locale in parts {
                if regionToS3FileName[locale] != nil { log.info("Duplicate regions not handled yet \(locale)") }
                
                if locale.count > 2 {
                    log.info("Only 2 letter locale codes are handled.")
                    let firstTwoLocaleCharacters = String(locale.prefix(2))
                    regionToS3FileName[firstTwoLocaleCharacters] = filename
                } else {
                    regionToS3FileName[locale] = filename
                }
            }
        }
    }
    
    /// We want to avoid situations in which user still has downloaded old abp data version.
    /// We remove all abp data after data version is updated, then the newest data is downloaded.
    private func setDataVersionPreference() {
        
        guard let dataVersioPref = Preferences.Shields.adblockStatsDataVersion.value, dataVersioPref == AdBlockStats.dataVersion else {
            cleanDatFiles()
            Preferences.Shields.adblockStatsDataVersion.value = AdBlockStats.dataVersion
            return
        }
    }
    
    private func cleanDatFiles() {
        guard let dir = NetworkDataFileLoader.directoryPath else { return }
        
        let fm = FileManager.default
        do {
            let folderPath = dir + "/\(adBlockDataFolderName)"
            let paths = try fm.contentsOfDirectory(atPath: folderPath)
            for path in paths {
                try fm.removeItem(atPath: "\(folderPath)/\(path)")
            }
        } catch {
            log.error(error.localizedDescription)
        }
    }
    
    fileprivate func getNetworkLoader(forLocale locale: LocaleCode, name: String) -> AdblockNetworkDataFileLoader {
        let dataUrl = URL(string: "\(adBlockDataUrlPath)\(AdBlockStats.dataVersion)/\(name).dat")!
        let dataFile = "abp-data-\(AdBlockStats.dataVersion)-\(locale).dat"
        let loader = AdblockNetworkDataFileLoader(url: dataUrl, file: dataFile, localDirName: adBlockDataFolderName)
        loader.lang = locale
        loader.delegate = self
        return loader
    }
    
    func startLoading() {
        // General adblock file is prepackaged. Regional files are downloaded from server.
        let generalAdblockFile = getNetworkLoader(forLocale: AdBlockStats.defaultLocale, name: blockListFileName)
        generalAdblockFile.loadLocalData(blockListFileName, type: "dat")

        loadRegionalResources()
    }
    
    private func loadRegionalResources() {
        if Preferences.Shields.useRegionAdBlock.value {
            regionalNetworkLoaders.forEach { $0.value.loadData() }
        }
    }
    
    fileprivate func updateRegionalAdblockEnabledState() {
        if currentLocaleCode == AdBlockStats.defaultLocale { return }
        
        guard let file = regionToS3FileName[currentLocaleCode] else {
            log.warning("No custom adblock file for \(self.currentLocaleCode)")
            return
        }
        
        regionalNetworkLoaders[currentLocaleCode] = getNetworkLoader(forLocale: currentLocaleCode, name: file)
        abpFilterLibWrappers[currentLocaleCode] = ABPFilterLibWrapper()
    }
    
    func shouldBlock(_ request: URLRequest) -> Bool {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        guard let url = request.url else {
            return false
        }
        
        var currentTabUrl: URL?
        
        DispatchQueue.main.async {
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
            currentTabUrl = delegate.browserViewController.tabManager.selectedTab?.url
        }
        
        // Do not block main frame urls
        // e.g. user clicked on an ad intentionally (adblock could block redirect to requested site)
        if url == currentTabUrl { return false }
        
        let mainDocDomain = stripLocalhostWebServer(request.mainDocumentURL?.host ?? "")
        
        // A cache entry is like: fifoOfCachedUrlChunks[0]["www.microsoft.com_http://some.url"] = true/false for blocking
        let key = "\(mainDocDomain)_" + stripLocalhostWebServer(url.absoluteString)
        
        if let checkedItem = fifoCacheOfUrlsChecked.getItem(key) {
            if checkedItem === NSNull() {
                return false
            } else {
                if let checkedItem = checkedItem as? Bool {
                    return checkedItem
                } else {
                    log.error("Can't cast checkedItem to Bool")
                    return false
                }
            }
        }
        
        var isBlocked = false
        let header = "*/*"
        
        for (locale, adblocker) in abpFilterLibWrappers {
            if locale != AdBlockStats.defaultLocale && !isRegionalAdblockEnabled { continue }
            
            isBlocked = adblocker.isBlockedConsideringType(url.absoluteString,
                                                           mainDocumentUrl: mainDocDomain,
                                                           acceptHTTPHeader: header)
          
            if isBlocked {
                break
            }
        }
        fifoCacheOfUrlsChecked.addItem(key, value: isBlocked as AnyObject)
        
        return isBlocked
    }
    
    // Firefox has uses urls of the form  http://localhost:6571/errors/error.html?url=http%3A//news.google.ca/ to populate the browser history, and load+redirect using GCDWebServer
    func stripLocalhostWebServer(_ url: String?) -> String {
        guard let url = url else { return "" }
    
        // I think the ones prefixed with the following are the only ones of concern. There is also about/sessionrestore urls, not sure if we need to look at those
        let token = "?url="
        
        if let range = url.range(of: token) {
            return url[range.upperBound..<url.endIndex].removingPercentEncoding ?? ""
        } else {
            return url
        }
    }
}

extension AdBlockStats: NetworkDataFileLoaderDelegate {
    
    func fileLoader(_ loader: NetworkDataFileLoader, setDataFile data: Data?) {
        guard let loader = loader as? AdblockNetworkDataFileLoader, let adblocker = abpFilterLibWrappers[loader.lang] else {
            assertionFailure()
            return
        }
        adblocker.setDataFile(data)
    }
    
    func fileLoaderHasDataFile(_ loader: NetworkDataFileLoader) -> Bool {
        guard let loader = loader as? AdblockNetworkDataFileLoader, let adblocker = abpFilterLibWrappers[loader.lang] else {
            assertionFailure()
            return false
        }
        return adblocker.hasDataFile()
    }
    
    func fileLoaderDelegateWillHandleInitialRead(_ loader: NetworkDataFileLoader) -> Bool {
        return false
    }
}
extension AdBlockStats: PreferencesObserver {
    func preferencesDidChange(for key: String) {
        if key == Preferences.Shields.useRegionAdBlock.key {
            loadRegionalResources()
        }
    }
}
