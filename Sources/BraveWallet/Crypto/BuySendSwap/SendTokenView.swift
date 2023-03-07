// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Strings
import DesignSystem
import BigNumber

struct SendTokenView: View {
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore
  @ObservedObject var sendTokenStore: SendTokenStore

  @State private var isShowingScanner = false
  @State private var isShowingError = false

  @ScaledMetric private var length: CGFloat = 16.0
  
  @Environment(\.appRatingRequestAction) private var appRatingRequest
  @Environment(\.openWalletURLAction) private var openWalletURL
  
  var completion: ((_ success: Bool) -> Void)?
  var onDismiss: () -> Void

  private var isSendDisabled: Bool {
    guard let balance = sendTokenStore.selectedSendTokenBalance,
          let token = sendTokenStore.selectedSendToken,
          !sendTokenStore.isMakingTx,
          !sendTokenStore.sendAddress.isEmpty,
          !sendTokenStore.isResolvingAddress,
          sendTokenStore.addressError == nil,
          sendTokenStore.sendError == nil else {
      return true
    }
    if sendTokenStore.isOffchainResolveRequired {
      // if offchain resolve is required, the send button will show 'Use ENS Domain'
      // and will enable ens offchain, instead of attempting to create send tx.
      return false
    }
    if token.isErc721 || token.isNft {
      return balance < 1
    }
    guard let sendAmount = BDouble(sendTokenStore.sendAmount.normalizedDecimals) else {
      return true
    }
    let weiFormatter = WeiFormatter(decimalFormatStyle: .decimals(precision: Int(token.decimals)))
    if weiFormatter.weiString(from: sendTokenStore.sendAmount.normalizedDecimals, radix: .decimal, decimals: Int(token.decimals)) == nil {
      return true
    }
    return sendAmount == 0 || sendAmount > balance || sendTokenStore.sendAmount.isEmpty
  }
  
  private var sendButtonTitle: String {
    if let error = sendTokenStore.sendError {
      return error.localizedDescription
    } else if sendTokenStore.isOffchainResolveRequired {
      return Strings.Wallet.ensOffchainGatewayButton
    } else {
      return Strings.Wallet.sendCryptoSendButtonTitle
    }
  }

