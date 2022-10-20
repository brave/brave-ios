// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

import XCTest
import Combine
import BraveCore
@testable import BraveWallet

class BuyTokenStoreTests: XCTestCase {
  private var cancellables: Set<AnyCancellable> = []
  
  private func setupServices(selectedNetwork: BraveWallet.NetworkInfo = .mockMainnet) -> (BraveWallet.TestBlockchainRegistry, BraveWallet.TestJsonRpcService, BraveWallet.TestBraveWalletService, BraveWallet.TestAssetRatioService) {
    let mockTokenList: [BraveWallet.BlockchainToken] = [
      .init(contractAddress: "0x0d8775f648430679a709e98d2b0cb6250d2887ef", name: "Basic Attention Token", logo: "", isErc20: true, isErc721: false, symbol: "BAT", decimals: 18, visible: true, tokenId: "", coingeckoId: "", chainId: BraveWallet.MainnetChainId, coin: .eth),
      .init(contractAddress: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52", name: "BNB", logo: "", isErc20: true, isErc721: false, symbol: "BNB", decimals: 18, visible: true, tokenId: "", coingeckoId: "", chainId: "", coin: .eth),
      .init(contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7", name: "Tether USD", logo: "", isErc20: true, isErc721: false, symbol: "USDT", decimals: 6, visible: true, tokenId: "", coingeckoId: "", chainId: "", coin: .eth),
      .init(contractAddress: "0x57f1887a8bf19b14fc0df6fd9b2acc9af147ea85", name: "Ethereum Name Service", logo: "", isErc20: false, isErc721: true, symbol: "ENS", decimals: 1, visible: true, tokenId: "", coingeckoId: "", chainId: "", coin: .eth),
      .init(contractAddress: "0xad6d458402f60fd3bd25163575031acdce07538d", name: "DAI Stablecoin", logo: "", isErc20: true, isErc721: false, symbol: "DAI", decimals: 18, visible: false, tokenId: "", coingeckoId: "", chainId: "", coin: .eth),
      .init(contractAddress: "0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0", name: "MATIC", logo: "", isErc20: true, isErc721: false, symbol: "MATIC", decimals: 18, visible: true, tokenId: "", coingeckoId: "", chainId: "", coin: .eth)
    ]
    let mockOnRampCurrencies: [BraveWallet.OnRampCurrency] = [
      .init(currencyCode: "usd", currencyName: "United States Dollar", providers: [.init(value: 0)]),
      .init(currencyCode: "eur", currencyName: "Euro", providers: [.init(value: 1)])
    ]
    let blockchainRegistry = BraveWallet.TestBlockchainRegistry()
    blockchainRegistry._buyTokens = { $2(mockTokenList)}
    blockchainRegistry._onRampCurrencies = { $0(mockOnRampCurrencies) }
    
    let rpcService = BraveWallet.TestJsonRpcService()
    rpcService._network = { $1(selectedNetwork) }
    rpcService._addObserver = { _ in }
    
    let walletService = BraveWallet.TestBraveWalletService()
    walletService._selectedCoin = { $0(.eth) }
    
    let buyURL = "https://crypto.sardine.ai/"
    let assetRatioService = BraveWallet.TestAssetRatioService()
    assetRatioService._buyUrlV1 = {_, _, _, _, _, _, completion in
      completion(buyURL, nil)
    }
    
    return (blockchainRegistry, rpcService, walletService, assetRatioService)
  }
  
  func testPrefilledToken() {
    let (blockchainRegistry, rpcService, walletService, assetRatioService) = setupServices()
    var store = BuyTokenStore(
      blockchainRegistry: blockchainRegistry,
      rpcService: rpcService,
      walletService: walletService,
      assetRatioService: assetRatioService,
      prefilledToken: nil
    )
    XCTAssertNil(store.selectedBuyToken)

    store = BuyTokenStore(
      blockchainRegistry: blockchainRegistry,
      rpcService: rpcService,
      walletService: walletService,
      assetRatioService: assetRatioService,
      prefilledToken: .previewToken
    )
    XCTAssertEqual(store.selectedBuyToken?.symbol.lowercased(), BraveWallet.BlockchainToken.previewToken.symbol.lowercased())
  }
  
  func testBuyDisabledForTestNetwork() {
    let (blockchainRegistry, rpcService, walletService, assetRatioService) = setupServices(selectedNetwork: .mockGoerli)
    let store = BuyTokenStore(
      blockchainRegistry: blockchainRegistry,
      rpcService: rpcService,
      walletService: walletService,
      assetRatioService: assetRatioService,
      prefilledToken: nil
    )
    
    let isSelectedNetworkSupportedExpectation = expectation(description: "buyTokenStore-isSelectedNetworkSupported")
    store.$isSelectedNetworkSupported
      .dropFirst() // initial/default value
      .sink { isSelectedNetworkSupported in
        defer { isSelectedNetworkSupportedExpectation.fulfill() }
        XCTAssertFalse(isSelectedNetworkSupported)
      }
      .store(in: &cancellables)
    wait(for: [isSelectedNetworkSupportedExpectation], timeout: 2)
  }

  func testBuyEnabledForNonTestNetwork() {
    let (blockchainRegistry, rpcService, walletService, assetRatioService) = setupServices(selectedNetwork: .mockMainnet)
    let store = BuyTokenStore(
      blockchainRegistry: blockchainRegistry,
      rpcService: rpcService,
      walletService: walletService,
      assetRatioService: assetRatioService,
      prefilledToken: nil
    )
    
    let isSelectedNetworkSupportedExpectation = expectation(description: "buyTokenStore-isSelectedNetworkSupported")
    store.$isSelectedNetworkSupported
      .dropFirst() // initial/default value
      .sink { isSelectedNetworkSupported in
        defer { isSelectedNetworkSupportedExpectation.fulfill() }
        XCTAssertTrue(isSelectedNetworkSupported)
      }
      .store(in: &cancellables)
    wait(for: [isSelectedNetworkSupportedExpectation], timeout: 2)
  }
  
  func testOrderedSupportedBuyOptions() async {
    let (_, rpcService, walletService, assetRatioService) = setupServices()
    let blockchainRegistry = BraveWallet.TestBlockchainRegistry()
    blockchainRegistry._buyTokens = {
      if $0 == .ramp {
        $2([.mockSolToken])
      } else {
        $2([.mockUSDCToken])
      }
    }
    blockchainRegistry._onRampCurrencies = { $0([.init(currencyCode: "usd", currencyName: "United States Dollar", providers: [.init(value: 0)])]) }
    
    let store = BuyTokenStore(
      blockchainRegistry: blockchainRegistry,
      rpcService: rpcService,
      walletService: walletService,
      assetRatioService: assetRatioService,
      prefilledToken: nil
    )
    
    await store.updateInfo()
    
    let orderSupportedBuyOptionsExpectation = expectation(description: "buyTokenStore-orderSupportedBuyOptions")
    XCTAssertEqual(store.orderedSupportedBuyOptions.count, 1)
    XCTAssertNotNil(store.orderedSupportedBuyOptions.first)
    XCTAssertEqual(store.orderedSupportedBuyOptions.first!, .ramp)
    orderSupportedBuyOptionsExpectation.fulfill()
    await waitForExpectations(timeout: 2)
  }
  
  func testAllTokens() async {
    let selectedNetwork: BraveWallet.NetworkInfo = .mockSolana
    let (_, rpcService, walletService, assetRatioService) = setupServices(selectedNetwork: selectedNetwork)
    let blockchainRegistry = BraveWallet.TestBlockchainRegistry()
    blockchainRegistry._buyTokens = {
      if $0 == .ramp {
        $2([.mockSolToken, .mockSpdToken])
      } else {
        $2([.mockSpdToken])
      }
    }
    blockchainRegistry._onRampCurrencies = { $0([.init(currencyCode: "usd", currencyName: "United States Dollar", providers: [.init(value: 0)])]) }
    
    let store = BuyTokenStore(
      blockchainRegistry: blockchainRegistry,
      rpcService: rpcService,
      walletService: walletService,
      assetRatioService: assetRatioService,
      prefilledToken: nil
    )
    
    await store.updateInfo()
    
    let allTokensExpectation = expectation(description: "buyTokenStore-allTokensExpectation")
    XCTAssertEqual(store.allTokens.count, 2)
    for token in store.allTokens {
      XCTAssertEqual(token.chainId, selectedNetwork.chainId)
    }
    allTokensExpectation.fulfill()
    
    await waitForExpectations(timeout: 2)
  }
}
