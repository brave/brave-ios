// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SwiftUI
import Strings
import BraveStrings

class DisplayCertificateActivity: UIActivity, MenuActivity {
  var callback: () -> Void
  
  init(callback: @escaping () -> Void) {
    self.callback = callback
    super.init()
  }
  
  override func perform() {
    callback()
    activityDidFinish(true)
  }
  
  override var activityTitle: String? {
    Strings.displayCertificate
  }
  
  override var activityImage: UIImage? {
    UIImage(braveSystemNamed: "leo.lock.plain")?.applyingSymbolConfiguration(.init(scale: .large))
  }
  
  var menuImage: Image {
    Image(braveSystemName: "leo.lock.plain")
  }
  
  override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
    return true
  }
}
