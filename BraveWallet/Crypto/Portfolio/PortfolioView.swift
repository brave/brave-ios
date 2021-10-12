/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SwiftUI
import BraveCore
import SnapKit
import struct Shared.Strings

struct Currency {
  var image: UIImage
  var name: String
  var symbol: String
  var cost: Double
}

struct Candle: DataPoint, Equatable {
  var value: CGFloat
}

struct PortfolioView: View {
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore
  @ObservedObject var portfolioStore: PortfolioStore
  
  @State private var dismissedBackupBannerThisSession: Bool = false
  @State private var isPresentingBackup: Bool = false
  @State private var isPresentingEditUserAssets: Bool = false
  
  private var isShowingBackupBanner: Bool {
    !keyringStore.keyring.isBackedUp && !dismissedBackupBannerThisSession
  }
  
  private var listHeader: some View {
    VStack(spacing: 0) {
      if isShowingBackupBanner {
        BackupNotifyView(action: {
          isPresentingBackup = true
        }, onDismiss: {
          // Animating this doesn't seem to work in SwiftUI.. will keep an eye out for iOS 15
          dismissedBackupBannerThisSession = true
        })
        .buttonStyle(PlainButtonStyle())
        .padding([.top, .leading, .trailing], 12)
        .sheet(isPresented: $isPresentingBackup) {
          NavigationView {
            BackupRecoveryPhraseView(keyringStore: keyringStore)
          }
          .environment(\.modalPresentationMode, $isPresentingBackup)
        }
      }
      BalanceHeaderView(
        balance: "$12,453.17",
        networkStore: networkStore,
        selectedDateRange: $portfolioStore.timeframe
      )
    }
  }
  
  var body: some View {
    List {
      Section(
        header: listHeader
          .padding(.horizontal, -16) // inset grouped layout margins workaround
          .resetListHeaderStyle()
      ) {
      }
      Section(
        header: WalletListHeaderView(title: Text(Strings.Wallet.assetsTitle))
      ) {
        ForEach(portfolioStore.userVisibleAssets) { asset in
          PortfolioAssetView(
            image: .init(),
            title: asset.token.name,
            symbol: asset.token.symbol,
            amount: asset.balance,
            quantity: asset.price
          )
        }
        Button(action: { isPresentingEditUserAssets = true }) {
          Text(Strings.Wallet.editVisibleAssetsButtonTitle)
            .multilineTextAlignment(.center)
            .font(.footnote.weight(.semibold))
            .foregroundColor(Color(.bravePrimary))
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $isPresentingEditUserAssets) {
          EditUserAssetsView(userAssetsStore: portfolioStore.userAssetsStore) {
            portfolioStore.update()
          }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
    }
    .animation(.default, value: portfolioStore.userVisibleAssets)
    .listStyle(InsetGroupedListStyle())
  }
}

struct BalanceHeaderView: View {
  var balance: String
  @ObservedObject var networkStore: NetworkStore
  @Binding var selectedDateRange: BraveWallet.AssetPriceTimeframe
  
  @Environment(\.sizeCategory) private var sizeCategory
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  
  @State private var selectedCandle: Candle?
  
  var data: [Candle] {
    switch selectedDateRange {
    case .oneDay:
      return [10, 20, 30, 20, 10, 40, 50, 80, 100].map(Candle.init)
    case .live:
      return [10, 20, 30, 20, 10, 40, 50, 80, 100].map(Candle.init).reversed()
    case .oneWeek:
      return [10, 20, 30, 20, 10].map(Candle.init)
    case .oneMonth:
      return [10, 20, 30, 20, 10, 40, 50, 80, 100, 200, 100, 120].map(Candle.init)
    case .threeMonths:
      return [10, 20, 30, 20, 10, 40, 50, 80, 100].map(Candle.init)
    case .oneYear:
      return [10, 20, 30, 20, 10, 40, 50, 80, 100].map(Candle.init)
    case .all:
      return [10, 20, 30, 20, 10, 40, 50, 80, 100].map(Candle.init)
    @unknown default:
      return [10, 20, 30, 20, 10, 40, 50, 80, 100].map(Candle.init)
    }
  }
  
  private var balanceOrDataPointView: some View {
    HStack {
      if let dataPoint = selectedCandle {
        Text(verbatim: "\(dataPoint.value)")
      } else {
        if sizeCategory.isAccessibilityCategory {
          VStack(alignment: .leading) {
            NetworkPicker(
              networks: networkStore.ethereumChains,
              selectedNetwork: networkStore.selectedChainBinding
            )
            Text(verbatim: balance)
          }
        } else {
          HStack {
            Text(verbatim: balance)
            NetworkPicker(
              networks: networkStore.ethereumChains,
              selectedNetwork: networkStore.selectedChainBinding
            )
            Spacer()
          }
        }
      }
      if horizontalSizeClass == .regular {
        Spacer()
        DateRangeView(selectedRange: $selectedDateRange)
          .padding(6)
          .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .strokeBorder(Color(.secondaryButtonTint))
          )
      }
    }
    .font(.largeTitle.bold())
    .foregroundColor(.primary)
    .padding(.top, 12)
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      balanceOrDataPointView
      HStack(spacing: 4) {
        Image(systemName: "triangle.fill")
          .font(.system(size: 8))
          .foregroundColor(.green)
        Text(verbatim: "1.3%")
          .foregroundColor(.green)
        Text(Strings.Wallet.today)
          .foregroundColor(.secondary)
      }
      .font(.subheadline)
      .frame(maxWidth: .infinity, alignment: .leading)
      LineChartView(data: data, numberOfColumns: 12, selectedDataPoint: $selectedCandle) {
        LinearGradient(braveGradient: .lightGradient02)
      }
      .frame(height: 148)
      .padding(.horizontal, -12)
      .animation(.default, value: data)
      if horizontalSizeClass == .compact {
        DateRangeView(selectedRange: $selectedDateRange)
      }
    }
    .padding(12)
  }
}

#if DEBUG
struct PortfolioViewController_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      PortfolioView(
        keyringStore: WalletStore.previewStore.keyringStore,
        networkStore: WalletStore.previewStore.networkStore,
        portfolioStore: WalletStore.previewStore.portfolioStore
      )
      .navigationBarTitleDisplayMode(.inline)
    }
      .previewColorSchemes()
  }
}
#endif
