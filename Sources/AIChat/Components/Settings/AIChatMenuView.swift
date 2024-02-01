// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore

private struct AIChatMenuHeaderView: View {
  
  let icon: String
  let title: String
  
  var body: some View {
    HStack {
      Image(braveSystemName: icon)
        .foregroundStyle(Color(braveSystemName: .iconDefault))
        .padding(.leading, 16.0)
        .padding(.trailing, 8.0)
        .padding(.vertical, 8.0)
      
      Text(title)
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(Color(braveSystemName: .textTertiary))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private struct AIChatMenuItemView<RightAccessoryView: View>: View {
  
  let title: String
  let subtitle: String
  let isSelected: Bool
  let rightAccessoryView: RightAccessoryView
  
  init(title: String, subtitle: String, isSelected: Bool, @ViewBuilder _ rightAccessoryView: () -> RightAccessoryView) {
    self.title = title
    self.subtitle = subtitle
    self.isSelected = isSelected
    self.rightAccessoryView = rightAccessoryView()
  }
  
  var body: some View {
    HStack(spacing: 0.0) {
      Image(braveSystemName: "leo.check.normal")
        .foregroundStyle(Color(braveSystemName: .textInteractive))
        .padding(.leading, 16.0)
        .padding(.trailing, 8.0)
        .hidden(isHidden: !isSelected)
      
      VStack {
        Text(title)
          .font(.body)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
          .frame(maxWidth: .infinity, alignment: .leading)
        
        Text(subtitle)
          .font(.footnote)
          .foregroundStyle(Color(braveSystemName: .textSecondary))
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      
      rightAccessoryView
        .padding(.horizontal, 16.0)
        .padding(.vertical, 8.0)
    }
    .padding(.vertical)
  }
}

enum AIChatMenuOptionTypes {
  case newChat, premium, advancedSettings
  
  var title: String {
    switch self {
    case .newChat:
      return "New Chat"
    case .premium:
      return "Go Premium"
    case .advancedSettings:
      return "Advanced Settings"
    }
  }
  
  var imageName: String {
    switch self {
    case .newChat:
      return "leo.erase"
    case .premium:
      return "leo.lock.open"
    case .advancedSettings:
      return "leo.settings"
    }
  }
}

struct AIChatMenuView: View {
  let currentModel: AiChat.Model
  let modelOptions: [AiChat.Model]
  let onModelChanged: (String) -> Void
  let onOptionSelected: (AIChatMenuOptionTypes) -> Void
  
  @Environment(\.presentationMode)
  private var presentationMode
  
  @State 
  private var appStoreConnectionErrorPresented = false

  var body: some View {
    LazyVStack(spacing: 0.0) {
      Text("LANGUAGE MODELS")
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24.0)
        .padding(.vertical)
        .background(Color(braveSystemName: .pageBackground))
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      AIChatMenuHeaderView(icon: "leo.message.bubble-comments", title: "CHAT")
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      ForEach(Array(modelOptions.enumerated()), id: \.offset) { index, model in
        Button(action: {
          onModelChanged(model.key)
          presentationMode.wrappedValue.dismiss()
        }, label: {
          AIChatMenuItemView(title: model.displayName, subtitle: model.displayMaker, isSelected: model.key == currentModel.key) {
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
            } else {
              Image(braveSystemName: "leo.lock.plain")
                .foregroundStyle(Color(braveSystemName: .iconDefault))
                .hidden(isHidden: true)
            }
          }
        })
        
        if index != modelOptions.count - 1 {
            Color(braveSystemName: .dividerSubtle)
            .frame(height: 1.0)
        }
      }
      
      Color(braveSystemName: .dividerSubtle)
      .frame(height: 8.0)
      
      generateMenuActionItems(menuOption: .newChat)
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      generateMenuActionItems(menuOption: .premium)
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      generateMenuActionItems(menuOption: .advancedSettings)
    }
    .alert(isPresented: $appStoreConnectionErrorPresented) {
        Alert(title: Text("App Store Error"),
              message: Text("Could not connect to Appstore, please try again later."),
              dismissButton: .default(Text("OK")))
    }
  }
  
  func generateMenuActionItems(menuOption: AIChatMenuOptionTypes) -> some View {
    Button {
      if menuOption == .premium, !LeoProductInfo.shared.isComplete {
        appStoreConnectionErrorPresented = true
      } else {
        presentationMode.wrappedValue.dismiss()
        onOptionSelected(menuOption)
      }
    } label: {
      Text(menuOption.title)
        .font(.body)
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
      
      Image(braveSystemName: menuOption.imageName)
        .foregroundStyle(Color(braveSystemName: .iconDefault))
        .padding(.horizontal, 16.0)
        .padding(.vertical, 8.0)
    }
  }
}

#Preview {
  AIChatMenuView(currentModel:
      .init(key: "mixtral_8x7b", name: "Mixtral-8x7b", displayName: "Mixtral 8x7b",
            displayMaker: "Powerful, fast and adaptive", engineType: .llamaRemote,
            category: .chat, access: .basicAndPremium,
            maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000),
                 modelOptions: [
                  .init(key: "mixtral_8x7b", name: "Mixtral-8x7b", displayName: "Mixtral 8x7b",
                        displayMaker: "Powerful, fast and adaptive", engineType: .llamaRemote,
                        category: .chat, access: .basicAndPremium,
                        maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000),
                  .init(key: "claude_instant", name: "Claude-Instant", displayName: "Claude Instant",
                        displayMaker: "Strength in creative tasks", engineType: .llamaRemote,
                        category: .chat, access: .basicAndPremium,
                        maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000),
                  .init(key: "llaba_2x13b", name: "Llama-2x13b", displayName: "Llama2 13b",
                        displayMaker: "General purpose chat", engineType: .llamaRemote,
                        category: .chat, access: .basic,
                        maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000),
                  .init(key: "llaba_2x70b", name: "Llama-2x70b", displayName: "Llama2 70b",
                        displayMaker: "Advanced and accurate chat", engineType: .llamaRemote,
                        category: .chat, access: .premium,
                        maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000),
                 ],
                 onModelChanged: {
    print("Model Changed To: \($0)")
  }, onOptionSelected: { _ in })
}
