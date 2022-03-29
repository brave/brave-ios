/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger

public struct Logger {}

// MARK: - Singleton Logger Instances
public extension Logger {

  /// Logger used for recording frontend/browser happenings
  static let browserLogger = RollingFileLogger(filenameRoot: "browser", logDirectoryPath: nil)

  /// Logger used for things recorded on BraveRewards framework.
  static let braveCoreLogger: RollingFileLogger = {
    let logger = RollingFileLogger(filenameRoot: "bravecore", logDirectoryPath: nil)
    logger.identifier = "BraveCore"
    logger.newLogWithDate(
      Date(),
      configureDestination: { destination in
        // Same as debug log, Rewards framework handles function names in message
        destination.showFunctionName = false
        destination.showThreadName = false
      })

    if !AppConstants.buildChannel.isPublic {
      // For rewards logs we want to show it only using the Apple System Log to make it visible
      // via console.app
      logger.destinations.removeAll(where: { ($0 is ConsoleDestination) })

      // Create a destination for the system console log (via NSLog)
      let systemDestination = AppleSystemLogDestination(identifier: "com.brave.ios.logs")

      systemDestination.outputLevel = .debug
      systemDestination.showLogIdentifier = true
      systemDestination.showLevel = true

      // Since we redirect from Rewards framework we don't have function
      // name's or thread names
      systemDestination.showFunctionName = false
      systemDestination.showThreadName = false

      logger.add(destination: systemDestination)
    }

    return logger
  }()
  
  /// Legacy logger, user browserLogger instead
  static let syncLogger = RollingFileLogger(filenameRoot: "sync", logDirectoryPath: nil)

  /// Legacy logger, user browserLogger instead
  static let keychainLogger = RollingFileLogger(filenameRoot: "corruptLogger", logDirectoryPath: nil)

  /// Legacy logger, user browserLogger instead
  static let corruptLogger: RollingFileLogger = {
    let logger = RollingFileLogger(filenameRoot: "corruptLogger", logDirectoryPath: nil)
    logger.newLogWithDate(Date())
    return logger
  }()
  
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
      browserLogger.error(error)
    }
  }
}
