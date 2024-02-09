// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

struct AIChatNetworkErrorView: View {
  let onRetryRequest: () -> Void
  
  var body: some View {
    HStack(alignment: .top, spacing: 0.0) {
      Image(braveSystemName: "leo.warning.circle-filled")
        .foregroundStyle(Color(braveSystemName: .systemfeedbackErrorIcon))
        .padding([.bottom, .trailing])
      
      VStack(spacing: 0.0) {
        Text(Strings.AIChat.networkErrorViewTitle)
          .font(.callout)
          .foregroundColor(Color(braveSystemName: .textPrimary))
          .padding(.bottom)
        
        HStack {
          Button(action: {
            onRetryRequest()
          }) {
            Text(Strings.AIChat.retryActionTitle)
              .font(.body.weight(.semibold))
              .foregroundColor(Color(.white))
          }
          .padding()
          .background(Color(braveSystemName: .buttonBackground))
          .foregroundStyle(.white)
          .clipShape(Capsule())
          
          Spacer()
        }
      }
    }
    .padding()
    .background(Color(braveSystemName: .systemfeedbackErrorBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
  }
}

#Preview {
  AIChatNetworkErrorView() {}
}
