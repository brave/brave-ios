/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SwiftUI
import BraveCore
import PanModal
import BraveUI
import Strings

struct CryptoTabsView: View {
  private enum Tab: Equatable, Hashable {
    case portfolio
    case activity
    case accounts
    case market
    
    @ViewBuilder var tabLabel: some View {
      switch self {
      case .portfolio:
        Label(Strings.Wallet.portfolioPageTitle, braveSystemImage: "leo.coins")
      case .activity:
        Label(Strings.Wallet.activityPageTitle, braveSystemImage: "leo.activity")
      case .accounts:
        Label(Strings.Wallet.accountsPageTitle, braveSystemImage: "leo.user.accounts")
      case .market:
        Label(Strings.Wallet.marketPageTitle, braveSystemImage: "leo.discover")
      }
    }
  }
  
  @ObservedObject var cryptoStore: CryptoStore
  @ObservedObject var keyringStore: KeyringStore

  @State private var isShowingMainMenu: Bool = false
  @State private var isShowingSettings: Bool = false
  @State private var isShowingSearch: Bool = false
  @State private var fetchedPendingRequestsThisSession: Bool = false
  @State private var selectedTab: Tab = .portfolio
  
  private var isConfirmationButtonVisible: Bool {
    if case .transactions(let txs) = cryptoStore.pendingRequest {
      return !txs.isEmpty
    }
    return cryptoStore.pendingRequest != nil
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      PortfolioView(
        cryptoStore: cryptoStore,
        keyringStore: keyringStore,
        networkStore: cryptoStore.networkStore,
        portfolioStore: cryptoStore.portfolioStore
      )
      .tabItem {
        Tab.portfolio.tabLabel
      }
      .tag(Tab.portfolio)
      
      TransactionsActivityView(
        store: cryptoStore.transactionsActivityStore,
        networkStore: cryptoStore.networkStore
      )
      .tabItem {
        Tab.activity.tabLabel
      }
      .tag(Tab.activity)
      
      AccountsView(
        cryptoStore: cryptoStore,
        keyringStore: keyringStore
      )
      .tabItem {
        Tab.accounts.tabLabel
      }
      .tag(Tab.accounts)
      
      MarketView(
        cryptoStore: cryptoStore,
        keyringStore: keyringStore
      )
      .tabItem {
        Tab.market.tabLabel
      }
      .tag(Tab.market)
    }
    .overlay(alignment: .bottomTrailing, content: {
      if isConfirmationButtonVisible {
        Button(action: {
          cryptoStore.isPresentingPendingRequest = true
        }) {
          Image(braveSystemName: "leo.notification.dot")
            .font(.system(size: 18))
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(
              Color(uiColor: .braveBlurpleTint)
                .clipShape(Circle())
            )
        }
        .accessibilityLabel(Text(Strings.Wallet.confirmTransactionsTitle))
        .padding(.trailing, 16)
        .padding(.bottom, 100)
      }
    })
    .onAppear {
      // If a user chooses not to confirm/reject their requests we shouldn't
      // do it again until they close and re-open wallet
      if !fetchedPendingRequestsThisSession {
        // Give the animation time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          self.fetchedPendingRequestsThisSession = true
          self.cryptoStore.prepare(isInitialOpen: true)
        }
      }
    }
    .ignoresSafeArea()
    .navigationTitle(Strings.Wallet.cryptoTitle)
    .navigationBarTitleDisplayMode(.inline)
    .introspectViewController(customize: { vc in
      vc.navigationItem.do {
        let appearance: UINavigationBarAppearance = {
          let appearance = UINavigationBarAppearance()
          appearance.configureWithOpaqueBackground()
          appearance.titleTextAttributes = [.foregroundColor: UIColor.braveLabel]
          appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.braveLabel]
          appearance.backgroundColor = .braveBackground
          return appearance
        }()
        $0.standardAppearance = appearance
        $0.compactAppearance = appearance
        $0.scrollEdgeAppearance = appearance
      }
    })
    .background(
      NavigationLink(
        destination: Web3SettingsView(
          settingsStore: cryptoStore.settingsStore,
          networkStore: cryptoStore.networkStore,
          keyringStore: keyringStore
        ),
        isActive: $isShowingSettings
      ) {
        Text(Strings.Wallet.settings)
      }
      .hidden()
    )
    .background(
      Color.clear
        .sheet(isPresented: $cryptoStore.isPresentingAssetSearch) {
          AssetSearchView(
            keyringStore: keyringStore,
            cryptoStore: cryptoStore,
            userAssetsStore: cryptoStore.portfolioStore.userAssetsStore
          )
        }
    )
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        Button(action: {
          cryptoStore.isPresentingAssetSearch = true
        }) {
          Label(Strings.Wallet.searchTitle, systemImage: "magnifyingglass")
            .labelStyle(.iconOnly)
            .foregroundColor(Color(.braveBlurpleTint))
        }
        Button(action: { self.isShowingMainMenu = true }) {
          Label(Strings.Wallet.otherWalletActionsAccessibilityTitle, braveSystemImage: "leo.more.horizontal")
            .labelStyle(.iconOnly)
            .foregroundColor(Color(.braveBlurpleTint))
        }
        .accessibilityLabel(Strings.Wallet.otherWalletActionsAccessibilityTitle)
      }
    }
    .sheet(isPresented: $isShowingMainMenu) {
      MainMenuView(
        isFromPortfolio: selectedTab == .portfolio,
        isShowingSettings: $isShowingSettings,
        keyringStore: keyringStore
      )
    }
  }
}
