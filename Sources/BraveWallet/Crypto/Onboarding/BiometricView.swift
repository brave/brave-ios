/* Copyright 2023 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import SwiftUI
import DesignSystem
import struct Shared.AppConstants

struct BiometricView: View {
  var keyringStore: KeyringStore
  var password: String
  var onSkip: () -> Void
  
  @State private var biometricError: OSStatus?
  
  var body: some View {
    VStack {
      Image(sharedName: "pin-migration-graphic")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: 250)
        .padding()
      Group {
        Text(Strings.Wallet.biometricsSetupTitle)
          .font(.title3)
          .foregroundColor(Color(.braveLabel))
          .padding(.bottom, 20)
        Text(Strings.Wallet.biometricsSetupSubTitle)
          .font(.body)
          .foregroundColor(Color(.secondaryBraveLabel))
      }
      .fixedSize(horizontal: false, vertical: true)
      .multilineTextAlignment(.center)
      Button {
        // Store password in keychain
        if case let status = keyringStore.storePasswordInKeychain(password),
           status != errSecSuccess {
          biometricError = status
        }
      } label: {
        Text(Strings.Wallet.web3DomainOptionEnabled)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(BraveFilledButtonStyle(size: .large))
      .padding(.vertical, 20)
      Button(action: {
        onSkip()
      }) {
        Text(Strings.Wallet.skipButtonTitle)
          .font(Font.subheadline.weight(.medium))
          .foregroundColor(Color(.braveLabel))
      }
    }
    .padding(.horizontal, 24)
    .alert(isPresented: Binding(
      get: { biometricError != nil },
      set: { _, _ in })
    ) {
      Alert(
        title: Text(Strings.Wallet.biometricsSetupErrorTitle),
        message: Text(Strings.Wallet.biometricsSetupErrorMessage + (AppConstants.buildChannel.isPublic ? "" : " (\(biometricError ?? -1))")),
        dismissButton: .default(Text(verbatim: Strings.OKString))
      )
    }
  }
}

struct BiometricView_Previews: PreviewProvider {
    static var previews: some View {
      BiometricView(
        keyringStore: .previewStore,
        password: "",
        onSkip: {}
      )
    }
}
