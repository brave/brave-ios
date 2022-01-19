// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

/// A test wallet service that implements some basic functionality for the use of SwiftUI Previews.
///
/// - note: Do not use this directly, use ``NetworkStore.previewStore``
class MockBraveWalletService: BraveWallet.TestBraveWalletService {
  private var assets: [String: [BraveWallet.BlockchainToken]] = [
    BraveWallet.MainnetChainId: [.previewToken],
    BraveWallet.RopstenChainId: [.previewToken],
  ]
  private var defaultCurrency = "usd"
  private var defaultCryptocurrency = "eth"
  
  override func userAssets(_ chainId: String, completion: @escaping ([BraveWallet.BlockchainToken]) -> Void) {
    completion(assets[chainId] ?? [])
  }
  
  override func addUserAsset(_ token: BraveWallet.BlockchainToken, chainId: String, completion: @escaping (Bool) -> Void) {
    assets[chainId]?.append(token)
  }
  
  override func removeUserAsset(_ token: BraveWallet.BlockchainToken, chainId: String, completion: @escaping (Bool) -> Void) {
    assets[chainId]?.removeAll(where: { $0.contractAddress == token.contractAddress })
  }
  
  override func setUserAssetVisible(_ token: BraveWallet.BlockchainToken, chainId: String, visible: Bool, completion: @escaping (Bool) -> Void) {
    let chainAssets = assets[chainId]
    if let index = chainAssets?.firstIndex(where: { $0.contractAddress == token.contractAddress }) {
      chainAssets?[index].visible = visible
    }
  }
  
  override func `import`(from type: BraveWallet.ExternalWalletType, password: String, newPassword: String, completion: @escaping (Bool, String?) -> Void) {
    completion(false, nil)
  }
  
  override func defaultWallet(_ completion: @escaping (BraveWallet.DefaultWallet) -> Void) {
    completion(.braveWallet)
  }
  
  override func hasEthereumPermission(_ origin: String, account: String, completion: @escaping (Bool, Bool) -> Void) {
    completion(false, false)
  }
  
  override func resetEthereumPermission(_ origin: String, account: String, completion: @escaping (Bool) -> Void) {
    completion(false)
  }
  
  override func activeOrigin(_ completion: @escaping (String) -> Void) {
    completion("")
  }
  
  override func pendingSignMessageRequests(_ completion: @escaping ([BraveWallet.SignMessageRequest]) -> Void) {
    completion([])
  }
  
  override func pendingAddSuggestTokenRequests(_ completion: @escaping ([BraveWallet.AddSuggestTokenRequest]) -> Void) {
    completion([])
  }
  
  override func defaultBaseCurrency(_ completion: @escaping (String) -> Void) {
    completion(defaultCurrency)
  }
  
  override func setDefaultBaseCurrency(_ currency: String) {
    defaultCurrency = currency.lowercased()
  }
  
  override func defaultBaseCryptocurrency(_ completion: @escaping (String) -> Void) {
    completion(defaultCryptocurrency)
  }
  
  override func setDefaultBaseCryptocurrency(_ cryptocurrency: String) {
    defaultCryptocurrency = cryptocurrency
  }
  
  override func isExternalWalletInstalled(_ type: BraveWallet.ExternalWalletType, completion: @escaping (Bool) -> Void) {
    completion(false)
  }
  
  override func isExternalWalletInitialized(_ type: BraveWallet.ExternalWalletType, completion: @escaping (Bool) -> Void) {
    completion(false)
  }
  
  override func addEthereumPermission(_ origin: String, account: String, completion: @escaping (Bool) -> Void) {
    completion(false)
  }
}
