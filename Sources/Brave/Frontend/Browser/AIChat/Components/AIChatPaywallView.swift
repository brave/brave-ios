// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SwiftUI
import BraveUI
import Strings
import DesignSystem

struct AIChatPaywallView: View {

  @Environment(\.presentationMode) @Binding private var presentationMode

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 0) {
          PremiumUpsellTitleView(upsellType: .premium)
            .padding(24)
          PremiumUpsellDetailView()
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
      .background(Color(red: 22 / 255, green: 16 / 255, blue: 101 / 255))
      .introspectViewController(customize: { vc in
        vc.navigationItem.do {
          let appearance: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.06274509804, blue: 0.3960784314, alpha: 1)
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            return appearance
          }()
          $0.standardAppearance = appearance
          $0.scrollEdgeAppearance = appearance
        }
      })
    }
  }
}
