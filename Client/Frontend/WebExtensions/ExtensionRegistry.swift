// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

class ExtensionRegistry {
  static let shared = ExtensionRegistry()
  private var installedExtensions = [String: WebExtensionInstallInfo]()

  func isInstalled(extensionId: String) -> Bool {
    // TODO: Check if Private-Browsing allows the extension, etc..
    return installedExtensions[extensionId] != nil
  }
  
  func add(info: WebExtensionInfo, manifest: WebExtensionManifest) {
    installedExtensions[info.id] = WebExtensionInstallInfo(info: info, manifest: manifest)
  }
  
  func removeExtension(id: String) {
    installedExtensions.removeValue(forKey: id)
  }
  
  func getExtension(id: String, kind: IncludeFlag) -> WebExtensionInstallInfo? {
    return installedExtensions[id]
  }
  
  func getAll(kind: IncludeFlag) -> [WebExtensionInstallInfo] {
    return installedExtensions.values.map { $0 }
  }
  
  struct IncludeFlag: OptionSet {
    let rawValue: Int
    
    static let none = IncludeFlag([])
    static let enabled = IncludeFlag(rawValue: 1 << 0)
    static let disabled = IncludeFlag(rawValue: 1 << 1)
    static let terminated = IncludeFlag(rawValue: 1 << 2)
    static let blocklisted = IncludeFlag(rawValue: 1 << 3)
    static let blocked = IncludeFlag(rawValue: 1 << 4)
    
    static let all: IncludeFlag = IncludeFlag(rawValue: (1 << 5) - 1)
  }
}

class ExtensionInstallTracker {
  static let shared = ExtensionInstallTracker()
  private let activeInstalls = [String: ActiveInstallData]()

  func isActivelyBeingInstalled(extensionId: String) -> Bool {
    return activeInstalls[extensionId] != nil
  }
  
  struct ActiveInstallData {
    let id: String
  }
}
