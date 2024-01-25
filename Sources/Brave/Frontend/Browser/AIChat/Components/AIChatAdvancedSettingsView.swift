// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this

import SwiftUI
import BraveUI
import BraveCore
import Strings
import DesignSystem
import Preferences

struct AIChatAdvancedSettingsView: View {

  @Environment(\.presentationMode) @Binding private var presentationMode
  
  var isModallyPresented: Bool

  var body: some View {
    if isModallyPresented {
      NavigationView {
        settingsView
        .navigationTitle("Leo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItemGroup(placement: .cancellationAction) {
            Button("Close") {
              presentationMode.dismiss()
            }
          }
        }
      }
    } else {
      settingsView
        .navigationTitle("Settings")
    }
  }
  
  private var settingsView: some View {
    List {
      Section {
        OptionToggleView(
          title: "Show autocomplete suggestions in address bar",
          subtitle: nil,
          option: Preferences.LeoAI.autocompleteSuggestionsEnabled
        )
        
        NavigationLink {

        } label: {
          LabelView(
            title: "Default model for new conversations",
            subtitle: "Chat (Llama-2-13b)"
          )
        }.listRowBackground(Color(.secondaryBraveGroupedBackground))
      } header: {
        Text("Leo is an AI-powered smart assistant. built right into the browser")
          .textCase(nil)
      }
    }
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .listStyle(.insetGrouped)
  }
}
