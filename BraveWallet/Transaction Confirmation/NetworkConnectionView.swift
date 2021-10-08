// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import Shared

struct NetworkConnectionView: View {
  private let bullets = ["View the addresses of your permitted accounts (required)"]
  @ScaledMetric private var networkIconLength = 48.0
  
    var body: some View {
      ScrollView(.vertical) {
        VStack(spacing: 35) {
          Text("Mainnet")
            .font(.headline.weight(.light))
            .frame(maxWidth: .infinity, alignment: .leading)
          
          VStack(spacing: 10) {
            Rectangle()
              .fill(Color(.tertiaryBraveBackground))
              .frame(width: networkIconLength, height: networkIconLength)
              .cornerRadius(4)
              
            Text(verbatim: "https://app.uniswap.org")
              .font(.subheadline)
              .foregroundColor(Color(.braveLabel))
              .padding(.top, 10)
            
            Text("Connect with Brave Wallet")
              .font(.headline)
              .padding(.top, 2)
            
            Text("0xfcD...00ee, 0xffd3...11ae")
              .foregroundColor(Color(.secondaryBraveLabel))
              .font(.footnote)
            
            VStack {
              ForEach(bullets, id: \.self) { bullet in
                BulletView(bullet: bullet)
              }
            }
            .padding(.vertical, 30)
            
            Text("Only connect with sites you trust.")
              .font(.subheadline)
          }
          .padding(.horizontal, 24)
          .frame(maxHeight: .infinity, alignment: .center)
          
          HStack {
            Button(action: back) {
              Text(Strings.backTitle)
            }
            .buttonStyle(BraveOutlineButtonStyle(size: .large))
            Button(action: connect) {
                Text("Connect")
            }
            .buttonStyle(BraveFilledButtonStyle(size: .large))
          }
        }
        .padding(24)
      }
    }
  
  struct BulletView: View {
    var bullet: String
    
    var body: some View {
      HStack(spacing: 12) {
        Image("wallet-checkmark")
          .foregroundColor(Color(.braveLighterBlurple))
        Text(bullet)
      }
      .font(.callout)
    }
  }
  
  private func back() {
  }
  
  private func connect() {
  }
}

struct NetworkConnectionView_Previews: PreviewProvider {
    static var previews: some View {
      NetworkConnectionView()
        .previewColorSchemes()
    }
}
