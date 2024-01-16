// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

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

private struct AIChatMenuItemView: View {
  
  let title: String
  let subtitle: String
  let rightAccessoryView: AnyView?
  
  var body: some View {
    HStack {
      Image(braveSystemName: "leo.check.normal")
        .foregroundStyle(Color(braveSystemName: .textInteractive))
        .padding(.leading, 16.0)
        .padding(.trailing, 8.0)
      
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
      
      if let rightAccessoryView {
        rightAccessoryView
      }
    }
    .padding(.vertical)
  }
}

struct AIChatMenuView: View {
  
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
      
      AIChatMenuItemView(title: "Mixtral 8x7b", subtitle: "Powerful, fast, adaptive", rightAccessoryView: nil)
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      AIChatMenuItemView(title: "Claude Instant", subtitle: "Strength in creative tasks", rightAccessoryView: nil)
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      AIChatMenuItemView(title: "Llama-2-13-b", subtitle: "General purpose chat", rightAccessoryView: nil)
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      AIChatMenuItemView(title: "Llama-2-70-b", subtitle: "Advanced and accurate chat", rightAccessoryView: nil)
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      AIChatMenuHeaderView(icon: "leo.code", title: "CODING")
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      AIChatMenuItemView(title: "Code Llama-13b", subtitle: "Code generation and discussion", rightAccessoryView: nil)
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      AIChatMenuItemView(title: "Code Llama-70b", subtitle: "Advanced code assistance", rightAccessoryView: nil)
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 7.0)
      
      HStack {
        Text("New Chat")
          .font(.body)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
      }
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      HStack {
        Text("Go Premium")
          .font(.body)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
      }
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      HStack {
        Text("Advanced Settings")
          .font(.body)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
      }
    }
  }
}

#Preview {
  AIChatMenuView()
}
