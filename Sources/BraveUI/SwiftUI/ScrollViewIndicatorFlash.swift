// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI

extension View {
  /// Flash the scrollView indicator when content height is bigger than the provided
  /// static height. This extension will be updated when iOS 17 is supported to backport
  /// the functionality to iOS 16 and below and using the iOS 17 API
  /// `scrollIndicatorsFlash`  directly for iOS 17
  public func scrollViewIndicatorFlash(staticContentHeight: CGFloat) -> some View {
    return self.introspectScrollView { scrollView in
      if scrollView.contentSize.height > staticContentHeight {
        scrollView.flashScrollIndicators()
      }
    }
  }
}
