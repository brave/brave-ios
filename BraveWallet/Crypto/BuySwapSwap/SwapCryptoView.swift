/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import BraveCore
import BraveUI
import struct Shared.Strings

struct ShortcutAmountGrid: View {
  enum Amount: Double, CaseIterable {
    case quarter = 0.25
    case half = 0.5
    case threeQuarters = 0.75
    case all = 1.0
    
    var label: String {
      let nf = NumberFormatter()
      nf.numberStyle = .percent
      return nf.string(from: NSNumber(value: rawValue)) ?? ""
    }
  }
  
  var action: (Amount) -> Void
  
  @Environment(\.sizeCategory) private var sizeCategory
  
  private var backgroundShape: some InsettableShape {
    RoundedRectangle(cornerRadius: 10, style: .continuous)
  }
  
  var body: some View {
    HStack(spacing: 8) {
      ForEach(Amount.allCases, id: \.rawValue) { amount in
        Button(action: { action(amount) }) {
          Text(amount.label)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .foregroundColor(Color(.secondaryBraveLabel))
            .background(
              backgroundShape
                .fill(Color(.secondaryBraveGroupedBackground))
                .overlay(
                  // When using an accessibility font size, inset grouped tables automatically change to
                  // grouped tables with separators. So we will match this change and add a border around
                  // the buttons to make them appear more uniform with the table
                  Group {
                    if sizeCategory.isAccessibilityCategory {
                      backgroundShape
                        .strokeBorder(Color(.separator))
                    }
                  }
                )
            )
            .padding(.top, 8)
        }
      }
    }
  }
}

struct MarketPriceView: View {
  @Binding var marketPrice: Double
  
  var refresh: () -> Void
  
  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text("Market Price in ETH")
          .foregroundColor(Color(.secondaryBraveLabel))
          .font(.subheadline)
        Text("0.0005841")
          .font(.title3.weight(.semibold))
      }
      Spacer()
      Button(action: { refresh() }) {
        Image("wallet-refresh")
          .renderingMode(.template)
          .foregroundColor(Color(.braveLighterBlurple))
          .font(.title3)
      }
      .buttonStyle(.plain)
    }
  }
}

struct SwapCryptoView: View {
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var ethNetworkStore: NetworkStore
  @ObservedObject var swapTokensStore: SwapTokenStore
  
  @State private var fromQuantity: String = ""
  @State private var toQuantity: String = ""
  @State private var orderType: OrderType = .market
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  enum OrderType {
    case market
    case limit
  }
  
  var body: some View {
    NavigationView {
      Form {
        Section(
          header: AccountPicker(
            keyringStore: keyringStore,
            networkStore: ethNetworkStore
          )
            .listRowBackground(Color.clear)
            .resetListHeaderStyle()
            .padding(.top)
            .padding(.bottom, -16) // Get it a bit closer
        ) {
        }
        Section(
          header: WalletListHeaderView(title: Text(Strings.Wallet.swapCryptoFromTitle))
        ) {
          NavigationLink(destination: SwapTokenSearchView(swapTokenStore: swapTokensStore, searchType: .fromToken)) {
            HStack {
              if let token = swapTokensStore.selectedFromToken {
                AssetIconView(token: token, length: 26)
              }
              Text(swapTokensStore.selectedFromToken?.symbol ?? "")
                .font(.title3.weight(.semibold))
                .foregroundColor(Color(.braveLabel))
              Spacer()
              Text(verbatim: "1.2832")
                .font(.footnote)
                .foregroundColor(Color(.secondaryBraveLabel))
            }
            .padding(.vertical, 8)
          }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
        Section(
          header: WalletListHeaderView(
            title: Text(String.localizedStringWithFormat(
              Strings.Wallet.swapCryptoAmountTitle,
              swapTokensStore.selectedFromToken?.symbol ?? ""))
          ),
          footer: ShortcutAmountGrid(action: { amount in
            
          })
          .listRowInsets(.zero)
          .padding(.bottom, 8)
        ) {
          TextField(
            String.localizedStringWithFormat(
              Strings.Wallet.swapCryptoAmountPlaceholder,
              swapTokensStore.selectedFromToken?.symbol ?? ""),
            text: $fromQuantity
          )
            .keyboardType(.decimalPad)
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
        Section(
          header: WalletListHeaderView(title: Text(Strings.Wallet.swapCryptoToTitle))
        ) {
          NavigationLink(destination: SwapTokenSearchView(swapTokenStore: swapTokensStore, searchType: .toToken)) {
            HStack {
              if let token = swapTokensStore.selectedToToken {
                AssetIconView(token: token, length: 26)
              }
              Text(swapTokensStore.selectedToToken?.symbol ?? "")
                .font(.title3.weight(.semibold))
                .foregroundColor(Color(.braveLabel))
              Spacer()
              Text(verbatim: "0.0000")
                .font(.footnote)
                .foregroundColor(Color(.secondaryBraveLabel))
            }
            .padding(.vertical, 8)
          }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
        Section(
          header: WalletListHeaderView(
            title: Text(String.localizedStringWithFormat(
              Strings.Wallet.swapCryptoAmountReceivingTitle,
              swapTokensStore.selectedToToken?.symbol ?? ""))
          )
        ) {
          TextField(
            String.localizedStringWithFormat(
              Strings.Wallet.swapCryptoAmountPlaceholder,
              swapTokensStore.selectedToToken?.symbol ?? ""),
            text: $toQuantity
          )
            .keyboardType(.decimalPad)
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
        Section(
          /*
           MVP only supports market price swap. Ref: https://github.com/brave/brave-browser/issues/18307
           */
          /*header: Picker(Strings.Wallet.swapOrderTypeLabel, selection: $orderType) {
            Text(Strings.Wallet.swapMarketOrderType).tag(OrderType.market)
            Text(Strings.Wallet.swapLimitOrderType).tag(OrderType.limit)
          }
            .pickerStyle(SegmentedPickerStyle())
            .resetListHeaderStyle()
            .padding(.bottom, 15)
            .listRowBackground(Color(.clear))*/
          header: MarketPriceView(marketPrice: Binding(projectedValue: .constant(0.0005841)), refresh: {
            // refresh
            })
            .listRowBackground(Color.clear)
            .resetListHeaderStyle()
            .padding(.trailing, 10)
            .padding(.bottom, 15)
        ) {
          NavigationLink(destination: EmptyView()) {
            HStack {
              Text("Slippage tolerance")
                .font(.subheadline)
              Spacer()
              Text("2%")
                .foregroundColor(Color(.secondaryBraveLabel))
                .font(.subheadline.weight(.semibold))
            }
          }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
        Section(
          header:
            Button(action: {}) {
              Text("Swap")
            }
            .buttonStyle(BraveFilledButtonStyle(size: .normal))
            .frame(maxWidth: .infinity)
            .resetListHeaderStyle()
        ) {
        }
      }
      .navigationTitle(Strings.Wallet.swap)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .cancellationAction) {
          Button(action: {
            presentationMode.dismiss()
          }) {
            Text(Strings.CancelString)
              .foregroundColor(Color(.braveOrange))
          }
        }
      }
      .onAppear {
        swapTokensStore.fetchAllTokens()
      }
    }
  }
}

#if DEBUG
struct SwapCryptoView_Previews: PreviewProvider {
  static var previews: some View {
    SwapCryptoView(
      keyringStore: .previewStoreWithWalletCreated,
      ethNetworkStore: .previewStore,
      swapTokensStore: .previewStore
    )
    .previewColorSchemes()
  }
}
#endif
