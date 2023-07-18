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

struct BackupRecoveryPhraseView: View {
  @ObservedObject var keyringStore: KeyringStore
  
  @State private var password: String
  @State private var recoveryWords: [RecoveryWord] = []
  @State private var isViewRecoveryPermitted: Bool = false
  @State private var isShowingSkipWarning: Bool = false
  @State private var hasCopied: Bool = false
  @State private var verifyRecoveryWordIndexes: [Int]?
  @State private var isShowingBiometricsPrompt: Bool = false
  @State private var isShowingCompleteState: Bool = false
  
  private var isBiometricsAvailable: Bool {
    LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
  }
  
  init(
    password: String,
    keyringStore: KeyringStore
  ) {
    self.password = password
    self.keyringStore = keyringStore
  }

  private func copyRecoveryPhrase() {
    UIPasteboard.general.setSecureString(
      recoveryWords.map(\.value).joined(separator: " ")
    )
    hasCopied = true
  }

  var body: some View {
    ScrollView(.vertical) {
      VStack(spacing: 16) {
        Group {
          Text(Strings.Wallet.backupRecoveryPhraseTitle)
            .font(.title)
            .foregroundColor(Color(uiColor: WalletV2Design.textPrimary))
          Text(Strings.Wallet.backupRecoveryPhraseSubtitle)
            .font(.subheadline)
            .foregroundColor(Color(uiColor: WalletV2Design.textSecondary))
            .padding(.bottom, 20)
        }
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
        RecoveryPhraseGrid(data: recoveryWords, id: \.self) { word in
          HStack(spacing: 10) {
            Text("#\(word.index + 1)")
            Text("\(word.value)")
              .customPrivacySensitive()
              .multilineTextAlignment(.leading)
              .frame(maxWidth: .infinity)
          }
          .font(.footnote.bold())
          .padding(8)
          .overlay(
            RoundedRectangle(cornerRadius: 4)
              .stroke(Color(.braveDisabled), lineWidth: 1)
          )
        }
        .padding(.horizontal)
        .blur(radius: isViewRecoveryPermitted ? 0 : 4)
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(.braveDisabled), lineWidth: isViewRecoveryPermitted ? 0 : 1)
        )
        if isViewRecoveryPermitted {
          Button(action: copyRecoveryPhrase) {
            if hasCopied {
              Text("\(Strings.Wallet.copiedToPasteboard)  \(Image(braveSystemName: "leo.check.normal"))")
                .font(.subheadline.bold())
                .foregroundColor(Color(.braveSuccessLabel))
            } else {
              Text(Strings.Wallet.copyToPasteboard)
                .font(.subheadline.bold())
                .foregroundColor(Color(.braveBlurpleTint))
            }
          }
          .padding(.top, 20)
          Button {
            var loop = 3
            var indexes: [Int] = []
            while loop != 0 {
              let randomIndex = Int.random(in: 0..<recoveryWords.count)
              if !indexes.contains(randomIndex) {
                indexes.append(randomIndex)
                loop -= 1
              }
            }
            verifyRecoveryWordIndexes = indexes
          } label: {
            Text(Strings.Wallet.continueButtonTitle)
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(BraveFilledButtonStyle(size: .large))
          .padding(.top, 72)
          .padding(.horizontal)
        } else {
          Button {
            isViewRecoveryPermitted = true
          } label: {
            Text(Strings.Wallet.viewRecoveryPhraseButtonTitle
            )
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(BraveFilledButtonStyle(size: .large))
          .padding(.top, 72)
          .padding(.horizontal)
        }
        if keyringStore.isOnboardingVisible {
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
    }
    .introspectViewController { vc in
      let appearance = UINavigationBarAppearance()
      appearance.configureWithTransparentBackground()
      vc.navigationItem.compactAppearance = appearance
      vc.navigationItem.scrollEdgeAppearance = appearance
      vc.navigationItem.standardAppearance = appearance
      vc.navigationItem.backButtonTitle = Strings.Wallet.backupRecoveryPhraseBackButtonTitle
      vc.navigationItem.backButtonDisplayMode = .generic
    }
    .background(Color(.braveBackground).edgesIgnoringSafeArea(.all))
    .alertOnScreenshot {
      Alert(
        title: Text(Strings.Wallet.screenshotDetectedTitle),
        message: Text(Strings.Wallet.recoveryPhraseScreenshotDetectedMessage),
        dismissButton: .cancel(Text(Strings.OKString))
      )
    }
    .background(
      NavigationLink(
        isActive: Binding(
          get: { verifyRecoveryWordIndexes != nil },
          set: { if !$0 { verifyRecoveryWordIndexes = nil }}
        ),
        destination: {
          if let verifyRecoveryWordIndexes {
            VerifyRecoveryPhraseView(
              keyringStore: keyringStore,
              recoveryWords: recoveryWords,
              targetedRecoveryWordIndexes: verifyRecoveryWordIndexes,
              password: password
            )
          }
        },
        label: {
          EmptyView()
        })
    )
    .background(
      WalletPromptView(
        isPresented: $isShowingSkipWarning,
        primaryButton: WalletPromptButton(title: Strings.Wallet.editTransactionErrorCTA, action: { _ in
          isShowingSkipWarning = false
        }),
        secondaryButton: WalletPromptButton(title: Strings.Wallet.backupSkipButtonTitle, action: { _ in
          isShowingSkipWarning = false
          if isBiometricsAvailable {
            isShowingBiometricsPrompt = true
          } else {
            isShowingCompleteState = true
          }
        }),
        showCloseButton: false,
        content: {
          VStack(alignment: .leading, spacing: 20) {
            Text(Strings.Wallet.backupSkipPromptTitle)
              .font(.subheadline.weight(.medium))
              .foregroundColor(Color(uiColor: WalletV2Design.textPrimary))
            Text(Strings.Wallet.backupSkipPromptSubTitle)
              .font(.subheadline)
              .foregroundColor(Color(uiColor: WalletV2Design.textSecondary))
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
          isShowingCompleteState = true
        },
        onFinish: {
          isShowingBiometricsPrompt = false
          isShowingCompleteState = true
        }
      )
    })
    .sheet(isPresented: $isShowingCompleteState) {
      OnBoardingCompletedView() {
        keyringStore.markOnboardingCompleted()
      }
    }
    .onAppear {
      keyringStore.recoveryPhrase(password: password) { words in
        recoveryWords = words
      }
    }
  }
}

#if DEBUG
struct BackupRecoveryPhraseView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      BackupRecoveryPhraseView(
        password: "",
        keyringStore: .previewStore
      )
    }
    .previewLayout(.sizeThatFits)
    .previewColorSchemes()
  }
}
#endif
