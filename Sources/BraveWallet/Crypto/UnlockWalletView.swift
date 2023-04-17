/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import DesignSystem
import Strings
import LocalAuthentication

struct UnlockWalletView: View {
  @ObservedObject var keyringStore: KeyringStore

  @State private var password: String = ""
  @State private var isPasswordRevealed: Bool = false
  @State private var unlockError: UnlockError?
  @State private var attemptedBiometricsUnlock: Bool = false
  @FocusState private var isPasswordFieldFocused: Bool

  private enum UnlockError: LocalizedError {
    case incorrectPassword

    var errorDescription: String? {
      switch self {
      case .incorrectPassword:
        return Strings.Wallet.incorrectPasswordErrorMessage
      }
    }
  }

  private var isPasswordValid: Bool {
    !password.isEmpty
  }

  private func unlock() {
    // Conflict with the keyboard submit/dismissal that causes a bug
    // with SwiftUI animating the screen away...
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
      keyringStore.unlock(password: password) { unlocked in
        if !unlocked {
          unlockError = .incorrectPassword
          UIImpactFeedbackGenerator(style: .medium).bzzt()
        }
      }
    }
  }

  private func fillPasswordFromKeychain() {
    if let password = keyringStore.retrievePasswordFromKeychain() {
      // hide password (if revealed) before populating field with stored password
      isPasswordRevealed = false
      self.password = password
      unlock()
    }
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

  var body: some View {
    ScrollView(.vertical) {
      VStack(spacing: 42) {
        Image("graphic-lock", bundle: .module)
          .accessibilityHidden(true)
          .padding(.top, 20)
        Text(Strings.Wallet.unlockWalletTitle)
          .font(.headline)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
        RevealableSecureField(Strings.Wallet.passwordPlaceholder, text: $password, isRevealed: $isPasswordRevealed)
          .textContentType(.password)
          .focused($isPasswordFieldFocused)
          .font(.subheadline)
          .textFieldStyle(BraveValidatedTextFieldStyle(error: unlockError))
          .onSubmit(unlock)
          .padding(.horizontal, 48)
        VStack(spacing: 30) {
          Button(action: unlock) {
            Text(Strings.Wallet.unlockWalletButtonTitle)
          }
          .buttonStyle(BraveFilledButtonStyle(size: .large))
          .disabled(!isPasswordValid)
          NavigationLink(destination: RestoreWalletContainerView(keyringStore: keyringStore)) {
            Text(Strings.Wallet.restoreWalletButtonTitle)
              .font(.subheadline.weight(.medium))
          }
          .foregroundColor(Color(.braveLabel))
        }
        .padding(.top, 10)
        
        if keyringStore.isKeychainPasswordStored, let icon = biometricsIcon {
          Button(action: fillPasswordFromKeychain) {
            icon
              .resizable()
              .aspectRatio(contentMode: .fit)
              .imageScale(.large)
              .font(.headline)
              .frame(width: 26, height: 26)
          }
          .padding(.top, 18)
        }
      }
      .frame(maxHeight: .infinity, alignment: .top)
      .padding()
      .padding(.vertical)
    }
    .navigationTitle(Strings.Wallet.cryptoTitle)
    .navigationBarTitleDisplayMode(.inline)
    .background(Color(.braveBackground).edgesIgnoringSafeArea(.all))
    .onChange(of: password) { _ in
      unlockError = nil
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
        if !keyringStore.lockedManually && !attemptedBiometricsUnlock && keyringStore.defaultKeyring.isLocked && UIApplication.shared.isProtectedDataAvailable {
          attemptedBiometricsUnlock = true
          fillPasswordFromKeychain()
        } else {
          // only focus field if not auto-filling via biometrics, and user did not manually lock
          isPasswordFieldFocused = !keyringStore.lockedManually
        }
      }
    }
  }
}

#if DEBUG
struct CryptoUnlockView_Previews: PreviewProvider {
  static var previews: some View {
    UnlockWalletView(keyringStore: .previewStore)
      .previewLayout(.sizeThatFits)
      .previewColorSchemes()
  }
}
#endif
