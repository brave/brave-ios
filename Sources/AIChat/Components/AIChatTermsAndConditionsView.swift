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
      Text("Chat Privately with Brave Leo")
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .font(.body.weight(.semibold))
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .padding(.bottom)
      
      Text("Brave Leo is a private AI smart assistant that enhances your use of the Internet. Leo is free to use with limited access. Brave Leo Premium offers more models, higher limits and gives subscribers early access to new features. The default model for all users is currently Mixtral 8x7B. See the **[Brave wiki](https://github.com/brave/brave-browser/wiki/Brave-Leo)** for more details.\n\nWhen you ask Leo a question it may use the context of the web page you are viewing or text you highlight to provide a response. The accuracy of responses is not guaranteed, and may include inaccurate, misleading, or false information. Leo uses data from Brave Search to improve response quality. Don't submit sensitive or private info, and use caution with any answers related to health, finance, personal safety, or similar. You can adjust Leo’s options in Settings any time.\n\nLeo does not collect identifiers such as your IP address that can be linked to you. No personal data is retained by the AI model or any 3rd-party model providers. See the **[privacy policy](https://brave.com/privacy/browser/#brave-leo)** for more information")
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
        Text("I Understand")
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
