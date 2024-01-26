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
  
  @ObservedObject var subscriptionManager = AIChatSubscriptionManager.shared

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
          option: Preferences.LeoAI.autocompleteSuggestionsEnabled
        )
        
        NavigationLink {
          // TODO: Add default model selection
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
      
      Section {
        if subscriptionManager.state == .purchased {
          LabelDetailView(title: "Status",
                          detail: subscriptionManager.activeType.title)
          LabelDetailView(title: "Expired", detail: "11/31/23")
          
          Button(action: {
            // TODO: Add Link subscription process
          }) {
            LabelView(
              title: "Link purchase to your Brave account",
              subtitle: "Link your Appstore purchase to your Brave account to use Leo on other devices."
            )
          }
        }
        
        Button(action: {
          switch subscriptionManager.state {
          case .purchased:
            print("Manage Subscription Action")
          case .notPurchased, .expired:
            print("Show Premium Buyout")
          }
        }) {
          HStack {
            LabelView(title: subscriptionManager.state.actionTitle)
            Spacer()
            Image(braveSystemName: "leo.launch")
              .foregroundStyle(Color(braveSystemName: .iconDefault))
          }
        }
        Button(action: {
        }) {
          Text("Reset And Clear Leo Data")
            .foregroundColor(Color(.braveBlurpleTint))
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
      } header: {
        Text("SUBSCRIPTION")
      }
    }
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .listStyle(.insetGrouped)
  }
}
