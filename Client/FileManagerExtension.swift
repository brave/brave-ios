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
    
    //Lock a folder using FolderLockObj provided.
    @discardableResult public func setFolderAccess(_ lockObjects: [FolderLockObj]) -> Bool {
        let baseDir = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        for lockObj in lockObjects {
            do {
                try self.setAttributes([.posixPermissions: (lockObj.lock ? 0 : 0o755)], ofItemAtPath: baseDir + lockObj.folder.rawValue)
            } catch {
                log.error("Failed to \(lockObj.lock ? "Lock" : "Unlock") item at path \(lockObj.folder.rawValue) with error: \n\(error)")
                return false
            }
        }
        return true
    }
    
    // Check the locked status of a folder. Returns true for locked.
    public func checkLockedStatus(folder: Folder) -> Bool {
        let baseDir = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        do {
            if let lockValue = try self.attributesOfItem(atPath: baseDir + folder.rawValue)[.posixPermissions] as? NSNumber {
                return lockValue == 0o755
            }
        } catch {
            log.error("Failed to check lock status on item at path \(folder.rawValue) with error: \n\(error)")
        }
        return false
    }
    
    func getOrCreateDirectory(withName name: String) -> (path: String, created: Bool) {
        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            log.error("Can't get documents dir.")
            return ("", false)
        }
        
        let path = documentDirectory + "/" + name
        var wasCreated = false
        if !fileExists(atPath: path) {
            do {
                try createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch {
                log.error("createDirectory error: \(error)")
            }
            wasCreated = true
        }
        return (path, wasCreated)
    }
    
    func writeToDiskInFolder(_ data: Data, fileName: String, folderName: String) -> Deferred<()> {
        let completion = Deferred<()>()
        let (dir, _) = getOrCreateDirectory(withName: folderName)
        
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
    
    static var documentsDirectory: String? {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    }
}
