// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this

import SwiftUI
import DesignSystem

struct AIChatAdvancedSettingsView: View {

  @Environment(\.presentationMode) @Binding private var presentationMode

  var body: some View {
    NavigationView {
      VStack {
        Text("Advanced Settings")
          .tint(Color(braveSystemName: .textInteractive))
          .font(.subheadline)
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .cancellationAction) {
          Button("Close") {
            presentationMode.dismiss()
          }
        }
      }
    }
  }
}
