// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

struct AIChatNetworkErrorView: View {
  var body: some View {
    HStack(alignment: .top, spacing: 0.0) {
      Image(braveSystemName: "leo.warning.circle-filled")
        .foregroundStyle(Color(braveSystemName: .systemfeedbackErrorIcon))
        .padding([.bottom, .trailing])
      
      VStack(spacing: 0.0) {
        Text("There was a network issue connecting to Leo, check your connection and try again.")
          .font(.callout)
          .foregroundColor(Color(braveSystemName: .textPrimary))
          .padding(.bottom)
        
        HStack {
          Button(action: {
            
          }) {
            Text("Retry")
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
  AIChatNetworkErrorView()
}
