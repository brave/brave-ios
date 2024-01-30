// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import BraveCore

struct AIChatDefaultModelView: View {
  
  @Environment(\.presentationMode) 
  private var presentationMode
  
  @StateObject 
  var aiModel: AIChatViewModel
  
  @State 
  private var isPresentingPaywallPremium: Bool = false

  let onModelChanged: (String) -> Void

  var body: some View {
    modelView
      .navigationTitle("Default Model")
  }
  
  private var modelView: some View {
    List {
      Section {
        ForEach(Array(aiModel.models.enumerated()), id: \.offset) { index, model in
          Button(action: {
            if model.access == .premium, aiModel.shouldShowPremiumPrompt {
              isPresentingPaywallPremium = true
            } else {
              onModelChanged(model.key)
              presentationMode.wrappedValue.dismiss()
            }
          }, label: {
            HStack(spacing: 0.0) {
              VStack {
                Text(model.displayName)
                  .font(.body)
                  .foregroundStyle(Color(braveSystemName: .textPrimary))
                  .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(model.displayMaker)
                  .font(.footnote)
                  .foregroundStyle(Color(braveSystemName: .textSecondary))
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
              
              // If the model is selected show check
              if model.key == aiModel.currentModel.key {
                Image(braveSystemName: "leo.check.normal")
                  .foregroundStyle(Color(braveSystemName: .textInteractive))
                  .padding(.horizontal, 4.0)
              } else {
                if model.access == .basicAndPremium {
                  Text("LIMITED")
                    .font(.caption2)
                    .foregroundStyle(Color(braveSystemName: .blue50))
                    .padding(.horizontal, 4.0)
                    .padding(.vertical, 2.0)
                    .background(
                      RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                        .strokeBorder(Color(braveSystemName: .blue50), lineWidth: 1.0)
                    )
                } else if model.access == .premium {
                  Image(braveSystemName: "leo.lock.plain")
                    .foregroundStyle(Color(braveSystemName: .iconDefault))
                    .padding(.horizontal, 4.0)
                }
              }
            }
          })
        }
      } header: {
        Text("CHAT")
      }
    }
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .listStyle(.insetGrouped)
    .background(Color.clear
      .sheet(isPresented: $isPresentingPaywallPremium) {
        AIChatPaywallView()
      })
  }
}
