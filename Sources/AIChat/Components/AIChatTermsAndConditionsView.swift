// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
      ScrollView {
        VStack {
          Image(braveSystemName: "leo.product.brave-leo")
            .frame(minWidth: 100.0, minHeight: 100.0)
          
          Text("About Leo")
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .font(.body.weight(.semibold))
            .foregroundStyle(Color(braveSystemName: .textPrimary))
            .padding(.bottom, 8.0)
          
          Text("Brave Leo is an AI smart assistant that can summarize web pages, transcribe videos, and answer questions. Brave Leo Premium uses advanced **[AI models](https://github.com/brave/brave-browser/wiki/Brave-Leo)** for even more nuanced replies, and gives early access to new features.\n\nThe accuracy of responses is not guaranteed, and may include inaccurate, misleading, or false information. Don't submit sensitive or private info, and use caution with any answers related to health, finance, personal safety, or similar.\n\nLeo does not collect identifiers such as your IP Address that can be linked to you. No personal data is retained by the AI model or any 3rd-party model providers.")
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
        }
        .padding()
      }
      
      Color(braveSystemName: .dividerSubtle)
        .frame(height: 1.0)
      
      Button(action: {
        presentationMode.wrappedValue.dismiss()
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
      .padding(16)
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
