// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

struct AIChatPromptInputView: View {
  let isSpeechToTextAvilable: Bool
  let onTextSubmitted: (String) -> Void
  let onVoiceSearchPressed: () -> Void

  @State private var prompt: String = ""

  var body: some View {
    HStack(spacing: 0.0) {
      /*Text("/")
        .font(.caption2)
        .foregroundStyle(Color(braveSystemName: .textTertiary))
        .padding(.horizontal, 12.0)
        .padding(.vertical, 4.0)
        .background(
          RoundedRectangle(cornerRadius: 4.0, style: .continuous)
            .strokeBorder(Color(braveSystemName: .dividerSubtle), lineWidth: 1.0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
        .padding()*/
      
      TextField("", text: $prompt,
                prompt: Text("Enter a prompt here")
                          .font(.subheadline)
                          .foregroundColor(Color(braveSystemName: .textTertiary))
      )
      .font(.subheadline)
      .foregroundColor(Color(braveSystemName: .textPrimary))
      .onSubmit {
        if !prompt.isEmpty {
          onTextSubmitted(prompt)
          prompt = ""
        }
      }
      .padding(.leading)
      
      if prompt.isEmpty {
        Button {
          onVoiceSearchPressed()
        } label: {
          Image(braveSystemName: "leo.microphone")
            .foregroundStyle(Color(braveSystemName: .iconDefault))
        }
        .hidden(isHidden: !isSpeechToTextAvilable)
        .padding()
      } else {
        Button {
          onTextSubmitted(prompt)
          prompt = ""
        } label: {
          Image(braveSystemName: "leo.send")
            .foregroundStyle(Color(braveSystemName: .iconDefault))
        }
        .padding()
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 8.0, style: .continuous)
        .strokeBorder(Color(braveSystemName: .dividerStrong), lineWidth: 1.0)
    )
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatPromptInputView(isSpeechToTextAvilable: true) { prompt in
    print("Prompt Submitted: \(prompt)")
  } onVoiceSearchPressed: {
    print("Voice Search Activated")
  }
    .previewLayout(.sizeThatFits)
}
