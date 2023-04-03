// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import XCTest
import Combine
import BraveCore
@testable import BraveWallet

class UserAssetsStoreTests: XCTestCase {
  
  private var cancellables: Set<AnyCancellable> = .init()
  
  let networks: [BraveWallet.CoinType: [BraveWallet.NetworkInfo]] = [
    .eth: [.mockMainnet],
    .sol: [.mockSolana]
  ]
  let visibleAssetsForCoins: [BraveWallet.CoinType: [BraveWallet.BlockchainToken]] = [
    .eth: [BraveWallet.NetworkInfo.mockMainnet.nativeToken.then { $0.visible = true }, .mockERC721NFTToken.then { $0.visible = true }],
    .sol: [BraveWallet.NetworkInfo.mockSolana.nativeToken.then { $0.visible = true }, .mockSolanaNFTToken.then { $0.visible = true }]
  ]
  let tokenRegistry: [BraveWallet.CoinType: [BraveWallet.BlockchainToken]] = [
    .eth: [.mockUSDCToken],
    .sol: [.mockSpdToken]
  ]
  
  private func setupServices() -> (BraveWallet.TestKeyringService, BraveWallet.TestJsonRpcService, BraveWallet.TestBraveWalletService, BraveWallet.TestBlockchainRegistry, BraveWallet.TestAssetRatioService) {
    let keyringService = BraveWallet.TestKeyringService()
    keyringService._addObserver = { _ in }
    
    let rpcService = BraveWallet.TestJsonRpcService()
    rpcService._addObserver = { _ in }
    rpcService._allNetworks = { coin, completion in
      completion(self.networks[coin] ?? [])
    }
    rpcService._erc721Metadata = { _, _, _, completion in
      completion("", "", .internalError, "")
    }
    let walletService = BraveWallet.TestBraveWalletService()
    walletService._userAssets = { chainId, coin, completion in
      completion(self.visibleAssetsForCoins[coin] ?? [])
    }
    
    let blockchainRegistry = BraveWallet.TestBlockchainRegistry()
    blockchainRegistry._allTokens = { chainId, coin, completion in
      completion(self.tokenRegistry[coin] ?? [])
    }
    
    let assetRatioService = BraveWallet.TestAssetRatioService()

    return (keyringService, rpcService, walletService, blockchainRegistry, assetRatioService)
  }
  
  func testUpdate() {
    let (keyringService, rpcService, walletService, blockchainRegistry, assetRatioService) = setupServices()
    
    let userAssetsStore = UserAssetsStore(
      walletService: walletService,
      blockchainRegistry: blockchainRegistry,
      rpcService: rpcService,
      keyringService: keyringService,
      assetRatioService: assetRatioService,
      ipfsApi: TestIpfsAPI()
    )
    
    let assetStoresException = expectation(description: "userAssetsStore-assetStores")
    userAssetsStore.$assetStores
      .dropFirst()
      .sink { assetStores in
        defer { assetStoresException.fulfill() }
        XCTAssertEqual(assetStores.count, 6)
        
        XCTAssertEqual(assetStores[0].token.symbol, BraveWallet.NetworkInfo.mockSolana.nativeToken.symbol)
        XCTAssertTrue(assetStores[0].token.visible)
        XCTAssertEqual(assetStores[0].network, BraveWallet.NetworkInfo.mockSolana)
        
        XCTAssertEqual(assetStores[1].token.symbol, BraveWallet.BlockchainToken.mockSolanaNFTToken.symbol)
        XCTAssertTrue(assetStores[1].token.visible)
        XCTAssertEqual(assetStores[1].network, BraveWallet.NetworkInfo.mockSolana)
        
        XCTAssertEqual(assetStores[2].token.symbol, BraveWallet.NetworkInfo.mockMainnet.nativeToken.symbol)
        XCTAssertTrue(assetStores[2].token.visible)
        XCTAssertEqual(assetStores[2].network, BraveWallet.NetworkInfo.mockMainnet)
        
        XCTAssertEqual(assetStores[3].token.symbol, BraveWallet.BlockchainToken.mockERC721NFTToken.symbol)
        XCTAssertTrue(assetStores[3].token.visible)
        XCTAssertEqual(assetStores[3].network, BraveWallet.NetworkInfo.mockMainnet)
        
        XCTAssertEqual(assetStores[4].token.symbol, BraveWallet.BlockchainToken.mockSpdToken.symbol)
        XCTAssertFalse(assetStores[4].token.visible)
        XCTAssertEqual(assetStores[4].network, BraveWallet.NetworkInfo.mockSolana)
        
        XCTAssertEqual(assetStores[5].token.symbol, BraveWallet.BlockchainToken.mockUSDCToken.symbol)
        XCTAssertFalse(assetStores[5].token.visible)
        XCTAssertEqual(assetStores[5].network, BraveWallet.NetworkInfo.mockMainnet)
      }
      .store(in: &cancellables)
    
    userAssetsStore.update()
    
    waitForExpectations(timeout: 1) { error in
      XCTAssertNil(error)
    }
  }
  
  func testUpdateWithNetworkFilter() {
    let (keyringService, rpcService, walletService, blockchainRegistry, assetRatioService) = setupServices()
    
    let userAssetsStore = UserAssetsStore(
      walletService: walletService,
      blockchainRegistry: blockchainRegistry,
      rpcService: rpcService,
      keyringService: keyringService,
      assetRatioService: assetRatioService,
      ipfsApi: TestIpfsAPI()
    )
    
    let assetStoresException = expectation(description: "userAssetsStore-assetStores")
    userAssetsStore.$assetStores
      .dropFirst()
      .sink { assetStores in
        defer { assetStoresException.fulfill() }
        XCTAssertEqual(assetStores.count, 3)
        
        XCTAssertEqual(assetStores[0].token.symbol, BraveWallet.NetworkInfo.mockMainnet.nativeToken.symbol)
        XCTAssertTrue(assetStores[0].token.visible)
        XCTAssertEqual(assetStores[0].network, BraveWallet.NetworkInfo.mockMainnet)
        
        XCTAssertEqual(assetStores[1].token.symbol, BraveWallet.BlockchainToken.mockERC721NFTToken.symbol)
        XCTAssertTrue(assetStores[1].token.visible)
        XCTAssertEqual(assetStores[1].network, BraveWallet.NetworkInfo.mockMainnet)
        
        XCTAssertEqual(assetStores[2].token.symbol, BraveWallet.BlockchainToken.mockUSDCToken.symbol)
        XCTAssertFalse(assetStores[2].token.visible)
        XCTAssertEqual(assetStores[2].network, BraveWallet.NetworkInfo.mockMainnet)
      }
      .store(in: &cancellables)
    
    // network filter assignment should call `update()` and update `assetStores`
    userAssetsStore.networkFilter = .network(.mockMainnet)
    
    waitForExpectations(timeout: 1) { error in
      XCTAssertNil(error)
    }
  }
}
