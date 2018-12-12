/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

private let log = Logger.browserLogger

class HttpsEverywhereStats {
    static let shared = HttpsEverywhereStats()
    
    static let kNotificationDataLoaded = "kNotificationDataLoaded"
    static let prefKey = "braveHttpsEverywhere"
    static let prefKeyDefaultValue = true
    static let dataVersion = "6.0"
    
    var isNSPrefEnabled = true
    
    static let levelDbFileName = "httpse.leveldb"
    
    /// If set to true, it uses local dat file instead of downloading it from the server.
    let useLocalLeveldbFile = true
    
    var httpseDb = HttpsEverywhereObjC()
    
    lazy var networkFileLoader: NetworkDataFileLoader = {
        let targetsDataUrl = URL(string: "https://s3.amazonaws.com/https-everywhere-data/\(HttpsEverywhereStats.dataVersion)/httpse.leveldb.tgz")!
        let dataFile = "httpse-\(HttpsEverywhereStats.dataVersion).leveldb.tgz"
        let loader = NetworkDataFileLoader(url: targetsDataUrl, file: dataFile, localDirName: "https-everywhere-data")
        loader.delegate = self
        return loader
    }()
    
    fileprivate init() { }
    
    func startLoading() {
        if useLocalLeveldbFile {
            HttpsEverywhereStats.shared.networkFileLoader.loadLocalData(HttpsEverywhereStats.levelDbFileName, type: "tgz")
        } else {
            HttpsEverywhereStats.shared.networkFileLoader.loadData()
        }
    }
    
    func shouldUpgrade(_ url: URL?) -> Bool {
        guard let url = url else {
            log.error("Httpse should block called with empty url")
            return false
        }
        
        return tryRedirectingUrl(url) != nil
    }
    
    func loadDb(dir: String, name: String) {
        let path = dir + "/" + name
        if !FileManager.default.fileExists(atPath: path) {
            return
        }
        
        httpseDb.load(path)
        if !httpseDb.isLoaded() {
            do { try FileManager.default.removeItem(atPath: path) } catch {}
        } else {
            NotificationCenter.default.post(name: Notification.Name(rawValue: HttpsEverywhereStats.kNotificationDataLoaded), object: self)
            log.debug("httpse loaded")
        }
        assert(httpseDb.isLoaded())
    }
    
    func tryRedirectingUrl(_ url: URL) -> URL? {
        
        if url.scheme?.starts(with: "https") == true {
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
    let unzip = (data as NSData).gunzipped()
    let fm = FileManager.default
    
    do {
        try fm.createFilesAndDirectories(atPath: dir,
                                         withTarData: unzip,
                                         progress: { _ in
        })
    } catch {
        #if DEBUG
        BraveApp.showErrorAlert(title: " error", error: "\(error)")
        #endif
    }
}

extension HttpsEverywhereStats: NetworkDataFileLoaderDelegate {
    func unzipAndLoad(_ dir: String, data: Data) {
        httpseDb.close()
        succeed().upon() { _ in
            
            let fm = FileManager.default
            if fm.fileExists(atPath: dir + "/" + HttpsEverywhereStats.levelDbFileName) {
                do {
                    try FileManager.default.removeItem(atPath: dir + "/" + HttpsEverywhereStats.levelDbFileName)
                } catch { NSLog("failed to remove leveldb file before unzip \(error)") }
            }
            
            unzipFile(dir: dir, data: data)
            
            DispatchQueue.main.async {
                self.loadDb(dir: dir, name: HttpsEverywhereStats.levelDbFileName)
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
            self.loadDb(dir: dir, name: HttpsEverywhereStats.levelDbFileName)
        }
        print("httpse doesn't need to d/l: \(httpseDb.isLoaded())")
        return httpseDb.isLoaded()
    }
    
    func fileLoaderDelegateWillHandleInitialRead(_ loader: NetworkDataFileLoader) -> Bool {
        return true
    }
}
