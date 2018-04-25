/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Alamofire

protocol NetworkDataFileLoaderDelegate: class {
    func fileLoader(_: NetworkDataFileLoader, setDataFile data: Data?)
    func fileLoaderHasDataFile(_: NetworkDataFileLoader) -> Bool
    func fileLoaderDelegateWillHandleInitialRead(_: NetworkDataFileLoader) -> Bool
}

class NetworkDataFileLoader {
    let dataUrl: URL
    let dataFile: String
    let nameOfDataDir: String

    weak var delegate: NetworkDataFileLoaderDelegate?

    init(url: URL, file: String, localDirName: String) {
        dataUrl = url
        dataFile = file
        nameOfDataDir = localDirName
    }

    // return the dir and a bool if the dir was created
    func createAndGetDataDirPath() -> (String, Bool) {
        if let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first {
            let path = dir + "/" + nameOfDataDir
            var wasCreated = false
            if !FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    BraveApp.showErrorAlert(title: "NetworkDataFileLoader error", error: "dataDir(): \(error)")
                }
                wasCreated = true
            }
            return (path, wasCreated)
        } else {
            BraveApp.showErrorAlert(title: "NetworkDataFileLoader error", error: "Can't get documents dir.")
            return ("", false)
        }
    }

    func etagFileNameFromDataFile(_ dataFileName: String) -> String {
        return dataFileName + ".etag"
    }

    func readDataEtag() -> String? {
        let (dir, _) = createAndGetDataDirPath()
        let path = etagFileNameFromDataFile(dir + "/" + dataFile)
        if !FileManager.default.fileExists(atPath: path) {
            return nil
        }
        guard let data = FileManager.default.contents(atPath: path) else { return nil }
        return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String
    }

    fileprivate func finishWritingToDisk(_ data: Data, etag: String?) {
        let (dir, _) = createAndGetDataDirPath()
        let path = dir + "/" + dataFile
        if !((try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])) != nil) { // will overwrite
            BraveApp.showErrorAlert(title: "NetworkDataFileLoader error", error: "Failed to write data to \(path)")
        }

//        addSkipBackupAttributeToItemAtURL(URL(fileURLWithPath: dir, isDirectory: true))

        if let etagData = etag?.data(using: String.Encoding.utf8) {
            let etagPath = etagFileNameFromDataFile(path)
            if !((try? etagData.write(to: URL(fileURLWithPath: etagPath), options: [.atomic])) != nil) {
                BraveApp.showErrorAlert(title: "NetworkDataFileLoader error", error: "Failed to write data to \(etagPath)")
            }
        }

        delegate?.fileLoader(self, setDataFile: data)
    }

    fileprivate func networkRequest() {
        let session = URLSession.shared
        let task = session.dataTask(with: dataUrl, completionHandler: {
            (data, response, error) -> Void in
            if let err = error {
                print(err.localizedDescription)
                DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
                    // keep trying every minute until successful
                    self.networkRequest()
                }
            }
            else {
                if let data = data, let response = response as? HTTPURLResponse {
                    if 400...499 ~= response.statusCode { // error
                        print("Failed to download, error: \(response.statusCode), URL:\(response.url)")
                    } else {
                        let etag = response.allHeaderFields["Etag"] as? String
                        self.finishWritingToDisk(data, etag: etag)
                    }
                }
            }
        }) 
        task.resume()
    }

    func pathToExistingDataOnDisk() -> String? {
        let (dir, _) = createAndGetDataDirPath()
        let path = dir + "/" + dataFile
        return FileManager.default.fileExists(atPath: path) ? path : nil
    }

    fileprivate func checkForUpdatedFileAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { // a few seconds after startup, check to see if a new file is available
            Alamofire.request(self.dataUrl, method: .head, encoding: JSONEncoding.default).response { response in
                if let err = response.error {
                    print("\(err)")
                } else {
                    guard let etag = response.response?.allHeaderFields["Etag"] as? String else { return }
                    let etagOnDisk = self.readDataEtag()
                    if etagOnDisk != etag {
                        self.networkRequest()
                    }
                }
            }
        }
    }

    func loadData() {
        guard let delegate = delegate else { return }
        checkForUpdatedFileAfterDelay()

        if !delegate.fileLoaderHasDataFile(self) {
            networkRequest()
        } else if !delegate.fileLoaderDelegateWillHandleInitialRead(self) {
            func readData() -> Data? {
                guard let path = pathToExistingDataOnDisk() else { return nil }
                return FileManager.default.contents(atPath: path)
            }

            let data = readData()
            if data == nil {
                networkRequest()
            } else {
                delegate.fileLoader(self, setDataFile: data)
            }
        }
    }
}
