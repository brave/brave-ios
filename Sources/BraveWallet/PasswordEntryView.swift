// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import DesignSystem
import Strings
import SwiftUI
import BraveCore
import LocalAuthentication

struct PasswordEntryView: View {
  
  struct EntryError: LocalizedError, Equatable {
    let message: String
    var errorDescription: String? { message }
  }
  
  let keyringStore: KeyringStore
  let title: String
  let message: String
  let shouldShowBiometrics: Bool
  let action: (_ password: String, _ completion: @escaping (EntryError?) -> Void) -> Void
  
  init(
    keyringStore: KeyringStore,
    title: String = Strings.Wallet.verifyPasswordTitle,
    message: String,
    shouldShowBiometrics: Bool = true,
    action: @escaping (_ password: String, _ completion: @escaping (EntryError?) -> Void) -> Void
  ) {
    self.keyringStore = keyringStore
    self.title = title
    self.message = message
    self.shouldShowBiometrics = shouldShowBiometrics
    self.action = action
  }
  
  @State private var password = ""
  @State private var error: EntryError?
  @State private var attemptedBiometricsUnlock: Bool = false
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  private var isPasswordValid: Bool {
    !password.isEmpty
  }
  
  private var biometricsIcon: Image? {
    let context = LAContext()
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
      switch context.biometryType {
      case .faceID:
        return Image(systemName: "faceid")
      case .touchID:
        return Image(systemName: "touchid")
      case .none:
        return nil
      @unknown default:
        return nil
      }
    }
    return nil
  }
  
  private func fillPasswordFromKeychain() {
    if let password = keyringStore.retrievePasswordFromKeychain() {
      self.password = password
      validate()
    }
  }
  
  private func validate() {
    action(password) { entryError in
      DispatchQueue.main.async {
        if let entryError = entryError {
          self.error = entryError
          UIImpactFeedbackGenerator(style: .medium).bzzt()
        } else {
          presentationMode.dismiss()
        }
      }
    }
  }
  
  var body: some View {
    NavigationView {
      ScrollView(.vertical) {
        VStack(spacing: 36) {
          Image("graphic-lock", bundle: .current)
            .accessibilityHidden(true)
          VStack {
            Text(message)
              .font(.headline)
              .padding(.bottom)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
            HStack {
              SecureField(Strings.Wallet.passwordPlaceholder, text: $password, onCommit: validate)
                .textContentType(.password)
                .font(.subheadline)
                .introspectTextField(customize: { tf in
                  tf.becomeFirstResponder()
                })
                .textFieldStyle(BraveValidatedTextFieldStyle(error: error))
              if shouldShowBiometrics, keyringStore.isKeychainPasswordStored, let icon = biometricsIcon {
                Button(action: fillPasswordFromKeychain) {
                  icon
                    .imageScale(.large)
                    .font(.headline)
                }
              }
            }
            .padding(.horizontal, 48)
          }
          Button(action: validate) {
            Text(Strings.Wallet.confirm)
          }
          .buttonStyle(BraveFilledButtonStyle(size: .normal))
          .disabled(!isPasswordValid)
          .frame(maxWidth: .infinity)
          .listRowInsets(.zero)
        }
        .padding()
        .padding(.vertical)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(title)
      }
    }
    .onAppear {
      guard shouldShowBiometrics else { return }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
        if !attemptedBiometricsUnlock && UIApplication.shared.isProtectedDataAvailable {
          attemptedBiometricsUnlock = true
          fillPasswordFromKeychain()
        }
      }
    }
  }
}
