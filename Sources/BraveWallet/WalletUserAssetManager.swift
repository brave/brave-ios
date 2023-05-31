// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Data
import BraveCore

public protocol WalletUserAssetManagerType: AnyObject {
  func getAllVisibleAssetsInNetworkAssets(networks: [BraveWallet.NetworkInfo]) -> [NetworkAssets]
  func getAllUserAssetsInNetworkAssets(networks: [BraveWallet.NetworkInfo]) -> [NetworkAssets]
}

public class WalletUserAssetManager: WalletUserAssetManagerType {
  
  public init() {}
  
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
}
#endif
