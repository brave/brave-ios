// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

private struct AIChatIntroBubbleView: View {
  let title: String
  let subtitle: String
  let image: String
  let onSummarizePage: (() -> Void)?
  
  var body: some View {
    VStack {
      Text(title)
        .font(.callout.weight(.semibold))
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
        .padding(.top)
      
      Text(subtitle)
        .font(.footnote)
        .foregroundStyle(Color(braveSystemName: .textTertiary))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
        .padding(.bottom)
      
      if let onSummarizePage = onSummarizePage {
        HStack {
          Button {
            onSummarizePage()
          } label: {
            Text("Summarize this page")
              .font(.callout)
              .foregroundColor(Color(braveSystemName: .textInteractive))
          }
          .padding(12.0)
          .background(
            RoundedRectangle(cornerRadius: 12.0, style: .continuous)
              .strokeBorder(Color(braveSystemName: .dividerInteractive), lineWidth: 1.0)
          )
          .clipShape(RoundedRectangle(cornerRadius: 12.0, style: .continuous))
          
          Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom)
      }
    }
    .background(
      HStack {
        Spacer()
        Image(image, bundle: .module)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(alignment: .bottomTrailing)
      }
    )
  }
}

struct AIChatIntroView: View {
  let onSummarizePage: (() -> Void)?
  
  var body: some View {
    VStack(spacing: 0.0) {
      Text("Hi, I'm Leo!")
        .font(.title2.weight(.semibold))
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom)
      
      Text("An AI-powered intelligent assistant, built right into Brave.")
        .font(.title2.weight(.semibold))
        .foregroundStyle(Color(braveSystemName: .textSecondary))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom)
      
      AIChatIntroBubbleView(title: "Need help with a website?",
                            subtitle: onSummarizePage != nil ? "I can help you summarizing articles, expanding on a site's content and much more. Not sure where to start? Try this:" : "I can help you summarizing articles, expanding on a site's content and much more.",
                            image: "leo-intro-website-shape",
                            onSummarizePage: onSummarizePage
      )
      .background(Color(braveSystemName: .purple10))
      .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
      .padding(.bottom)
      
      AIChatIntroBubbleView(title: "Just want to chat?",
                            subtitle: "Ask me anything! We can talk about any topic you want. I'm always learning and improving to provide better answers.",
                            image: "leo-intro-star-burst",
                            onSummarizePage: nil
      )
      .background(Color(braveSystemName: .teal10))
      .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
      .padding(.bottom)
    }
  }
}

#Preview {
  AIChatIntroView(onSummarizePage: nil)
}
