/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Logger
import SwiftKeychainWrapper

public extension KeychainWrapper {
  static var sharedAppContainerKeychain: KeychainWrapper {
    let baseBundleIdentifier = AppInfo.baseBundleIdentifier
    let accessGroupPrefix = Bundle.main.infoDictionaryString(forKey: "MozDevelopmentTeam")
    let accessGroupIdentifier = AppInfo.keychainAccessGroupWithPrefix(accessGroupPrefix)
    return KeychainWrapper(serviceName: baseBundleIdentifier, accessGroup: accessGroupIdentifier)
  }
}

public extension KeychainWrapper {
  func ensureStringItemAccessibility(_ accessibility: SwiftKeychainWrapper.KeychainItemAccessibility, forKey key: String) {
    if self.hasValue(forKey: key) {
      if self.accessibilityOfKey(key) != .afterFirstUnlock {
        Log.legacy.debug("updating item \(key) with \(accessibility.hashValue)")

        guard let value = self.string(forKey: key) else {
          Log.legacy.error("failed to get item \(key)")
          return
        }

        if !self.removeObject(forKey: key) {
          Log.legacy.warning("failed to remove item \(key)")
        }

        if !self.set(value, forKey: key, withAccessibility: accessibility) {
          Log.legacy.warning("failed to update item \(key)")
        }
      }
    }
  }

  func ensureObjectItemAccessibility(_ accessibility: SwiftKeychainWrapper.KeychainItemAccessibility, forKey key: String) {
    if self.hasValue(forKey: key) {
      if self.accessibilityOfKey(key) != .afterFirstUnlock {
        Log.legacy.debug("updating item \(key) with \(accessibility.hashValue)")

        guard let value = self.object(forKey: key) else {
          Log.legacy.error("failed to get item \(key)")
          return
        }

        if !self.removeObject(forKey: key) {
          Log.legacy.warning("failed to remove item \(key)")
        }

        if !self.set(value, forKey: key, withAccessibility: accessibility) {
          Log.legacy.warning("failed to update item \(key)")
        }
      }
    }
  }
}
