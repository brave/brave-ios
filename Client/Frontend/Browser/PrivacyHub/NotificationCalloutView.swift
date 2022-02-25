// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI

extension PrivacyReportsView {
  struct NotificationCalloutView: View {
    var body: some View {
      Group {
        VStack {
          HStack(alignment: .top) {
            HStack {
              Image(uiImage: .init(imageLiteralResourceName: "brave_document"))
              Text("Get weekly privacy updates on tracker & ad blocking.")
                .font(.headline)
            }
            Spacer()
            Image(systemName: "xmark")
          }
          .frame(maxWidth: .infinity)
          
          Button(action: {
            
          }, label: {
            ZStack {
              VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                .edgesIgnoringSafeArea(.all)
              
              Label("Turn on noticications", image: "brave.bell")
                .font(.callout)
                .padding(.vertical, 12)
            }
            .clipShape(Capsule())
          })
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .padding()
        .foregroundColor(Color.white)
        .background(
          LinearGradient(
            gradient:
              Gradient(colors: [.init(.braveBlurple),
                                .init(.braveInfoLabel)]),
            startPoint: .topLeading, endPoint: .bottomTrailing)
        )
      .cornerRadius(15)
      }
    }
  }
}

#if DEBUG
struct NotificationCalloutView_Previews: PreviewProvider {
  static var previews: some View {
    PrivacyReportsView.NotificationCalloutView()
  }
}
#endif
