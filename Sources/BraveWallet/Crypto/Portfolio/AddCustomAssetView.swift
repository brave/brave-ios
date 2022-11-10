// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import Strings
import BraveUI

struct AddCustomAssetView: View {
  @ObservedObject var networkStore: NetworkStore
  var keyringStore: KeyringStore
  @ObservedObject var userAssetStore: UserAssetsStore
  @Environment(\.presentationMode) @Binding private var presentationMode

  enum TokenType: Int, Identifiable, CaseIterable {
    case token
    case nft
    
    var id: Self { self }
    
    var title: String {
      switch self {
      case .token:
        return Strings.Wallet.addCustomTokenTitle
      case .nft:
        return Strings.Wallet.addCustomNFTTitle
      }
    }
  }
  
  @State private var selectedNetwork: BraveWallet.NetworkInfo?
  @State private var networkSelectionStore: NetworkSelectionStore?
  @State private var selectedTokenType: TokenType = .token
  @State private var nameInput = ""
  @State private var addressInput = ""
  @State private var symbolInput = ""
  @State private var decimalsInput = ""
  @State private var tokenId = ""
  @State private var logo = ""
  @State private var coingeckoId = ""
  @State private var showError = false
  @State private var showAdvanced = false
  
  private var addButtonDisabled: Bool {
    switch selectedTokenType {
    case .token:
      return nameInput.isEmpty || symbolInput.isEmpty || decimalsInput.isEmpty || addressInput.isEmpty || selectedNetwork == nil || (selectedNetwork?.coin != .sol && !addressInput.isETHAddress)
    case .nft:
      return nameInput.isEmpty || symbolInput.isEmpty || (selectedNetwork?.coin != .sol && tokenId.isEmpty) || addressInput.isEmpty || selectedNetwork == nil || (selectedNetwork?.coin != .sol && !addressInput.isETHAddress)
    }
  }
  
  private var showTokenID: Bool {
    if let customAssetNetwork = selectedNetwork, customAssetNetwork.coin == .sol {
      return false
    }
    return true
  }

