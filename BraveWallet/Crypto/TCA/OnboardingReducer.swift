// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import ComposableArchitecture

struct OnboardingState: Equatable {
  enum CurrentStep {
    case welcome
    case createWallet
    case backupWelcome
    case backupPhrase
    case verifyPhrase
  }
  var step: CurrentStep = .welcome
  var recoveryPhrase: String?
}

enum OnboardingAction {
  case moveForward
  case fetchRecoveryPhrase
  case recoveryPhraseFetched(String)
}

struct OnboardingEnvironment {
  var keyringController: BraveWalletKeyringController
}

let onboardingReducer = Reducer<
  OnboardingState, OnboardingAction, OnboardingEnvironment
> { state, action, environment in
  switch action {
  case .moveForward:
    return .none
  case .fetchRecoveryPhrase:
    return .future { callback in
      environment
        .keyringController.mnemonic { phrase in
          callback(.success(.recoveryPhraseFetched(phrase)))
        }
    }
  case .recoveryPhraseFetched(let phrase):
    state.recoveryPhrase = phrase
    return .none
  }
}
