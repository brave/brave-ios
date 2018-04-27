/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class AdblockNetworkDataFileLoader: NetworkDataFileLoader {
    var lang = "en"
}

typealias localeCode = String

public class AdBlocker {
    public static let singleton = AdBlocker()

    static let prefKey = "braveBlockAdsAndTracking"
    static let prefKeyDefaultValue = true
    static let prefKeyUseRegional = "braveAdblockUseRegional"
    static let prefKeyUseRegionalDefaultValue = true
    static let dataVersion = "3"

    var isNSPrefEnabled = true
    fileprivate var fifoCacheOfUrlsChecked = FifoDict()
    fileprivate var regionToS3FileName = [localeCode: String]()
    fileprivate var networkLoaders = [localeCode: AdblockNetworkDataFileLoader]()
    fileprivate lazy var abpFilterLibWrappers: [localeCode: ABPFilterLibWrapper] = { return ["en": ABPFilterLibWrapper()] }()
    var currentLocaleCode: localeCode = "en" {
        didSet {
            updateRegionalAdblockEnabledState()
        }
    }
    fileprivate var isRegionalAdblockEnabled: Bool? = nil
    // From https://github.com/brave/browser-android-tabs/blob/master/chrome/android/java/src/org/chromium/chrome/browser/init/ChromeBrowserInitializer.java#L84
    fileprivate let wellTestedAdblockRegions = ["ru", "uk", "be", "hi", "sv"]

    fileprivate init() {
        NotificationCenter.default.addObserver(self, selector: #selector(AdBlocker.prefsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)

        updateEnabledState()

        networkLoaders["en"] = getNetworkLoader(forLocale: "en", name: "ABPFilterParserData")

        let regional = try! NSString(contentsOfFile: Bundle.main.path(forResource: "adblock-regions", ofType: "txt")!, encoding: String.Encoding.utf8.rawValue) as String
        regional.components(separatedBy: "\n").forEach {
            let parts = String($0).components(separatedBy: ",")
            guard let filename = parts.last, parts.count > 1 else {
                return
            }

            for i in 0..<parts.count-1 {
                var twoLetterLocale = parts[i]
                if let _ = regionToS3FileName[twoLetterLocale] {
                    print("Duplicate regions not handled yet \(twoLetterLocale)")
                }
                if twoLetterLocale.characters.count > 2 {
                    print("Only 2 letter locale codes are handled.")
                    twoLetterLocale = (twoLetterLocale as NSString).substring(to: 2)
                }
                regionToS3FileName[twoLetterLocale] = filename // looks like: "cs": "7CCB6921-7FDA"
            }

        }

        defer { // so that didSet is called from init
            let lang = Locale.preferredLanguages[0] as NSString
            self.currentLocaleCode = lang.substring(to: 2)
        }
    }

    fileprivate func getNetworkLoader(forLocale locale: localeCode, name: String) -> AdblockNetworkDataFileLoader {
        let dataUrl = URL(string: "https://s3.amazonaws.com/adblock-data/\(AdBlocker.dataVersion)/\(name).dat")!
        let dataFile = "abp-data-\(AdBlocker.dataVersion)-\(locale).dat"
        let loader = AdblockNetworkDataFileLoader(url: dataUrl, file: dataFile, localDirName: "abp-data")
        loader.lang = locale
        loader.delegate = self
        return loader
    }

    public func startLoading() {
        networkLoaders.forEach { $0.1.loadData() }
    }

    func isRegionalAdblockPossible() -> (hasRegionalFile: Bool, isDefaultSettingOn: Bool) {
        return (hasRegionalFile: currentLocaleCode != "en" && regionToS3FileName[currentLocaleCode] != nil,
                isDefaultSettingOn: isRegionalAdblockEnabled ?? false)
   }

    func updateEnabledState() {
        isNSPrefEnabled = BraveApp.getPrefs()?.boolForKey(AdBlocker.prefKey) ?? AdBlocker.prefKeyDefaultValue
    }

    fileprivate func updateRegionalAdblockEnabledState() {
        isRegionalAdblockEnabled = BraveApp.getPrefs()?.boolForKey(AdBlocker.prefKeyUseRegional)
        if isRegionalAdblockEnabled == nil && wellTestedAdblockRegions.contains(currentLocaleCode) {
            // in this case it is only enabled by default for well tested regions (leave set to nil otherwise)
            isRegionalAdblockEnabled = true
        }

        if currentLocaleCode != "en" && (isRegionalAdblockEnabled ?? false) {
            if let file = regionToS3FileName[currentLocaleCode] {
                if networkLoaders[currentLocaleCode] == nil {
                    networkLoaders[currentLocaleCode] = getNetworkLoader(forLocale: currentLocaleCode, name: file)
                    abpFilterLibWrappers[currentLocaleCode] = ABPFilterLibWrapper()

                }
            } else {
                NSLog("No custom adblock file for \(currentLocaleCode)")
            }
        }
    }

    @objc func prefsChanged(_ info: Notification) {
        updateEnabledState()

        updateRegionalAdblockEnabledState()
        networkLoaders.forEach {
            $0.1.loadData()
        }
    }

    // We can add whitelisting logic here for puzzling adblock problems
    fileprivate func isWhitelistedUrl(_ url: String?, forMainDocDomain domain: String) -> Bool {
        guard let url = url else { return false }
        // https://github.com/brave/browser-ios/issues/89
        if domain.contains("yahoo") && url.contains("s.yimg.com/zz/combo") {
            return true
        }

        // issue 385
        if domain.contains("m.jpost.com") {
            return true
        }

        return false
    }

    func setForbesCookie() {
        let cookieName = "forbes bypass"
        let storage = HTTPCookieStorage.shared
        let existing = storage.cookies(for: URL(string: "http://www.forbes.com")!)
        if let existing = existing {
            for c in existing {
                if c.name == cookieName {
                    return
                }
            }
        }

        var dict: [HTTPCookiePropertyKey:Any] = [:]
        dict[HTTPCookiePropertyKey.path] = "/"
        dict[HTTPCookiePropertyKey.name] = cookieName
        dict[HTTPCookiePropertyKey.value] = "forbes_ab=true; welcomeAd=true; adblock_session=Off; dailyWelcomeCookie=true"
        dict[HTTPCookiePropertyKey.domain] = "www.forbes.com"

        let components: DateComponents = DateComponents()
        (components as NSDateComponents).setValue(1, forComponent: NSCalendar.Unit.month);
        dict[HTTPCookiePropertyKey.expires] = (Calendar.current as NSCalendar).date(byAdding: components, to: Date(), options: NSCalendar.Options(rawValue: 0))

        let newCookie = HTTPCookie(properties: dict)
        if let c = newCookie {
            storage.setCookie(c)
        }
    }

    class RedirectLoopGuard {
        let timeWindow: TimeInterval // seconds
        let maxRedirects: Int
        var startTime = Date()
        var redirects = 0

        init(timeWindow: TimeInterval, maxRedirects: Int) {
            self.timeWindow = timeWindow
            self.maxRedirects = maxRedirects
        }

        func isLooping() -> Bool {
            return redirects > maxRedirects
        }

        func increment() {
            let time = Date()
            if time.timeIntervalSince(startTime) > timeWindow {
                startTime = time
                redirects = 0
            }
            redirects += 1
        }
    }

    // In the valid case, 4-5x we see 'forbes/welcome' page in succession (URLProtocol can call more than once for an URL, this is well documented)
    // Set the window as 10x in 10sec, after that stop forwarding the page.
    var forbesRedirectGuard = RedirectLoopGuard(timeWindow: 10.0, maxRedirects: 10)

    public func shouldBlock(_ request: URLRequest) -> Bool {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard let url = request.url else {
            return false
        }

        if url.host?.contains("forbes.com") ?? false {
            setForbesCookie()

            if url.absoluteString.contains("/forbes/welcome") {
                forbesRedirectGuard.increment()
                if !forbesRedirectGuard.isLooping() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        /* For some reason, even with the cookie set, I can't get past the welcome page, until I manually load a page on forbes. So if a do a google search for a subpage on forbes, I can click on that and get to forbes, and from that point on, I no longer see the welcome page. This hack seems to work perfectly for duplicating that behaviour. */
//                        BraveApp.getCurrentWebView()?.loadRequest(URLRequest(url: URL(string: "http://www.forbes.com")!))
                    }
                }
            }
        }


//        if let main = request.mainDocumentURL?.absoluteString, (main.startsWith(WebServer.sharedInstance.base)) {
//            if !main.contains("testing/") { // don't skip for localhost testing
//                return false
//            }
//        }

