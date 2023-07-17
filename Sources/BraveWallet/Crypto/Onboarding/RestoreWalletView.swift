/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftUI
import DesignSystem
import Strings
import struct Shared.AppConstants
import LocalAuthentication

struct RestoreWalletContainerView: View {
  @ObservedObject var keyringStore: KeyringStore

  var body: some View {
    ScrollView(.vertical) {
      RestoreWalletView(keyringStore: keyringStore)
        .background(Color(.braveBackground))
    }
    .background(Color(.braveBackground).edgesIgnoringSafeArea(.all))
    .introspectViewController { vc in
      let appearance = UINavigationBarAppearance()
      appearance.configureWithTransparentBackground()
      vc.navigationItem.compactAppearance = appearance
      vc.navigationItem.scrollEdgeAppearance = appearance
      vc.navigationItem.standardAppearance = appearance
      vc.navigationItem.backButtonTitle = Strings.Wallet.restoreWalletBackButtonTitle
      vc.navigationItem.backButtonDisplayMode = .generic
    }
  }
}

private struct RestoreWalletView: View {
  @ObservedObject var keyringStore: KeyringStore
  
  @Environment(\.sizeCategory) private var sizeCategory
  @Environment(\.dismiss) private var dismiss
  
  @State private var isBraveLegacyWallet: Bool = false
  @State private var isRevealRecoveryWords: Bool = true
  @State private var scrollViewIndicatorState: Bool = false
  @State private var recoveryWords: [String] = .init(repeating: "", count: 12)
  @State private var newPassword: String = ""
  @State private var isShowingCreateNewPassword: Bool = false
  @State private var isShowingPhraseError: Bool = false
  @State private var isShowingCompleteState: Bool = false
  private let staticGridsViewHeight: CGFloat = 156

  private var isBiometricsAvailable: Bool {
    LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
  }
  
  private var numberOfColumns: Int {
    sizeCategory.isAccessibilityCategory ? 2 : 3
  }
  
  private var isLegacyWallet: Bool {
    recoveryWords.count == 24
  }
  
  private var errorLabel: some View {
    HStack(spacing: 12) {
      Image(braveSystemName: "leo.warning.circle-filled")
        .renderingMode(.template)
        .foregroundColor(Color(.braveLighterOrange))
      Text(Strings.Wallet.restoreWalletPhraseInvalidError)
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
  
  private func handleRecoveryWordsChanged(_ value: [String]) {
    for word in value {
      let phrases = word.split(separator: " ")
      if phrases.count > 1 {
        let currentLength = recoveryWords.count
        var newPhrases = Array(repeating: "", count: currentLength)
        for (index, pastedWord) in phrases.enumerated() {
          newPhrases[index] = String(pastedWord)
        }
        recoveryWords = newPhrases
        break
      }
    }
  }

  var body: some View {
    VStack(spacing: 48) {
      VStack(spacing: 14) {
        Text(Strings.Wallet.restoreWalletTitle)
          .font(.title)
          .foregroundColor(Color(uiColor: WalletV2Design.textPrimary))
        Text(Strings.Wallet.restoreWalletSubtitle)
          .font(.subheadline)
          .foregroundColor(Color(uiColor: WalletV2Design.textSecondary))
      }
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: false, vertical: true)
      let columns: [GridItem] = (0..<numberOfColumns).map { _ in .init(.flexible()) }
      ScrollView {
        LazyVGrid(columns: columns, spacing: 8) {
          ForEach(self.recoveryWords.indices, id: \.self) { index in
            VStack(alignment: .leading, spacing: 10) {
              if isRevealRecoveryWords {
                TextField(String.localizedStringWithFormat(Strings.Wallet.restoreWalletPhrasePlaceholder, (index + 1)), text: $recoveryWords[index])
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .foregroundColor(Color(.braveLabel))
              } else {
                SecureField(String.localizedStringWithFormat(Strings.Wallet.restoreWalletPhrasePlaceholder, (index + 1)), text: $recoveryWords[index])
                  .textContentType(.newPassword)
              }
              Divider()
            }
          }
        }
      }
      .frame(height: staticGridsViewHeight)
      .padding(.horizontal)
      if isShowingPhraseError {
        errorLabel
      }
      HStack {
        Spacer()
        Button {
          recoveryWords = isLegacyWallet ? .init(repeating: "", count: 12) : .init(repeating: "", count: 24)
          scrollViewIndicatorState.toggle()
        } label: {
          Text(isLegacyWallet ? Strings.Wallet.restoreWalletImportFromRegularBraveWallet : Strings.Wallet.restoreWalletImportFromLegacyBraveWallet)
            .fontWeight(.medium)
            .foregroundColor(Color(.braveBlurpleTint))
        }
        Spacer()
        Button {
          isRevealRecoveryWords.toggle()
        } label: {
          Image(braveSystemName: isRevealRecoveryWords ? "leo.eye.off" : "leo.eye.on")
            .foregroundColor(Color(.braveLabel))
        }
      }
      Button {
        isShowingCreateNewPassword = true
      } label: {
        Text(Strings.Wallet.continueButtonTitle)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(BraveFilledButtonStyle(size: .large))
    }
    .padding()
    .onChange(of: recoveryWords, perform: handleRecoveryWordsChanged)
    .scrollViewIndicatorFlash(staticContentHeight: staticGridsViewHeight)
    .sheet(isPresented: $isShowingCreateNewPassword) {
      NavigationView {
        CreateWalletContainerView(
          keyringStore: keyringStore,
          restorePackage: RestorePackage(
            recoveryWords: recoveryWords,
            newPassword: newPassword,
            onRestoreCompleted: { success, password in
              if success {
                isShowingPhraseError = false
                keyringStore.resetKeychainStoredPassword()
                if isBiometricsAvailable {
                  keyringStore.isRestoreFromUnlockBiometricsPromptVisible = true
                } else {
                  // If we're displaying this via onboarding, mark as completed.
                  keyringStore.markOnboardingCompleted()
                }
              } else {
                newPassword = password
                isShowingPhraseError = true
              }
            }
          )
        )
        .toolbar {
          ToolbarItemGroup(placement: .destructiveAction) {
            Button(Strings.CancelString) {
              isShowingCreateNewPassword = false
            }
          }
        }
      }
    }
    .sheet(isPresented: $keyringStore.isRestoreFromUnlockBiometricsPromptVisible) {
      BiometricView(
        keyringStore: keyringStore,
        password: newPassword,
        onSkip: {
          keyringStore.isRestoreFromUnlockBiometricsPromptVisible = false
          isShowingCompleteState = true
        },
        onFinish: {
          keyringStore.isRestoreFromUnlockBiometricsPromptVisible = false
          isShowingCompleteState = true
        }
      )
    }
    .sheet(isPresented: $isShowingCompleteState) {
      OnBoardingCompletedView() {
        keyringStore.markOnboardingCompleted()
      }
    }
  }
}

#if DEBUG
struct RestoreWalletView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      RestoreWalletContainerView(keyringStore: .previewStore)
    }
    .previewLayout(.sizeThatFits)
    .previewColorSchemes()
  }
}
#endif
