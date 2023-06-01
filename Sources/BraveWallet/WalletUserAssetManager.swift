// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Data
import BraveCore
import Preferences

public protocol WalletUserAssetManagerType: AnyObject {
  func getAllVisibleAssetsInNetworkAssets(networks: [BraveWallet.NetworkInfo]) -> [NetworkAssets]
  func getAllUserAssetsInNetworkAssets(networks: [BraveWallet.NetworkInfo]) -> [NetworkAssets]
  func getUserAsset(_ asset: BraveWallet.BlockchainToken) -> WalletUserAsset?
  func addUserAsset(_ asset: BraveWallet.BlockchainToken, completion: (() -> Void)?)
  func removeUserAsset(_ asset: BraveWallet.BlockchainToken, completion: (() -> Void)?)
  func updateUserAsset(for asset: BraveWallet.BlockchainToken, visible: Bool, completion: (() -> Void)?)
}

public class WalletUserAssetManager: WalletUserAssetManagerType {
  
  private let rpcService: BraveWalletJsonRpcService
  private let walletService: BraveWalletBraveWalletService
  
  public init(
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService
  ) {
    self.rpcService = rpcService
    self.walletService = walletService
  }
  
  public func getAllUserAssetsInNetworkAssets(networks: [BraveWallet.NetworkInfo]) -> [NetworkAssets] {
    var allVisibleUserAssets: [NetworkAssets] = []
    for (index, network) in networks.enumerated() {
      let groupId = "\(network.coin.rawValue).\(network.chainId)"
      if let walletUserAssets = WalletUserAssetGroup.getGroup(groupId: groupId)?.walletUserAssets {
        let networkAsset = NetworkAssets(
          network: network,
          tokens: walletUserAssets.map({ $0.blockchainToken }),
          sortOrder: index
        )
        allVisibleUserAssets.append(networkAsset)
      }
    }
    return allVisibleUserAssets.sorted(by: { $0.sortOrder < $1.sortOrder })
  }
  
  public func getAllVisibleAssetsInNetworkAssets(networks: [BraveWallet.NetworkInfo]) -> [NetworkAssets] {
    var allVisibleUserAssets: [NetworkAssets] = []
    for (index, network) in networks.enumerated() {
      let groupId = "\(network.coin.rawValue).\(network.chainId)"
      if let walletUserAssets = WalletUserAssetGroup.getGroup(groupId: groupId)?.walletUserAssets?.filter(\.visible) {
        let networkAsset = NetworkAssets(
          network: network,
          tokens: walletUserAssets.map({ $0.blockchainToken }),
          sortOrder: index
        )
        allVisibleUserAssets.append(networkAsset)
      }
    }
    return allVisibleUserAssets.sorted(by: { $0.sortOrder < $1.sortOrder })
  }
  
  public func getUserAsset(_ asset: BraveWallet.BlockchainToken) -> WalletUserAsset? {
    WalletUserAsset.getUserAsset(asset: asset)
  }
  
  public func addUserAsset(_ asset: BraveWallet.BlockchainToken, completion: (() -> Void)?) {
    WalletUserAsset.addUserAsset(asset: asset, completion: completion)
  }
  
  public func removeUserAsset(_ asset: BraveWallet.BlockchainToken, completion: (() -> Void)?) {
    WalletUserAsset.removeUserAsset(asset: asset, completion: completion)
  }
  
  public func updateUserAsset(for asset: BraveWallet.BlockchainToken, visible: Bool, completion: (() -> Void)?) {
    WalletUserAsset.updateUserAsset(for: asset, visible: visible, completion: completion)
  }
  
  public func migrateUserAssets(for coin: BraveWallet.CoinType? = nil, completion: (() -> Void)? = nil) {
    Task { @MainActor in
      guard !Preferences.Wallet.migrateCoreToWalletUserAssetCompleted.value else {
        return
      }
      var fetchedUserAssets: [String: [BraveWallet.BlockchainToken]] = [:]
      var networks: [BraveWallet.NetworkInfo] = []
      if let coin = coin {
        networks = await rpcService.allNetworks(coin)
      } else {
        networks = await rpcService.allNetworksForSupportedCoins()
      }
      networks = networks.filter { !WalletConstants.supportedTestNetworkChainIds.contains($0.chainId) }
      let networkAssets = await walletService.allUserAssets(in: networks)
      for networkAsset in networkAssets {
        fetchedUserAssets["\(networkAsset.network.coin.rawValue).\(networkAsset.network.chainId)"] = networkAsset.tokens
      }
      WalletUserAsset.migrateVisibleAssets(fetchedUserAssets) {
        Preferences.Wallet.migrateCoreToWalletUserAssetCompleted.value = true
        completion?()
      }
    }
  }
}

#if DEBUG
public class TestableWalletUserAssetManager: WalletUserAssetManagerType {
  public var _getAllVisibleAssetsInNetworkAssets: ((_ networks: [BraveWallet.NetworkInfo]) -> [NetworkAssets])?
  public var _getAllUserAssetsInNetworkAssets: ((_ networks: [BraveWallet.NetworkInfo]) -> [NetworkAssets])?
  
  public init() {}
  
  public func getAllUserAssetsInNetworkAssets(networks: [BraveWallet.NetworkInfo]) -> [NetworkAssets] {
    _getAllUserAssetsInNetworkAssets?(networks) ?? []
  }
  
  public func getAllVisibleAssetsInNetworkAssets(networks: [BraveWallet.NetworkInfo]) -> [NetworkAssets] {
    _getAllVisibleAssetsInNetworkAssets?(networks) ?? []
  }
  
  public func getUserAsset(_ asset: BraveWallet.BlockchainToken) -> WalletUserAsset? {
    return nil
  }
  
  public func addUserAsset(_ asset: BraveWallet.BlockchainToken, completion: (() -> Void)?) {
  }
  
  public func removeUserAsset(_ asset: BraveWallet.BlockchainToken, completion: (() -> Void)?) {
  }
  
  public func updateUserAsset(for asset: BraveWallet.BlockchainToken, visible: Bool, completion: (() -> Void)?) {
  }
}
#endif
