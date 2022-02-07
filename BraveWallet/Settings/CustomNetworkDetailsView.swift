// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import Shared

struct NetworkInputItem {
  var input: String
  var error: String?
}

struct NetworkTextField: View {
  var placeholder: String
  @Binding var item: NetworkInputItem
  
  var body: some View {
    VStack(alignment: .leading) {
      TextField(placeholder, text: $item.input)
        .autocapitalization(.none)
        .disableAutocorrection(true)
      if let error = item.error {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Image(systemName: "exclamationmark.circle.fill")
          Text(error)
            .fixedSize(horizontal: false, vertical: true)
              .animation(nil, value: error)
        }
        .transition(
          .asymmetric(
            insertion: .opacity.animation(.default),
            removal: .identity
          )
        )
        .font(.footnote)
        .foregroundColor(Color(.braveErrorLabel))
      }
    }
  }
}

class CustomNetworkModel: ObservableObject {
  @Published var networkId = NetworkInputItem(input: "")
  @Published var networkName = NetworkInputItem(input: "")
  @Published var networkSymbolName = NetworkInputItem(input: "")
  @Published var networkSymbol = NetworkInputItem(input: "")
  @Published var networkDecimals = NetworkInputItem(input: "")
  
  @Published var rpcUrls: [NetworkInputItem] = [NetworkInputItem(input: "")]
  @Published var iconUrls = [NetworkInputItem(input: "")]
  @Published var blockUrls = [NetworkInputItem(input: "")]
  
  @Published var testUrls = [NetworkInputItem(input: "")]
  
  init(network: BraveWallet.EthereumChain? = nil) {
    if let network = network {
      let chainIdInDecimal: String
      if let intValue = Int(network.chainId.removingHexPrefix, radix: 16) {
        chainIdInDecimal = "\(intValue)"
      } else {
        chainIdInDecimal = network.chainId
      }
      self.networkId.input = chainIdInDecimal
      self.networkName.input = network.chainName
      self.networkSymbolName.input = network.symbolName
      self.networkSymbol.input = network.symbol
      self.networkDecimals.input = String(network.decimals)
      if !network.rpcUrls.isEmpty {
        self.rpcUrls = network.rpcUrls.compactMap({ NetworkInputItem(input: $0) })
      }
      if !network.iconUrls.isEmpty {
        self.iconUrls = network.iconUrls.compactMap({ NetworkInputItem(input: $0) })
      }
      if !network.blockExplorerUrls.isEmpty {
        self.blockUrls = network.blockExplorerUrls.compactMap({ NetworkInputItem(input: $0) })
      }
    }
  }
}

struct CustomNetworkDetailsView: View {
  @ObservedObject var networkStore: NetworkStore
  @ObservedObject var model: CustomNetworkModel
  
  var isEditMode: Bool
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  init(networkStore: NetworkStore,
       model: CustomNetworkModel,
       isEditMode: Bool
  ) {
    self.networkStore = networkStore
    self.model = model
    self.isEditMode = isEditMode
  }
  
