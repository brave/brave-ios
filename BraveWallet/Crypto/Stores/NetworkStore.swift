/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import BraveCore
import SwiftUI
import Strings

/// An interface that helps you interact with a json-rpc service
///
/// This wraps a JsonRpcService that you would obtain through BraveCore and makes it observable
public class NetworkStore: ObservableObject {
  
  @Published private(set) var allChains: [BraveWallet.NetworkInfo] = []

  @Published private(set) var selectedChainId: String = BraveWallet.MainnetChainId
  var selectedChain: BraveWallet.NetworkInfo {
    allChains.first(where: { $0.chainId == self.selectedChainId }) ?? .init()
  }
  var selectedChainBinding: Binding<BraveWallet.NetworkInfo> {
    .init(
      get: { self.allChains.first(where: { $0.chainId == self.selectedChainId }) ?? .init() },
      set: { newNetwork in
        self.setSelectedChain(newNetwork)
      }
    )
  }

  private let rpcService: BraveWalletJsonRpcService
  private let walletService: BraveWalletBraveWalletService

  public init(
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService
  ) {
    self.rpcService = rpcService
    self.walletService = walletService
    self.updateChainList()
    rpcService.add(self)
    
    Task { // fetch current selected network
      let selectedCoin = await walletService.selectedCoin()
      let chainIdForCoin = await rpcService.chainId(selectedCoin)
      let allNetworksForCoin = await rpcService.allNetworks(selectedCoin)
      guard let chain = allNetworksForCoin.first(where: { $0.chainId == chainIdForCoin }) else {
        // set selected chain to `.init()`?
        return
      }
      self.setSelectedChain(chain)
    }
  }

  private func updateChainList() {
    Task { // fetch all networks for all coin types
      self.allChains = await withTaskGroup(of: [BraveWallet.NetworkInfo].self) { [weak rpcService] group -> [BraveWallet.NetworkInfo] in
        guard let rpcService = rpcService else { return [] }
        for coinType in WalletConstants.supportedCoinTypes {
          group.addTask {
            let chains = await rpcService.allNetworks(coinType)
            return chains.filter { // localhost not supported
              $0.chainId != BraveWallet.LocalhostChainId
            }
          }
        }
        let allChains = await group.reduce([BraveWallet.NetworkInfo](), { $0 + $1 })
        return allChains.sorted { lhs, rhs in
          // sort solana chains to the front of the list
          lhs.coin == .sol && rhs.coin != .sol
        }
      }
    }
  }
  
  private func setSelectedChain(_ network: BraveWallet.NetworkInfo) {
    if network.coin != .eth {
      // TODO: check if we need to prompt to create new account
      print("Selected network that does not use Ethereum Coin Type!")
      return
    }
    guard self.selectedChainId != network.chainId else { return }
    self.selectedChainId = network.chainId
  }

  // MARK: - Custom Networks

  @Published var isAddingNewNetwork: Bool = false

  public func addCustomNetwork(
    _ network: BraveWallet.NetworkInfo,
    completion: @escaping (_ accepted: Bool, _ errMsg: String) -> Void
  ) {
    guard network.coin == .eth else {
      completion(false, "Not supported")
      return
    }
    func add(network: BraveWallet.NetworkInfo, completion: @escaping (_ accepted: Bool, _ errMsg: String) -> Void) {
      rpcService.addEthereumChain(network) { [self] chainId, status, message in
        if status == .success {
          // Update `ethereumChains` by api calling
          updateChainList()
          isAddingNewNetwork = false
          completion(true, "")
        } else {
          // meaning add custom network failed for some reason.
          // Also add the the old network back on rpc service
          if let oldNetwork = allChains.filter({ $0.coin == .eth }).first(where: { $0.id.lowercased() == network.id.lowercased() }) {
            rpcService.addEthereumChain(oldNetwork) { _, _, _ in
              // Update `ethereumChains` by api calling
              self.updateChainList()
              self.isAddingNewNetwork = false
              completion(false, message)
            }
          } else {
            isAddingNewNetwork = false
            completion(false, message)
          }
        }
      }
    }

    isAddingNewNetwork = true
    if allChains.filter({ $0.coin == .eth }).contains(where: { $0.id.lowercased() == network.id.lowercased() }) {
      removeNetworkForNewAddition(network) { [self] success in
        guard success else {
          isAddingNewNetwork = false
          completion(false, Strings.Wallet.failedToRemoveCustomNetworkErrorMessage)
          return
        }
        add(network: network, completion: completion)
      }
    } else {
      add(network: network, completion: completion)
    }
  }

  /// This method will not update `ethereumChains`
  private func removeNetworkForNewAddition(
    _ network: BraveWallet.NetworkInfo,
    completion: @escaping (_ success: Bool) -> Void
  ) {
    rpcService.removeEthereumChain(network.id) { success in
      completion(success)
    }
  }

  public func removeCustomNetwork(
    _ network: BraveWallet.NetworkInfo,
    completion: @escaping (_ success: Bool) -> Void
  ) {
    guard network.coin == .eth else {
      completion(false)
      return
    }
    rpcService.removeEthereumChain(network.id) { [self] success in
      if success {
        // check if its the current network, set mainnet the active net
        if network.id.lowercased() == selectedChainId.lowercased() {
          rpcService.setNetwork(BraveWallet.MainnetChainId, coin: .eth, completion: { _ in })
        }
        // Update `ethereumChains` by api calling
        updateChainList()
      }
      completion(success)
    }
  }
}

extension NetworkStore: BraveWalletJsonRpcServiceObserver {
  public func onIsEip1559Changed(_ chainId: String, isEip1559: Bool) {
  }
  public func onAddEthereumChainRequestCompleted(_ chainId: String, error: String) {
    updateChainList()
  }
  public func chainChangedEvent(_ chainId: String, coin: BraveWallet.CoinType) {
    guard let chain = allChains.first(where: { $0.chainId == chainId && $0.coin == coin }) else {
      // set selected chain to `.init()`?
      return
    }
    setSelectedChain(chain)
  }
}
