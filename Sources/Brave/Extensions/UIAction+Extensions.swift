// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Strings

extension UIAction {
  static func makePasteAndGoAction(pasteCallback: @escaping (String) -> Void) -> UIAction {
    return UIAction(
      identifier: .pasteAndGo,
      handler: UIAction.deferredActionHandler { _ in
        if let pasteboardContents = UIPasteboard.general.string {
          pasteCallback(pasteboardContents)
        }
      }
    )
  }

  static func makePasteAction(pasteCallback: @escaping (String) -> Void) -> UIAction {
    return UIAction(
      identifier: .paste,
      handler: UIAction.deferredActionHandler { _ in
        if let pasteboardContents = UIPasteboard.general.string {
          pasteCallback(pasteboardContents)
        }
      }
    )
  }
  
  static func makeCopyAction(for url: URL) -> UIAction {
    return UIAction(
      title: Strings.copyLinkActionTitle,
      image: UIImage(systemName: "doc.on.doc"),
      handler: UIAction.deferredActionHandler { _ in
        UIPasteboard.general.url = url as URL
      }
    )
  }
  
  static func makeCleanCopyAction(for url: URL, isPrivateMode: Bool) -> UIAction {
    return UIAction(
      title: Strings.copyCleanLink,
      image: UIImage(systemName: "doc.on.doc"),
      handler: UIAction.deferredActionHandler { _ in
        let cleanedURL = CleanURLService.shared.cleanup(url: url, isPrivateMode: isPrivateMode)
        UIPasteboard.general.url = cleanedURL
      }
    )
  }
}
