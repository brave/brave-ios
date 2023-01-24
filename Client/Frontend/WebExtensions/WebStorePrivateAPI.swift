// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
import Foundation
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

class WebStorePrivateAPI {
  func beginIntallWithManifest3(details: WebExtensionDetails) async -> WebStoreResult {
    if !CRXFile.IDUtil.isValidId(id: details.id) {
      return .invalidId
    }

    if NSURL(idnString: details.iconUrl) == nil {
      return .invalidIconUrl
    }
    
    if ExtensionRegistry.shared.isInstalled(extensionId: details.id) ||
        ExtensionInstallTracker.shared.isActivelyBeingInstalled(extensionId: details.id) {
      return .alreadyInstalled
    }
    
    return .userGestureRequired
  }
}
