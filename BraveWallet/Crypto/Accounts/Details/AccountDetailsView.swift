/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SwiftUI
import BraveCore
import CoreImage
// For some reason SwiftLint thinks this is a duplicate import
// swiftlint:disable:next duplicate_imports
import CoreImage.CIFilterBuiltins
import struct Shared.Strings
import BraveShared

struct AccountDetailsView: View {
  @ObservedObject var keyringStore: KeyringStore
  var account: BraveWallet.AccountInfo
  var editMode: Bool
  
  @State private var name: String = ""
  @State private var isFieldFocused: Bool = false
  @State private var isPresentingRemoveConfirmation: Bool = false
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  private func removeAccount() {
    keyringStore.removeSecondaryAccount(forAddress: account.address)
  }
  
  private func renameAccountAndDismiss() {
    if name.isEmpty {
      // Show error?
      return
    }
    keyringStore.renameAccount(account, name: name)
    presentationMode.dismiss()
  }
  
  var body: some View {
    NavigationView {
      List {
        Section {
          AccountDetailsHeaderView(address: account.address)
            .frame(maxWidth: .infinity)
            .listRowInsets(.zero)
            .listRowBackground(Color(.braveGroupedBackground))
        }
        Section(
          header: WalletListHeaderView(
            title: Text(Strings.Wallet.accountDetailsNameTitle)
              .font(.subheadline.weight(.semibold))
              .foregroundColor(Color(.bravePrimary))
          )
        ) {
          TextField(Strings.Wallet.accountDetailsNamePlaceholder, text: $name)
            .introspectTextField { tf in
              if editMode && !isFieldFocused && !tf.isFirstResponder {
                isFieldFocused = tf.becomeFirstResponder()
              }
            }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
        Section {
          NavigationLink(destination: AccountPrivateKeyView(keyringStore: keyringStore, account: account)) {
            Text(Strings.Wallet.accountPrivateKey)
          }
        }
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
        if account.isImported {
          Section {
            Button(action: { isPresentingRemoveConfirmation = true }) {
              Text(Strings.Wallet.accountRemoveButtonTitle)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }
            .alert(isPresented: $isPresentingRemoveConfirmation) {
              Alert(
                title: Text(Strings.Wallet.accountRemoveAlertConfirmation),
                message: Text(Strings.Wallet.accountRemoveAlertConfirmationMessage),
                primaryButton: .destructive(Text(Strings.yes), action: removeAccount),
                secondaryButton: .cancel(Text(Strings.no))
              )
            }
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
      }
      .listStyle(InsetGroupedListStyle())
      .navigationTitle(Strings.Wallet.accountDetailsTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .cancellationAction) {
          Button(action: { presentationMode.dismiss() }) {
            Text(Strings.cancelButtonTitle)
              .foregroundColor(Color(.braveOrange))
          }
        }
        ToolbarItemGroup(placement: .confirmationAction) {
          Button(action: renameAccountAndDismiss) {
            Text(Strings.done)
              .foregroundColor(Color(.braveOrange))
          }
        }
      }
    }
    .onAppear {
      if name.isEmpty {
        // Wait until next runloop pass to fix bug where body isn't recomputed based on state change
        DispatchQueue.main.async {
          // Setup TextField state binding
          name = account.name
        }
      }
    }
  }
}

private struct AccountDetailsHeaderView: View {
  var address: String
  
  private var qrCodeImage: UIImage? {
    guard let addressData = address.data(using: .utf8) else { return nil }
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = addressData
    filter.correctionLevel = "H"
    if let image = filter.outputImage,
       let cgImage = context.createCGImage(image, from: image.extent) {
      return UIImage(cgImage: cgImage)
    }
    return nil
  }
  
  var body: some View {
    VStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.white)
        .frame(width: 220, height: 220)
        .overlay(
          Group {
            if let image = qrCodeImage?.cgImage {
              Image(uiImage: UIImage(cgImage: image))
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .padding()
                .accessibilityHidden(true)
            }
          }
        )
      HStack {
        Text(address.truncatedAddress)
          .foregroundColor(Color(.secondaryBraveLabel))
        Button(action: { UIPasteboard.general.string = address }) {
          Label(Strings.Wallet.copyToPasteboard, image: "brave.clipboard")
            .labelStyle(.iconOnly)
            .foregroundColor(Color(.braveLabel))
        }
      }
      .font(.title3.weight(.semibold))
    }
    .padding(.horizontal)
  }
}

#if DEBUG
struct AccountDetailsViewController_Previews: PreviewProvider {
  static var previews: some View {
    AccountDetailsView(
      keyringStore: .previewStoreWithWalletCreated,
      account: KeyringStore.previewStoreWithWalletCreated.keyring.accountInfos.first!,
      editMode: false
    )
    .previewColorSchemes()
  }
}
#endif
