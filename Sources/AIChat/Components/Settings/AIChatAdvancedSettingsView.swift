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

public struct AIChatAdvancedSettingsView: View {
  @Environment(\.presentationMode)
  @Binding private var presentationMode
  
  @ObservedObject 
  private var storeSDK = BraveStoreSDK.shared

  @ObservedObject 
  var aiModel: AIChatViewModel
  
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
    
    Task { @MainActor in
      await aiModel.getPremiumStatus()
    }
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
    guard let state = storeSDK.leoSubscriptionStatus?.state else {
      return "Go Premium"
    }
    
    switch state {
    case .subscribed: return "Manage Subscription"
    case .expired, .inBillingRetryPeriod, .inGracePeriod, .revoked: return "Go Premium"
    default: return "Go Premium"
    }
  }
  
  private var subscriptionStatusTitle: String {
    if storeSDK.leoMonthlyProduct != nil {
      return "Monthly Subscription"
    }
    
    if storeSDK.leoYearlyProduct != nil {
      return "Yearly Subscription"
    }
    
    return "Unknown"
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
    
    if let leoMonthlySubscription = storeSDK.leoMonthlyProduct?.subscription?.subscriptionPeriod {
      return formatSubscriptionPeriod(leoMonthlySubscription) ?? "N/A"
    }

    if let leoYearlySubscription = storeSDK.leoYearlyProduct?.subscription?.subscriptionPeriod {
      return formatSubscriptionPeriod(leoYearlySubscription) ?? "N/A"
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
    
    if let leoMonthlySubscription = storeSDK.leoMonthlyProduct?.subscription?.subscriptionPeriod,
       let date = periodToDate(leoMonthlySubscription) {
      return dateFormatter.string(from: date)
    }

    if let leoYearlySubscription = storeSDK.leoYearlyProduct?.subscription?.subscriptionPeriod,
       let date = periodToDate(leoYearlySubscription) {
      return dateFormatter.string(from: date)
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
        if storeSDK.leoSubscriptionStatus?.state == .subscribed {
          LabelDetailView(title: "Status",
                          detail: subscriptionStatusTitle)
          
          LabelDetailView(title: "Expires", 
                          detail: expirationDateTitle)
          
          Button(action: {
            openURL(.brave.braveLeoLinkReceiptProd)
          }) {
            LabelView(
              title: "Link purchase to your Brave account",
              subtitle: "Link your Appstore purchase to your Brave account to use Leo on other devices."
            )
          }
          
          if storeSDK.enviroment != .production {
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
            guard let url = URL.apple.manageSubscriptions else { return }
            if UIApplication.shared.canOpenURL(url) {
              // Opens Apple's 'manage subscription' screen
              UIApplication.shared.open(url, options: [:])
            }
          }) {
            premiumActionView
          }
        } else {
          Button(action: {
            if LeoProductInfo.shared.isComplete {
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
