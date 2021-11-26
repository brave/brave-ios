// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

/// A store contains data for buying tokens
public class BuyTokenStore: ObservableObject {
  /// The current selected token to buy. Default with nil value.
  @Published var selectedBuyToken: BraveWallet.ERCToken?
  /// All available buyable tokens
  @Published var buyTokens: [BraveWallet.ERCToken] = []
  
  private let tokenRegistry: BraveWalletERCTokenRegistry
  private let rpcController: BraveWalletEthJsonRpcController
  private let buyAssetUrls: [String: String] = [BraveWallet.RopstenChainId: "https://faucet.metamask.io/",
                                                BraveWallet.RinkebyChainId: "https://www.rinkeby.io/",
                                                BraveWallet.GoerliChainId: "https://goerli-faucet.slock.it/",
                                                BraveWallet.KovanChainId: "https://github.com/kovan-testnet/faucet",
                                                BraveWallet.LocalhostChainId: ""]
  
  public init(
    tokenRegistry: BraveWalletERCTokenRegistry,
    rpcController: BraveWalletEthJsonRpcController
  ) {
    self.tokenRegistry = tokenRegistry
    self.rpcController = rpcController
  }
  
  func fetchBuyUrl(account: BraveWallet.AccountInfo, amount: String, completion: @escaping (_ url: String?) -> Void) {
    guard let token = selectedBuyToken else {
      completion(nil)
      return
    }
    
    tokenRegistry.buyUrl(account.address, symbol: token.symbol, amount: amount) { url in
      completion(url)
    }
  }
  
  func fetchTestFaucetUrl(completion: @escaping (_ url: String?) -> Void) {
    rpcController.chainId { [self] chainId in
      completion(self.buyAssetUrls[chainId])
    }
  }
  
  func fetchBuyTokens() {
    self.tokenRegistry.buyTokens { tokens in
      self.buyTokens = tokens.sorted(by: { $0.symbol < $1.symbol })
      if self.selectedBuyToken == nil, let index = tokens.firstIndex(where: { $0.symbol == "BAT" }) {
        self.selectedBuyToken = tokens[index]
      }
    }
  }
}

extension BuyTokenStore: SubStore {
  public func resetStore() {
    selectedBuyToken = nil
    buyTokens = []
  }
}
