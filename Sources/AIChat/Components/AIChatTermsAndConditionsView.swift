// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

public struct AIChatTermsAndConditionsView: View {
  let onTermsAccepted: () -> Void
  let onOpenURL: (URL) -> Void
  
  @Environment(\.presentationMode)
  private var presentationMode
  
  public init(onTermsAccepted: @escaping () -> Void, onOpenURL: @escaping (URL) -> Void) {
    self.onTermsAccepted = onTermsAccepted
    self.onOpenURL = onOpenURL
  }
  
  public var body: some View {
    VStack {
      Text("Privacy agreement")
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .font(.body.weight(.semibold))
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .padding(.bottom)
      
      Text("Brave Leo is an AI smart assistant that can summarize web pages, transcribe videos, and answer questions. Brave Leo Premium uses advanced AI models for even more nuanced replies, and gives early access to new features.\n\nThe accuracy of responses is not guaranteed, and may include inaccurate, misleading, or false information. Don't submit sensitive or private info, and use caution with any answers related to health, finance, personal safety, or similar.\n\nLeo does not collect or otherwise process identifiers such as IP Address that can be linked to you. No personal data is retained by the AI model or any 3rd-party model providers.")
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .font(.body)
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .tint(Color(braveSystemName: .primary50))
        .environment(\.openURL, OpenURLAction { url in
          presentationMode.wrappedValue.dismiss()
          onOpenURL(url)
          return .handled
        })
        .padding(.bottom)
      
      Button(action: {
        onTermsAccepted()
      }) {
        Text("Accept and begin")
          .font(.subheadline.weight(.semibold))
          .padding([.top, .bottom], 12)
          .padding([.leading, .trailing], 16)
          .frame(maxWidth: .infinity)
      }
      .background(Color(braveSystemName: .buttonBackground))
      .foregroundStyle(.white)
      .clipShape(Capsule())
      .padding(16.0)
    }
  }
}

#Preview {
  AIChatTermsAndConditionsView() {
    print("Terms Accepted")
  } onOpenURL: { url in
    print("OPEN URL: \(url)")
  }
}
