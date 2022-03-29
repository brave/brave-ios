/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import os.log

public struct Log {}

// MARK: - Singleton Logger Instances
public extension Log {
  
  static let braveCore = Logger(subsystem: "com.brave.ios", category: "brave-core")

  static let main = Logger(subsystem: "com.brave.ios", category: "main")
  
  /// Logger used in legacy places, in code we inherited from Firefox, should not be used elsewhere.
  static let legacy = Logger(subsystem: "com.brave.ios", category: "legacy")
  
  static func removeLegacyLogs() {
    let fileManager = FileManager.default
    
    guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
      return
    }
    
    let logDir = cacheDir.appendingPathComponent("Logs")

    if !fileManager.fileExists(atPath: logDir.path) {
      return
    }

    do {
      try fileManager.removeItem(at: logDir)
    } catch {
      
      Log.main.error("\(error.localizedDescription, privacy: .public)")
    }
  }
}
