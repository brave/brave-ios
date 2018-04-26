/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Shields

private let _singleton = SafeBrowsing()

class SafeBrowsing {
    static let prefKey = "braveSafeBrowsing"
    static let prefKeyDefaultValue = true
    static let dataVersion = AdBlocker.dataVersion

    lazy var abpFilterLibWrapper: ABPFilterLibWrapper = { return ABPFilterLibWrapper() }()

    lazy var networkFileLoader: NetworkDataFileLoader = {
        let dataUrl = URL(string: "https://s3.amazonaws.com/adblock-data/\(TrackingProtection.dataVersion)/SafeBrowsingData.dat")!
        let dataFile = "safe-browsing-data-\(TrackingProtection.dataVersion).dat"
        let loader = NetworkDataFileLoader(url: dataUrl, file: dataFile, localDirName: "safe-browsing-data")
        loader.delegate = self
        return loader
    }()

    var blah = WeakList<SafeBrowsing>()
    var fifoCacheOfUrlsChecked = FifoDict()
    var isNSPrefEnabled = true

    fileprivate init() {
        NotificationCenter.default.addObserver(self, selector: #selector(SafeBrowsing.prefsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
        updateEnabledState()
    }

    class var singleton: SafeBrowsing {
        return _singleton
    }

    func updateEnabledState() {
//        isNSPrefEnabled = BraveApp.getPrefs()?.boolForKey(SafeBrowsing.prefKey) ?? SafeBrowsing.prefKeyDefaultValue
    }

    @objc func prefsChanged(_ info: Notification) {
        updateEnabledState()
    }

    func shouldBlock(_ request: URLRequest) -> Bool {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

//        if request.mainDocumentURL?.absoluteString.startsWith(WebServer.sharedInstance.base) ?? false ||
//            request.url?.absoluteString.startsWith(WebServer.sharedInstance.base) ?? false {
//            return false
//        }

        guard let url = request.url else { return false }

        let host: String = request.mainDocumentURL?.host ?? url.host ?? ""

        // A cache entry is like: fifoOfCachedUrlChunks[0]["www.microsoft.com_http://some.url"] = true/false for blocking
        let key = "\(host)_" + url.absoluteString

        if let checkedItem = fifoCacheOfUrlsChecked.getItem(key) {
            if checkedItem === NSNull() {
                return false
            } else {
                return checkedItem as! Bool
            }
        }

        let isBlocked = abpFilterLibWrapper.isBlockedIgnoringType(url.absoluteString, mainDocumentUrl: host)

        fifoCacheOfUrlsChecked.addItem(key, value: isBlocked as AnyObject)

        // #if LOG_AD_BLOCK
        if isBlocked {
            print("safe browsing blocked \(url.absoluteString)")
        }
        // #endif

        return isBlocked
    }
}

extension SafeBrowsing: NetworkDataFileLoaderDelegate {

    func fileLoader(_: NetworkDataFileLoader, setDataFile data: Data?) {
        abpFilterLibWrapper.setDataFile(data)
    }

    func fileLoaderHasDataFile(_: NetworkDataFileLoader) -> Bool {
        return abpFilterLibWrapper.hasDataFile()
    }

    func fileLoaderDelegateWillHandleInitialRead(_: NetworkDataFileLoader) -> Bool {
        return false
    }
}
