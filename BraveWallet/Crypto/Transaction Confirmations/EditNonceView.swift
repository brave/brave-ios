// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import BraveCore
import struct Shared.Strings

struct EditNonceView: View {
  var confirmationStore: TransactionConfirmationStore
  var transaction: BraveWallet.TransactionInfo
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  @State private var nonce = ""
  
  var body: some View {
    List {
      Section(
        header: Text(Strings.Wallet.editNonceHeader)
          .textCase(.none),
        footer: Text(Strings.Wallet.editNonceFooter)
      ) {
        TextField(Strings.Wallet.editNoncePlaceholder, text: $nonce)
          .keyboardType(.numberPad)
      }
      Section {
        Button(action: {
          if let value = Int(nonce) {
            let nonceHex = "0x\(String(format: "%02x", value))"
            confirmationStore.editNonce(
              for: transaction,
              nonce: nonceHex) { success in
                if success {
                  presentationMode.dismiss()
                } else {
                  // Show error?
               }
              }
          }
        }) {
          Text(Strings.Wallet.saveCustomNonce)
        }
        .buttonStyle(BraveFilledButtonStyle(size: .large))
        .frame(maxWidth: .infinity)
        .listRowInsets(.zero)
        .listRowBackground(Color(.braveGroupedBackground))
      }
    }
    .listStyle(InsetGroupedListStyle())
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle(Strings.Wallet.advancedSettingsTransaction)
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        setup()
      }
    }
  }
  
  private func setup() {
    if let txNonce = transaction.txDataUnion.ethTxData1559?.baseData.nonce {
      let nonceDecimal: String
      if let intValue = Int(txNonce.removingHexPrefix, radix: 16) { // BaseData.nonce should always in hex
        nonceDecimal = "\(intValue)"
      } else {
        nonceDecimal = txNonce
      }
      nonce = nonceDecimal
    }
  }
}

#if DEBUG
struct EditNonceView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      EditNonceView(
        confirmationStore: .previewStore,
        transaction: .previewConfirmedSend
      )
    }
  }
}
#endif
