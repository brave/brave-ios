/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import BraveCore
import SwiftUI

/// An interface that helps you interact with a json-rpc service
///
/// This wraps a JsonRpcService that you would obtain through BraveCore and makes it observable
public class NetworkStore: ObservableObject {
  @Published private(set) var ethereumChains: [BraveWallet.EthereumChain] = []
  @Published private(set) var selectedChainId: String = BraveWallet.MainnetChainId
  
  var selectedChain: BraveWallet.EthereumChain {
    ethereumChains.first(where: { $0.chainId == self.selectedChainId }) ?? .init()
  }
  
  var selectedChainBinding: Binding<BraveWallet.EthereumChain> {
    .init(
      get: { self.ethereumChains.first(where: { $0.chainId == self.selectedChainId }) ?? .init() },
      set: {
        self.selectedChainId = $0.chainId
        self.rpcService.setNetwork($0.chainId) { _ in }
      }
    )
  }
  
  private let rpcService: BraveWalletJsonRpcService
  
  public init(rpcService: BraveWalletJsonRpcService) {
    self.rpcService = rpcService
    self.rpcService.allNetworks { chains in
      self.ethereumChains = chains.filter {
        $0.chainId != BraveWallet.LocalhostChainId
      }
    }
    rpcService.chainId { chainId in
      let id = chainId.isEmpty ? BraveWallet.MainnetChainId : chainId
      self.selectedChainId = id
      self.rpcService.setNetwork(id) { _ in }
    }
    rpcService.add(self)
  }
  
  public func updateSelectedNetwork(_ network: BraveWallet.EthereumChain) {
    if selectedChainId != network.chainId {
      rpcService.setNetwork(network.chainId) { [self] success in
        if success {
          selectedChainId = network.chainId
        }
      }
    }
  }
  
  // MARK: - Custom Networks
  public func addCustomNetwork(_ network: BraveWallet.EthereumChain,
                               completion: @escaping (_ accepted: Bool) -> Void) {
    func addNetwors(_ network: BraveWallet.EthereumChain, completion: @escaping (_ accepted: Bool) -> Void) {
      rpcService.add(network) { [self] chainId, status, message in
        if status == .success {
          // meaning removal is also succeeded if id exists. need to update the list by removing the old then adding the new
          if let index = ethereumChains.firstIndex(where: { $0.id == network.id }) {
            ethereumChains.remove(at: index)
          }
          ethereumChains.append(network)
          completion(true)
        } else {
          // meaning add custom network failed for some reason. We will not update `ethereumChains`
          // Also add the the old network back on rpc service
          if let oldNetwork = ethereumChains.first(where: { $0.id == network.id }) {
            rpcService.add(oldNetwork) { _, _, _ in
              completion(false)
            }
          } else {
            completion(false)
          }
        }
      }
    }
    
    if ethereumChains.contains(where: { $0.chainId == network.chainId }) {
      removeNetworkForNewAddition(network) { success in
        guard success else {
          completion(false)
          return
        }
        addNetwors(network, completion: completion)
      }
    } else {
      addNetwors(network, completion: completion)
    }
  }
  
  /// This method will not update `ethereumChains`
  private func removeNetworkForNewAddition(_ network: BraveWallet.EthereumChain,
                                           completion: @escaping (_ success: Bool) -> Void) {
    rpcService.removeEthereumChain(network.chainId) { success in
      completion(success)
    }
  }
  
  public func removeCustomNetwork(_ network: BraveWallet.EthereumChain,
                                  completion: @escaping (_ success: Bool) -> Void) {
    rpcService.removeEthereumChain(network.chainId) { [self] success in
      if success {
        if let index = ethereumChains.firstIndex(where: { $0.id == network.id }) {
          ethereumChains.remove(at: index)
        }
      }
      completion(success)
    }
  }
}

extension NetworkStore: BraveWalletJsonRpcServiceObserver {
  public func onIsEip1559Changed(_ chainId: String, isEip1559: Bool) {
  }
  public func onAddEthereumChainRequestCompleted(_ chainId: String, error: String) {
  }
  public func chainChangedEvent(_ chainId: String) {
    self.selectedChainId = chainId
  }
}
