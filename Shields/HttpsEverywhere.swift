/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import SQLite
import Shared

private let _singleton = HttpsEverywhere()
private let levelDbFileName = "httpse.leveldb"

class HttpsEverywhere {
    static let kNotificationDataLoaded = "kNotificationDataLoaded"
    static let prefKey = "braveHttpsEverywhere"
    static let prefKeyDefaultValue = true
    static let dataVersion = "5.2"
    var isNSPrefEnabled = true

    var httpseDb = HttpsEverywhereObjC()

    lazy var networkFileLoader: NetworkDataFileLoader = {
        let targetsDataUrl = URL(string: "https://s3.amazonaws.com/https-everywhere-data/\(dataVersion)/httpse.leveldb.tgz")!
        let dataFile = "httpse-\(dataVersion).leveldb.tgz"
        let loader = NetworkDataFileLoader(url: targetsDataUrl, file: dataFile, localDirName: "https-everywhere-data")
        loader.delegate = self
        self.runtimeDebugOnlyTestVerifyResourcesLoaded()
        return loader
    }()

    class var singleton: HttpsEverywhere {
        return _singleton
    }

    fileprivate init() {
        NotificationCenter.default.addObserver(self, selector: #selector(HttpsEverywhere.prefsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
        updateEnabledState()
    }


    func loadDb(dir:String, name:String) {
        let path = dir + "/" + name
        if !FileManager.default.fileExists(atPath: path) {
            return
        }

        httpseDb.load(path)
        if !httpseDb.isLoaded() {
            do { try FileManager.default.removeItem(atPath: path) }
            catch {}
        } else {
            NotificationCenter.default.post(name: Notification.Name(rawValue: HttpsEverywhere.kNotificationDataLoaded), object: self)
            print("httpse loaded")
        }
        assert(httpseDb.isLoaded())
    }

    func updateEnabledState() {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

//        isNSPrefEnabled = BraveApp.getPrefs()?.boolForKey(HttpsEverywhere.prefKey) ?? true
    }

    @objc func prefsChanged(_ info: Notification) {
        updateEnabledState()
    }


    func tryRedirectingUrl(_ url: URL) -> URL? {
        if url.scheme?.startsWith("https") ?? false {
            return nil
        }

        let result = httpseDb.tryRedirectingUrl(url)
        if (result?.isEmpty)! {
            return nil
        } else {
            return URL(string: result!)
        }
    }
}

private func unzipFile(dir: String, data: Data) {
//    let unzip = (data as NSData).gunzipped()
//    let fm = FileManager.default
//
//    do {
//        try fm.createFilesAndDirectories(atPath: dir,
//                                               withTarData: unzip,
//                                               progress:  { _ in
//        })
//    }
//    catch {
//        #if DEBUG
//            BraveApp.showErrorAlert(title: " error", error: "\(error)")
//        #endif
//    }
}


extension HttpsEverywhere: NetworkDataFileLoaderDelegate {
    func unzipAndLoad(_ dir: String, data: Data) {
        httpseDb.close()
        succeed().upon() { _ in

            let fm = FileManager.default
            if fm.fileExists(atPath: dir + "/" + levelDbFileName) {
                do { try FileManager.default.removeItem(atPath: dir + "/" + levelDbFileName) }
                catch { NSLog("failed to remove leveldb file before unzip \(error)") }
            }

            unzipFile(dir: dir, data: data)
            DispatchQueue.main.async {
                self.loadDb(dir: dir, name: levelDbFileName)
            }
        }
    }
    func fileLoader(_ loader: NetworkDataFileLoader, setDataFile data: Data?) {
        guard let data = data else { return }
        let (dir, _) = loader.createAndGetDataDirPath()
        unzipAndLoad(dir, data: data)
    }

    func fileLoaderHasDataFile(_ loader: NetworkDataFileLoader) -> Bool {
        if !httpseDb.isLoaded() {
            let (dir, _) = loader.createAndGetDataDirPath()
            self.loadDb(dir: dir, name: levelDbFileName)
        }
        print("httpse doesn't need to d/l: \(httpseDb.isLoaded())")
        return httpseDb.isLoaded()
    }

    func fileLoaderDelegateWillHandleInitialRead(_ loader: NetworkDataFileLoader) -> Bool {
        return true
    }
}


// Build in test cases, swift compiler is mangling the test cases in HttpsEverywhereTests.swift and they are failing. The compiler is falsely casting  AnyObjects to XCUIElement, which then breaks the runtime tests, I don't have time to look at this further ATM.
extension HttpsEverywhere {
    fileprivate func runtimeDebugOnlyTestDomainsRedirected() {
        #if DEBUG
            let urls = ["thestar.com", "thestar.com/", "www.thestar.com", "apple.com", "xkcd.com"]
            for url in urls {
                guard let unwrappedURL = URL(string: "http://" + url), let _ = HttpsEverywhere.singleton.tryRedirectingUrl(unwrappedURL) else {
                    BraveApp.showErrorAlert(title: "Debug Error", error: "HTTPS-E validation failed on url: \(url)")
                    return
                }
            }

            // TODO: Should combine
            guard let unwrappedURL = URL(string: "http://www.googleadservices.com/pagead/aclk?sa=L&ai=CD0d/") else {
                BraveApp.showErrorAlert(title: "Debug Error", error: "HTTPS-E validation failed for url args")
                return
            }
            
            let url = HttpsEverywhere.singleton.tryRedirectingUrl(unwrappedURL)
            if url == nil || !(url!.absoluteString.hasSuffix("?sa=L&ai=CD0d/")) {
                BraveApp.showErrorAlert(title: "Debug Error", error: "HTTPS-E validation failed for url args")
            }
        #endif
    }

    fileprivate func runtimeDebugOnlyTestVerifyResourcesLoaded() {
        #if DEBUG
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                if !self.httpseDb.isLoaded() {
                    BraveApp.showErrorAlert(title: "Debug Error", error: "HTTPS-E didn't load")
                } else {
                    self.runtimeDebugOnlyTestDomainsRedirected()
                }
            }
        #endif
    }
}
