// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import ComposableArchitecture

struct PortfolioState: Equatable {
  struct VisibleAsset: Equatable, Identifiable {
    var token: BraveWallet.ERCToken
    var price: String
    var decimalBalance: Double
    
    var id: String {
      token.symbol
    }
  }
  
  @BindableState var isPresentingEditUserAssets: Bool = false
  @BindableState var isPresentingBackup: Bool = false
  var dismissedBackupBannerThisSession: Bool = false
  var visibleAssets: [VisibleAsset] = []
  var totalBalance: String = ""
  var balanceHistory: [BalanceTimePrice] = []
  var selectedTimeframe: BraveWallet.AssetPriceTimeframe = .oneDay
  var isLoadingBalances: Bool = false
  var selectedChain: BraveWallet.EthereumChain = .init()
  var isShowingBackupBanner: Bool = false
  var selectedToken: BraveWallet.ERCToken?
}

enum PortfolioAction: BindableAction, Equatable {
  case onAppear
  case isWalletBackedUp(Bool)
  case update
  case dataLoaded([PortfolioState.VisibleAsset], history: [BalanceTimePrice])
  case network(BraveWallet.EthereumChain)
  case dismissedBackupBanner
  case assetTapped(BraveWallet.ERCToken)
  case assetDetailDismissed
  case keyringObservation(KeyringObserver.Action)
  case rpcObservation(NetworkObserverAction)
  case binding(BindingAction<PortfolioState>)
  case lock
  case addAccount
}

struct PortfolioEnvironment {
  let keyringController: BraveWalletKeyringController
  let keyringObserver: Effect<KeyringObserver.Action, Never>
  let rpcController: BraveWalletEthJsonRpcController
  let rpcControllerObserver: Effect<NetworkObserverAction, Never>
  let walletService: BraveWalletBraveWalletService
  let assetRatioController: BraveWalletAssetRatioController
  let tokenRegistry: BraveWalletERCTokenRegistry
}

let portfolioReducer: Reducer<
  PortfolioState, PortfolioAction, PortfolioEnvironment
