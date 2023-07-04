/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftUI
import LocalAuthentication
import DesignSystem
import Strings
import struct Shared.AppConstants

struct CreateWalletContainerView: View {
  @ObservedObject var keyringStore: KeyringStore

  var body: some View {
    ScrollView(.vertical) {
      CreateWalletView(keyringStore: keyringStore)
        .background(Color(.braveBackground))
    }
    .background(Color(.braveBackground).edgesIgnoringSafeArea(.all))
    .navigationTitle(Strings.Wallet.cryptoTitle)
    .navigationBarTitleDisplayMode(.inline)
    .introspectViewController { vc in
      vc.navigationItem.backButtonTitle = Strings.Wallet.createWalletBackButtonTitle
      vc.navigationItem.backButtonDisplayMode = .minimal
    }
  }
}

private struct CreateWalletView: View {
  @ObservedObject var keyringStore: KeyringStore

  private enum ValidationError: LocalizedError, Equatable {
    case requirementsNotMet
    case inputsDontMatch

    var errorDescription: String? {
      switch self {
      case .requirementsNotMet:
        return Strings.Wallet.passwordDoesNotMeetRequirementsError
      case .inputsDontMatch:
        return Strings.Wallet.passwordsDontMatchError
      }
    }
  }
  
  private enum LocalValidation {
    case weak
    case medium // more than 12
    case strong // more than 16
    
    var description: String {
      switch self {
      case .weak:
        return "Weak"
      case .medium:
        return "Medium"
      case .strong:
        return "Strong"
      }
    }
  }
  
  private var autoLockIntervals: [AutoLockInterval] {
    let all = AutoLockInterval.allOptions
    return all.sorted(by: { $0.value < $1.value })
  }

  @State private var password: String = ""
  @State private var repeatedPassword: String = ""
  @State private var validationError: ValidationError?
  @State private var isShowingBiometricsPrompt: Bool = false
  @State private var isSkippingBiometricsPrompt: Bool = false
  @State private var passwordStatus: LocalValidation?
  @State private var isInputsMatch: Bool = false

  private func createWallet() {
    validate { success in
      if !success {
        return
      }
      keyringStore.createWallet(password: password) { mnemonic in
        if !mnemonic.isEmpty {
          if isBiometricsAvailable {
            isShowingBiometricsPrompt = true
          } else {
            isSkippingBiometricsPrompt = true
          }
        }
      }
    }
  }

  private var isBiometricsAvailable: Bool {
    LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
  }

  private func validate(_ completion: @escaping (Bool) -> Void) {
    keyringStore.isStrongPassword(password) { isValidPassword in
      if !isValidPassword {
        validationError = .requirementsNotMet
      } else if password != repeatedPassword {
        validationError = .inputsDontMatch
      } else {
        validationError = nil
      }
      completion(validationError == nil)
    }
  }

  private func handlePasswordChanged(_ value: String) {
    if validationError == .requirementsNotMet {
      // Reset validation on user changing
      validationError = nil
    }
    if password.count >= 16 {
      passwordStatus = .strong
    } else if password.count >= 12 {
      passwordStatus = .medium
    } else if password.isEmpty {
      passwordStatus = nil
    } else {
      passwordStatus = .weak
    }
  }

  private func handleRepeatedPasswordChanged(_ value: String) {
    if validationError == .inputsDontMatch {
      // Reset validation on user changing
      validationError = nil
    }
    isInputsMatch = password == repeatedPassword
  }
  
  @ViewBuilder func passwordStatusView(value: Float, tintColor: Color, label: String) -> some View {
    HStack {
      ProgressView(value: value)
        .tint(tintColor)
      Text(label)
        .foregroundColor(tintColor)
        .font(.footnote)
        .padding(.leading, 20)
    }
  }

