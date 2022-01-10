// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import BraveUI
import Shared

struct TransactionDetailsView: View {
  var txInfo: BraveWallet.TransactionInfo
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore
  var visibleTokens: [BraveWallet.ERCToken]
  var displayAccountCreator: Bool
  var assetRatios: [String: Double]
  var txDetailsStore: TransactionDetailsStore
  
  @Environment(\.sizeCategory) private var sizeCategory
  @Environment(\.openWalletURLAction) private var openWalletURL

  private var fromAccountName: String {
    NamedAddresses.name(for: txInfo.fromAddress, accounts: keyringStore.keyring.accountInfos)
  }
  
  private var toAccountName: String {
    NamedAddresses.name(for: txInfo.txData.baseData.to, accounts: keyringStore.keyring.accountInfos)
  }
  
  private let numberFormatter = NumberFormatter().then {
    $0.numberStyle = .currency
    $0.currencyCode = "USD"
  }
  
  private let dateFormatter = DateFormatter().then {
    $0.dateFormat = "E, d MMM yyyy HH:mm:ss zzz"
  }
  
  private var txDate: Text {
    let date = Text(txInfo.createdTime, formatter: dateFormatter)
    return date
  }
  
  private var gasFee: (String, fiat: String)? {
    let isEIP1559Transaction = txInfo.isEIP1559Transaction
    let limit = txInfo.txData.baseData.gasLimit
    let formatter = WeiFormatter(decimalFormatStyle: .gasFee(limit: limit.removingHexPrefix, radix: .hex))
    let hexFee = isEIP1559Transaction ? txInfo.txData.maxFeePerGas : txInfo.txData.baseData.gasPrice
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
  
  @ViewBuilder var txDetailsHeader: some View {
    VStack(spacing: 10.0) {
      VStack {
        BlockieGroup(
          fromAddress: txInfo.fromAddress,
          toAddress: txInfo.txData.baseData.to,
          size: 48
        )
        Group {
          if sizeCategory.isAccessibilityCategory {
            VStack {
              Text(fromAccountName)
              Image(systemName: "arrow.down")
              Text(toAccountName)
            }
          } else {
            HStack {
              Text(fromAccountName)
              Image(systemName: "arrow.right")
              Text(toAccountName)
            }
          }
        }
        .foregroundColor(Color(.bravePrimary))
        .font(.callout)
      }
      .accessibilityElement()
      .accessibility(addTraits: .isStaticText)
      .accessibility(
        label: Text(String.localizedStringWithFormat(
          Strings.Wallet.transactionFromToAccessibilityLabel, fromAccountName, toAccountName
        ))
      )
      amount
        .foregroundColor(Color(.bravePrimary))
    }
  }
  
  @ViewBuilder private var amount: some View {
    let formatter = WeiFormatter(decimalFormatStyle: .balance)
    switch txInfo.txType {
    case .erc20Approve:
      if txInfo.txArgs.count > 1, let token = visibleTokens.first(where: {
        $0.contractAddress == txInfo.txArgs[0]
      }) {
        let amount = formatter.decimalString(for: txInfo.txArgs[1].removingHexPrefix, radix: .hex, decimals: Int(token.decimals)) ?? ""
        VStack(spacing: 5.0) {
          Text(Strings.Wallet.transactionDetailsApproved)
            .font(.body)
          Text(String.localizedStringWithFormat(Strings.Wallet.transactionDetailsAmount, amount, token.symbol))
            .font(.title3.weight(.bold))
        }
      } else {
        Text(Strings.Wallet.transactionUnknownApprovalTitle)
      }
    case .ethSend, .other:
      let amount = formatter.decimalString(for: txInfo.txData.baseData.value.removingHexPrefix, radix: .hex, decimals: Int(networkStore.selectedChain.decimals)) ?? ""
      let fiat = numberFormatter.string(from: NSNumber(value: assetRatios[networkStore.selectedChain.symbol.lowercased(), default: 0] * (Double(amount) ?? 0))) ?? "$0.00"
      if txInfo.isSwap {
        VStack(spacing: 5.0) {
          Text(Strings.Wallet.transactionDetailsSwapped)
            .font(.body)
          Text(String.localizedStringWithFormat(Strings.Wallet.transactionDetailsAmount, amount, networkStore.selectedChain.symbol))
            .font(.headline.weight(.bold))
          Text(fiat)
        }
      } else {
        VStack(spacing: 5.0) {
          Text(Strings.Wallet.transactionDetailsSent)
            .font(.body)
          Text(String.localizedStringWithFormat(Strings.Wallet.transactionDetailsAmount, amount, networkStore.selectedChain.symbol))
            .font(.title3.weight(.bold))
          Text(fiat)
            .font(.body)
        }
      }
    case .erc20Transfer:
      if txInfo.txArgs.count > 1, let token = visibleTokens.first(where: {
        $0.contractAddress.caseInsensitiveCompare(txInfo.txData.baseData.to) == .orderedSame
      }) {
        let amount = formatter.decimalString(for: txInfo.txArgs[1].removingHexPrefix, radix: .hex, decimals: Int(token.decimals)) ?? ""
        let fiat = numberFormatter.string(from: NSNumber(value: assetRatios[token.symbol.lowercased(), default: 0] * (Double(amount) ?? 0))) ?? "$0.00"
        VStack(spacing: 5.0) {
          Text(Strings.Wallet.transactionDetailsSent)
            .font(.body)
          Text(String.localizedStringWithFormat(Strings.Wallet.transactionDetailsAmount, amount, token.symbol))
            .font(.title3.weight(.bold))
          Text(fiat)
            .font(.body)
        }
      } else {
        Text(Strings.Wallet.send)
      }
    case .erc721TransferFrom, .erc721SafeTransferFrom:
      if let token = visibleTokens.first(where: {
        $0.contractAddress.caseInsensitiveCompare(txInfo.txData.baseData.to) == .orderedSame
      }) {
        Text(String.localizedStringWithFormat(Strings.Wallet.transactionUnknownSendTitle, token.symbol))
      } else {
        Text(Strings.Wallet.send)
      }
    @unknown default:
      EmptyView()
    }
  }
  
  var body: some View {
    List {
      Section {
        txDetailsHeader
          .frame(maxWidth: .infinity)
          .listRowInsets(.zero)
          .listRowBackground(Color(.braveGroupedBackground))
      }
      Section {
        Group {
          HStack {
            Text(Strings.Wallet.transactionDetailsTxFee)
              .fontWeight(.bold)
              .foregroundColor(Color(.bravePrimary))
            Spacer()
            if let (fee, fiat) = gasFee {
              VStack(alignment: .trailing) {
                Text("\(fee) ETH")
                Text(fiat)
              }
              .accessibilityElement(children: .combine)
              .multilineTextAlignment(.trailing)
              .foregroundColor(Color(.braveLabel))
            }
          }
          HStack {
            Text(Strings.Wallet.transactionDetailsTxDate)
              .fontWeight(.bold)
              .foregroundColor(Color(.bravePrimary))
            Spacer()
            txDate
              .foregroundColor(Color(.braveLabel))
          }
          if txInfo.txStatus != .rejected {
            HStack {
              Text(Strings.Wallet.transactionDetailsTxHash)
                .fontWeight(.bold)
                .foregroundColor(Color(.bravePrimary))
              Spacer()
              Button(
                action: {
                  if txInfo.txStatus != .error, let baseURL = self.networkStore.selectedChain.blockExplorerUrls.first.map(URL.init(string:)),
                     let url = baseURL?.appendingPathComponent("tx/\(txInfo.txHash)") {
                    openWalletURL?(url)
                  }
                }
              ) {
                Text(txInfo.txHash.truncatedAddress)
                  .foregroundColor(Color(.braveBlurpleTint))
                  .multilineTextAlignment(.trailing)
              }
            }
          }
          HStack {
            Text(Strings.Wallet.transactionDetailsTxNetwork)
              .fontWeight(.bold)
              .foregroundColor(Color(.bravePrimary))
            Spacer()
            Text(networkStore.selectedChain.chainName)
              .foregroundColor(Color(.braveLabel))
          }
          HStack {
            Text(Strings.Wallet.transactionDetailsTxStatus)
              .fontWeight(.bold)
              .foregroundColor(Color(.bravePrimary))
            Spacer()
            HStack(spacing: 4) {
              Image(systemName: "circle.fill")
                .foregroundColor(txInfo.txStatus.color)
                .imageScale(.small)
                .accessibilityHidden(true)
              Text(txInfo.txStatus.localizedDescription)
                .fontWeight(.bold)
                .foregroundColor(Color(.braveLabel))
                .multilineTextAlignment(.trailing)
            }
          }
        }
        .font(.callout)
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      if txInfo.txStatus == .submitted || txInfo.txStatus == .approved {
        Section(
          header:
            HStack {
              WalletLoadingButton(
                isLoading: txDetailsStore.isLoading,
                action: {
                  txDetailsStore.speedUpTx(txMetaId: txInfo.id)
                },
                label: {
                  Text(Strings.Wallet.transactionDetailsSpeedUp)
                }
              )
                .disabled(txDetailsStore.isLoading)
                .buttonStyle(BraveFilledButtonStyle(size: sizeCategory.isAccessibilityCategory ? .small : .large))
                .frame(maxWidth: .infinity)
              WalletLoadingButton(
                isLoading: txDetailsStore.isLoading,
                action: {
                  txDetailsStore.cancelTx(txMetaId: txInfo.id)
                },
                label: {
                  Text(Strings.cancelButtonTitle)
                }
              )
                .disabled(txDetailsStore.isLoading)
                .buttonStyle(BraveFilledButtonStyle(size: sizeCategory.isAccessibilityCategory ? .small : .large))
                .frame(maxWidth: .infinity)
            }
            .resetListHeaderStyle()
            .padding(.top)
        ) {
        }
      } else if txInfo.txStatus == .error {
        Section(
          header:
            WalletLoadingButton(
              isLoading: txDetailsStore.isLoading,
              action: {
                txDetailsStore.cancelTx(txMetaId: txInfo.id)
              },
              label: {
                Text(Strings.Wallet.transactionDetailsRetry)
              }
            )
            .disabled(txDetailsStore.isLoading)
            .buttonStyle(BraveFilledButtonStyle(size: sizeCategory.isAccessibilityCategory ? .small : .large))
            .resetListHeaderStyle()
            .frame(maxWidth: .infinity)
            .padding(.top)
        ) {
        }
      }
    }
    .navigationBarTitle(Strings.Wallet.transactionDetailsNavTitle)
  }
}

#if DEBUG
struct TransactionDetailsView_Previews: PreviewProvider {
  static var previews: some View {
    TransactionDetailsView(
      txInfo: BraveWallet.TransactionInfo.previewSubmittedERC20Approve,
      keyringStore: .previewStoreWithWalletCreated,
      networkStore: .previewStore,
      visibleTokens: [.eth],
      displayAccountCreator: false,
      assetRatios: ["eth": 4576.36],
      txDetailsStore: .previewStore
    )
      .previewSizeCategories()
  }
}
#endif
