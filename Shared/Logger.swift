/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger
import os.log

public struct LegacyLogger {}

// MARK: - Singleton Logger Instances
public extension LegacyLogger {

  /// Logger used for recording frontend/browser happenings
  static let browserLogger = Logger(subsystem: "com.brave.ios", category: "main")
  static let braveCoreLogger = Logger(subsystem: "com.brave.ios", category: "brave-core")
  
  /// Logger used in legacy places, in code we inherited from Firefox, should not be used elsewhere.
  static let legacyLogger = Logger(subsystem: "com.brave.ios", category: "legacy")
  
  static func removeExistingLogs() {
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
      
      browserLogger.error("\(error.localizedDescription, privacy: .public)")
    }
  }
}