  var body: some View {
    VStack(spacing: 16) {
      VStack {
        Text(Strings.Wallet.createWalletTitle)
          .font(.title)
          .padding(.bottom)
          .multilineTextAlignment(.center)
          .foregroundColor(.primary)
        Text(Strings.Wallet.createWalletSubTitle)
          .font(.subheadline)
          .padding(.bottom)
          .multilineTextAlignment(.center)
          .foregroundColor(Color(.secondaryBraveLabel))
      }
      VStack(alignment: .leading, spacing: 20) {
        VStack(spacing: 30) {
          VStack(alignment: .leading, spacing: 5) {
            Text(Strings.Wallet.passwordPlaceholder)
              .foregroundColor(Color(.braveLabel))
            SecureField(Strings.Wallet.passwordPlaceholder, text: $password)
              .textContentType(.newPassword)
              .textFieldStyle(BraveValidatedTextFieldStyle(error: validationError, when: .requirementsNotMet))
            if let passwordStatus {
              switch passwordStatus {
              case .weak:
                passwordStatusView(value: 0.33, tintColor: Color(.braveErrorLabel), label: LocalValidation.weak.description)
              case .medium:
                passwordStatusView(value: 0.66, tintColor: Color(.braveWarningLabel), label: LocalValidation.medium.description)
              case .strong:
                passwordStatusView(value: 1, tintColor: Color(.braveSuccessLabel), label: LocalValidation.strong.description)
              }
            }
          }
          VStack(alignment: .leading, spacing: 5) {
            Text(Strings.Wallet.repeatedPasswordPlaceholder)
              .foregroundColor(Color(.braveLabel))
            SecureField(Strings.Wallet.repeatedPasswordPlaceholder, text: $repeatedPassword, onCommit: createWallet)
              .textContentType(.newPassword)
              .textFieldStyle(BraveValidatedTextFieldStyle(error: validationError, when: .inputsDontMatch))
            if isInputsMatch {
              HStack {
                Spacer()
                Text(Image(braveSystemName: "leo.check.normal")) + Text(" Match!")
              }
              .frame(maxWidth: .infinity)
              .multilineTextAlignment(.trailing)
              .font(.footnote)
              .foregroundColor(Color(.braveBlurpleTint))
            }
          }
        }
        .font(.subheadline)
        HStack {
          Image(braveSystemName: "leo.lock")
            .renderingMode(.template)
            .foregroundColor(Color(.braveBlurpleTint).opacity(0.5))
            .font(.caption)
            .frame(width: 24, height: 24)
            .background(Color(.braveDisabled).opacity(0.5))
            .clipShape(Circle())
          Text("Brave Wallet will auto-lock after")
            .font(.footnote)
            .foregroundColor(Color(.braveLabel))
          Spacer()
          Picker("time interval", selection: $keyringStore.autoLockInterval) {
            ForEach(autoLockIntervals) { interval in
              Text(interval.label)
                .foregroundColor(Color(.secondaryBraveLabel))
                .tag(interval)
            }
          }
          .tint(Color(.braveBlurpleTint))
        }
      }
      Spacer()
      Button(action: createWallet) {
        Text(Strings.Wallet.continueButtonTitle)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(BraveFilledButtonStyle(size: .large))
      .disabled(!isInputsMatch || password.isEmpty || repeatedPassword.isEmpty)
      Spacer()
    }
    .padding(20)
    .background(.white)
    .cornerRadius(8)
    .background(
      NavigationLink(
        destination: BackupRecoveryPhraseView(
          password: password,
          keyringStore: keyringStore
        ),
        isActive: $isSkippingBiometricsPrompt
      ) {
        EmptyView()
      }
    )
    .onChange(of: password, perform: handlePasswordChanged)
    .onChange(of: repeatedPassword, perform: handleRepeatedPasswordChanged)
  }
}

#if DEBUG
struct CreateWalletView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      CreateWalletContainerView(keyringStore: .previewStore)
    }
    .previewLayout(.sizeThatFits)
    .previewColorSchemes()
  }
}
#endif
