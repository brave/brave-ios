// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import Combine
import Data
import Preferences

/// The main wallet store
public class WalletStore {

  public let keyringStore: KeyringStore
  public var cryptoStore: CryptoStore?
  /// The origin of the active tab (if applicable). Used for fetching/selecting network for the DApp origin.
  public var origin: URLOrigin? {
    didSet {
      cryptoStore?.origin = origin
      keyringStore.origin = origin
    }
  }
  
  public let onPendingRequestUpdated = PassthroughSubject<Void, Never>()

  // MARK: -

  private var cancellable: AnyCancellable?
  private var onPendingRequestCancellable: AnyCancellable?

  public init(
    keyringService: BraveWalletKeyringService,
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService,
    assetRatioService: BraveWalletAssetRatioService,
    swapService: BraveWalletSwapService,
    blockchainRegistry: BraveWalletBlockchainRegistry,
    txService: BraveWalletTxService,
    ethTxManagerProxy: BraveWalletEthTxManagerProxy,
    solTxManagerProxy: BraveWalletSolanaTxManagerProxy,
    ipfsApi: IpfsAPI
  ) {
    self.keyringStore = .init(keyringService: keyringService, walletService: walletService, rpcService: rpcService)
    self.setUp(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      assetRatioService: assetRatioService,
      swapService: swapService,
      blockchainRegistry: blockchainRegistry,
      txService: txService,
      ethTxManagerProxy: ethTxManagerProxy,
      solTxManagerProxy: solTxManagerProxy,
      ipfsApi: ipfsApi
    )
  }

  private func setUp(
    keyringService: BraveWalletKeyringService,
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService,
    assetRatioService: BraveWalletAssetRatioService,
    swapService: BraveWalletSwapService,
    blockchainRegistry: BraveWalletBlockchainRegistry,
    txService: BraveWalletTxService,
    ethTxManagerProxy: BraveWalletEthTxManagerProxy,
    solTxManagerProxy: BraveWalletSolanaTxManagerProxy,
    ipfsApi: IpfsAPI
  ) {
    self.cancellable = self.keyringStore.$defaultKeyring
      .map(\.isKeyringCreated)
      .removeDuplicates()
      .sink { [weak self] isDefaultKeyringCreated in
        guard let self = self else { return }
        if !isDefaultKeyringCreated, self.cryptoStore != nil {
          self.cryptoStore = nil
        } else if isDefaultKeyringCreated, self.cryptoStore == nil {
          if !Preferences.Wallet.migrateCoreToWalletUserAssetCompleted.value {
            self.migrateUserAssets(
              rpcService: rpcService,
              walletService: walletService
            )
          }
          self.cryptoStore = CryptoStore(
            keyringService: keyringService,
            rpcService: rpcService,
            walletService: walletService,
            assetRatioService: assetRatioService,
            swapService: swapService,
            blockchainRegistry: blockchainRegistry,
            txService: txService,
            ethTxManagerProxy: ethTxManagerProxy,
            solTxManagerProxy: solTxManagerProxy,
            ipfsApi: ipfsApi,
            origin: self.origin
          )
          if let cryptoStore = self.cryptoStore {
            Task {
              // if called in `CryptoStore.init` we may crash
              await cryptoStore.networkStore.setup()
            }
            self.onPendingRequestCancellable = cryptoStore.$pendingRequest
              .removeDuplicates()
              .sink { [weak self] _ in
                self?.onPendingRequestUpdated.send()
              }
          }
        }
      }
  }
  
  private func migrateUserAssets(
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService
  ) {
    Task { @MainActor in
      var fetchedUserAssets: [String: [BraveWallet.BlockchainToken]] = [:]
      let networks = await rpcService.allNetworksForSupportedCoins()
        .filter { !WalletConstants.supportedTestNetworkChainIds.contains($0.chainId) }
      for network in networks {
        let assets = await walletService.userAssets(network.chainId, coin: network.coin)
        fetchedUserAssets["\(network.coin.rawValue).\(network.chainId)"] = assets
      }
      WalletUserAsset.migrateVisibleAssets(fetchedUserAssets) {
        let allGroups = WalletUserAssetGroup.getAllGroups()
        print("*****After migration, groups count: \(allGroups?.count ?? 0)")
        if let groups = allGroups {
          for group in groups {
            print("GroupId: \(group.groupId)")
            if let assets = group.walletUserAssets {
              print("Assets: \(assets.count)")
            }
          }
        }
        if let assets = WalletUserAsset.getAllUserAssets() {
          for asset in assets {
            print("Asset name: \(asset.name) coin: \(BraveWallet.CoinType(rawValue: Int(asset.coin))) chainId: \(asset.chainId)")
          }
        }
        Preferences.Wallet.migrateCoreToWalletUserAssetCompleted.value = true
      }
    }
  }
}
