// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import Shared
import BraveShared

extension PrivacyReportsView {
  struct NotificationCalloutView: View {
    var body: some View {
      Group {
        VStack {
          HStack(alignment: .top) {
            HStack {
              Image(uiImage: .init(imageLiteralResourceName: "brave_document"))
              Text(Strings.PrivacyHub.notificationCalloutBody)
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
              
              Label(Strings.PrivacyHub.notificationCalloutButtonText, image: "brave.bell")
                .font(.callout)
                .padding(.vertical, 12)
            }
            .clipShape(Capsule())
          })
            .frame(maxWidth: .infinity)
        }
        .padding()
        .foregroundColor(Color.white)
        .background(
          LinearGradient(braveGradient: .gradient05)
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
