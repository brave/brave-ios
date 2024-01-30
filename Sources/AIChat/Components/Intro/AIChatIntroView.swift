// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

private struct AIChatIntroBubbleView: View {
  let title: String
  let subtitle: String
  let image: String
  
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
    }
    .background(
      HStack {
        Spacer()
        Image(image, bundle: .module)
          .resizable()
          .aspectRatio(contentMode: .fit)
      }
    )
  }
}

struct AIChatIntroView: View {
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
                            subtitle: "I can help you summarizing articles, expanding on a site's content and much more.",
                            image: "leo-intro-website-shape")
      .background(Color(braveSystemName: .purple10))
      .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
      .padding(.bottom)
      
      AIChatIntroBubbleView(title: "Just want to chat?",
                            subtitle: "Ask me anything! We can talk about any topic you want. I'm always learning and improving to provide better answers.",
                            image: "leo-intro-star-burst")
      .background(Color(braveSystemName: .teal10))
      .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
      .padding(.bottom)
    }
  }
}

#Preview {
  AIChatIntroView()
}
