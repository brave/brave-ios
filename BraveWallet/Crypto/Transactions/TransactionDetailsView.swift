// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import BraveUI
import SwiftUI
import Swift
import struct Shared.Strings

struct TransactionDetailsView: View {
  
  var info: BraveWallet.TransactionInfo
  @ObservedObject var networkStore: NetworkStore
  var visibleTokens: [BraveWallet.BlockchainToken]
  var assetRatios: [String: Double]
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  @Environment(\.openWalletURLAction) private var openWalletURL
  
  private let dateFormatter = DateFormatter().then {
    $0.dateFormat = "h:mm a - MMM d, yyyy"
  }
  
  private let numberFormatter = NumberFormatter().then {
    $0.numberStyle = .currency
    $0.currencyCode = "USD"
  }

  private var value: String {
    let formatter = WeiFormatter(decimalFormatStyle: .balance)
    switch info.txType {
    case .erc20Transfer:
      return info.txArgs[1]
    case .erc721TransferFrom, .erc721SafeTransferFrom:
      return "1" // Can only send 1 erc721 at a time
    case .erc20Approve:
      if info.txArgs.count > 1, let token = visibleTokens.first(where: {
        $0.contractAddress == info.txArgs[0]
      }) {
        return formatter.decimalString(for: info.txArgs[1].removingHexPrefix, radix: .hex, decimals: Int(token.decimals)) ?? ""
      } else {
        return "0.0"
      }
    case .ethSend, .other:
      return formatter.decimalString(for: info.ethTxValue.removingHexPrefix, radix: .hex, decimals: Int(networkStore.selectedChain.decimals)) ?? ""
    @unknown default:
      return "0.0"
    }
  }
  
  private var fiat: String? {
    let formatter = WeiFormatter(decimalFormatStyle: .balance)
    switch info.txType {
    case .erc721TransferFrom, .erc721SafeTransferFrom:
      return nil
    case .erc20Approve:
      return Strings.Wallet.transactionUnknownApprovalTitle
    case .ethSend, .other:
      let amount = formatter.decimalString(for: info.ethTxValue.removingHexPrefix, radix: .hex, decimals: Int(networkStore.selectedChain.decimals)) ?? ""
      let fiat = numberFormatter.string(from: NSNumber(value: assetRatios[networkStore.selectedChain.symbol.lowercased(), default: 0] * (Double(amount) ?? 0))) ?? "$0.00"
      return fiat
    case .erc20Transfer:
      if info.txArgs.count > 1, let token = visibleTokens.first(where: {
        $0.contractAddress.caseInsensitiveCompare(info.ethTxToAddress) == .orderedSame
      }) {
        let amount = formatter.decimalString(for: info.txArgs[1].removingHexPrefix, radix: .hex, decimals: Int(token.decimals)) ?? ""
        let fiat = numberFormatter.string(from: NSNumber(value: assetRatios[token.symbol.lowercased(), default: 0] * (Double(amount) ?? 0))) ?? "$0.00"
        return fiat
      } else {
        return "$0.00"
      }
    @unknown default:
      return nil
    }
  }
  
  private var gasFee: (String, fiat: String)? {
    let isEIP1559Transaction = info.isEIP1559Transaction
    let limit = info.ethTxGasLimit
    let formatter = WeiFormatter(decimalFormatStyle: .gasFee(limit: limit.removingHexPrefix, radix: .hex))
    let hexFee = isEIP1559Transaction ? (info.txDataUnion.ethTxData1559?.maxFeePerGas ?? "") : info.ethTxGasPrice
    if let value = formatter.decimalString(for: hexFee.removingHexPrefix, radix: .hex, decimals: Int(networkStore.selectedChain.decimals)) {
      return (value, {
        guard let doubleValue = Double(value), let assetRatio = assetRatios[networkStore.selectedChain.symbol.lowercased()] else {
          return "$0.00"
        }
        return numberFormatter.string(from: NSNumber(value: doubleValue * assetRatio)) ?? "$0.00"
      }())
    }
    return nil
  }
  
  private var transactionFee: String? {
    guard let (fee, fiat) = gasFee else {
      return nil
    }
    let symbol = networkStore.selectedChain.symbol
    return String(format: "%@ %@\n%@", fee, symbol, fiat)
  }
  
  private var marketPrice: String {
    let symbol = networkStore.selectedChain.symbol
    let marketPrice = numberFormatter.string(from: NSNumber(value: assetRatios[symbol.lowercased(), default: 0])) ?? "$0.00"
    return marketPrice
  }
    
