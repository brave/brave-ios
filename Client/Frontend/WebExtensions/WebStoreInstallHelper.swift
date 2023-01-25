// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit

protocol WebStoreInstallHelperDelegate {
  func onWebStoreParseSuccess(id: String, icon: UIImage, parsedManifest: WebExtensionManifest)
  func onWebStoreParseFailure(id: String, resultCode: WebStoreInstallHelper.InstallHelperResultCode, errorMessage: String)
}

class WebStoreInstallHelper {
  enum InstallHelperResultCode: Error {
    case unknownError
    case iconError
    case manifestError
  }
  
  init(extensionId: String, manifest: String, iconUrl: URL) {
    self.extensionId = extensionId
    self.manifest = manifest
    self.iconUrl = iconUrl
  }
  
  func start() async throws -> (icon: UIImage, manifest: WebExtensionManifest) {
    guard let data = self.manifest.data(using: .utf8) else {
      throw InstallHelperResultCode.manifestError
    }
    
    do {
      self.parsedManifest = try JSONDecoder().decode(WebExtensionManifest.self, from: data)
    } catch {
      throw InstallHelperResultCode.manifestError
    }
    
    do {
      let (data, _) = try await URLSession.shared.data(for: URLRequest(url: self.iconUrl))
      if let icon = await UIImage(data: data, scale: UIScreen.main.scale), let manifest = parsedManifest {
        return (icon, manifest)
      }
    } catch {
      print(error)
    }
    
    throw InstallHelperResultCode.iconError
  }
  
  private let extensionId: String
  private let manifest: String
  private let iconUrl: URL
  
  private var parsedManifest: WebExtensionManifest?
}
