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
  /// Indicates if current network is mainnet network aka not for testing
  @Published var isMainnet: Bool = true
  /// The name of the current selected network name
  @Published var networkName: String = ""
  
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
    
    self.rpcController.add(self)
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
  
  func prepareScreen() {
    fetchBuyTokens()
    checkNetwork()
  }
  
  private func fetchBuyTokens() {
    self.tokenRegistry.buyTokens { tokens in
      self.buyTokens = tokens.sorted(by: { $0.symbol < $1.symbol })
      if self.selectedBuyToken == nil, let index = tokens.firstIndex(where: { $0.symbol == "BAT" }) {
        self.selectedBuyToken = tokens[index]
      }
    }
  }
  
  private func checkNetwork() {
    rpcController.chainId { [self] chainId in
      self.isMainnet = chainId == BraveWallet.MainnetChainId
      
      updateNetworkName(chainId: chainId)
    }
  }
  
  private func updateNetworkName(chainId: String) {
    rpcController.allNetworks { [self] chains in
      let chain = chains.first(where: { $0.chainId == chainId })
      
      self.networkName = chain?.chainName ?? ""
    }
  }
}

extension BuyTokenStore: BraveWalletEthJsonRpcControllerObserver {
  public func chainChangedEvent(_ chainId: String) {
    isMainnet = chainId == BraveWallet.MainnetChainId
    
    updateNetworkName(chainId: chainId)
  }
  
  public func onAddEthereumChainRequestCompleted(_ chainId: String, error: String) {
  }
  
  public func onIsEip1559Changed(_ chainId: String, isEip1559: Bool) {
  }
}
