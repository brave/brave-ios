/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import BraveShared
import Deferred

private let log = Logger.browserLogger

class AdBlockStats {
    static let shared = AdBlockStats()
    
    typealias LocaleCode = String
    
    static let dataVersion = 4
    
    static let dataVersionPrefKey = "dataVersionPrefKey"
    static let defaultLocale = "en"
    
    private let blockListFileName = "ABPFilterParserData"
    
    fileprivate var fifoCacheOfUrlsChecked = FifoDict()
    
    fileprivate lazy var abpFilterLibWrappers: [LocaleCode: ABPFilterLibWrapper] = {
        return [AdBlockStats.defaultLocale: ABPFilterLibWrapper()]
    }()
    
    let currentLocaleCode: LocaleCode
    
    fileprivate var isRegionalAdblockEnabled: Bool { return Preferences.Shields.useRegionAdBlock.value }
    
    fileprivate init() {
        currentLocaleCode = Locale.current.languageCode ?? AdBlockStats.defaultLocale
        setDataVersionPreference()
        updateRegionalAdblockEnabledState()
    }
    
    private func setDataVersionPreference() {
        
        guard let dataVersioPref = Preferences.Shields.adblockStatsDataVersion.value, dataVersioPref == AdBlockStats.dataVersion else {
            Preferences.Shields.adblockStatsDataVersion.value = AdBlockStats.dataVersion
            return
        }
    }
    
    func startLoading() {
        loadLocalData(blockListFileName, type: "dat")
    }
    
    func loadLocalData(_ name: String, type: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            log.error("Could not find local file with name: \(name) and type :\(type)")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            let data = try Data(contentsOf: url)
            setDataFile(data: data)
        } catch {
            log.error(error)
        }
    }
    
    fileprivate func updateRegionalAdblockEnabledState() {
        if currentLocaleCode == AdBlockStats.defaultLocale { return }
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
    
    @discardableResult func setDataFile(data: Data) -> Deferred<()> {
        let completion = Deferred<()>()
        let locale = Locale.current.languageCode!
        guard let adblocker = abpFilterLibWrappers[locale] else {
            assertionFailure()
            return completion
        }
        adblocker.setDataFile(data)
        
        if adblocker.hasDataFile() {
            completion.fill(())
        }
        return completion
    }
}
