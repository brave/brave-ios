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
      VStack(spacing: 8) {
        ScrollView {
          VStack(spacing: 0) {
            PremiumUpsellTitleView(
              upsellType: .premium,
              isPaywallPresented: true)
              .padding(16)
            PremiumUpsellDetailView(isPaywallPresented: true)
              .padding([.top, .horizontal], 8)
              .padding(.bottom, 24)
            tierSelection
              .padding([.bottom, .horizontal], 8)
          }
          .navigationTitle("Leo Premium")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItemGroup(placement: .confirmationAction) {
              Button("Restore") {
                // TODO: In-app purchase restore
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
        
        paywallActionView
          .padding(.bottom, 16)
      }
      .background(
        Color(braveSystemName: .primitivePrimary90).edgesIgnoringSafeArea(.all)
          .overlay(Image("leo-product", bundle: .module),
                   alignment: .topTrailing))
    }
  }
  
  private var tierSelection: some View {
    VStack {
      Button(action: {
        
      }) {
        HStack {
          VStack(alignment: .leading, spacing: 8) {
            Text("One Year")
              .font(.title2.weight(.semibold))
              .foregroundColor(Color(.white))
            
            Text("SAVE UP TO 25%")
              .font(.caption2.weight(.semibold))
              .foregroundColor(Color(braveSystemName: .green50))
              .padding(4)
              .background(Color(braveSystemName: .green20))
              .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
          }
          Spacer()
          
          HStack(alignment: .center, spacing: 2) {
            Text("US$")
              .font(.subheadline)
              .foregroundColor(Color(braveSystemName: .primitivePrimary30))
            
            Text("150")
              .font(.title)
              .foregroundColor(.white)
            
            Text(" / year")
              .font(.subheadline)
              .foregroundColor(Color(braveSystemName: .primitivePrimary30))
          }
        }
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color(braveSystemName: .primitivePrimary60))
      .overlay(
        RoundedRectangle(cornerRadius: 8.0, style: .continuous)
          .strokeBorder(Color(braveSystemName: .primitivePrimary50), lineWidth: 2.0)
      )
      .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
      
      Button(action: {
        
      }) {
        HStack {
          Text("Monthly")
            .font(.title2.weight(.semibold))
            .foregroundColor(Color(.white))
            
          Spacer()
          
          HStack(alignment: .center, spacing: 2) {
            Text("US$")
              .font(.subheadline)
              .foregroundColor(Color(braveSystemName: .primitivePrimary30))
            
            Text("15")
              .font(.title)
              .foregroundColor(.white)
            
            Text(" / month")
              .font(.subheadline)
              .foregroundColor(Color(braveSystemName: .primitivePrimary30))
          }
        }
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color(braveSystemName: .primitivePrimary80))
      .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
      
      Text("All subscriptions are auto-renewed but can be cancelled at any time before renewal.")
        .multilineTextAlignment(.center)
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(Color(braveSystemName: .primary20))
        .padding([.horizontal], 16)
        .padding([.vertical], 12)
    }
  }
  
  private var paywallActionView: some View {
    VStack(spacing: 16) {
      Rectangle()
        .frame(height: 1)
        .foregroundColor(Color(braveSystemName: .primitivePrimary70))
      
      VStack {
        Button(action: {
          
        }) {
          Text("Upgrade Now")
            .font(.body.weight(.semibold))
            .foregroundColor(Color(.white))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(braveSystemName: .legacyInteractive1))
        .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
      }
      .padding([.horizontal], 16)
    }
  }
}
