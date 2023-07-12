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

  @State private var recoveryWords: [RecoveryWord]
  @State private var randomizedWords: [RecoveryWord]
  @State private var selectedWords: [RecoveryWord] = []
  @State private var input: String = ""
  @State private var isShowingError = false
  @State private var activeCheckIndex: Int = 0
  @State private var isShowingBiometricsPrompt: Bool = false
  @State private var isShowingSkipWarning: Bool = false
  @State private var isShowingCompleteState: Bool = false

  @Environment(\.modalPresentationMode) @Binding private var modalPresentationMode
  
  @FocusState private var isTextFieldFocused: Bool
  
  private let targetedRecoveryWordIndexes: [Int]
  private let password: String
  
  init(
    recoveryWords: [RecoveryWord],
    keyringStore: KeyringStore,
    password: String
  ) {
    self.recoveryWords = recoveryWords
    self.randomizedWords = recoveryWords.shuffled()
    self.keyringStore = keyringStore
    var loop = 3
    var indexes: [Int] = []
    while loop != 0 {
      let randomIndex = Int.random(in: 0..<recoveryWords.count)
      if !indexes.contains(randomIndex) {
        indexes.append(randomIndex)
        loop -= 1
      }
    }
    self.targetedRecoveryWordIndexes = indexes
    self.password = password
  }

  private var wordsSelectedInCorrectOrder: Bool {
    recoveryWords == selectedWords
  }

  private func tappedWord(_ word: RecoveryWord) {
    withAnimation(.default) {
      selectedWords.append(word)
    }
  }

  private func tappedVerify() {
    guard wordsSelectedInCorrectOrder else { return }
    keyringStore.notifyWalletBackupComplete()
    if keyringStore.isOnboardingVisible {
      keyringStore.markOnboardingCompleted()
    } else {
      modalPresentationMode = false
    }
  }
  
  private var isBiometricsAvailable: Bool {
    LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
  }
  
  var body: some View {
    ScrollView {
      VStack {
        HStack(spacing: 16) {
          Text(Strings.Wallet.verifyRecoveryPhraseTitle)
            .font(.title.weight(.medium))
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
          RecoveryPhrasePager(activeIndex: $activeCheckIndex)
        }
        Text(LocalizedStringKey(String.localizedStringWithFormat(Strings.Wallet.verifyRecoveryPhraseSubTitle, targetedRecoveryWordIndexes[activeCheckIndex] + 1)))
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 40)
        VStack(alignment: .leading) {
          TextField("", text: $input)
            .focused($isTextFieldFocused)
            .autocorrectionDisabled()
            .autocapitalization(.none)
          Divider()
        }
        if isShowingError {
          HStack(spacing: 12) {
            Image(braveSystemName: "leo.warning.circle-filled")
              .renderingMode(.template)
              .foregroundColor(Color(.braveLighterOrange))
            Text("Recovery phrase doesn't match.")
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
              // check if biometric is available
              if isBiometricsAvailable {
                isShowingBiometricsPrompt = true
              } else {
                isShowingCompleteState = true
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
    .padding()
    .background(Color(.braveBackground).edgesIgnoringSafeArea(.all))
    .background(
      WalletPromptView(
        isPresented: $isShowingSkipWarning,
        primaryButton: WalletPromptButton(title: Strings.Wallet.editTransactionErrorCTA, action: { _ in
          isShowingSkipWarning = false
        }),
        secondaryButton: WalletPromptButton(title: Strings.Wallet.backupSkipButtonTitle, action: { _ in
          isShowingSkipWarning = false
          keyringStore.markOnboardingCompleted()
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
          keyringStore.notifyWalletBackupComplete()
          if keyringStore.isOnboardingVisible {
            keyringStore.markOnboardingCompleted()
          } else {
            modalPresentationMode = false
          }
        }
      )
    })
    .sheet(isPresented: $isShowingCompleteState) {
      OnBoardingCompletedView() {
        keyringStore.notifyWalletBackupComplete()
        if keyringStore.isOnboardingVisible {
          keyringStore.markOnboardingCompleted()
        } else {
          modalPresentationMode = false
        }
      }
    }
  }
}

#if DEBUG
struct VerifyRecoveryPhraseView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      VerifyRecoveryPhraseView(
        recoveryWords: [
          .init(value: "First", index: 0),
          .init(value: "Second", index: 1),
          .init(value: "Third", index: 2)
        ],
        keyringStore: .previewStore,
        password: ""
      )
    }
    .previewLayout(.sizeThatFits)
    .previewColorSchemes()
  }
}
#endif
