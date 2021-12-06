// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import ComposableArchitecture

struct CryptoState: Equatable {
  @BindableState var isShowingSearch: Bool = false
  var isShowingSettings: Bool = false
  var fetchedUnapprovedTransactionsThisSession: Bool = false
  var buySendSwapDestination: BuySendSwapDestination?
  var isPresentingTransactionConfirmations: Bool = false
  var unapprovedTransactions: [BraveWallet.TransactionInfo] = []
  var portfolio: PortfolioState = .init()
  var accountList: AccountListState = .init()
}

enum CryptoMenuAction {
  case lockWallet
  case openSettings
}

enum CryptoAction: BindableAction {
  case onAppear
  case menu(CryptoMenuAction)
  case binding(BindingAction<CryptoState>)
  case fetchedUnapprovedTransactions([BraveWallet.TransactionInfo])
  case transactionObservation(TransactionAction)
  case portfolio(PortfolioAction)
  case accountList(AccountListAction)
}

let cryptoReducer: Reducer<CryptoState, CryptoAction, WalletEnvironment> = .combine(
  portfolioReducer
    .pullback(state: \.portfolio, action: /CryptoAction.portfolio, environment: {
      return .init(
        keyringController: $0.keyringController,
        keyringObserver: $0.keyringObserver,
        rpcController: $0.rpcController,
        rpcControllerObserver: $0.rpcControllerObserver,
        walletService: $0.walletService,
        assetRatioController: $0.assetRatioController,
        tokenRegistry: $0.tokenRegistry
      )
    }),
  accountListReducer
    .pullback(state: \.accountList, action: /CryptoAction.accountList, environment: {
      return .init(
        keyringController: $0.keyringController
      )
    }),
  Reducer { state, action, environment in
    struct CancelId: Hashable {}
    switch action {
    case .onAppear:
      return .merge(
        Effect<[BraveWallet.TransactionInfo], Never>.future { callback in
          let task = Task {
            guard !Task.isCancelled else { return }
            let keyring = await environment.keyringController.defaultKeyringInfo()
            var transactions: [BraveWallet.TransactionInfo] = []
            for account in keyring.accountInfos {
              transactions.append(contentsOf:
                await environment.transactionController.allTransactionInfo(account.address)
                  .filter { $0.txStatus == .unapproved }
              )
            }
            guard !Task.isCancelled else { return }
            callback(.success(transactions))
          }
        }
          .map(CryptoAction.fetchedUnapprovedTransactions),
        environment
          .transactionObserver
          .cancellable(id: CancelId(), cancelInFlight: true)
          .map(CryptoAction.transactionObservation)
      )
      
    case .menu(.lockWallet):
      environment.keyringController.lock()
      return .none
      
    case .menu(.openSettings):
      state.isShowingSettings = true
      return .none
      
    case .transactionObservation:
      return .none
      
    case .fetchedUnapprovedTransactions(let transactions):
      state.isPresentingTransactionConfirmations = !transactions.isEmpty
      state.unapprovedTransactions = transactions
      return .none
      
    case .binding:
      return .none
      
    case .portfolio:
      return .none
      
    case .accountList:
      return .none
    }
  }
  .binding()
)