        var mainDocDomain = request.mainDocumentURL?.host ?? ""
        mainDocDomain = stripLocalhostWebServer(mainDocDomain)

        if isWhitelistedUrl(url.absoluteString, forMainDocDomain: mainDocDomain) {
            return false
        }

        // A cache entry is like: fifoOfCachedUrlChunks[0]["www.microsoft.com_http://some.url"] = true/false for blocking
        let key = "\(mainDocDomain)_" + stripLocalhostWebServer(url.absoluteString)

        if let checkedItem = fifoCacheOfUrlsChecked.getItem(key) {
            if checkedItem === NSNull() {
                return false
            } else {
                return checkedItem as! Bool
            }
        }

        var isBlocked = false
        var blockedByLocale = ""
        for (locale, adblocker) in abpFilterLibWrappers {
            isBlocked = adblocker.isBlockedConsideringType(url.absoluteString,
                                                           mainDocumentUrl: mainDocDomain,
                                                           acceptHTTPHeader:request.value(forHTTPHeaderField: "Accept"))

            if isBlocked {
                blockedByLocale = locale
                if locale != "en" && AppConstants.IsRunningTest {
//                    messageUITest(identifier: "blocked-url", message:"\(blockedByLocale) \(url.absoluteString)")
                }
                break
            }
        }
        fifoCacheOfUrlsChecked.addItem(key, value: isBlocked as AnyObject)


        #if LOG_AD_BLOCK
            if isBlocked {
                print("blocked \(url.absoluteString)")
            }
        #endif

        return isBlocked
    }
}

extension AdBlocker: NetworkDataFileLoaderDelegate {

    func fileLoader(_ loader: NetworkDataFileLoader, setDataFile data: Data?) {
        guard let loader = loader as? AdblockNetworkDataFileLoader, let adblocker = abpFilterLibWrappers[loader.lang] else {
            assert(false)
            return
        }
        adblocker.setDataFile(data)
    }

    func fileLoaderHasDataFile(_ loader: NetworkDataFileLoader) -> Bool {
        guard let loader = loader as? AdblockNetworkDataFileLoader, let adblocker = abpFilterLibWrappers[loader.lang] else {
            assert(false)
            return false
        }
        return adblocker.hasDataFile()
    }

    func fileLoaderDelegateWillHandleInitialRead(_ loader: NetworkDataFileLoader) -> Bool {
        return false
    }
}
