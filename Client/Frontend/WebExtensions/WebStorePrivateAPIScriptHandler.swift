// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
import Foundation
import WebKit
import Data
import BraveShared
import Shared
import SwiftUI
import BraveUI

private struct Manifest: Codable {
  // Required
  let manifestVersion: Double
  let name: String
  let version: String
  let updateUrl: String

  // Recommended
  let action: Action?
  let defaultLocale: String?
  let description: String?
  let icons: Icons?

  // Optional
  let author: String?
  let automation: String?
  let background: Background?

  let permissions: [String]?

  struct Action: Codable {

  }

  struct Icons: Codable {

  }

  struct Background: Codable {
    // Required
    let serviceWorker: String?

    // Optional
    let type: String?
  }

  private enum CodingKeys: String, CodingKey {
    case manifestVersion = "manifest_version"
    case name
    case version
    case updateUrl = "update_url"

    case action
    case defaultLocale = "default_locale"
    case description
    case icons

    case author
    case automation
    case background
    case permissions
  }
}

class WebStorePrivateAPIScriptHandler: TabContentScript {
  private weak var tab: Tab?
  private let webStoreHandler = WebStorePrivateAPI()

  required init(tab: Tab) {
    self.tab = tab
  }

  static let scriptName = "WebStorePrivateAPI"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "\(scriptName)_\(messageUUID)"
  static let scriptSandbox: WKContentWorld = .page
  static let userScript: WKUserScript? = {
    guard var script = loadUserScript(named: scriptName) else {
      return nil
    }
    return WKUserScript.create(source: secureScript(handlerName: messageHandlerName,
                                                    securityToken: scriptId,
                                                    script: script),
                               injectionTime: .atDocumentStart,
                               forMainFrameOnly: true,
                               in: scriptSandbox)
  }()

  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
    if !verifyMessage(message: message) {
      assertionFailure("Missing required security token.")
      return
    }
    
    guard let message = message.body as? [String: AnyHashable] else {
      replyHandler(nil, "Invalid Message")
      return
    }
    
    guard let messageName = message["name"] as? String,
          let messageData = message["data"] as? [String: AnyHashable] else {
      replyHandler(nil, "Invalid Message")
      return
    }
    
    switch messageName {
    case "beginInstallWithManifest3": beginInstallWithManifest3(data: messageData, replyHandler: replyHandler)
    case "getExtensionStatus": replyHandler(ExtensionRegistry.shared.isInstalled(extensionId: messageData["extension_id"] as? String ?? "") ? "already_installed" : "installable", nil)
    default:
      assertionFailure("Unhandled WebStore Message: \(messageName)")
      replyHandler(nil, "Unhandled Message")
    }
  }
  
  private func beginInstallWithManifest3(data: [String: AnyHashable], replyHandler: @escaping (Any?, String?) -> Void) {
    Task { @MainActor in
      let json = try JSONSerialization.data(withJSONObject: data, options: [.fragmentsAllowed])
      let model = try JSONDecoder().decode(WebExtensionInfo.self, from: json)
      
      let (result, icon, manifest) = await webStoreHandler.beginIntallWithManifest3(details: model)
      if result == .userGestureRequired, let icon = icon, let manifest = manifest {
        let browserController = tab?.webView?.window?.windowScene?.browserViewController
        
        var installView = WebStoreInstallUI(title: model.localizedName,
                                            author: manifest.author?["name"] as? String ?? "N/A",
                                            iconURL: model.iconUrl ?? "",
                                            permissions: manifest.permissions ?? []
        )
        
        installView.onCancel = { [replyHandler] in
          replyHandler(nil, "user_cancelled")
          browserController?.dismiss(animated: true, completion: nil)
        }
        
        installView.onInstall = {
          replyHandler(nil, nil)
          browserController?.dismiss(animated: true, completion: nil)
        }
        
        let controller = PopupViewController(rootView: installView).then {
          $0.isModalInPresentation = true
          $0.modalPresentationStyle = .overFullScreen
        }
        
        browserController?.present(controller, animated: true)
      } else {
        replyHandler(nil, "Invalid Manifest")
      }
    }
  }
}
