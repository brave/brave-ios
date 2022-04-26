// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import BraveUI

/// A container to present when a webpage wants to present some request to the user such as adding a suggested
/// token, change networks, authorize a transaction, etc.
struct WebpageRequestContainerView<DismissContent: ToolbarContent>: View {
  var cryptoStore: CryptoStore
  var toolbarDismissContent: DismissContent
  
  var body: some View {
    UIKitNavigationView {
      Group {
        EmptyView()
      }
      .toolbar {
        toolbarDismissContent
      }
    }
    .onAppear {
      // TODO: Fetch pending requests
    }
  }
}
