// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

struct AIChatUserMessageView: View {
  let prompt: String
  
  var body: some View {
    VStack {
      HStack {
        ZStack {
          Color(braveSystemName: .containerHighlight)
          Image(braveSystemName: "leo.user.circle")
            .padding(8.0)
        }
        .fixedSize()
        .clipShape(Capsule())
        
        Spacer()
      }
      
      Text(prompt)
        .font(.subheadline)
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatUserMessageView(prompt: "Does it work with Apple devices?")
    .previewLayout(.sizeThatFits)
}
