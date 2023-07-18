/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftUI
import DesignSystem
import Strings
import LocalAuthentication

struct VerifyRecoveryPhraseView: View {
  @ObservedObject var keyringStore: KeyringStore

  @State private var input: String = ""
  @State private var isShowingError = false
  @State private var activeCheckIndex: Int = 0
  @State private var isShowingBiometricsPrompt: Bool = false
  @State private var isShowingSkipWarning: Bool = false
  @State private var isShowingCompleteState: Bool = false

  @Environment(\.modalPresentationMode) @Binding private var modalPresentationMode
  
  private var recoveryWords: [RecoveryWord]
  private let targetedRecoveryWordIndexes: [Int]
  private let password: String
  private var isBiometricsAvailable: Bool {
    LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
  }
  
  init(
    keyringStore: KeyringStore,
    recoveryWords: [RecoveryWord],
    targetedRecoveryWordIndexes: [Int],
    password: String
  ) {
    self.keyringStore = keyringStore
    self.recoveryWords = recoveryWords
    self.targetedRecoveryWordIndexes = targetedRecoveryWordIndexes
    self.password = password
  }
  
  private func markOnboardingCompleted() {
    if keyringStore.isOnboardingVisible {
      keyringStore.markOnboardingCompleted()
    } else {
      modalPresentationMode = false
    }
  }
  
  var body: some View {
    ScrollView {
      VStack {
        HStack(spacing: 16) {
          Text(Strings.Wallet.verifyRecoveryPhraseTitle)
            .font(.title.weight(.medium))
            .foregroundColor(Color(uiColor: WalletV2Design.textPrimary))
            .fixedSize(horizontal: false, vertical: true)
          RecoveryPhrasePager(activeIndex: $activeCheckIndex)
        }
        Text(LocalizedStringKey(String.localizedStringWithFormat(Strings.Wallet.verifyRecoveryPhraseSubTitle, targetedRecoveryWordIndexes[activeCheckIndex] + 1)))
          .font(.subheadline)
          .foregroundColor(Color(uiColor: WalletV2Design.textPrimary))
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 40)
        VStack(alignment: .leading) {
          TextField("", text: $input)
            .font(.body)
            .autocorrectionDisabled()
            .autocapitalization(.none)
          Divider()
        }
        if isShowingError {
          HStack(spacing: 12) {
            Image(braveSystemName: "leo.warning.circle-filled")
              .renderingMode(.template)
              .foregroundColor(Color(.braveLighterOrange))
            Text(Strings.Wallet.verifyRecoveryPhraseError)
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
        Button {
          let targetIndex = targetedRecoveryWordIndexes[activeCheckIndex]
          if input == recoveryWords[targetIndex].value {
            isShowingError = false
            if activeCheckIndex == targetedRecoveryWordIndexes.count - 1 { // finished all checks
              if keyringStore.isOnboardingVisible {
                // check if biometric is available
                if isBiometricsAvailable {
                  isShowingBiometricsPrompt = true
                } else {
                  keyringStore.notifyWalletBackupComplete()
                  isShowingCompleteState = true
                }
              } else { // coming from BackUpWalletView
                keyringStore.notifyWalletBackupComplete()
              }
            } else {
              // next check
              activeCheckIndex += 1
              input = ""
            }
          } else {
            isShowingError = true
          }
        } label: {
          Text(Strings.Wallet.continueButtonTitle)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(BraveFilledButtonStyle(size: .large))
        .padding(.top, 86)
        Button(action: {
          isShowingSkipWarning = true
        }) {
          Text(Strings.Wallet.skipButtonTitle)
            .font(Font.subheadline.weight(.medium))
            .foregroundColor(Color(.braveLabel))
        }
        .padding(.top, 16)
      }
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 20)
    .background(Color(.braveBackground).edgesIgnoringSafeArea(.all))
    .background(
      WalletPromptView(
        isPresented: $isShowingSkipWarning,
        primaryButton: WalletPromptButton(title: Strings.Wallet.editTransactionErrorCTA, action: { _ in
          isShowingSkipWarning = false
        }),
        secondaryButton: WalletPromptButton(title: Strings.Wallet.backupSkipButtonTitle, action: { _ in
          isShowingSkipWarning = false
          isShowingCompleteState = true
        }),
        showCloseButton: false,
        content: {
          VStack(alignment: .leading, spacing: 20) {
            Text(Strings.Wallet.backupSkipPromptTitle)
              .font(.subheadline.weight(.medium))
              .foregroundColor(.primary)
            Text(Strings.Wallet.backupSkipPromptSubTitle)
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .multilineTextAlignment(.leading)
          .padding(.vertical, 20)
        })
    )
    .sheet(isPresented: $isShowingBiometricsPrompt, content: {
      BiometricView(
        keyringStore: keyringStore,
        password: password,
        onSkip: {
          isShowingBiometricsPrompt = false
          keyringStore.notifyWalletBackupComplete()
          isShowingCompleteState = true
        },
        onFinish: {
          isShowingBiometricsPrompt = false
          keyringStore.notifyWalletBackupComplete()
          isShowingCompleteState = true
        }
      )
    })
    .sheet(isPresented: $isShowingCompleteState) {
      OnBoardingCompletedView() {
        markOnboardingCompleted()
      }
    }
    .introspectViewController { vc in
      let appearance = UINavigationBarAppearance()
      appearance.configureWithTransparentBackground()
      vc.navigationItem.compactAppearance = appearance
      vc.navigationItem.scrollEdgeAppearance = appearance
      vc.navigationItem.standardAppearance = appearance
      vc.navigationItem.backButtonDisplayMode = .generic
    }
  }
}

#if DEBUG
struct VerifyRecoveryPhraseView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      VerifyRecoveryPhraseView(
        keyringStore: .previewStore,
        recoveryWords: [
          .init(value: "First", index: 0),
          .init(value: "Second", index: 1),
          .init(value: "Third", index: 2)
        ],
        targetedRecoveryWordIndexes: [0, 1, 2],
        password: ""
      )
    }
    .previewLayout(.sizeThatFits)
    .previewColorSchemes()
  }
}
#endif