> = .init { state, action, environment in
  switch action {
  case .onAppear:
    return .merge(
      Effect(value: .update),
      .future { callback in
        environment
          .rpcController
          .network {
            callback(.success(.network($0)))
          }
      },
      .future { callback in
        environment
          .keyringController
          .isWalletBackedUp {
            callback(.success(.isWalletBackedUp($0)))
          }
      },
      environment
        .rpcControllerObserver
        .map(PortfolioAction.rpcObservation),
      environment
        .keyringObserver
        .cancellable(id: KeyringObserver.CancelId())
        .map(PortfolioAction.keyringObservation)
    )
    
  case .network(let chain):
    state.selectedChain = chain
    return .none
    
  case .isWalletBackedUp(let isBackedUp):
    state.isShowingBackupBanner = !state.dismissedBackupBannerThisSession && !isBackedUp
    return .none
  
  case .dismissedBackupBanner:
    state.dismissedBackupBannerThisSession = true
    state.isShowingBackupBanner = false
    return .none
    
  case .keyringObservation(.backedUp):
    state.isShowingBackupBanner = false
    return .none
    
  case .keyringObservation:
    return .none
    
  case .rpcObservation(.chainChangedEvent):
    return .merge(
      .future { callback in
        environment
          .rpcController
          .network {
            callback(.success(.network($0)))
          }
      },
      Effect(value: .update)
    )
    
  case .rpcObservation:
    return .none
    
  case .dataLoaded(let assets, let history):
    state.visibleAssets = assets
    state.isLoadingBalances = false
    state.balanceHistory = [
    ]
    return .none
    
  case .assetTapped(let token):
    state.selectedToken = token
    return .none
    
  case .assetDetailDismissed:
    state.selectedToken = nil
    return .none
    
  case .lock:
    return .fireAndForget {
      environment
        .keyringController.lock()
    }
    
  case .addAccount:
    return .fireAndForget {
      environment.keyringController.addAccount("Test") { _ in
      }
    }
    
  case .update:
    state.isLoadingBalances = true
    return .merge(
      .future { callback in
        Task {
          let chainId = await environment.rpcController.chainId()
          let assets = await environment.walletService.userAssets(chainId)
            .filter(\.visible)
          var visibleAssets: [PortfolioState.VisibleAsset] = []
          for token in assets {
            let asset = PortfolioState.VisibleAsset(
              token: token,
              price: "–",
              decimalBalance: 0
            )
            visibleAssets.append(asset)
          }
          callback(.success(.dataLoaded(visibleAssets, history: [])))
        }
      }
        .receive(on: DispatchQueue.main)
        .eraseToEffect(),
      .future { [selectedTimeframe = state.selectedTimeframe] callback in
        Task { @MainActor in
          let chainId = await environment.rpcController.chainId()
          let assets = await environment.walletService.userAssets(chainId)
            .filter(\.visible)
          let keyring = await environment.keyringController.defaultKeyringInfo()
          // Fetch balances for all accounts for each visible asset
          let fetchBalanceTask = Task { () -> [String: Double] in
            var balances: [String: Double] = [:]
            for account in keyring.accountInfos {
              for token in assets {
                if let balance = await environment.rpcController.balance(for: token, in: account) {
                  balances[token.symbol] = balance
                }
              }
            }
            return balances
          }
          // Fetch prices for all visible assets
          let fetchPricesTask = Task { () -> [String: String] in
            let (success, prices) = await Task { @MainActor in
              return await environment.assetRatioController
                .price(
                  assets.map { $0.symbol.lowercased() },
                  toAssets: ["usd"],
                  timeframe: selectedTimeframe
                )
            }.value
            if success {
              return prices.reduce(into: [String: String](), { result, value in
                result[value.fromAsset.lowercased()] = value.price
              })
            }
            return [:]
          }
          
          async let prices = await fetchPricesTask.value
          async let balances = await fetchBalanceTask.value
          
          // Fetch price history for all visible assets
          let fetchHistoryTask = Task { () -> [BalanceTimePrice] in
            var history: [String: [BraveWallet.AssetTimePrice]] = [:]
            for token in assets {
              let (success, values) = await Task { @MainActor in
                return await environment.assetRatioController.priceHistory(token.symbol.lowercased(), timeframe: selectedTimeframe)
              }.value
              if success {
                history[token.symbol.lowercased()] = values
              }
            }
            // Shortest array count
            guard let minCount = history.map({ $1.count }).min() else {
              return []
            }
            let normalized = history.mapValues { $0[0..<minCount] }
            return []
            //          return (0..<minCount).map { index in
            //            let value: Double = { //history.reduce(0.0, { result, item in
            //              var value = 0.0
            //              for (key, value) in normalized {
            //                if let balance = balances[key.lowercased()] {
            //                  value += ((Double(value[index].price) ?? 0.0) * balance)
            //                }
            //              }
            //              return value
            //            }()
            //            return .init(
            //              date: assets.map { $0.history[index].date }.max() ?? .init(),
            //              price: value,
            //              formattedPrice: "0.00" /*numberFormatter.string(from: NSNumber(value: value)) ?? */
            //            )
            //          }
          }
          
          async let history = await fetchHistoryTask.value
          
          var visibleAssets: [PortfolioState.VisibleAsset] = []
          for token in assets {
            let asset = PortfolioState.VisibleAsset(
              token: token,
              price: await prices[token.symbol.lowercased()] ?? "–",
              decimalBalance: await balances[token.symbol] ?? 0
            )
            visibleAssets.append(asset)
          }
          
          callback(.success(.dataLoaded(
            visibleAssets, history: await history
          )))
        }
      }
        .receive(on: DispatchQueue.main)
        .eraseToEffect()
    )
    
  case .binding:
    return .none
  }
}
.debug()
