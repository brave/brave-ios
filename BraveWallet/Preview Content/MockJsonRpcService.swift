/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import BraveCore

/// A test eth json controller which can be passed to a ``NetworkStore`` that implements some basic
/// functionality for the use of SwiftUI Previews.
///
/// - note: Do not use this directly, use ``NetworkStore.previewStore``
class MockJsonRpcService: BraveWallet.TestJsonRpcService {
  private var chainId: String = BraveWallet.MainnetChainId
  private var networks: [BraveWallet.EthereumChain] = [.mainnet, .rinkeby, .ropsten]
  private var networkURL: URL?
  private var observers: NSHashTable<BraveWalletJsonRpcServiceObserver> = .weakObjects()
  
  override func chainId(_ completion: @escaping (String) -> Void) {
    completion(chainId)
  }
  
  override func blockTrackerUrl(_ completion: @escaping (String) -> Void) {
    completion(networks.first(where: { $0.chainId == self.chainId })?.blockExplorerUrls.first ?? "")
  }
  
  override func networkUrl(_ completion: @escaping (String) -> Void) {
    completion(networkURL?.absoluteString ?? "")
  }
  
  override func network(_ completion: @escaping (BraveWallet.EthereumChain) -> Void) {
    completion(networks.first(where: { $0.chainId == self.chainId }) ?? .init())
  }
  
  override func balance(_ address: String, coin: BraveWallet.CoinType, completion: @escaping (String, BraveWallet.ProviderError, String) -> Void) {
    // return fake sufficient ETH balance `0x13e25e19dc20ba7` is about 0.0896 ETH
    completion("0x13e25e19dc20ba7", .success, "")
  }
  
  override func erc20TokenBalance(_ contract: String, address: String, completion: @escaping (String, BraveWallet.ProviderError, String) -> Void) {
    completion("10", .success, "")
  }
  
  override func request(_ jsonPayload: String, autoRetryOnNetworkChange: Bool, completion: @escaping (Int32, String, [String: String]) -> Void) {
    completion(0, "", [:])
  }
  
  override func add(_ observer: BraveWalletJsonRpcServiceObserver) {
    observers.add(observer)
  }
  
  override func pendingChainRequests(_ completion: @escaping ([BraveWallet.EthereumChain]) -> Void) {
    completion([])
  }
  
  override func allNetworks(_ completion: @escaping ([BraveWallet.EthereumChain]) -> Void) {
    completion(networks)
  }
  
  override func setNetwork(_ chainId: String, completion: @escaping (Bool) -> Void) {
    self.chainId = chainId
    completion(true)
  }
  
  override func erc20TokenAllowance(_ contract: String, ownerAddress: String, spenderAddress: String, completion: @escaping (String, BraveWallet.ProviderError, String) -> Void) {
    completion("", .disconnected, "Error Message")
  }
  
  override func ensGetEthAddr(_ domain: String, completion: @escaping (String, BraveWallet.ProviderError, String) -> Void) {
    completion("", .unknownChain, "Error Message")
  }
  
  override func unstoppableDomainsGetEthAddr(_ domain: String, completion: @escaping (String, BraveWallet.ProviderError, String) -> Void) {
    completion("", .unknownChain, "Error Message")
  }
  
  override func erc721Owner(of contract: String, tokenId: String, completion: @escaping (String, BraveWallet.ProviderError, String) -> Void) {
    completion("", .unknownChain, "Error Message")
  }
  
  override func erc721TokenBalance(_ contractAddress: String, tokenId: String, accountAddress: String, completion: @escaping (String, BraveWallet.ProviderError, String) -> Void) {
    completion("", .disconnected, "Error Message")
  }
  
  override func pendingSwitchChainRequests(_ completion: @escaping ([BraveWallet.SwitchChainRequest]) -> Void) {
    completion([])
  }
  
  func addEthereumChain(forOrigin chain: BraveWallet.EthereumChain, origin: URL, completion: @escaping (String, Bool) -> Void) {
    completion("", false)
  }
  
  override func removeEthereumChain(_ chainId: String, completion: @escaping (Bool) -> Void) {
    completion(false)
  }
  
  func add(_ chain: BraveWallet.EthereumChain, completion: @escaping (String, Bool) -> Void) {
    completion("", false)
  }
}

extension BraveWallet.EthereumChain {
  static let mainnet: BraveWallet.EthereumChain = .init(
    chainId: BraveWallet.MainnetChainId,
    chainName: "Mainnet",
    blockExplorerUrls: ["https://etherscan.io"],
    iconUrls: [],
    rpcUrls: [],
    symbol: "ETH",
    symbolName: "Ethereum",
    decimals: 18,
    isEip1559: true
  )
  static let rinkeby: BraveWallet.EthereumChain = .init(
    chainId: BraveWallet.RinkebyChainId,
    chainName: "Rinkeby",
    blockExplorerUrls: ["https://rinkeby.etherscan.io"],
    iconUrls: [],
    rpcUrls: [],
    symbol: "ETH",
    symbolName: "Ethereum",
    decimals: 18,
    isEip1559: false
  )
  static let ropsten: BraveWallet.EthereumChain = .init(
    chainId: BraveWallet.RopstenChainId,
    chainName: "Ropsten",
    blockExplorerUrls: ["https://ropsten.etherscan.io"],
    iconUrls: [],
    rpcUrls: [],
    symbol: "ETH",
    symbolName: "Ethereum",
    decimals: 18,
    isEip1559: false
  )
}
