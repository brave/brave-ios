// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
    }
    .padding(.vertical)
  }
}

enum AIChatMenuOptionTypes {
    case newChat, premium, advancedSettings
}

struct AIChatMenuView: View {
  let currentModel: AiChat.Model
  let modelOptions: [AiChat.Model]
  let onModelChanged: (String) -> Void
  let onOptionSelected: (AIChatMenuOptionTypes) -> Void
  
  @Environment(\.presentationMode)
  private var presentationMode
  
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
            Image(braveSystemName: "leo.lock.plain")
              .foregroundStyle(Color(braveSystemName: .iconDefault))
              .padding(.leading, 16.0)
              .padding(.trailing, 8.0)
              .hidden(isHidden: !model.isPremium)
          }
        })
        
        if index != modelOptions.count - 1 {
            Color(braveSystemName: .dividerSubtle)
            .frame(height: 1.0)
        }
      }
      
      Color(braveSystemName: .dividerSubtle)
      .frame(height: 8.0)
      
      Button {
        presentationMode.wrappedValue.dismiss()
        onOptionSelected(.newChat)
      } label: {
        Text("New Chat")
          .font(.body)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
        
        Image(braveSystemName: "leo.erase")
          .foregroundStyle(Color(braveSystemName: .iconDefault))
          .padding(.leading, 16.0)
          .padding(.trailing, 8.0)
      }
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      Button {
        presentationMode.wrappedValue.dismiss()
        onOptionSelected(.premium)
      } label: {
        Text("Go Premium")
          .font(.body)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
        
        Image(braveSystemName: "leo.lock.open")
          .foregroundStyle(Color(braveSystemName: .iconDefault))
          .padding(.leading, 16.0)
          .padding(.trailing, 8.0)
      }
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      Button {
        presentationMode.wrappedValue.dismiss()
        onOptionSelected(.advancedSettings)
      } label: {
        Text("Advanced Settings")
          .font(.body)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
        
        Image(braveSystemName: "leo.settings")
          .foregroundStyle(Color(braveSystemName: .iconDefault))
          .padding(.leading, 16.0)
          .padding(.trailing, 8.0)
      }
    }
  }
}

#Preview {
  AIChatMenuView(currentModel:
      .init(key: "mixtral_8x7b", name: "Mixtral 8x7b", displayName: "Mixtral 8x7b",
            displayMaker: "", engineType: .llamaRemote,
            category: .chat, isPremium: false,
            maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000),
                 modelOptions: [
                  .init(key: "mx_8x7b", name: "Mixtral 8x7b", displayName: "Mixtral 8x7b",
                        displayMaker: "", engineType: .llamaRemote,
                        category: .chat, isPremium: false,
                        maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000),
                  .init(key: "mixtral_8x7b", name: "Mixtral 8x7b", displayName: "Mixtral 8x7b",
                        displayMaker: "", engineType: .llamaRemote,
                        category: .chat, isPremium: false,
                        maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000),
                  .init(key: "mixtral_8x7b", name: "Mixtral 8x7b", displayName: "Mixtral 8x7b",
                        displayMaker: "", engineType: .llamaRemote,
                        category: .chat, isPremium: false,
                        maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000),
                  .init(key: "mixtral_8x7b", name: "Mixtral 8x7b", displayName: "Mixtral 8x7b",
                        displayMaker: "", engineType: .llamaRemote,
                        category: .chat, isPremium: false,
                        maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000),
                  .init(key: "mixtral_8x7b", name: "Mixtral 8x7b", displayName: "Mixtral 8x7b",
                        displayMaker: "", engineType: .llamaRemote,
                        category: .chat, isPremium: false,
                        maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000),
                  .init(key: "mixtral_8x7b", name: "Mixtral 8x7b", displayName: "Mixtral 8x7b",
                        displayMaker: "", engineType: .llamaRemote,
                        category: .chat, isPremium: false,
                        maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000)
                 ],
                 onModelChanged: {
    print("Model Changed To: \($0)")
  }, onOptionSelected: { _ in })
}