  var body: some View {
    NavigationView {
      Form {
        Section {
          AccountPicker(
            keyringStore: keyringStore,
            networkStore: networkStore
          )
          .listRowBackground(Color(UIColor.braveGroupedBackground))
          .resetListHeaderStyle()
        }
        Section(
          header: WalletListHeaderView(title: Text(Strings.Wallet.sendCryptoFromTitle))
        ) {
          NavigationLink(
            destination:
              SendTokenSearchView(
                sendTokenStore: sendTokenStore,
                network: networkStore.selectedChain
              )
          ) {
            HStack {
              if let token = sendTokenStore.selectedSendToken {
                if token.isErc721 || token.isNft {
                  NFTIconView(
                    token: token,
                    network: networkStore.selectedChain,
                    url: sendTokenStore.selectedSendNFTMetadata?.imageURL,
                    length: 26
                  )
                } else {
                  AssetIconView(
                    token: token,
                    network: networkStore.selectedChain,
                    length: 26
                  )
                }
              }
              Text(sendTokenStore.selectedSendToken?.symbol ?? "")
                .font(.title3.weight(.semibold))
                .foregroundColor(Color(.braveLabel))
              Spacer()
              Text(sendTokenStore.selectedSendTokenBalance?.decimalDescription ?? "0.0000")
                .font(.title3.weight(.semibold))
                .foregroundColor(Color(.braveLabel))
            }
            .padding(.vertical, 8)
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
        if sendTokenStore.selectedSendToken?.isErc721 == false && sendTokenStore.selectedSendToken?.isNft == false {
          Section(
            header:
              WalletListHeaderView(
                title: Text(
                  String.localizedStringWithFormat(
                    Strings.Wallet.sendCryptoAmountTitle,
                    sendTokenStore.selectedSendToken?.symbol ?? "")
                )
              ),
            footer: ShortcutAmountGrid(action: { amount in
              sendTokenStore.suggestedAmountTapped(amount)
            })
            .listRowInsets(.zero)
            .padding(.bottom, 8)
          ) {
            TextField(
              String.localizedStringWithFormat(
                Strings.Wallet.amountInCurrency,
                sendTokenStore.selectedSendToken?.symbol ?? ""),
              text: $sendTokenStore.sendAmount
            )
            .keyboardType(.decimalPad)
            .listRowBackground(Color(.secondaryBraveGroupedBackground))
          }
        }
        Section(
          header: WalletListHeaderView(title: Text(Strings.Wallet.sendCryptoToTitle)),
          footer: Group {
            if let error = sendTokenStore.addressError {
              HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "exclamationmark.circle.fill")
                Text(error.localizedDescription)
                  .fixedSize(horizontal: false, vertical: true)
                  .animation(nil, value: error.localizedDescription)
              }
              .transition(
                .asymmetric(
                  insertion: .opacity.animation(.default),
                  removal: .identity
                )
              )
              .font(.footnote)
              .foregroundColor(Color(.braveErrorLabel))
              .padding(.bottom)
            } else {
              // SwiftUI will add/remove this Section footer when addressError
              // optionality is changed. This can cause keyboard to dismiss.
              // By using clear square, the footer remains and section is not
              // redrawn, so the keyboard does not dismiss as user types.
              Color.clear.frame(width: 1, height: 1)
                .accessibility(hidden: true)
                .transition(.identity)
            }
          }
        ) {
          VStack {
            HStack(spacing: 14.0) {
              TextField(Strings.Wallet.sendToCryptoAddressPlaceholder, text: $sendTokenStore.sendAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
              Button(action: {
                if let string = UIPasteboard.general.string {
                  sendTokenStore.sendAddress = string
                }
              }) {
                Label(Strings.Wallet.pasteFromPasteboard, braveSystemImage: "brave.clipboard")
                  .labelStyle(.iconOnly)
                  .foregroundColor(Color(.primaryButtonTint))
                  .font(.body)
              }
              .buttonStyle(PlainButtonStyle())
              Button(action: {
                isShowingScanner = true
              }) {
                Label(Strings.Wallet.scanQRCodeAccessibilityLabel, braveSystemImage: "brave.qr-code")
                  .labelStyle(.iconOnly)
                  .foregroundColor(Color(.primaryButtonTint))
                  .font(.body)
              }
              .buttonStyle(PlainButtonStyle())
            }
            Group {
              if sendTokenStore.isResolvingAddress {
                ProgressView()
              }
              if sendTokenStore.isOffchainResolveRequired {
                VStack(alignment: .leading, spacing: 8) {
                  Divider()
                  Text(Strings.Wallet.ensOffchainGatewayTitle)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.braveLabel))
                    .fixedSize(horizontal: false, vertical: true)
                  Text(Strings.Wallet.ensOffchainGatewayDesc)
                    .font(.body)
                    .foregroundColor(Color(.secondaryBraveLabel))
                    .fixedSize(horizontal: false, vertical: true)
                  Button(action: {
                    openWalletURL?(WalletConstants.braveWalletENSOffchainURL)
                  }) {
                    Text(Strings.Wallet.learnMoreButton)
                      .foregroundColor(Color(.braveBlurpleTint))
                  }
                }
                .font(.subheadline)
                .padding(.top, 8) // padding between sendAddress & divider
                .frame(maxWidth: .infinity)
              }
              if let resolvedAddress = sendTokenStore.resolvedAddress {
                AddressView(address: resolvedAddress) {
                  Text(resolvedAddress)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(Color(.secondaryBraveLabel))
                }
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
        Section(
          header:
            WalletLoadingButton(
              isLoading: sendTokenStore.isLoading || sendTokenStore.isMakingTx,
              action: {
                if sendTokenStore.isOffchainResolveRequired {
                  sendTokenStore.enableENSOffchainLookup()
                } else {
                  sendTokenStore.sendToken(
                    amount: sendTokenStore.sendAmount
                  ) { success, _ in
                    isShowingError = !success
                    if success {
                      appRatingRequest?()
                    }
                    completion?(success)
                  }
                }
              },
              label: {
                Text(sendButtonTitle)
              }
            )
            .buttonStyle(BraveFilledButtonStyle(size: .normal))
            .disabled(isSendDisabled)
            .frame(maxWidth: .infinity)
            .resetListHeaderStyle()
            .listRowBackground(Color(.clear))
        ) {
        }
      }
      .listBackgroundColor(Color(.braveGroupedBackground))
      .environment(\.defaultMinListHeaderHeight, 0)
      .environment(\.defaultMinListRowHeight, 0)
      .alert(isPresented: $isShowingError) {
        Alert(
          title: Text(""),
          message: Text(Strings.Wallet.sendCryptoSendError),
          dismissButton: .cancel(Text(Strings.OKString))
        )
      }
      .sheet(isPresented: $isShowingScanner) {
        AddressQRCodeScannerView(
          coin: sendTokenStore.selectedSendToken?.coin ?? .eth,
          address: $sendTokenStore.sendAddress
        )
      }
      .navigationTitle(Strings.Wallet.send)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .cancellationAction) {
          Button(action: { onDismiss() }) {
            Text(Strings.cancelButtonTitle)
              .foregroundColor(Color(.braveBlurpleTint))
          }
        }
      }
    }
    .onAppear {
      sendTokenStore.update()
    }
    .navigationViewStyle(.stack)
  }
}

#if DEBUG
struct SendTokenView_Previews: PreviewProvider {
  static var previews: some View {
    SendTokenView(
      keyringStore: .previewStore,
      networkStore: .previewStore,
      sendTokenStore: .previewStore,
      onDismiss: {}
    )
    .previewColorSchemes()
  }
}
#endif
