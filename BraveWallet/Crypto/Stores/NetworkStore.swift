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
