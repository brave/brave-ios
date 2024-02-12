// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import DesignSystem
import Then
import StoreKit
import BraveStrings

enum AIChatPaymentStatus {
  case ongoing
  case success
  case failure
}

enum AIChatSubscriptionTier {
  case monthly
  case yearly
}

struct AIChatPaywallView: View {
  @Environment(\.presentationMode) 
  @Binding private var presentationMode
  
  @State 
  private var selectedTierType: AIChatSubscriptionTier = .monthly
  
  @State
  private var availableTierTypes: [AIChatSubscriptionTier] = [.monthly]
  
  @ObservedObject
  private(set) var storeSDK = BraveStoreSDK.shared
  
  @State
  private var paymentStatus: AIChatPaymentStatus = .success
  
  @State
  private var isShowingPurchaseAlert = false
  
  @State
  private var shouldDismiss: Bool = false
  
  // Timer used for resetting the restore action to prevent infinite loading
  @State 
  private var iapRestoreTimer: Timer?
  
  var premiumUpgrageSuccessful: ((AIChatSubscriptionTier) -> Void)?

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
          .navigationTitle(Strings.AIChat.paywallViewTitle)
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItemGroup(placement: .confirmationAction) {
              Button(action: {
                paymentStatus = .ongoing
                
                Task { @MainActor in
                  if await storeSDK.restorePurchases() {
                    iapRestoreTimer?.invalidate()
                    paymentStatus = .success
                    shouldDismiss.toggle()
                  } else {
                    iapRestoreTimer?.invalidate()
                    paymentStatus = .failure
                    isShowingPurchaseAlert.toggle()
                  }
                }
                
                if iapRestoreTimer != nil {
                  iapRestoreTimer?.invalidate()
                  iapRestoreTimer = nil
                }
                
                // Adding 1 minute timer for restore
                iapRestoreTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { timer in
                  paymentStatus = .failure

                  // Show Alert for failure of restore
                  isShowingPurchaseAlert.toggle()
                }
              }) {
                if paymentStatus == .ongoing {
                  ProgressView()
                    .tint(Color.white)
                } else {
                  Text(Strings.AIChat.restorePaywallButtonTitle)
                }
              }
              .foregroundColor(.white)
              .disabled(paymentStatus == .ongoing)
            }
            
            ToolbarItemGroup(placement: .cancellationAction) {
              Button(Strings.CancelString) {
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
      .background(
        Color(braveSystemName: .primitivePrimary90)
          .edgesIgnoringSafeArea(.all)
          .overlay(Image("leo-product", bundle: .module),
                   alignment: .topTrailing))
      .alert(isPresented: $isShowingPurchaseAlert) {
        Alert(
          title: Text(Strings.genericErrorTitle),
          message: Text(Strings.AIChat.paywallPurchaseErrorDescription),
          dismissButton: .default(Text(Strings.OKString)))
      }
      .onChange(of: shouldDismiss) { shouldDismiss in
        premiumUpgrageSuccessful?(selectedTierType)
        
        if shouldDismiss {
          presentationMode.dismiss()
        }
      }

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
              Text(Strings.AIChat.paywallYearlySubscriptionTitle)
                .font(.title2.weight(.semibold))
                .foregroundColor(Color(.white))
              
              Text(Strings.AIChat.paywallYearlySubscriptionDescription)
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color(braveSystemName: .green50))
                .padding(4.0)
                .background(Color(braveSystemName: .green20))
                .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
            }
            Spacer()
            
            if let yearlyProduct = storeSDK.leoYearlyProduct {
              HStack(alignment: .center, spacing: 2) {
                Text("\(yearlyProduct.priceFormatStyle.locale.currencyCode ?? "")\(yearlyProduct.priceFormatStyle.locale.currencySymbol ?? "")")
                  .font(.subheadline)
                  .foregroundColor(Color(braveSystemName: .primitivePrimary30))
                
                Text(yearlyProduct.price.frontSymbolCurrencyFormatted(
                  with: yearlyProduct.priceFormatStyle.locale, isSymbolIncluded: false) ?? "$0")
                  .font(.title)
                  .foregroundColor(.white)
                
                Text(" / " + Strings.AIChat.paywallYearlyPriceDividend)
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
            Text(Strings.AIChat.paywallMontlySubscriptionTitle)
              .font(.title2.weight(.semibold))
              .foregroundColor(Color(.white))
            
            Spacer()
            
            if let monthlyProduct = storeSDK.leoMonthlyProduct {
              HStack(alignment: .center, spacing: 2.0) {
                Text("\(monthlyProduct.priceFormatStyle.locale.currencySymbol ?? "")")
                  .font(.subheadline)
                  .foregroundColor(Color(braveSystemName: .primitivePrimary30))
                
                Text(monthlyProduct.price.frontSymbolCurrencyFormatted(
                  with: monthlyProduct.priceFormatStyle.locale, isSymbolIncluded: false) ?? "$0")
                  .font(.title)
                  .foregroundColor(.white)
                
                Text(" / " + Strings.AIChat.paywallMonthlyPriceDividend)
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
      
      Text(Strings.AIChat.paywallPurchaseDeepNote)
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
          paymentStatus = .ongoing
          
          Task {
            do {
              switch selectedTierType {
              case .monthly:
                try await storeSDK.purchase(product: BraveStoreProduct.leoMonthly)
              case .yearly:
                try await storeSDK.purchase(product: BraveStoreProduct.leoYearly)
              }
              
              paymentStatus = .success
              
              Task.delayed(bySeconds: 2.0) { @MainActor in
                shouldDismiss = true
              }
            } catch {
              paymentStatus = .failure
              isShowingPurchaseAlert.toggle()
            }
          }
        }) {
          if paymentStatus == .ongoing {
            ProgressView()
              .tint(Color.white)
          } else {
            Text(Strings.AIChat.paywallPurchaseActionTitle)
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
        .disabled(paymentStatus == .ongoing)
      }
      .padding([.horizontal], 16.0)
    }
  }
}
