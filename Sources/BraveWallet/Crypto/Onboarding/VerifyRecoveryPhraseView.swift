/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftUI
import DesignSystem
import Strings

struct VerifyRecoveryPhraseView: View {
  @ObservedObject var keyringStore: KeyringStore

  @State private var recoveryWords: [RecoveryWord]
  @State private var randomizedWords: [RecoveryWord]
  @State private var selectedWords: [RecoveryWord] = []
  @State private var input: String = ""
  @State private var isShowingError = false
  @State private var activeCheckIndex = 0

  @Environment(\.modalPresentationMode) @Binding private var modalPresentationMode
  
  @FocusState private var isTextFieldFocused: Bool
  
  private let randomizedIndex: Int = 0
  private let targetedRecoveryWordIndexes: [Int]
  
  init(
    recoveryWords: [RecoveryWord],
    keyringStore: KeyringStore
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
  
  var body: some View {
    ScrollView {
      VStack {
        HStack(spacing: 10) {
          Text(Strings.Wallet.verifyRecoveryPhraseTitle)
            .font(.title.weight(.medium))
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
          RecoveryPhrasePager(activeIndex: $activeCheckIndex)
        }
        Group {
          Text(String.localizedStringWithFormat(Strings.Wallet.verifyRecoveryPhraseSubTitle, targetedRecoveryWordIndexes[activeCheckIndex] + 1))
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 40)
        VStack(alignment: .leading) {
          TextField("", text: $input)
            .focused($isTextFieldFocused)
            .autocorrectionDisabled()
            .autocapitalization(.none)
          Divider()
        }
        Button {
          let targetIndex = targetedRecoveryWordIndexes[activeCheckIndex]
          if input == recoveryWords[targetIndex].value {
            isShowingError = false
            if activeCheckIndex == targetedRecoveryWordIndexes.count - 1 { // finished all checks
              keyringStore.notifyWalletBackupComplete()
              if keyringStore.isOnboardingVisible {
                keyringStore.markOnboardingCompleted()
              } else {
                modalPresentationMode = false
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
        }) {
          Text(Strings.Wallet.skipButtonTitle)
            .font(Font.subheadline.weight(.medium))
            .foregroundColor(Color(.braveLabel))
        }
      }
    }
    .padding()
    .background(Color(.braveBackground).edgesIgnoringSafeArea(.all))
    .navigationTitle(Strings.Wallet.braveWallet)
    .navigationBarTitleDisplayMode(.inline)
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
        keyringStore: .previewStore
      )
    }
    .previewLayout(.sizeThatFits)
    .previewColorSchemes()
  }
}
#endif
