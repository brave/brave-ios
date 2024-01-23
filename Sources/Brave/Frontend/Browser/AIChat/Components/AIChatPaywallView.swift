// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import DesignSystem
import Then

struct AIChatPaywallView: View {

  @Environment(\.presentationMode) @Binding private var presentationMode

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 0) {
          PremiumUpsellTitleView(
            upsellType: .premium,
            isPaywallPresented: true)
            .padding(16)
          PremiumUpsellDetailView(isPaywallPresented: true)
            .padding(8)
        }
        .navigationTitle("Leo Premium")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItemGroup(placement: .confirmationAction) {
            Button("Restore") {
            }
            .foregroundColor(.white)
          }
          
          ToolbarItemGroup(placement: .cancellationAction) {
            Button("Close") {
              presentationMode.dismiss()
            }
            .foregroundColor(.white)
          }
        }
      }
      .background(
        Color(braveSystemName: .primitivePrimary90).edgesIgnoringSafeArea(.all)
          .overlay(Image("leo-product", bundle: .module),
                   alignment: .topTrailing))
      .introspectViewController(customize: { vc in
        vc.navigationItem.do {
          let appearance = UINavigationBarAppearance().then {
            $0.configureWithDefaultBackground()
            $0.backgroundColor = UIColor(braveSystemName: .primitivePrimary90)
            $0.titleTextAttributes = [.foregroundColor: UIColor.white]
            $0.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
          }
          $0.standardAppearance = appearance
          $0.scrollEdgeAppearance = appearance
        }
      })
    }
  }
  
  
  
  
  
  
}
