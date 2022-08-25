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

struct AssetDetailView: View {
  @ObservedObject var assetDetailStore: AssetDetailStore
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore

  @State private var tableInset: CGFloat = -16.0
  @State private var isShowingAddAccount: Bool = false
  @State private var transactionDetails: TransactionDetailsStore?
  @State private var isShowingAuroraBridgeAlert: Bool = false

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
    .listStyle(InsetGroupedListStyle())
    .navigationTitle(assetDetailStore.token.name)
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      assetDetailStore.update()
    }
    .introspectTableView { tableView in
      tableInset = -tableView.layoutMargins.left
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
          if proceed {
            openWalletURL?(WalletConstants.auroraBridgeLink)
          }
          return true
        },
        content: {
          VStack {
            Text(Strings.Wallet.auroraBridgeAlertTitle)
              .font(.headline.weight(.bold))
              .multilineTextAlignment(.center)
              .padding(.vertical)
            VStack(alignment: .leading) {
              Text(Strings.Wallet.auroraBridgeAlertDescription)
                .font(.subheadline)
              Button(action: {
                isShowingAuroraBridgeAlert = false
                openWalletURL?(WalletConstants.auroraBridgeRiskLink)
              }) {
                Text(Strings.Wallet.learnMoreButton)
                  .font(.subheadline)
                  .foregroundColor(Color(.braveBlurpleTint))
              }
            }
          }
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
