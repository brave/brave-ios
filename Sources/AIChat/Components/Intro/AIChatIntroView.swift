// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

private struct AIChatIntroBubbleView<ImageOverlay: View>: View {
  let title: String
  let subtitle: String
  let image: ImageOverlay
  let onSummarizePage: (() -> Void)?
  
  var body: some View {
    VStack {
      Text(title)
        .font(.callout.weight(.semibold))
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding([.horizontal, .top], 24.0)
        .padding(.bottom, 8.0)
      
      Text(subtitle)
        .font(.footnote)
        .foregroundStyle(Color(braveSystemName: .textSecondary))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding([.horizontal, .bottom], 24.0)
      
      if let onSummarizePage = onSummarizePage {
        HStack {
          Button {
            onSummarizePage()
          } label: {
            Text(Strings.AIChat.summarizePageActionTitle)
              .font(.callout)
              .foregroundColor(Color(braveSystemName: .textInteractive))
          }
          .padding(.horizontal, 12.0)
          .padding(.vertical, 8.0)
          .background(
            RoundedRectangle(cornerRadius: 12.0, style: .continuous)
              .strokeBorder(Color(braveSystemName: .dividerInteractive), lineWidth: 1.0)
          )
          .clipShape(RoundedRectangle(cornerRadius: 12.0, style: .continuous))
          
          Spacer()
        }
        .padding([.horizontal, .bottom], 24.0)
      }
    }
    .background(
      VStack {
        Spacer()
        HStack {
          Spacer()
          image
            .opacity(0.40)
            .frame(alignment: .bottomTrailing)
        }
      }
    )
  }
}

struct AIChatIntroView: View {
  let onSummarizePage: (() -> Void)?
  
  var body: some View {
    VStack(spacing: 0.0) {
      Text(Strings.AIChat.chatIntroTitle)
        .font(.largeTitle.weight(.semibold))
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 24.0)
        .padding(.bottom, 8.0)
      
      Text(Strings.AIChat.chatIntroSubTitle)
        .font(.title.weight(.semibold))
        .foregroundStyle(Color(braveSystemName: .textTertiary))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 24.0)
        .padding(.bottom, 36.0)
      
      AIChatIntroBubbleView(
        title: Strings.AIChat.chatIntroWebsiteHelpTitle,
        subtitle: onSummarizePage != nil
          ? Strings.AIChat.chatIntroWebsiteHelpSubtitlePageSummarize
          : Strings.AIChat.chatIntroWebsiteHelpSubtitleArticleSummarize,
        image: Image("leo-intro-website-shape", bundle: .module)
          .renderingMode(.template)
          .foregroundStyle(Color(braveSystemName: .purple20)),
        onSummarizePage: onSummarizePage
      )
      .background(Color(braveSystemName: .purple10))
      .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
      .padding([.horizontal, .bottom], 12.0)
      
      AIChatIntroBubbleView(
        title: Strings.AIChat.chatIntroJustTalkTitle,
        subtitle: Strings.AIChat.chatIntroJustTalkSubTitle,
        image: Image("leo-intro-star-burst", bundle: .module)
          .renderingMode(.template)
          .foregroundStyle(Color(braveSystemName: .teal20)),
        onSummarizePage: nil
      )
      .background(Color(braveSystemName: .teal10))
      .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
      .padding([.horizontal, .bottom], 12.0)
    }
  }
}

#Preview {
  AIChatIntroView(onSummarizePage: nil)
}
