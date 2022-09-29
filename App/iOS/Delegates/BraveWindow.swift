// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit

let traitCollectionDidChangeNotification = NSNotification.Name("traitCollectionDidChange")

final class BraveWindow: UIWindow {
  private var userInterfaceStyle = UITraitCollection.current.userInterfaceStyle

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    let currentUserInterfaceStyle = UITraitCollection.current.userInterfaceStyle
    if currentUserInterfaceStyle != userInterfaceStyle {
      userInterfaceStyle = currentUserInterfaceStyle
      NotificationCenter.default.post(name: traitCollectionDidChangeNotification, object: self)
    }
  }
}
