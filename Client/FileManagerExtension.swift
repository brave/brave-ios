// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import Deferred

private let log = Logger.browserLogger

public extension FileManager {
    public enum Folder: String {
        case cookie = "/Cookies"
        case webSiteData = "/WebKit/WebsiteData"
    }
    typealias FolderLockObj = (folder: Folder, lock: Bool)
    public func setFolderAccess(_ lockObjects: [FolderLockObj]) -> Bool {
        let baseDir = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        for lockObj in lockObjects {
            do {
                try self.setAttributes([.posixPermissions: (lockObj.lock ? NSNumber(value: 0 as Int16) : NSNumber(value: 0o755 as Int16))], ofItemAtPath: baseDir + lockObj.folder.rawValue)
            } catch let e {
                log.error("Failed to \(lockObj.lock ? "Lock" : "Unlock") item at path \(lockObj.folder.rawValue) with error: \n\(e)")
                return false
            }
        }
        return true
    }
    
    func getOrCreateDirectory(withName name: String) -> (path: String, created: Bool) {
        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            log.error("Can't get documents dir.")
            return ("", false)
        }
        
        let path = documentDirectory + "/" + name
        var wasCreated = false
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch {
                log.error("createDirectory error: \(error)")
            }
            wasCreated = true
        }
        return (path, wasCreated)
    }
    
    func writeToDiskInFolder(_ data: Data, fileName: String, folderName: String) -> Deferred<()> {
        let completion = Deferred<()>()
        let (dir, _) = FileManager.default.getOrCreateDirectory(withName: folderName)
        
        let path = dir + "/" + fileName
        if !((try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])) != nil) { // will overwrite
            log.error("Failed to write data to \(path)")
        }
        
        addSkipBackupAttributeToItemAtURL(URL(fileURLWithPath: dir, isDirectory: true))
        
        completion.fill(())
        return completion
    }
    
    func addSkipBackupAttributeToItemAtURL(_ url: URL) {
        do {
            try (url as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
        } catch {
            log.error("Error excluding \(url.lastPathComponent) from backup \(error)")
        }
    }
}
