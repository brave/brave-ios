// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionToBraveViewController: UIViewController {
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
      
    // Get the item[s] for handling from the extension context
    for item in extensionContext?.inputItems as? [NSExtensionItem] ?? [] {
      for provider in item.attachments ?? [] {
        if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
          provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { text, _ in
            // TODO: Launch the browser with url text
          }
          
          break
        }
        
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
          provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { url, _ in
            // TODO: Launch the browser with url
          }
          
          break
        }
      }
    }
  }

  func done() {
    // Return any edited content to the host app
    // In this case empty
    extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
  }
}
