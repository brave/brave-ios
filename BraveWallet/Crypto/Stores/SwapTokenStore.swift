// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

/// A store contains data for swap tokens
public class SwapTokenStore: ObservableObject {
  /// All  tokens
  @Published var allTokens: [BraveWallet.ERCToken] = []
  /// The current selected token to swap from. Default with nil value.
  @Published var selectedFromToken: BraveWallet.ERCToken? {
    didSet {
      print("set")
    }
  }
  /// The current selected token to swap to. Default with nil value
  @Published var selectedToToken: BraveWallet.ERCToken?
  /// The current selected token balance to swap from. Default with nil value.
  @Published var selectedFromTokenBalance: Double?
  /// The current selected token balance to swap to. Default with nil value.
  @Published var selectedToTokenBalance: Double?
  /// The current market price for selected token to swap to. Default with nil value
  @Published var selevtedToTokenPrice: Double?
  
  private let tokenRegistry: BraveWalletERCTokenRegistry
  private let rpcController: BraveWalletEthJsonRpcController
  
  public init(
    tokenRegistry: BraveWalletERCTokenRegistry,
    rpcController: BraveWalletEthJsonRpcController
  ) {
    self.tokenRegistry = tokenRegistry
    self.rpcController = rpcController
  }
  
  func fetchAllTokens() {
    tokenRegistry.allTokens { [self] tokens in
      let fullList = tokens + [.eth]
      allTokens = fullList.sorted(by: { $0.symbol < $1.symbol })
      
      if selectedFromToken == nil {
        selectedFromToken = allTokens.first(where: { $0.symbol == "ETH" })
      }
      
      rpcController.chainId { [self] chainId in
        if selectedToToken == nil {
          if chainId == BraveWallet.MainnetChainId {
            selectedToToken = allTokens.first(where: { $0.symbol == "BAT" })
          } else if chainId == BraveWallet.RopstenChainId {
            selectedToToken = allTokens.first(where: { $0.symbol == "DAI" })
          }
        }
      }
    }
  }
}
