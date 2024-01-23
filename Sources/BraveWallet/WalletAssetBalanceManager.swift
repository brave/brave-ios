// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Data
import BraveCore
import Preferences
import CoreData

public protocol WalletUserAssetBalanceManagerType: AnyObject {
  /// Return balance in String of the given asset. Return nil if there no balance stored
  func getBalance(for asset: BraveWallet.BlockchainToken?, account: String?) -> [WalletUserAssetBalance]?
  /// Store asset balance if there is none exists. Update asset balance if asset exists in database
  func updateBalance(for asset: BraveWallet.BlockchainToken, account: String, balance: String, completion: (() -> Void)?)
  /// Remove a `WalletUserAssetBalance` representation of the given
  /// `BraveWallet.BlockchainToken` from CoreData
  func removeBalance(for asset: BraveWallet.BlockchainToken, completion: (() -> Void)?)
}

public class WalletUserAssetBalanceManager: WalletUserAssetBalanceManagerType {
 
  private let keyringService: BraveWalletKeyringService
  private let rpcService: BraveWalletJsonRpcService
  private let assetManager: WalletUserAssetManager
  
  init(
    keyringService: BraveWalletKeyringService,
    rpcService: BraveWalletJsonRpcService,
    assetManager: WalletUserAssetManager
  ) {
    self.keyringService = keyringService
    self.rpcService = rpcService
    self.assetManager = assetManager
  }
  
  public func getBalance(for asset: BraveWallet.BlockchainToken?, account: String?) -> [WalletUserAssetBalance]? {
    WalletUserAssetBalance.getBalance(for: asset, account: account)
  }
  
  public func updateBalance(for asset: BraveWallet.BlockchainToken, account: String, balance: String, completion: (() -> Void)?) {
    WalletUserAssetBalance.updateBalance(
      for: asset,
      balance: balance,
      account: account,
      completion: completion
    )
  }
  
  public func removeBalance(for asset: BraveWallet.BlockchainToken, completion: (() -> Void)?) {
    WalletUserAssetBalance.removeBalance(
      for: asset,
      completion: completion
    )
  }
  
  public func refreshBalances() async {
    let accounts = await keyringService.allAccounts().accounts
    let allNetworks = await rpcService.allNetworksForSupportedCoins()
    let allUserAssets: [NetworkAssets] = assetManager.getAllUserAssetsInNetworkAssets(
      networks: allNetworks,
      includingUserDeleted: false
    )
    typealias TokenNetworkAccounts = (token: BraveWallet.BlockchainToken, network: BraveWallet.NetworkInfo, accounts: [BraveWallet.AccountInfo])
    let allTokenNetworkAccounts = allUserAssets.flatMap { networkAssets in
      networkAssets.tokens.map { token in
        TokenNetworkAccounts(
          token: token,
          network: networkAssets.network,
          accounts: accounts.filter {
            if token.coin == .fil {
              return $0.keyringId == BraveWallet.KeyringId.keyringId(for: token.coin, on: token.chainId)
            } else {
              return $0.coin == token.coin
            }
          }
        )
      }
    }
    /// Fetch balance for each token, for all accounts applicable to that token
    await withTaskGroup(
      of: Void.self,
      body: { @MainActor [rpcService] group in
        for tokenNetworkAccounts in allTokenNetworkAccounts { // for each token
          group.addTask { @MainActor in
            let token = tokenNetworkAccounts.token
            for account in tokenNetworkAccounts.accounts { // fetch balance for this token for each account
              let balanceForToken = await rpcService.balance(
                for: token,
                in: account,
                network: tokenNetworkAccounts.network
              )
              WalletUserAssetBalance.updateBalance(for: token, balance: String(balanceForToken ?? 0), account: account.address)
            }
          }
        }
      }
    )
  }
}

#if DEBUG
public class TestableWalletUserAssetBalanceManager: WalletUserAssetBalanceManagerType {
  public var _getBalance: ((_ asset: BraveWallet.BlockchainToken?, _ account: String?) -> [WalletUserAssetBalance]?)?
  
  public init() {}
  
  public func getBalance(for asset: BraveWallet.BlockchainToken?, account: String?) -> [WalletUserAssetBalance]? {
    _getBalance?(asset, account)
  }
  
  public func updateBalance(for asset: BraveWallet.BlockchainToken, account: String, balance: String, completion: (() -> Void)?) {
    completion?()
  }
  
  public func removeBalance(for asset: BraveWallet.BlockchainToken, completion: (() -> Void)?) {
    completion?()
  }
}
#endif
