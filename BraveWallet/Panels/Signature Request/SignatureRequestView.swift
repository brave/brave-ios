// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import struct Shared.Strings
import BraveCore
import BraveShared
import BraveUI

struct SignatureRequestView: View {
  var request: BraveWallet.SignMessageRequest
  @ObservedObject var keyringStore: KeyringStore
  
  var onDismiss: (_ approved: Bool) -> Void

  @Environment(\.sizeCategory) private var sizeCategory
  @Environment(\.presentationMode) @Binding private var presentationMode
  @ScaledMetric private var blockieSize = 54
  
  private var account: BraveWallet.AccountInfo {
    keyringStore.keyring.accountInfos.first(where: { $0.address == request.address }) ?? keyringStore.selectedAccount
  }
  
  var body: some View {
    ScrollView(.vertical) {
      VStack {
        VStack(spacing: 8) {
          Blockie(address: account.address)
            .frame(width: blockieSize, height: blockieSize)
          Text(account.name)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(Color(.secondaryBraveLabel))
          Text(Strings.Wallet.signatureRequestSubtitle)
            .font(.headline)
        }
        .padding(.vertical, 32)
        VStack(spacing: 12) {
          StaticTextView(text: request.message, isMonospaced: false)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(Color(.tertiaryBraveGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .padding()
          .background(
            Color(.secondaryBraveGroupedBackground)
          )
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        buttonsContainer
          .padding(.top)
          .opacity(sizeCategory.isAccessibilityCategory ? 0 : 1)
          .accessibility(hidden: sizeCategory.isAccessibilityCategory)
      }
      .padding()
    }
    .overlay(
      Group {
        if sizeCategory.isAccessibilityCategory {
          buttonsContainer
            .frame(maxWidth: .infinity)
            .padding(.top)
            .background(
              LinearGradient(
                stops: [
                  .init(color: Color(.braveGroupedBackground).opacity(0), location: 0),
                  .init(color: Color(.braveGroupedBackground).opacity(1), location: 0.05),
                  .init(color: Color(.braveGroupedBackground).opacity(1), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
              .ignoresSafeArea()
              .allowsHitTesting(false)
            )
        }
      },
      alignment: .bottom
    )
    .frame(maxWidth: .infinity)
    .navigationTitle(Strings.Wallet.signatureRequestTitle)
    .navigationBarTitleDisplayMode(.inline)
    .foregroundColor(Color(.braveLabel))
    .background(Color(.braveGroupedBackground).edgesIgnoringSafeArea(.all))
    .toolbar {
      ToolbarItemGroup(placement: .cancellationAction) {
        Button(action: { presentationMode.dismiss() }) {
          Text(Strings.cancelButtonTitle)
            .foregroundColor(Color(.braveOrange))
        }
      }
    }
  }
  
  @ViewBuilder private var buttonsContainer: some View {
    if sizeCategory.isAccessibilityCategory {
      VStack {
        buttons
      }
    } else {
      HStack {
        buttons
      }
    }
  }
  
  @ViewBuilder private var buttons: some View {
    Button(action: { onDismiss(false) }) {
      Label(Strings.cancelButtonTitle, systemImage: "xmark")
        .imageScale(.large)
    }
    .buttonStyle(BraveOutlineButtonStyle(size: .large))
    Button(action: { onDismiss(true) }) {
      Label(Strings.Wallet.sign, image: "brave.key")
        .imageScale(.large)
    }
    .buttonStyle(BraveFilledButtonStyle(size: .large))
  }
}

#if DEBUG
struct SignatureRequestView_Previews: PreviewProvider {
  static var previews: some View {
    SignatureRequestView(
      request: .previewRequest,
      keyringStore: .previewStoreWithWalletCreated,
      onDismiss: { _ in }
    )
  }
}
#endif
