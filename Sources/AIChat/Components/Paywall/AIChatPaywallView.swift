// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import DesignSystem
import Then

struct AIChatPaywallView: View {
  
  @Environment(\.presentationMode) 
  @Binding private var presentationMode
  
  @State 
  private var selectedTierType: SubscriptionType = .monthly
  
  @State
  private var availableTierTypes: [SubscriptionType] = [.monthly]

  @ObservedObject
  private var productInfo = LeoProductInfo.shared
  
  @ObservedObject
  var subscriptionManager = LeoSubscriptionManager.shared
  
  var restoreAction: (() -> Void)?
  var upgradeAction: ((SubscriptionType) -> Void)?
  
  @State
  var inAppPurchaseActionOngoing = false
  
  @StateObject 
  var observerDelegate = PaymentObserverDelegate()

  var body: some View {
    NavigationView {
      VStack(spacing: 8.0) {
        ScrollView {
          VStack(spacing: 0.0) {
            PremiumUpsellTitleView(
              upsellType: .premium,
              isPaywallPresented: true)
            .padding(16.0)
            
            PremiumUpsellDetailView(isPaywallPresented: true)
              .padding([.top, .horizontal], 8.0)
              .padding(.bottom, 24.0)
            tierSelection
              .padding([.bottom, .horizontal], 8.0)
          }
          .navigationTitle("Leo Premium")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItemGroup(placement: .confirmationAction) {
              Button(action: {
                subscriptionManager.restorePurchasesAction()
                inAppPurchaseActionOngoing.toggle()
              }) {
                if inAppPurchaseActionOngoing {
                  ProgressView()
                    .tint(Color.white)
                } else {
                  Text("Restore")
                }
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
          .padding(.bottom, 16.0)
      }
      .onAppear {
        // Observe subscription manager events
        subscriptionManager.inAppPurchaseObserver.delegate = observerDelegate
      }
      .background(
        Color(braveSystemName: .primitivePrimary90)
          .edgesIgnoringSafeArea(.all)
          .overlay(Image("leo-product", bundle: .module),
                   alignment: .topTrailing))
    }
  }
  
  private var tierSelection: some View {
    VStack {
      if availableTierTypes.contains(.yearly) {
        Button(action: {
          selectedTierType = .yearly
        }) {
          HStack {
            VStack(alignment: .leading, spacing: 8.0) {
              Text("One Year")
                .font(.title2.weight(.semibold))
                .foregroundColor(Color(.white))
              
              Text("SAVE UP TO 25%")
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color(braveSystemName: .green50))
                .padding(4.0)
                .background(Color(braveSystemName: .green20))
                .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
            }
            Spacer()
            
            if let yearlyProduct = productInfo.yearlySubProduct {
              HStack(alignment: .center, spacing: 2) {
                Text("\(yearlyProduct.priceLocale.currencyCode ?? "")\(yearlyProduct.priceLocale.currencySymbol ?? "")")
                  .font(.subheadline)
                  .foregroundColor(Color(braveSystemName: .primitivePrimary30))
                
                Text(yearlyProduct.price.frontSymbolCurrencyFormatted(with: yearlyProduct.priceLocale) ?? "$0")
                  .font(.title)
                  .foregroundColor(.white)
                
                Text(" / year")
                  .font(.subheadline)
                  .foregroundColor(Color(braveSystemName: .primitivePrimary30))
              }
            } else {
              ProgressView()
                .tint(Color.white)
            }
          }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(braveSystemName: selectedTierType == .yearly ? .primitivePrimary60 : .primitivePrimary80))
        .overlay(
          RoundedRectangle(cornerRadius: 8.0, style: .continuous)
            .strokeBorder(Color(braveSystemName: .primitivePrimary50),
                          lineWidth: selectedTierType == .yearly ? 2.0 : 0.0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
      }
      
      if availableTierTypes.contains(.monthly) {
        Button(action: {
          selectedTierType = .monthly
        }) {
          HStack {
            Text("Monthly")
              .font(.title2.weight(.semibold))
              .foregroundColor(Color(.white))
            
            Spacer()
            
            if let monthlyProduct = productInfo.monthlySubProduct {
              HStack(alignment: .center, spacing: 2.0) {
                Text("\(monthlyProduct.priceLocale.currencySymbol ?? "")")
                  .font(.subheadline)
                  .foregroundColor(Color(braveSystemName: .primitivePrimary30))
                
                Text(monthlyProduct.price.frontSymbolCurrencyFormatted(
                  with: monthlyProduct.priceLocale, isSymbolIncluded: false) ?? "$0")
                  .font(.title)
                  .foregroundColor(.white)
                
                Text(" / month")
                  .font(.subheadline)
                  .foregroundColor(Color(braveSystemName: .primitivePrimary30))
              }
            } else {
              ProgressView()
                .tint(Color.white)
            }
          }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(braveSystemName: selectedTierType == .monthly ? .primitivePrimary60 : .primitivePrimary80))
        .overlay(
          RoundedRectangle(cornerRadius: 8.0, style: .continuous)
            .strokeBorder(Color(braveSystemName: .primitivePrimary50),
                          lineWidth: selectedTierType == .monthly ? 2.0 : 0.0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
      }
      
      Text("All subscriptions are auto-renewed but can be cancelled at any time before renewal.")
        .multilineTextAlignment(.center)
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(Color(braveSystemName: .primitivePrimary20))
        .padding([.horizontal], 16.0)
        .padding([.vertical], 12.0)
    }
  }
  
  private var paywallActionView: some View {
    VStack(spacing: 16.0) {
      Rectangle()
        .frame(height: 1.0)
        .foregroundColor(Color(braveSystemName: .primitivePrimary70))
      
      VStack {
        Button(action: {
          subscriptionManager.startSubscriptionAction(with: selectedTierType)
          inAppPurchaseActionOngoing.toggle()
        }) {
          if inAppPurchaseActionOngoing {
            ProgressView()
              .tint(Color.white)
          } else {
            Text("Upgrade Now")
              .font(.body.weight(.semibold))
              .foregroundColor(Color(.white))
          }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(LinearGradient(gradient:
                                    Gradient(colors: [
                                      Color(UIColor(rgb: 0xFF5500)),
                                      Color(UIColor(rgb: 0xFF006B))
                                    ]),
                                   startPoint: .init(x: 0.0, y: 0.0),
                                   endPoint: .init(x: 0.0, y: 1.0)))
        .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
        .disabled(inAppPurchaseActionOngoing)
      }
      .padding([.horizontal], 16.0)
    }
  }
}

class PaymentObserverDelegate: ObservableObject, LeoInAppPurchaseObserverDelegate {
  
  @Published
  var purchasedStatus: (success: Bool, LeoInAppPurchaseObserver.PurchaseError?) = (false, nil)
    
  func purchasedOrRestoredProduct(validateReceipt: Bool) {
    if validateReceipt {
      // TODO: Receipt Validation Logic
      // Check the result of receipt validation and use
      // purchasedStatus(true, nil)  or
      // purchasedStatus(false, .receiptError) accordingly and
      // return
    }
    
    purchasedStatus = (true, nil)
  }
  
  func purchaseFailed(error: LeoInAppPurchaseObserver.PurchaseError) {
    purchasedStatus = (false, error)
  }
}
