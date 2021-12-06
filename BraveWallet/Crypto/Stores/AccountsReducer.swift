// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import ComposableArchitecture
import SwiftUI

struct AccountListState: Equatable {
  var accounts: [BraveWallet.AccountInfo] = []
}

enum AccountListAction {
  case onAppear
  case fetchedAccounts([BraveWallet.AccountInfo])
  case accountTapped(BraveWallet.AccountInfo)
  case settingsTapped
  case backupTapped
  case addAccountTapped
}

struct AccountListEnvironment {
  var keyringController: BraveWalletKeyringController
}

let accountListReducer = Reducer<
  AccountListState, AccountListAction, AccountListEnvironment
> { state, action, environment in
  switch action {
  case .onAppear:
    return .future { callback in
      environment.keyringController
        .defaultKeyringInfo { keyring in
          callback(.success(.fetchedAccounts(keyring.accountInfos)))
        }
    }
    
  case .fetchedAccounts(let accounts):
    state.accounts = accounts
    return .none
    
  case .settingsTapped:
    return .none
    
  case .backupTapped:
    return .none
    
  case .addAccountTapped:
    return .none
    
  case .accountTapped(_):
    return .none
  }
}
