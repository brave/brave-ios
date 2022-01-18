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
  
  var isAddMode: Bool
  
  @State private var networkId: RegularItem = RegularItem(input: "")
  @State private var networkName: RegularItem = RegularItem(input: "")
  @State private var networkSymbolName: RegularItem = RegularItem(input: "")
  @State private var networkSymbol: RegularItem = RegularItem(input: "")
  @State private var networkDecimals: RegularItem = RegularItem(input: "")
  
  @State private var rpcUrls: [UrlItem] = [UrlItem(input: "", id: 0)]
  @State private var iconUrls: [UrlItem] = [UrlItem(input: "", id: 0)]
  @State private var blockUrls: [UrlItem] = [UrlItem(input: "", id: 0)]
  
  var body: some View {
    Form {
      Section(
        header:
          Text("The id of new chain")
          .textCase(.none)
      ) {
        NetworkTextField(placeholder: "A positive decimal number",
                         item: networkId) { newValue in
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
          if let intValue = Int(newValue), intValue > 0 {
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
        Button(action: {}) {
          Text(isAddMode ? "Add" : "Update")
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
}

struct CustomNetworkDetailsView_Previews: PreviewProvider {
    static var previews: some View {
      NavigationView {
        CustomNetworkDetailsView(
          networkStore: .previewStore,
          isAddMode: true
        )
      }
    }
}
