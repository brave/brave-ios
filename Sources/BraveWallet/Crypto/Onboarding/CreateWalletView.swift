/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftUI
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

private struct CreateWalletView: View {
  @ObservedObject var keyringStore: KeyringStore

  @State private var password: String = ""
  @State private var repeatedPassword: String = ""
  @State private var validationError: ValidationError?
  @State private var hasCreatedNewWallet: Bool = false
  @State private var passwordStatus: PasswordStatus = .none
  @State private var isInputsMatch: Bool = false

  private func createWallet() {
    keyringStore.createWallet(password: password) { mnemonic in
      if !mnemonic.isEmpty {
        hasCreatedNewWallet = true
      }
    }
  }

  private func validatePassword() {
    keyringStore.isStrongPassword(password) { status in
      passwordStatus = status
      if status == .none {
        validationError = nil
      } else if status == .invalid {
        validationError = .requirementsNotMet
      } else {
        if !password.isEmpty && !repeatedPassword.isEmpty {
          if password == repeatedPassword {
            isInputsMatch = true
            validationError = nil
          } else {
            isInputsMatch = false
            validationError = .inputsDontMatch
          }
        } else {
          validationError = nil
        }
      }
    }
  }

  private func handlePasswordChanged(_ value: String) {
    if validationError == .requirementsNotMet {
      // Reset validation on user changing
      validationError = nil
    }
    validatePassword()
  }

  private func handleRepeatedPasswordChanged(_ value: String) {
    if validationError == .inputsDontMatch {
      // Reset validation on user changing
      validationError = nil
    }
    validatePassword()
  }
  
  private func handleInputChange(_ value: String) {
    validationError = nil
    isInputsMatch = false
    validatePassword()
  }
  
  @ViewBuilder func passwordStatusView(_ status: PasswordStatus) -> some View {
    HStack(spacing: 4) {
      ProgressView(value: status.percentage)
        .tint(status.tintColor)
        .background(status.tintColor.opacity(0.1))
        .frame(width: 52, height: 4)
      Text(status.description)
        .foregroundColor(status.tintColor)
        .font(.footnote)
        .padding(.leading, 20)
    }
  }
  
  func errorLabel(_ error: ValidationError) -> some View {
    HStack(spacing: 12) {
      Image(braveSystemName: "leo.warning.circle-filled")
        .renderingMode(.template)
        .foregroundColor(Color(.braveLighterOrange))
      Text(error.errorDescription ?? "")
        .multilineTextAlignment(.leading)
        .font(.callout)
      Spacer()
    }
    .padding(12)
    .background(
      Color(.braveErrorBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    )
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
          .foregroundColor(.secondary)
      }
      VStack(alignment: .leading, spacing: 20) {
        VStack(spacing: 30) {
          VStack(alignment: .leading, spacing: 10) {
            Text(Strings.Wallet.passwordPlaceholder)
              .foregroundColor(.primary)
            HStack(spacing: 8) {
              SecureField(Strings.Wallet.passwordPlaceholder, text: $password)
                .textContentType(.newPassword)
              Spacer()
              if passwordStatus != .none {
                passwordStatusView(passwordStatus)
              }
            }
            Divider()
          }
          VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Wallet.repeatedPasswordPlaceholder)
              .foregroundColor(.primary)
            HStack(spacing: 8) {
              SecureField(Strings.Wallet.repeatedPasswordPlaceholder, text: $repeatedPassword, onCommit: createWallet)
                .textContentType(.newPassword)
              Spacer()
              if isInputsMatch {
                Text("\(Image(braveSystemName: "leo.check.normal")) \(Strings.Wallet.repeatedPasswordMatch)")
                  .multilineTextAlignment(.trailing)
                  .font(.footnote)
                  .foregroundColor(.secondary)
              }
            }
            Divider()
          }
        }
        .font(.subheadline)
        if let validationError {
          errorLabel(validationError)
        }
      }
      Button(action: createWallet) {
        Text(Strings.Wallet.continueButtonTitle)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(BraveFilledButtonStyle(size: .large))
      .disabled(validationError != nil || password.isEmpty || repeatedPassword.isEmpty)
      .padding(.top, 80)
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
        isActive: $hasCreatedNewWallet
      ) {
        EmptyView()
      }
    )
    .onChange(of: password, perform: handleInputChange)
    .onChange(of: repeatedPassword, perform: handleInputChange)
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
