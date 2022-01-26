// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore

protocol NetworkInputItem {
  var input: String { get set }
  var error: String? { get set }
}

struct RegularItem: NetworkInputItem {
  var input: String
  var error: String?
}

struct UrlItem: NetworkInputItem, Identifiable {
  var input: String
  var error: String?
  var id: Int
}

struct NetworkTextField: View {
  var placeholder: String
  var item: NetworkInputItem
  var onChange: (String) -> Void
  @State private var input = ""
  
  init(placeholder: String,
       item: NetworkInputItem,
       onChange: @escaping (String) -> Void
  ) {
    self.placeholder = placeholder
    self.item = item
    self.onChange = onChange
    self._input = State(wrappedValue: item.input)
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      TextField(placeholder, text: $input)
        .onChange(of: input) { newValue in
          onChange(newValue)
        }
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

struct CustomNetworkDetailsView: View {
  @ObservedObject var networkStore: NetworkStore
  
  var isEditMode: Bool
  var network: BraveWallet.EthereumChain?
  
  @State private var networkId: RegularItem = RegularItem(input: "")
  @State private var networkName: RegularItem = RegularItem(input: "")
  @State private var networkSymbolName: RegularItem = RegularItem(input: "")
  @State private var networkSymbol: RegularItem = RegularItem(input: "")
  @State private var networkDecimals: RegularItem = RegularItem(input: "")
  
  @State private var rpcUrls: [UrlItem] = [UrlItem(input: "", id: 0)]
  @State private var iconUrls: [UrlItem] = [UrlItem(input: "", id: 0)]
  @State private var blockUrls: [UrlItem] = [UrlItem(input: "", id: 0)]
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  init(networkStore: NetworkStore,
       isEditMode: Bool,
       network: BraveWallet.EthereumChain? = nil
  ) {
    self.networkStore = networkStore
    self.isEditMode = isEditMode
    self.network = network
    if let network = network {
      self._networkId = State(wrappedValue: RegularItem(input: network.chainId.chainIdInDecimal))
      self._networkName = State(wrappedValue: RegularItem(input: network.chainName))
      self._networkSymbolName = State(wrappedValue: RegularItem(input: network.symbolName))
      self._networkSymbol = State(wrappedValue: RegularItem(input: network.symbol))
      self._networkDecimals = State(wrappedValue: RegularItem(input: String(network.decimals)))
      if network.rpcUrls.count > 0 {
        self._rpcUrls = State(wrappedValue: network.rpcUrls.enumerated().compactMap({ UrlItem(input: $1, id: $0) }))
      }
      if network.iconUrls.count > 0 {
        self._iconUrls = State(wrappedValue: network.iconUrls.enumerated().compactMap({ UrlItem(input: $1, id: $0) }))
      }
      if network.blockExplorerUrls.count > 0 {
        self._blockUrls = State(wrappedValue: network.blockExplorerUrls.enumerated().compactMap({ UrlItem(input: $1, id: $0) }))
      }
    }
  }
  
  var body: some View {
    Form {
      Section(
        header:
          Text("The id of new chain")
          .textCase(.none)
      ) {
        NetworkTextField(placeholder: "A positive decimal number",
                         item: networkId) { newValue in
          networkId.input = newValue
          if let intValue = Int(newValue), intValue > 0 {
            networkId.error = nil
          } else {
            networkId.error = "Invalid format, the chain id is a positive number."
          }
        }
          .keyboardType(.numberPad)
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header:
          Text("The name of new chain")
          .textCase(.none)
      ) {
        NetworkTextField(placeholder: "Enter chain name",
                         item: networkName) { newValue in
          networkName.input = newValue
          if newValue.count < 1 {
            networkName.error = "This field cannot be blank."
          } else {
            networkName.error = nil
          }
        }
          .disableAutocorrection(true)
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header:
          Text("Chain's currency name")
          .textCase(.none)
      ) {
        NetworkTextField(placeholder: "Enter currency name",
                         item: networkSymbolName) { newValue in
          networkSymbolName.input = newValue
          if newValue.count < 1 {
            networkSymbolName.error = "This field cannot be blank."
          } else {
            networkSymbolName.error = nil
          }
        }
          .disableAutocorrection(true)
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header:
          Text("Chain's currency symbol")
          .textCase(.none)
      ) {
        NetworkTextField(placeholder: "Enter currency symbol",
                         item: networkSymbol) { newValue in
          networkSymbol.input = newValue
          if newValue.count < 1 {
            networkSymbol.error = "This field cannot be blank."
          } else {
            networkSymbol.error = nil
          }
        }
          .disableAutocorrection(true)
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header:
          Text("Chain's currency decimals")
          .textCase(.none)
      ) {
        NetworkTextField(placeholder: "Enter currency decimals",
                         item: networkDecimals) { newValue in
          networkDecimals.input = newValue
          if newValue.isEmpty {
            networkDecimals.error = "This field cannot be blank."
          } else if let intValue = Int(newValue), intValue > 0 {
            networkDecimals.error = nil
          } else {
            networkDecimals.error = "Invalid format, the currency decimals is a positive number."
          }
        }
          .keyboardType(.numberPad)
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header: Text("RPC URLs")
      ) {
        ForEach(rpcUrls.indices, id: \.self) { index in
          var item = rpcUrls[index]
          NetworkTextField(placeholder: "Enter URL",
                       item: item) { newValue in
            item.input = newValue
            if validateUrl(newValue) {
              item.error = nil
              rpcUrls[index] = item
              
              if index == rpcUrls.count - 1 { // add a new row
                let newRow = UrlItem(input: "", id: rpcUrls.count)
                rpcUrls.append(newRow)
              }
            } else {
              item.error = "Invalid address"
              rpcUrls[index] = item
            }
          }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header: Text("Icon URLs")
      ) {
        ForEach(iconUrls.indices, id: \.self) { index in
          var item = iconUrls[index]
          NetworkTextField(placeholder: "Enter URL",
                       item: item) { newValue in
            item.input = newValue
            if validateUrl(newValue) {
              item.error = nil
              iconUrls[index] = item
              
              if index == iconUrls.count - 1 { // add a new row
                let newRow = UrlItem(input: "", id: iconUrls.count)
                iconUrls.append(newRow)
              }
            } else {
              item.error = "Invalid address"
              iconUrls[index] = item
            }
          }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      Section(
        header: Text("Block explorer URLs")
      ) {
        ForEach(blockUrls.indices, id: \.self) { index in
          var item = blockUrls[index]
          NetworkTextField(placeholder: "Enter URL",
                       item: item) { newValue in
            item.input = newValue
            if validateUrl(newValue) {
              item.error = nil
              blockUrls[index] = item
              
              if index == blockUrls.count - 1 { // add a new row
                let newRow = UrlItem(input: "", id: blockUrls.count)
                blockUrls.append(newRow)
              }
            } else {
              item.error = "Invalid address"
              blockUrls[index] = item
            }
          }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
    }
    .navigationBarTitle("Add new network")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .confirmationAction) {
        Button(action: {
          addCustomNetwork()
        }) {
          Text(isEditMode ? "Update" : "Add")
            .foregroundColor(Color(.braveOrange))
        }
      }
    }
  }
  
  private func validateUrl(_ url: String) -> Bool {
    let regex = "http[s]?://(([^/:.[:space:]]+(.[^/:.[:space:]]+)*)|([0-9](.[0-9]{3})))(:[0-9]+)?((/[^?#[:space:]]+)([^#[:space:]]+)?(#.+)?)?"
    let test = NSPredicate(format: "SELF MATCHES %@", regex)
    return test.evaluate(with: url)
  }
  
  private func validateAllFields() -> Bool {
    networkId.error = networkId.input.isEmpty ? "This field cannot be blank." : nil
    networkName.error = networkName.input.isEmpty ? "This field cannot be blank." : nil
    networkSymbolName.error = networkSymbolName.input.isEmpty ? "This field cannot be blank." : nil
    networkSymbol.error = networkSymbol.input.isEmpty ? "This field cannot be blank." : nil
    if networkDecimals.input.isEmpty {
      networkDecimals.error = "This field cannot be blank."
    } else if let value = Int(networkDecimals.input), value > 0 {
      networkDecimals.error = nil
    } else {
      networkDecimals.error = "Invalid format, the currency decimals is a positive number."
    }
                 
    if networkId.error != nil
        || networkName.error != nil
        || networkSymbolName.error != nil
        || networkSymbol.error != nil
        || networkDecimals.error != nil
        || rpcUrls.first!.input.isEmpty {
      return false
    }
    
    return true
  }
  
  private func addCustomNetwork() {
    guard validateAllFields() else { return }
    
    let network: BraveWallet.EthereumChain = .init().then {
      if let idValue = Int(networkId.input) {
        $0.chainId = "0x\(String(format: "%02X", idValue))"
      }
      $0.chainName = networkName.input
      $0.symbolName = networkSymbolName.input
      $0.symbol = networkSymbol.input
      $0.decimals = Int32(networkDecimals.input) ?? 18
      $0.rpcUrls = rpcUrls.compactMap({
        if !$0.input.isEmpty && $0.error == nil {
          return $0.input
        } else {
          return nil
        }
      })
      $0.iconUrls = iconUrls.compactMap({
        if !$0.input.isEmpty && $0.error == nil {
          return $0.input
        } else {
          return nil
        }
      })
      $0.blockExplorerUrls = blockUrls.compactMap({
        if !$0.input.isEmpty && $0.error == nil {
          return $0.input
        } else {
          return nil
        }
      })
    }
    networkStore.addCustomNetwork(network) { accpted in
      guard accpted else {
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
          isEditMode: true
        )
      }
    }
}
#endif