  var body: some View {
    Form {
      Section(
        header: Text(Strings.Wallet.customNetworkChainIdTitle)
          .textCase(.none)
      ) {
        NetworkTextField(
          placeholder: Strings.Wallet.customNetworkChainIdPlaceholder,
          item: $model.networkId
        )
          .onChange(of: model.networkId.input, perform: { newValue in
            if let intValue = Int(newValue), intValue > 0 {
              model.networkId.error = nil
            } else {
              model.networkId.error = Strings.Wallet.customNetworkChainIdErrMsg
            }
          })
          .keyboardType(.numberPad)
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header: Text(Strings.Wallet.customNetworkChainNameTitle)
          .textCase(.none)
      ) {
        NetworkTextField(
          placeholder: Strings.Wallet.customNetworkChainNamePlaceholder,
          item: $model.networkName
        )
          .onChange(of: model.networkName.input, perform: { newValue in
            if newValue.isEmpty {
              model.networkName.error = Strings.Wallet.customNetworkEmptyErrMsg
            } else {
              model.networkName.error = nil
            }
          })
          .disableAutocorrection(true)
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header: Text(Strings.Wallet.customNetworkSymbolNameTitle)
          .textCase(.none)
      ) {
        NetworkTextField(
          placeholder: Strings.Wallet.customNetworkSymbolNamePlaceholder,
          item: $model.networkSymbolName
        )
          .onChange(of: model.networkSymbolName.input, perform: { newValue in
            if newValue.isEmpty {
              model.networkSymbolName.error = Strings.Wallet.customNetworkEmptyErrMsg
            } else {
              model.networkSymbolName.error = nil
            }
          })
          .disableAutocorrection(true)
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header: Text(Strings.Wallet.customNetworkSymbolTitle)
          .textCase(.none)
      ) {
        NetworkTextField(
          placeholder: Strings.Wallet.customNetworkSymbolPlaceholder,
          item: $model.networkSymbol
        )
          .onChange(of: model.networkSymbol.input, perform: { newValue in
            if newValue.isEmpty {
              model.networkSymbol.error = Strings.Wallet.customNetworkEmptyErrMsg
            } else {
              model.networkSymbol.error = nil
            }
          })
          .disableAutocorrection(true)
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header: Text(Strings.Wallet.customNetworkCurrencyDecimalTitle)
          .textCase(.none)
      ) {
        NetworkTextField(
          placeholder: Strings.Wallet.customNetworkCurrencyDecimalPlaceholder,
          item: $model.networkDecimals
        )
          .onChange(of: model.networkDecimals.input, perform: { newValue in
            if newValue.isEmpty {
              model.networkDecimals.error = Strings.Wallet.customNetworkEmptyErrMsg
            } else if let intValue = Int(newValue), intValue > 0 {
              model.networkDecimals.error = nil
            } else {
              model.networkDecimals.error = Strings.Wallet.customNetworkCurrencyDecimalErrMsg
            }
          })
          .keyboardType(.numberPad)
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header: Text(Strings.Wallet.customNetworkRpcUrlsTitle)
          .textCase(.none)
      ) {
        ForEach(model.rpcUrls.indices, id: \.self) { index in
          NetworkTextField(
            placeholder: Strings.Wallet.customNetworkUrlsPlaceholder,
            item: $model.rpcUrls[index]
          )
            .onChange(of: model.rpcUrls[index].input) { newValue in
              var item = model.rpcUrls[index]
              if URIFixup.getURL(newValue) != nil {
                item.error = nil
                model.rpcUrls[index] = item
                
                if index == model.rpcUrls.count - 1 { // add a new row
                  let newRow = NetworkInputItem(input: "")
                  model.rpcUrls.append(newRow)
                }
              } else {
                item.error = Strings.Wallet.customNetworkInvalidAddressErrMsg
                model.rpcUrls[index] = item
              }
            }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header: Text(Strings.Wallet.customNetworkIconUrlsTitle)
          .textCase(.none)
      ) {
        ForEach(model.iconUrls.indices, id: \.self) { index in
          NetworkTextField(
            placeholder: Strings.Wallet.customNetworkUrlsPlaceholder,
            item: $model.iconUrls[index]
          )
            .onChange(of: model.iconUrls[index].input) { newValue in
              var item: NetworkInputItem = model.iconUrls[index]
              if URIFixup.getURL(newValue) != nil {
                item.error = nil
                model.iconUrls[index] = item
                
                if index == model.iconUrls.count - 1 { // add a new row
                  let newRow = NetworkInputItem(input: "")
                  model.iconUrls.append(newRow)
                }
              } else {
                item.error = Strings.Wallet.customNetworkInvalidAddressErrMsg
                model.iconUrls[index] = item
              }
            }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header: Text(Strings.Wallet.customNetworkBlockExplorerUrlsTitle)
          .textCase(.none)
      ) {
        ForEach(model.blockUrls.indices, id: \.self) { index in
          NetworkTextField(
            placeholder: Strings.Wallet.customNetworkUrlsPlaceholder,
            item: $model.blockUrls[index]
          )
            .onChange(of: model.blockUrls[index].input) { newValue in
              var item: NetworkInputItem = model.blockUrls[index]
              if URIFixup.getURL(newValue) != nil {
                item.error = nil
                model.blockUrls[index] = item
                
                if index == model.blockUrls.count - 1 { // add a new row
                  let newRow = NetworkInputItem(input: "")
                  model.blockUrls.append(newRow)
                }
              } else {
                item.error = Strings.Wallet.customNetworkInvalidAddressErrMsg
                model.blockUrls[index] = item
              }
            }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
    }
    .navigationBarTitle(Strings.Wallet.customNetworkDetailsTitle)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .confirmationAction) {
        Button(action: {
          addCustomNetwork()
        }) {
          Text(isEditMode ? Strings.Wallet.update : Strings.Wallet.add)
            .foregroundColor(Color(.braveOrange))
        }
      }
    }
  }
  
  private func validateAllFields() -> Bool {
    if model.networkId.input.isEmpty {
      model.networkId.error = Strings.Wallet.customNetworkEmptyErrMsg
    }
    model.networkName.error = model.networkName.input.isEmpty ? Strings.Wallet.customNetworkEmptyErrMsg : nil
    model.networkSymbolName.error = model.networkSymbolName.input.isEmpty ? Strings.Wallet.customNetworkEmptyErrMsg : nil
    model.networkSymbol.error = model.networkSymbol.input.isEmpty ? Strings.Wallet.customNetworkEmptyErrMsg : nil
    if model.networkDecimals.input.isEmpty {
      model.networkDecimals.error = Strings.Wallet.customNetworkEmptyErrMsg
    }
    if var rpcUrl = model.rpcUrls.first {
      if rpcUrl.input.isEmpty {
        rpcUrl.error = Strings.Wallet.customNetworkEmptyErrMsg
        model.rpcUrls[0] = rpcUrl
      }
    }
                 
    if model.networkId.error != nil
        || model.networkName.error != nil
        || model.networkSymbolName.error != nil
        || model.networkSymbol.error != nil
        || model.networkDecimals.error != nil
        || model.rpcUrls.first!.error != nil {
      return false
    }
    
    return true
  }
  
  private func addCustomNetwork() {
    guard validateAllFields() else { return }
    
    let network: BraveWallet.EthereumChain = .init().then {
      if let idValue = Int(model.networkId.input) {
        $0.chainId = "0x\(String(format: "%02X", idValue))"
      }
      $0.chainName = model.networkName.input
      $0.symbolName = model.networkSymbolName.input
      $0.symbol = model.networkSymbol.input
      $0.decimals = Int32(model.networkDecimals.input) ?? 18
      $0.rpcUrls = model.rpcUrls.compactMap({
        if !$0.input.isEmpty && $0.error == nil {
          return $0.input
        } else {
          return nil
        }
      })
      $0.iconUrls = model.iconUrls.compactMap({
        if !$0.input.isEmpty && $0.error == nil {
          return $0.input
        } else {
          return nil
        }
      })
      $0.blockExplorerUrls = model.blockUrls.compactMap({
        if !$0.input.isEmpty && $0.error == nil {
          return $0.input
        } else {
          return nil
        }
      })
    }
    networkStore.addCustomNetwork(network) { accepted in
      guard accepted else {
        return
      }
      
      presentationMode.dismiss()
    }
  }
}

#if DEBUG
struct CustomNetworkDetailsView_Previews: PreviewProvider {
    static var previews: some View {
      NavigationView {
        CustomNetworkDetailsView(
          networkStore: .previewStore,
          model: .init(),
          isEditMode: true
        )
      }
    }
}
#endif