  var body: some View {
    NavigationView {
      Form {
        Section {
        } header: {
          Picker("", selection: $selectedTokenType) {
            ForEach(TokenType.allCases) { type in
              Text(type.title)
            }
          }
          .pickerStyle(.segmented)
        }
        Section(
          header: WalletListHeaderView(title: Text(Strings.Wallet.customTokenNetworkHeader))
        ) {
          HStack {
            Button(action: {
              networkSelectionStore = .init(mode: .formSelection, networkStore: networkStore)
            }) {
              Text(selectedNetwork?.chainName ?? Strings.Wallet.customTokenNetworkButtonTitle)
                .foregroundColor(selectedNetwork == nil ? .gray.opacity(0.6) : Color(.braveLabel))
            }
            Spacer()
            Image(systemName: "chevron.down.circle")
              .foregroundColor(Color(.braveBlurple))
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
        Section(
          header: WalletListHeaderView(title: Text(Strings.Wallet.tokenName))
        ) {
          HStack {
            TextField(Strings.Wallet.enterTokenName, text: $nameInput)
              .autocapitalization(.none)
              .autocorrectionDisabled()
              .disabled(userAssetStore.isSearchingToken)
            if userAssetStore.isSearchingToken && nameInput.isEmpty {
              ProgressView()
            }
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
        Section(
          header: WalletListHeaderView(title: Text(Strings.Wallet.tokenAddress))
        ) {
          TextField(Strings.Wallet.enterAddress, text: $addressInput)
            .onChange(of: addressInput) { newValue in
              if !newValue.isEmpty, newValue.isETHAddress {
                userAssetStore.tokenInfo(by: newValue) { token in
                  if let token = token {
                    if nameInput.isEmpty {
                      nameInput = token.name
                    }
                    if symbolInput.isEmpty {
                      symbolInput = token.symbol
                    }
                    if !token.isErc721 {
                      if decimalsInput.isEmpty {
                        decimalsInput = "\(token.decimals)"
                      }
                    }
                  }
                }
              }
            }
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .disabled(userAssetStore.isSearchingToken)
            .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
        Section(
          header: WalletListHeaderView(title: Text(Strings.Wallet.tokenSymbol))
        ) {
          HStack {
            TextField(Strings.Wallet.enterTokenSymbol, text: $symbolInput)
              .autocapitalization(.none)
              .autocorrectionDisabled()
              .disabled(userAssetStore.isSearchingToken)
            if userAssetStore.isSearchingToken && symbolInput.isEmpty {
              ProgressView()
            }
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
        switch selectedTokenType {
        case .token:
          Section(
            header: WalletListHeaderView(title: Text(Strings.Wallet.decimalsPrecision))
          ) {
            HStack {
              TextField(NumberFormatter().string(from: NSNumber(value: 0)) ?? "0", text: $decimalsInput)
                .keyboardType(.numberPad)
                .disabled(userAssetStore.isSearchingToken)
              if userAssetStore.isSearchingToken && decimalsInput.isEmpty {
                ProgressView()
              }
            }
            .listRowBackground(Color(.secondaryBraveGroupedBackground))
          }
          Section {
            Button(
              action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                  showAdvanced.toggle()
                }
              }
            ) {
              VStack {
                HStack {
                  Text(Strings.Wallet.addCustomTokenAdvanced)
                    .foregroundColor(.gray)
                  Spacer()
                  Image("wallet-dismiss", bundle: .module)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundColor(Color(.secondaryBraveLabel))
                    .frame(width: 12, height: 6)
                    .rotationEffect(.degrees(showAdvanced ? 180 : 0))
                    .animation(.default, value: showAdvanced)
                }
                .contentShape(Rectangle())
                Divider()
              }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Strings.Wallet.addCustomTokenAdvanced)
            .accessibility(addTraits: .isButton)
            .listRowBackground(Color(UIColor.braveGroupedBackground))
            .resetListHeaderStyle()
          }
          if showAdvanced {
            Section(
              header: WalletListHeaderView(title: Text(Strings.Wallet.addCustomTokenIconURL))
            ) {
              HStack {
                TextField(Strings.Wallet.enterTokenIconURL, text: $logo)
                  .autocapitalization(.none)
                  .autocorrectionDisabled()
              }
              .listRowBackground(Color(.secondaryBraveGroupedBackground))
            }
            Section(
              header: WalletListHeaderView(title: Text(Strings.Wallet.addCustomTokenCoingeckoId))
            ) {
              HStack {
                TextField(Strings.Wallet.enterTokenCoingeckoId, text: $coingeckoId)
                  .autocapitalization(.none)
                  .autocorrectionDisabled()
              }
              .listRowBackground(Color(.secondaryBraveGroupedBackground))
            }
          }
        case .nft:
          if showTokenID {
            Section(
              header: WalletListHeaderView(title: Text(Strings.Wallet.addCustomTokenId))
            ) {
              HStack {
                TextField(Strings.Wallet.enterTokenId, text: $tokenId)
                  .keyboardType(.numberPad)
              }
              .listRowBackground(Color(.secondaryBraveGroupedBackground))
            }
          }
        }
      }
      .listBackgroundColor(Color(UIColor.braveGroupedBackground))
      .onChange(of: selectedTokenType, perform: { _ in
        resignFirstResponder()
        clearInput()
      })
      .navigationTitle(Strings.Wallet.customTokenTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .cancellationAction) {
          Button(action: {
            presentationMode.dismiss()
          }) {
            Text(Strings.cancelButtonTitle)
              .foregroundColor(Color(.braveOrange))
          }
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button(action: {
            resignFirstResponder()
            addCustomToken()
          }) {
            Text(Strings.Wallet.add)
              .foregroundColor(Color(.braveOrange))
          }
          .disabled(addButtonDisabled)
        }
      }
      .alert(isPresented: $showError) {
        Alert(
          title: Text(Strings.Wallet.addCustomTokenErrorTitle),
          message: Text(Strings.Wallet.addCustomTokenErrorMessage),
          dismissButton: .default(Text(Strings.OKString))
        )
      }
      .background(
        Color.clear
          .sheet(
            isPresented: Binding(
              get: { self.networkSelectionStore != nil },
              set: { if !$0 { self.networkSelectionStore = nil } }
            )
          ) {
            if let networkSelectionStore = networkSelectionStore {
              NavigationView {
                NetworkSelectionView(
                  keyringStore: keyringStore,
                  networkStore: networkStore,
                  networkSelectionStore: networkSelectionStore
                )
              }
              .onDisappear {
                if let network = networkSelectionStore.networkSelectionInForm {
                  selectedNetwork = network
                }
              }
              .accentColor(Color(.braveOrange))
              .navigationViewStyle(.stack)
            }
          }
      )
    }
  }

  private func resignFirstResponder() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
  
  private func clearInput() {
    nameInput = ""
    addressInput = ""
    symbolInput = ""
    decimalsInput = ""
    tokenId = ""
    logo = ""
    coingeckoId = ""
    selectedNetwork = nil
  }

  private func addCustomToken() {
    let network = selectedNetwork ?? networkStore.selectedChain
    let token: BraveWallet.BlockchainToken
    switch selectedTokenType {
    case .token:
      token = BraveWallet.BlockchainToken(
        contractAddress: addressInput,
        name: nameInput,
        logo: logo,
        isErc20: network.coin != .sol,
        isErc721: false,
        symbol: symbolInput,
        decimals: Int32(decimalsInput) ?? Int32((selectedNetwork?.decimals ?? 18)),
        visible: true,
        tokenId: "",
        coingeckoId: coingeckoId,
        chainId: network.chainId,
        coin: network.coin
      )
    case .nft:
      var tokenIdToHex = ""
      if let tokenIdValue = Int16(tokenId) {
        tokenIdToHex = "0x\(String(format: "%02x", tokenIdValue))"
      }
      token = BraveWallet.BlockchainToken(
        contractAddress: addressInput,
        name: nameInput,
        logo: "",
        isErc20: false,
        isErc721: network.coin != .sol && !tokenIdToHex.isEmpty,
        symbol: symbolInput,
        decimals: 0,
        visible: true,
        tokenId: tokenIdToHex,
        coingeckoId: coingeckoId,
        chainId: network.chainId,
        coin: network.coin
      )
    }
    userAssetStore.addUserAsset(token) { [self] success in
      if success {
        presentationMode.dismiss()
      } else {
        showError = true
      }
    }
  }
}

#if DEBUG
struct AddCustomAssetView_Previews: PreviewProvider {
  static var previews: some View {
    AddCustomAssetView(
      networkStore: .previewStore,
      keyringStore: .previewStore,
      userAssetStore: .previewStore
    )
  }
}
#endif
