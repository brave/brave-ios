// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import Combine

enum WebStoreResult: String {
  case none = ""
  case emptyString = "empty_string"
  case success = "success"
  case userGestureRequired = "user_gesture_required"
  case unknownError = "unknown_error"
  case featureDisabled = "feature_disabled"
  case unsupportedExtensionType = "unsupported_extension_type"
  case missingDependencies = "missing_dependencies"
  case installError = "install_error"
  case userCancelled = "user_cancelled"
  case invalidId = "invalid_id"
  case blacklisted = "blacklisted"
  case blockedByPolicy = "blocked_by_policy"
  case installInProgress = "install_in_progress"
  case launchInProgress = "launch_in_progress"
  case manifestError = "manifest_error"
  case iconError = "icon_error"
  case invalidIconUrl = "invalid_icon_url"
  case alreadyInstalled = "already_installed"
  case blockedForChildAccount = "blocked_for_child_account"
}

enum WebStoreWebGLStatus: String {
  case none = ""
  case allowed = "webgl_allowed"
  case blocked = "webgl_blocked"
}

enum WebStoreExtensionInstallStatus: String {
  case none = ""
  case canRequest = "can_request"
  case requestPending = "request_pending"
  case blockByPolicy = "blocked_by_policy"
  case installable = "installable"
  case enabled = "enabled"
  case disabled = "disabled"
  case terminated = "terminated"
  case blacklisted = "blacklisted"
  case custodianApprovalRequired = "custodian_approval_required"
  case forceInstalled = "force_installed"
}

enum WebStoreInstallError: String, Error {
  case alreadyInstalled = "This item is already installed"
  case invalidIconUrl = "Invalid icon url"
  case invalidId = "Invalid id"
  case invalidManifest = "Invalid manifest"
  case noPreviousBeginInstallWithManifest = "* does not match a previous call to beginInstallWithManifest3"
  case userCancelledError = "User cancelled install"
  case blockByPolicy = "Extension installation is blocked by policy"
  case incognitoError = "Apps cannot be installed in guest/incognito mode"
  case legacyPackagedApp = "Legacy packaged apps are no longer supported"
  case ephemeralAppLaunchingNotSupported = "Ephemeral launching of apps is no longer supported"
  
  static func from(_ result: WebStoreResult) -> WebStoreInstallError {
    switch result {
    case .alreadyInstalled: return .alreadyInstalled
    case .invalidIconUrl: return .invalidIconUrl
    case .invalidId: return .invalidId
    default: return .userCancelledError
    }
  }
}

class WebStorePrivateAPI {
  private let queue = DispatchQueue.init(label: "com.webstore.private-api.queue", qos: .userInitiated)
  
  func beginIntallWithManifest3(details: WebExtensionInfo) async -> (result: WebStoreResult, image: UIImage?, manifest: WebExtensionManifest?) {
    if !CRXFile.IDUtil.isValidId(id: details.id) {
      return (.invalidId, nil, nil)
    }

    guard let iconUrlString = details.iconUrl,
          let iconUrl = NSURL(idnString: iconUrlString) else {
      return (.invalidIconUrl, nil, nil)
    }
    
    if ExtensionRegistry.shared.isInstalled(extensionId: details.id) ||
        ExtensionInstallTracker.shared.isActivelyBeingInstalled(extensionId: details.id) {
      return (.alreadyInstalled, nil, nil)
    }
    
    let activeInstall = ExtensionInstallTracker.ActiveInstallData(id: details.id)
    let installHelper = WebStoreInstallHelper(extensionId: details.id, manifest: details.manifest, iconUrl: iconUrl as URL)
    
    do {
      let (icon, manifest) = try await installHelper.start()
      ExtensionRegistry.shared.add(info: details, manifest: manifest)
      return (.userGestureRequired, icon, manifest)
    } catch {
      guard let error = error as? WebStoreInstallHelper.InstallHelperResultCode else {
        return (.installError, nil, nil)
      }
      
      switch error {
      case .iconError: return (.iconError, nil, nil)
      case .manifestError: return (.manifestError, nil, nil)
      case .unknownError: return (.unknownError, nil, nil)
      }
    }
  }
}
