// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct LinkPurchaseView: View {
    var body: some View {
      ScrollView {
        VStack(alignment: .leading) {
          Text("Link your App Store subscription details to your Brave account")
            .font(.title3.weight(.bold))
          
          VStack(alignment: .leading, spacing: 0) {
            Text("Purchase Receipt")
              .fontWeight(.bold)
              .padding(16)
            Divider()
            Text("Subscription: Active")
              .padding(16)
            Divider()
            Text("Paid: June 3, 2021")
              .padding(16)
            Divider()
            Text("Amount: $9.99/mo")
              .padding(16)
          }
          .font(.headline.weight(.regular))
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(.secondaryBraveBackground))
          .overlay(
                  RoundedRectangle(cornerRadius: 8)
                      .stroke(.gray, lineWidth: 1)
              )
          
          Button("Connect Brave account") {
            
          }
          .font(.subheadline)
          .frame(maxWidth: .infinity)
          .padding(8)
          .foregroundColor(.white)
          .background(Color(.braveOrange))
          .clipShape(RoundedRectangle(cornerRadius: 1000, style: .continuous))
          
          Text(.init(footerText))
            .font(.subheadline)
            .accentColor(.red)
            .osAvailabilityModifiers { content in
              if #available(iOS 15.0, *) {
                content
                  .environment(\.openURL, OpenURLAction { url in
                    // Intercept markdown's open url and do nothing.
                    return .discarded
                  })
              } else {
                content
              }
            }
        }
        .padding()
      }
    }
  
  private var footerText: String {
    // iOS 15 adds a simple markdown formatter.
    // For iOS 14 we do nothing.
    let urlFormat = { () -> String in
      if #available(iOS 15, *) {
        return "[account.brave.com](https://)"
      } else {
        return "account.brave.com"
      }
    }
    
    return String(format: "Use Brave VPN on up to 5 devices by submitting your subscription receipt details. Login on %@ from the new device you wish to use.", urlFormat())
  }
}

#if DEBUG
struct LinkPurchaseView_Previews: PreviewProvider {
    static var previews: some View {
      LinkPurchaseView()
    }
}
#endif
