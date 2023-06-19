/* Copyright 2022 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import BraveCore
import SwiftUI
import BraveShared

struct Selectable<T: Identifiable & Equatable>: Equatable, Identifiable {
  let isSelected: Bool
  let model: T
  
  var id: T.ID { model.id }
}

struct NetworkFilterView: View {
  
  @State var networks: [Selectable<BraveWallet.NetworkInfo>]
  @ObservedObject var networkStore: NetworkStore
  let saveAction: ([Selectable<BraveWallet.NetworkInfo>]) -> Void
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  init(
    networks: [Selectable<BraveWallet.NetworkInfo>],
    networkStore: NetworkStore,
    saveAction: @escaping ([Selectable<BraveWallet.NetworkInfo>]) -> Void
  ) {
    self._networks = .init(initialValue: networks)
    self.networkStore = networkStore
    self.saveAction = saveAction
  }
  
  var body: some View {
    NetworkSelectionRootView(
      navigationTitle: Strings.Wallet.networkFilterTitle,
      selectedNetworks: networks.filter(\.isSelected).map(\.model),
      allNetworks: networks.map(\.model),
      selectNetwork: selectNetwork
    )
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(action: {
          saveAction(networks)
          presentationMode.dismiss()
        }) {
          Text("Save")
            .foregroundColor(Color(.braveBlurpleTint))
        }
      }
    }
  }
  
  private func selectNetwork(_ network: BraveWallet.NetworkInfo) {
    DispatchQueue.main.async {
      if let index = networks.firstIndex(
        where: { $0.model.chainId == network.chainId && $0.model.coin == network.coin }
      ) {
        networks[index] = .init(isSelected: !networks[index].isSelected, model: networks[index].model)
      }
    }
  }
}