  private var header: some View {
    VStack(spacing: 16) {
      VStack(spacing: 8) {
        if let fiat = fiat {
          Text(fiat)
            .font(.title.weight(.semibold))
            .foregroundColor(Color(.braveLabel))
        }
        Text(String(format: "%@ %@", value, networkStore.selectedChain.symbol))
          .font(.callout.weight(.medium))
          .foregroundColor(Color(.secondaryBraveLabel))
      }
      HStack(spacing: 4) {
        Image(systemName: "circle.fill")
          .foregroundColor(info.txStatus.color)
          .imageScale(.small)
          .accessibilityHidden(true)
        Text(info.txStatus.localizedDescription)
          .foregroundColor(Color(.braveLabel))
          .multilineTextAlignment(.trailing)
      }
      .accessibilityElement(children: .combine)
      .font(.caption.weight(.semibold))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 30)
  }
  
  var body: some View {
    NavigationView {
      List {
        Section(
          header: header
            .textCase(.none)
            .osAvailabilityModifiers { content in
              if #available(iOS 15.0, *) {
                content // Padding already applied
              } else {
                content.padding(.top)
              }
            }
        ) {
          if let transactionFee = transactionFee {
            detailRow(title: Strings.Wallet.transactionDetailsTxFeeTitle, value: transactionFee)
          }
          detailRow(title: Strings.Wallet.transactionDetailsMarketPriceTitle, value: marketPrice)
          detailRow(title: Strings.Wallet.transactionDetailsToAddressTitle, value: info.ethTxToAddress.truncatedAddress)
          detailRow(title: Strings.Wallet.transactionDetailsDateTitle, value: dateFormatter.string(from: info.createdTime))
          detailRow(title: Strings.Wallet.transactionDetailsNetworkTitle, value: networkStore.selectedChain.chainName)
          detailRow(title: Strings.Wallet.transactionDetailsTxHashTitle, value: !info.txHash.isEmpty ? info.txHash.truncatedHash : "***")
        }
        .listRowInsets(.zero)
        if !info.txHash.isEmpty {
          Section {
            Button(action: {
              if let baseURL = self.networkStore.selectedChain.blockExplorerUrls.first.map(URL.init(string:)),
                 let url = baseURL?.appendingPathComponent("tx/\(info.txHash)") {
                openWalletURL?(url)
              }
            }) {
              Text(Strings.Wallet.transactionDetailsViewOnEtherscanTitle)
            }
            .buttonStyle(BraveFilledButtonStyle(size: .large))
            .frame(maxWidth: .infinity)
            .listRowInsets(.zero)
            .listRowBackground(Color(.braveGroupedBackground))
          }
        }
      }
      .listStyle(.insetGrouped)
      .background(Color(.braveGroupedBackground).edgesIgnoringSafeArea(.all))
      .navigationTitle(Strings.Wallet.transactionDetailsTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .confirmationAction) {
          Button(action: { presentationMode.dismiss() }) {
            Text(Strings.done)
              .foregroundColor(Color(.braveOrange))
          }
        }
      }
    }
  }
  
  private func detailRow(title: String, value: String) -> some View {
    HStack {
      Text(title)
      Spacer()
      Text(value)
        .multilineTextAlignment(.trailing)
    }
    .font(.caption)
    .foregroundColor(Color(.braveLabel))
    .padding(.horizontal)
    .padding(.vertical, 13)
    .listRowBackground(Color(.secondaryBraveGroupedBackground))
  }
}

#if DEBUG
struct TransactionDetailsView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      TransactionDetailsView(
        info: .previewConfirmedSend,
        networkStore: .previewStore,
        visibleTokens: [.previewToken],
        assetRatios: ["eth": 4576.36]
      )
        .previewColorSchemes()
      TransactionDetailsView(
        info: .previewConfirmedSwap,
        networkStore: .previewStore,
        visibleTokens: [.previewToken],
        assetRatios: ["eth": 4576.36]
      )
        .previewColorSchemes()
      TransactionDetailsView(
        info: .previewConfirmedERC20Approve, // FIXME: failing to get value / fiat value
        networkStore: .previewStore,
        visibleTokens: [.previewToken],
        assetRatios: ["eth": 4576.36]
      )
        .previewColorSchemes()
    }
  }
}
#endif
