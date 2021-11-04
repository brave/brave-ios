/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import BraveCore
import BraveUI
import struct Shared.Strings

private struct RroundedBackgroundModifier: ViewModifier {
  @Environment(\.sizeCategory) private var sizeCategory
  
  var backgroundColor: Color = Color(.secondaryBraveGroupedBackground)
  
  private var backgroundShape: some InsettableShape {
    RoundedRectangle(cornerRadius: 10, style: .continuous)
  }
  
  func body(content: Content) -> some View {
    content
      .background(
        backgroundShape
          .fill(backgroundColor)
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
  }
}

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
            .modifier(RroundedBackgroundModifier())
            .padding(.top, 8)
        }
      }
    }
  }
}

struct SlippageGrid: View {
  enum Option: Int, CaseIterable {
    case optionOne = 0
    case optionTwo
    case optionThree
    case other
    
    var value: Double {
      switch self {
      case .optionOne:
        return 0.005
      case .optionTwo:
        return 0.01
      case .optionThree:
        return 0.02
      case .other:
        return 0.0
      }
    }
    
    var index: Int {
      return rawValue
    }
    
    var label: String {
      guard index != 3 else { return "%"}
      
      let nf = NumberFormatter()
      nf.numberStyle = .percent
      nf.maximumFractionDigits = 2
      return nf.string(from: NSNumber(value: value)) ?? ""
    }
  }
  
  var action: (Double) -> Void
  @State private var selectedIndex: Int = 0
  @State private var input = ""
  
  @Environment(\.sizeCategory) private var sizeCategory
  
  private var backgroundShape: some InsettableShape {
    RoundedRectangle(cornerRadius: 10, style: .continuous)
  }
  
  var body: some View {
    HStack(spacing: 8) {
      ForEach(Option.allCases, id: \.rawValue) { option in
        if case .other = option {
          TextField(option.label, text: $input, onEditingChanged: { changed in
            if selectedIndex != option.index && changed {
              selectedIndex = option.index
            }
          })
            .onChange(of: input) { value in
              if selectedIndex == option.index {
                action((Double(value) ?? option.value) / 100)
              }
            }
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .foregroundColor(Color(option.index == selectedIndex ? .white : .secondaryBraveLabel))
            .modifier(RroundedBackgroundModifier(backgroundColor: Color(option.index == selectedIndex ? .braveLighterBlurple : .secondaryBraveGroupedBackground)))
            .padding(.top, 8)
        } else {
          Button(action: {
            if selectedIndex != option.index {
              selectedIndex = option.index
            }
            input = ""
            action(option.value)
            resignFirstResponder()
          }) {
            Text(option.label)
              .lineLimit(1)
              .minimumScaleFactor(0.75)
              .padding(.vertical, 12)
              .frame(maxWidth: .infinity)
              .foregroundColor(Color(option.index == selectedIndex ? .white : .secondaryBraveLabel))
              .modifier(RroundedBackgroundModifier(backgroundColor: Color(option.index == selectedIndex ? .braveLighterBlurple : .secondaryBraveGroupedBackground)))
              .padding(.top, 8)
          }
        }
      }
    }
  }
  
  func resignFirstResponder() {
      UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

struct MarketPriceView: View {
  @ObservedObject var swapTokenStore: SwapTokenStore
  
  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(String.localizedStringWithFormat(Strings.Wallet.swapCryptoMarketPriceTitle, swapTokenStore.selectedFromToken?.symbol ?? ""))
          .foregroundColor(Color(.secondaryBraveLabel))
          .font(.subheadline)
        Text("$\(swapTokenStore.selectedFromTokenPrice ?? 0)")
          .font(.title3.weight(.semibold))
      }
      Spacer()
      Button(action: { }) {
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
  @State var slippage: Double = 0.005
  @State var hideSlippage = true
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  private var isSwapEnable: Bool {
    let selectedChain = ethNetworkStore.selectedChainId
    return selectedChain == BraveWallet.MainnetChainId || selectedChain == BraveWallet.RopstenChainId
  }
  
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
        if isSwapEnable {
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
                Text(String(format: "%.04f", swapTokensStore.selectedFromTokenBalance ?? 0))
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
                Text(String(format: "%.04f", swapTokensStore.selectedToTokenBalance ?? 0))
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
            header: MarketPriceView(swapTokenStore: swapTokensStore)
              .listRowBackground(Color.clear)
              .resetListHeaderStyle()
              .padding(.trailing, 10)
              .padding(.bottom, 15),
            footer: SlippageGrid(action: { value in
              slippage = value
            })
              .listRowInsets(.zero)
              .opacity(hideSlippage ? 0 : 1)
          ) {
            HStack {
              Text(Strings.Wallet.swapCryptoSlippageTitle)
                .font(.subheadline)
              Spacer()
              Text(formatSlippage())
                .foregroundColor(Color(.secondaryBraveLabel))
                .font(.subheadline.weight(.semibold))
              Button(action: {
                hideSlippage.toggle()
              }) {
                Image("wallet-dismiss")
                  .renderingMode(.template)
                  .resizable()
                  .foregroundColor(Color(.secondaryBraveLabel))
                  .frame(width: 12, height: 6)
                  .rotationEffect(Angle.degrees(hideSlippage ? 0 : 180))
                  .animation(.default)
              }
              .buttonStyle(PlainButtonStyle())
            }
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
          Section(
            header:
              Button(action: {}) {
                Text(Strings.Wallet.swapCryptoSwapButtonTitle)
              }
              .buttonStyle(BraveFilledButtonStyle(size: .normal))
              .frame(maxWidth: .infinity)
              .resetListHeaderStyle()
              .padding(.top, hideSlippage ? -20 : 20)
          ) {
          }
        } else {
          Section {
            VStack(alignment: .leading, spacing: 4.0) {
              Text(Strings.Wallet.swapCryptoUnsupportNetworkTitle)
                .font(.headline)
              Text(String.localizedStringWithFormat(Strings.Wallet.swapCryptoUnsupportNetworkDescription, ethNetworkStore.selectedChain.chainName))
                .font(.subheadline)
                .foregroundColor(Color(.secondaryBraveLabel))
            }
            .padding(.vertical, 6.0)
            .listRowBackground(Color(.secondaryBraveGroupedBackground))
          }
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
        swapTokensStore.prepare(with: keyringStore.selectedAccount)
      }
    }
  }
  
  private func formatSlippage() -> String {
    let nf = NumberFormatter()
    nf.numberStyle = .percent
    nf.maximumFractionDigits = 2
    
    return nf.string(from: NSNumber(value: slippage)) ?? ""
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
