// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import BraveUI

extension TabTrayController {

  class TabSyncView: UIView {
    
    override init(frame: CGRect) {
      super.init(frame: frame)

      backgroundColor = .red
      accessibilityLabel = "Synced Tabs"
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }
  }
}
