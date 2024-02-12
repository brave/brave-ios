// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import BraveCore
import Strings
import DesignSystem
import Preferences
import StoreKit

private class LeoSubscriptionDetail: ObservableObject {
  enum SkuOrderStatus {
    case loading
    case inactive
    case expired
    case active
  }
  
  enum SkuOrderType {
    case notDetermined
    case monthly
    case yearly
  }
  
  @ObservedObject
  private var storeSDK = BraveStoreSDK.shared
  
  @Published
  private(set) var credentialSummary: SkusCredentialSummary?
  
  private var isLoading = true
  
  var skuOrderStatus: SkuOrderStatus {
    if isLoading {
      return .loading
    }
    
    guard let order = credentialSummary?.order else {
      return .inactive
    }
    
    if let expiresAt = order.expiresAt {
      return Date() > expiresAt ? .expired : .active
    }
    
    return .inactive
  }
  
  init() {
    if storeSDK.leoSubscriptionStatus == nil {
      self.fetchOrder()
    }
  }
  
  private func fetchOrder() {
    Task { @MainActor in
      let credentialSummary = try? await BraveSkusSDK(product: .leoMonthly).credentialsSummary()
      
      self.isLoading = false
      
      self.credentialSummary = credentialSummary
    }
  }
  
  var skuOrderExpirationDate: Date? {
    guard let order = credentialSummary?.order, let expiresAt = order.expiresAt else {
      return nil
    }
    
    return expiresAt
  }
  
  var skuOrderProductType: SkuOrderType? {
    // SkusSDK only returns `brave-leo-premium` as the sku for the Order Items
    if skuOrderStatus == .active {
      if credentialSummary?.order.items.first?.sku == "brave-leo-premium" {
        return .monthly
      }
      
      if credentialSummary?.order.items.first?.sku == "brave-leo-premium-year" {
        return .yearly
      }
      
      return .notDetermined
    }
    
    return nil
  }
  
  var inAppPurchasedProductType: BraveStoreProduct? {
    if storeSDK.leoSubscriptionStatus != nil {
      for product in storeSDK.purchasedProducts.all {
        if product.id == BraveStoreProduct.leoMonthly.rawValue {
          return .leoMonthly
        }
        
        if product.id == BraveStoreProduct.leoYearly.rawValue {
          return .leoYearly
        }
      }
    }
    
    return nil
  }
  
  var inAppPurchaseSubscriptionState: Product.SubscriptionInfo.RenewalState? {
    storeSDK.leoSubscriptionStatus?.state
  }
  
  var inAppPurchaseSubscriptionPeriod: StoreKit.Product.SubscriptionPeriod? {
    if storeSDK.leoSubscriptionStatus != nil {
      if let leoMonthlySubscription = storeSDK.leoMonthlyProduct?.subscription?.subscriptionPeriod {
        return leoMonthlySubscription
      }
      
      if let leoYearlySubscription = storeSDK.leoYearlyProduct?.subscription?.subscriptionPeriod {
        return leoYearlySubscription
      }
    }
    
    return nil
  }
  
  var inAppPurchaseSubscriptionEnviroment: BraveStoreEnvironment {
    storeSDK.enviroment
  }
  
  var inAppPurchaseProductsLoaded: Bool {
    storeSDK.isLeoProductsLoaded
  }
  
  var canDisplaySubscriptionStatus: Bool {
    return storeSDK.leoSubscriptionStatus?.state == .subscribed 
      || skuOrderStatus == .active
      || skuOrderStatus == .loading
  }
  
  var canSubscriptionBeLinked: Bool {
    // Check subscription is activated with in-app purchase
    if storeSDK.leoSubscriptionStatus?.state != nil {
      // Order status is active no need to link purchase
      if skuOrderStatus != .loading, skuOrderStatus != .active {
        return true
      }
    }
    
    return false
  }
  
  var isSubscriptionStatusLoading: Bool {
    return storeSDK.leoSubscriptionStatus?.state != nil || credentialSummary != nil
  }
  
