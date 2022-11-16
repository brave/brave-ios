/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SwiftUI
import BraveCore
import DesignSystem
import Strings
import BraveShared
import BraveUI
import Introspect

struct AssetDetailView: View {
  @ObservedObject var assetDetailStore: AssetDetailStore
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore

  @State private var tableInset: CGFloat = -16.0
  @State private var isShowingAddAccount: Bool = false
  @State private var transactionDetails: TransactionDetailsStore?
  @State private var isShowingAuroraBridgeAlert: Bool = false
  
  @Environment(\.sizeCategory) private var sizeCategory
  /// Reference to the collection view used to back the `List` on iOS 16+
  @State private var collectionView: UICollectionView?

  @Environment(\.buySendSwapDestination)
  private var buySendSwapDestination: Binding<BuySendSwapDestination?>

  @Environment(\.openWalletURLAction) private var openWalletURL

  var body: some View {
    List {
      Section(
        header: AssetDetailHeaderView(
          assetDetailStore: assetDetailStore,
          keyringStore: keyringStore,
          networkStore: networkStore,
          buySendSwapDestination: buySendSwapDestination,
          isShowingBridgeAlert: $isShowingAuroraBridgeAlert
        )
        .resetListHeaderStyle()
        .padding(.horizontal, tableInset)  // inset grouped layout margins workaround
      ) {
      }
      Section(
        header: WalletListHeaderView(title: Text(Strings.Wallet.accountsPageTitle)),
        footer: Button(action: {
          isShowingAddAccount = true
        }) {
          Text(Strings.Wallet.addAccountTitle)
        }
        .listRowInsets(.zero)
        .buttonStyle(BraveOutlineButtonStyle(size: .small))
        .padding(.vertical, 8)
      ) {
        Group {
          if assetDetailStore.accounts.isEmpty {
            Text(Strings.Wallet.noAccounts)
              .redacted(reason: assetDetailStore.isLoadingAccountBalances ? .placeholder : [])
              .shimmer(assetDetailStore.isLoadingAccountBalances)
              .font(.footnote)
          } else {
            ForEach(assetDetailStore.accounts) { viewModel in
              HStack {
                AddressView(address: viewModel.account.address) {
                  AccountView(address: viewModel.account.address, name: viewModel.account.name)
                }
                let showFiatPlaceholder = viewModel.fiatBalance.isEmpty && assetDetailStore.isLoadingPrice
                let showBalancePlaceholder = viewModel.balance.isEmpty && assetDetailStore.isLoadingAccountBalances
                if assetDetailStore.token.isNft || assetDetailStore.token.isErc721 {
                  Text(showBalancePlaceholder ? "0 \(assetDetailStore.token.symbol)" : "\(viewModel.balance) \(assetDetailStore.token.symbol)")
                    .redacted(reason: showBalancePlaceholder ? .placeholder : [])
                    .shimmer(assetDetailStore.isLoadingAccountBalances)
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryBraveLabel))
                } else {
                  VStack(alignment: .trailing) {
                    Text(showFiatPlaceholder ? "$0.00" : viewModel.fiatBalance)
                      .redacted(reason: showFiatPlaceholder ? .placeholder : [])
                      .shimmer(assetDetailStore.isLoadingPrice)
                    Text(showBalancePlaceholder ? "0.0000 \(assetDetailStore.token.symbol)" : "\(viewModel.balance) \(assetDetailStore.token.symbol)")
                      .redacted(reason: showBalancePlaceholder ? .placeholder : [])
                      .shimmer(assetDetailStore.isLoadingAccountBalances)
                  }
                  .font(.footnote)
                  .foregroundColor(Color(.secondaryBraveLabel))
                }
              }
            }
          }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
      }
      Section(
        header: WalletListHeaderView(title: Text(Strings.Wallet.transactionsTitle))
      ) {
        Group {
          if assetDetailStore.transactionSummaries.isEmpty {
            Text(Strings.Wallet.noTransactions)
              .font(.footnote)
          } else {
            ForEach(assetDetailStore.transactionSummaries) { txSummary in
              Button(action: {
                self.transactionDetails = assetDetailStore.transactionDetailsStore(for: txSummary.txInfo)
              }) {
                TransactionSummaryView(summary: txSummary, displayAccountCreator: true)
              }
              .contextMenu {
                if !txSummary.txHash.isEmpty {
                  Button(action: {
                    if let baseURL = self.networkStore.selectedChain.blockExplorerUrls.first.map(URL.init(string:)),
                       let url = baseURL?.appendingPathComponent("tx/\(txSummary.txHash)") {
                      openWalletURL?(url)
                    }
                  }) {
                    Label(Strings.Wallet.viewOnBlockExplorer, systemImage: "arrow.up.forward.square")
                  }
                }
              }
            }
          }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
      }
      if !assetDetailStore.token.isNft && !assetDetailStore.token.isErc721 {
        Section {
          EmptyView()
        } header: {
          Text(Strings.Wallet.coinGeckoDisclaimer)
            .multilineTextAlignment(.center)
            .font(.footnote)
            .foregroundColor(Color(.secondaryBraveLabel))
            .frame(maxWidth: .infinity)
            .listRowBackground(Color(.braveGroupedBackground))
            .resetListHeaderStyle(insets: nil)
        }
      }
    }
    .listStyle(InsetGroupedListStyle())
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .navigationTitle(assetDetailStore.token.name)
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      assetDetailStore.update()
    }
    .introspectTableView { tableView in
      tableInset = -tableView.layoutMargins.left
    }
    .onChange(of: sizeCategory) { _ in
      // Fix broken header when text size changes on iOS 16+
      collectionView?.collectionViewLayout.invalidateLayout()
    }
    .introspect(
      selector: TargetViewSelector.ancestorOrSiblingContaining
    ) { (collectionView: UICollectionView) in
      self.collectionView = collectionView
    }
    .background(
      Color.clear
        .sheet(isPresented: $isShowingAddAccount) {
          NavigationView {
            AddAccountView(keyringStore: keyringStore)
          }
          .navigationViewStyle(StackNavigationViewStyle())
        }
    )
    .background(
      Color.clear
        .sheet(
          isPresented: Binding(
            get: { self.transactionDetails != nil },
            set: { if !$0 { self.transactionDetails = nil } }
          )
        ) {
          if let transactionDetailsStore = transactionDetails {
            TransactionDetailsView(
              transactionDetailsStore: transactionDetailsStore,
              networkStore: networkStore
            )
          }
        }
    )
    .background(
      WalletPromptView(
        isPresented: $isShowingAuroraBridgeAlert,
        buttonTitle: Strings.Wallet.auroraBridgeButtonTitle,
        action: { proceed, _ in
          isShowingAuroraBridgeAlert = false
          if proceed, let link = WalletConstants.auroraBridgeLink {
            openWalletURL?(link)
          }
          return true
        },
        content: {
          VStack(spacing: 10) {
            Text(Strings.Wallet.auroraBridgeAlertTitle)
              .font(.headline.weight(.bold))
              .multilineTextAlignment(.center)
              .padding(.vertical)
            Text(Strings.Wallet.auroraBridgeAlertDescription)
              .multilineTextAlignment(.center)
              .font(.subheadline)
          }
        },
        footer: {
          VStack(spacing: 8) {
            Button(action: {
              isShowingAuroraBridgeAlert = false
              Preferences.Wallet.showAuroraPopup.value = false
            }) {
              Text(Strings.Wallet.auroraPopupDontShowAgain)
                .foregroundColor(Color(.braveLabel))
                .font(.callout.weight(.semibold))
            }
            Button {
              isShowingAuroraBridgeAlert = false
              if let link = WalletConstants.auroraBridgeOverviewLink {
                openWalletURL?(link)
              }
            } label: {
              Text(Strings.Wallet.auroraBridgeLearnMore)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.braveBlurpleTint))
                .font(.subheadline)
            }
            Button {
              isShowingAuroraBridgeAlert = false
              if let link = WalletConstants.auroraBridgeRiskLink {
                openWalletURL?(link)
              }
            } label: {
              Text(Strings.Wallet.auroraBridgeRisk)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.braveBlurpleTint))
                .font(.subheadline)
            }
          }
          .padding(.top, 16)
        }
      )
    )
    .onChange(of: keyringStore.defaultKeyring) { newValue in
      if newValue.isLocked, isShowingAuroraBridgeAlert {
        isShowingAuroraBridgeAlert = false
      }
    }
  }
}

#if DEBUG
struct CurrencyDetailView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      AssetDetailView(
        assetDetailStore: .previewStore,
        keyringStore: .previewStore,
        networkStore: .previewStore
      )
      .navigationBarTitleDisplayMode(.inline)
    }
    .previewColorSchemes()
  }
}
#endif
