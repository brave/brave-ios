// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public extension FileManager {
    public enum Folder: String {
        case cookie = "/Cookies"
        case webkit = "/WebKit"
        case cache = "/Caches"
    }
    typealias FolderLockObj = (folder: Folder, lock: Bool)
    public func lockFolders(_ lockObjects: [FolderLockObj]) {
        let baseDir = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        for lockObj in lockObjects {
            do {
                try self.setAttributes([FileAttributeKey.posixPermissions: (lockObj.lock ? NSNumber(value: 0 as Int16) : NSNumber(value: 0o755 as Int16))], ofItemAtPath: baseDir + lockObj.folder.rawValue)
            } catch {
                print(error)
            }
        }
    }
}