  var isDevReceiptLinkingAvailable: Bool {
    storeSDK.enviroment != .production
  }
}

public struct AIChatAdvancedSettingsView: View {
  @Environment(\.presentationMode)
  @Binding private var presentationMode

  @ObservedObject 
  private var aiModel: AIChatViewModel
  
  @ObservedObject
  private var subscriptionDetail: LeoSubscriptionDetail
  
  @State 
  private var appStoreConnectionErrorPresented = false

  @State 
  private var isPaywallPresented = false

  var isModallyPresented: Bool
  
  var openURL: ((URL) -> Void)
  
  public init(aiModel: AIChatViewModel, isModallyPresented: Bool, openURL: @escaping (URL) -> Void) {
    self.aiModel = aiModel
    self.isModallyPresented = isModallyPresented
    self.openURL = openURL
    self.subscriptionDetail = LeoSubscriptionDetail()
  }

  public var body: some View {
    if isModallyPresented {
      NavigationView {
        settingsView
        .navigationTitle("Leo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItemGroup(placement: .cancellationAction) {
            Button("Close") {
              presentationMode.dismiss()
            }
          }
        }
      }
    } else {
      settingsView
        .navigationTitle("Settings")
    }
  }
  
  private var subscriptionMenuTitle: String {
    // Display the info from the AppStore
    if let state = subscriptionDetail.inAppPurchaseSubscriptionState {
      switch state {
      case .subscribed: 
        return "Manage Subscription"
      case .expired, .inBillingRetryPeriod, .inGracePeriod, .revoked:
        return "Go Premium"
      default: 
        return "Go Premium"
      }
    }
    
    // Display the info from SkusSDK
    if subscriptionDetail.skuOrderStatus == .active {
      return "Manage Subscription"
    }
    
    // No order found
    return "Go Premium"
  }
  
  private var subscriptionStatusTitle: String {
    // Display the info from the AppStore
    let inAppPurchaseProductType = subscriptionDetail.inAppPurchasedProductType
    
    switch inAppPurchaseProductType {
    case .leoMonthly:
      return "Monthly Subscription"
    case .leoYearly:
      return "Yearly Subscription"
    default:
      break
    }

    // Display the info from SkusSDK
    let skuProductType = subscriptionDetail.skuOrderProductType
    
    switch skuProductType {
    case .monthly:
      return "Monthly Subscription"
    case .yearly:
      return "Yearly Subscription"
    case .notDetermined:
      return " Premium Subscription"
    default:
      break
    }

    // No order found
    return "None"
  }
  
  private var subscriptionTimeLeftTitle: String {
    let formatSubscriptionPeriod = { (subscription: StoreKit.Product.SubscriptionPeriod) -> String? in
      let plural = subscription.value != 1
      switch subscription.unit {
      case .day:
        return plural ? "\(subscription.value) days" : "day"
      case .week:
        return plural ? "\(subscription.value) weeks" : "week"
      case .month:
        return plural ? "\(subscription.value) months" : "month"
      case .year:
        return plural ? "\(subscription.value) years" : "year"
      @unknown default:
        return nil
      }
    }
    
    if let period = subscriptionDetail.inAppPurchaseSubscriptionPeriod {
      return formatSubscriptionPeriod(period) ?? "N/A"
    }
    
    return "N/A"
  }
  
  private var expirationDateTitle: String {
    let dateFormatter = DateFormatter().then {
      $0.locale = Locale.current
      $0.dateFormat = "MM/dd/yy"
    }
    
    let periodToDate = { (subscription: StoreKit.Product.SubscriptionPeriod) -> Date? in
      let now = Date.now
      if subscription.value == 0 {
        return now
      }
      
      switch subscription.unit {
      case .day:
        return Calendar.current.date(byAdding: .day, value: subscription.value, to: now)
      case .week:
        return Calendar.current.date(byAdding: .weekOfYear, value: subscription.value, to: now)
      case .month:
        return Calendar.current.date(byAdding: .month, value: subscription.value, to: now)
      case .year:
        return Calendar.current.date(byAdding: .year, value: subscription.value, to: now)
      @unknown default:
        return nil
      }
    }
    
    if let period = subscriptionDetail.inAppPurchaseSubscriptionPeriod,
       let date = periodToDate(period) {
      return dateFormatter.string(from: date)
    }
    
    // Display the info from SkusSDK
    if let expiryDate = subscriptionDetail.skuOrderExpirationDate {
      return dateFormatter.string(from: expiryDate)
    }
    
    return "N/A"
  }
  
  @ViewBuilder
  private var settingsView: some View {
    List {
      Section {
        OptionToggleView(
          title: "Show autocomplete suggestions in address bar",
          option: Preferences.AIChat.autocompleteSuggestionsEnabled
        )
        
        NavigationLink {
          AIChatDefaultModelView(
            aiModel: aiModel,
            onModelChanged: { modelKey in
              aiModel.changeModel(modelKey: modelKey)
            })
        } label: {
          LabelView(
            title: "Default model for new conversations",
            subtitle: aiModel.currentModel.displayName
          )
        }.listRowBackground(Color(.secondaryBraveGroupedBackground))
      } header: {
        Text("Leo is an AI-powered smart assistant. built right into the browser")
          .textCase(nil)
      }
      
      Section {
        if subscriptionDetail.canDisplaySubscriptionStatus {
          if subscriptionDetail.isSubscriptionStatusLoading {
            LabelDetailView(title: "Status",
                            detail: subscriptionStatusTitle)
            
            LabelDetailView(title: "Expires",
                            detail: expirationDateTitle)
          } else {
            // Subscription information is loading
            LabelDetailView(title: "Status",
                            detail: nil)
            
            LabelDetailView(title: "Expires",
                            detail: nil)
          }
          
          // Check subscription is activated with in-app purchase
          if subscriptionDetail.canSubscriptionBeLinked {
            Button(action: {
              openURL(.brave.braveLeoLinkReceiptProd)
            }) {
              LabelView(
                title: "Link purchase to your Brave account",
                subtitle: "Link your Appstore purchase to your Brave account to use Leo on other devices."
              )
            }
            
            if subscriptionDetail.isDevReceiptLinkingAvailable {
              Button(action: {
                openURL(.brave.braveLeoLinkReceiptStaging)
              }) {
                LabelView(
                  title: "[Staging] Link receipt"
                )
              }
              
              Button(action: {
                openURL(.brave.braveLeoLinkReceiptDev)
              }) {
                LabelView(
                  title: "[Dev] Link receipt"
                )
              }
            }
            
            Button(action: {
              guard let url = URL.apple.manageSubscriptions else {
                return
              }
              
              // Opens Apple's 'manage subscription' screen
              if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:])
              }
            }) {
              premiumActionView
            }
          }
        } else {
          Button(action: {
            if subscriptionDetail.inAppPurchaseProductsLoaded {
              isPaywallPresented = true
            } else {
              appStoreConnectionErrorPresented = true
            }
          }) {
            premiumActionView
          }
        }
      } header: {
        Text("SUBSCRIPTION")
      }
      .sheet(isPresented: $isPaywallPresented) {
        AIChatPaywallView()
      }
      .alert(isPresented: $appStoreConnectionErrorPresented) {
          Alert(title: Text("App Store Error"), 
                message: Text("Could not connect to Appstore, please try again later."),
                dismissButton: .default(Text("OK")))
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      
      Section {
        Button(action: {
          aiModel.clearAndResetData()
        }) {
          Text("Reset And Clear Leo Data")
            .foregroundColor(Color(.braveBlurpleTint))
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
      }
    }
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .listStyle(.insetGrouped)
  }

  @ViewBuilder
  var premiumActionView: some View {
    HStack {
      LabelView(title: subscriptionMenuTitle)
      Spacer()
      Image(braveSystemName: "leo.launch")
        .foregroundStyle(Color(braveSystemName: .iconDefault))
    }
  }
}
