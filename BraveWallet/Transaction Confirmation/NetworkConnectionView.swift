// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import Shared

struct NetworkConnectionView: View {
  private let bullets = ["View the addresses of your permitted accounts (required)"]
  
    var body: some View {
      ScrollView {
        VStack(spacing: 35) {
          Text("Mainnet")
            .font(.headline)
            .fontWeight(.light)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 28,
                                leading: 24,
                                bottom: 0,
                                trailing: 0))
          
          VStack(spacing: 10) {
            Rectangle()
              .fill(Color(.tertiaryBraveBackground))
              .frame(width: 48, height: 48)
              .cornerRadius(4)
              
            Text(verbatim: "https://app.uniswap.org")
              .font(.subheadline)
              .foregroundColor(Color(.braveLabel))
              .padding(.top, 10)
            
            Text("Connect with Brave Wallet")
              .font(.headline)
              .padding(.top, 2)
            
            Text("0xfcD...00ee, 0xffd3...11ae")
              .font(.footnote)
              .opacity(0.7)
            
            VStack {
              ForEach(bullets, id: \.self) { bullet in
                BulletView(bullet: bullet)
              }
            }
            .padding(.top, 30)
            
            Text("Only connect with sites you trust.")
              .font(.subheadline)
              .padding(.top, 40)
            
            HStack() {
              Button(action: back) {
                Text(Strings.backTitle)
                  .padding(.vertical, 4)
                  .padding(.horizontal, 6)
              }
              .buttonStyle(BraveOutlineButtonStyle(size: .normal))
              Button(action: connect) {
                  Text("Connect")
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
              }
              .buttonStyle(BraveFilledButtonStyle(size: .normal))
            }
            .padding(.top, 20)
          }
          .padding(EdgeInsets(top: 0, leading: 45, bottom: 0, trailing: 45))
          .frame(maxHeight: .infinity, alignment: .center)
        }
      }
    }
  
  struct BulletView: View {
    var bullet: String
    
    var body: some View {
      HStack(spacing: 12) {
        Image("wallet-checkmark")
        Text(bullet)
          .font(.callout)
      }
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
