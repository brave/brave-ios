// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

struct AIChatIntroMessageView: View {
  let prompt: String
  
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
        Text("Chat")
          .font(.headline)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
        
        Text("Mixtral by Mistral AI")
          .font(.footnote)
          .foregroundStyle(Color(braveSystemName: .textTertiary))
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.bottom)
        
        Text(prompt)
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
  AIChatIntroMessageView(prompt: "Hi, I'm Leo. I'm a fully hosted AI assistant by Brave. I'm powered by Mixtral 8x7B, a model created by Mistral AI to handle advanced tasks.")
    .previewLayout(.sizeThatFits)
}
