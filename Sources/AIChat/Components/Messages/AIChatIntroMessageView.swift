// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem
import BraveCore

struct AIChatIntroMessageView: View {
  let model: AiChat.Model

  private var modelDescription: String {
    switch model.key {
    case "chat-basic":
      return Strings.AIChat.introMessageLlamaModelDescription
      
    case "chat-leo-expanded":
      return Strings.AIChat.introMessageMixtralModelDescription
      
    case "chat-claude-instant":
      return Strings.AIChat.introMessageClaudeInstantModelDescription
      
    default:
      return model.displayName
    }
  }
  
  private var introMessage: String {
    switch model.key {
    case "chat-basic":
      return Strings.AIChat.introMessageLlamaMessageDescription
      
    case "chat-leo-expanded":
      return Strings.AIChat.introMessageMixtralMessageDescription
      
    case "chat-claude-instant":
      return Strings.AIChat.introMessageClaudeInstantMessageDescription
      
    default:
      return String(format: Strings.AIChat.introMessageGenericMessageDescription, model.displayName)
    }
  }
  
  var body: some View {
    HStack(alignment: .top, spacing: 0.0) {
      ZStack {
        LinearGradient(gradient:
                        Gradient(colors: [
                          Color(UIColor(rgb: 0xFA7250)),
                          Color(UIColor(rgb: 0xFF1893)),
                          Color(UIColor(rgb: 0xA77AFF))]),
                       startPoint: .init(x: 1.0, y: 1.0),
                       endPoint: .zero)
        
        Image(braveSystemName: "leo.product.brave-leo")
          .foregroundColor(.white)
          .font(.title2)
          .padding(8.0)
      }
      .fixedSize()
      .clipShape(Circle())
      .padding(.trailing, 16.0)
      
      VStack(spacing: 0.0) {
        Text(Strings.AIChat.introMessageTitle)
          .font(.headline)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
        
        Text(modelDescription)
          .font(.footnote)
          .foregroundStyle(Color(braveSystemName: .textTertiary))
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.bottom)
        
        Text(introMessage)
          .font(.subheadline)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatIntroMessageView(model: .init(key: "mixtral_8x7b", name: "Mixtral-8x7b", displayName: "Mixtral 8x7b",
                                      displayMaker: "Powerful, fast and adaptive", engineType: .llamaRemote,
                                      category: .chat, access: .basicAndPremium,
                                      maxPageContentLength: 9000, longConversationWarningCharacterLimit: 20000))
    .previewLayout(.sizeThatFits)
}
