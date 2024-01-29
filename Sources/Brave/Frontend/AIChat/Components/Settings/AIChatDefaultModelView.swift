// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import BraveCore

struct AIChatDefaultModelView: View {
  
  var body: some View {
    modelView
      .navigationTitle("Default Model")
  }
  
  private var modelView: some View {
    List {
      Section {
        Text("Test")
      } header: {
        Text("CHAT")
      }
    }
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .listStyle(.insetGrouped)
  }
  
}
