// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import Combine
import BraveCore
import BraveShared
@testable import BraveWallet

@MainActor class NetworkSelectionStoreTests: XCTestCase {
  
  private var cancellables: Set<AnyCancellable> = .init()

  private let allNetworks: [BraveWallet.CoinType: [BraveWallet.NetworkInfo]] = [
    .eth: [.mockMainnet, .mockGoerli, .mockSepolia, .mockPolygon],
    .sol: [.mockSolana, .mockSolanaTestnet]
  ]
  
  private func setupServices() -> (BraveWallet.TestKeyringService, BraveWallet.TestJsonRpcService, BraveWallet.TestBraveWalletService, BraveWallet.TestSwapService) {
    let currentNetwork: BraveWallet.NetworkInfo = .mockMainnet
    let currentChainId = currentNetwork.chainId
    let currentSelectedCoin: BraveWallet.CoinType = .eth
    
    let keyringService = BraveWallet.TestKeyringService()
    keyringService._keyringInfo = { keyringId, completion in
      let isEthereumKeyringId = keyringId == BraveWallet.CoinType.eth.keyringId
      let keyring: BraveWallet.KeyringInfo = .init(
        id: BraveWallet.DefaultKeyringId,
        isKeyringCreated: true,
        isLocked: false,
        isBackedUp: true,
        accountInfos: isEthereumKeyringId ? [.previewAccount] : []
      )
      completion(keyring)
    }
    keyringService._addObserver = { _ in }
    keyringService._isLocked = { $0(false) }
    
    let rpcService = BraveWallet.TestJsonRpcService()
    rpcService._addObserver = { _ in }
    rpcService._chainId = { $1(currentChainId) }
    rpcService._network = { $1(currentNetwork) }
    rpcService._allNetworks = { [weak self] coinType, completion in
      completion(self?.allNetworks[coinType, default: []] ?? [])
    }
    rpcService._setNetwork = { _, _, completion in
      completion(true)
    }
    rpcService._customNetworks = { $1([]) }
    
    let walletService = BraveWallet.TestBraveWalletService()
    walletService._addObserver = { _ in }
    walletService._selectedCoin = { $0(currentSelectedCoin) }
    
    let swapService = BraveWallet.TestSwapService()
    swapService._isSwapSupported = { $1(true) }
    
    return (keyringService, rpcService, walletService, swapService)
  }
  
  func testUpdateSelectMode() {
    Preferences.Wallet.showTestNetworks.value = false

    let (keyringService, rpcService, walletService, swapService) = setupServices()
    
    let networkStore = NetworkStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      swapService: swapService
    )
    
    // wait for all chains to populate in `NetworkStore`
    let allChainsException = expectation(description: "networkStore-allChains")
    networkStore.$allChains
      .dropFirst()
      .sink { allChains in
        allChainsException.fulfill()
      }
      .store(in: &cancellables)
    wait(for: [allChainsException], timeout: 1)
    
    let store = NetworkSelectionStore(networkStore: networkStore)
    XCTAssertTrue(store.primaryNetworks.isEmpty, "Test setup failed, expected empty primary networks")
    XCTAssertTrue(store.secondaryNetworks.isEmpty, "Test setup failed, expected empty secondary networks")
    
    store.update()
    
    let expectedPrimaryNetworks: [NetworkPresentation] = [
      .init(network: .network(.mockSolana), subNetworks: [], isPrimaryNetwork: true),
      .init(network: .network(.mockMainnet), subNetworks: [], isPrimaryNetwork: true)
    ]
    let expectedSecondaryNetworks: [NetworkPresentation] = [
      .init(network: .network(.mockPolygon), subNetworks: [], isPrimaryNetwork: false)
    ]
    XCTAssertEqual(store.primaryNetworks, expectedPrimaryNetworks, "Unexpected primary networks set")
    XCTAssertEqual(store.secondaryNetworks, expectedSecondaryNetworks, "Unexpected secondary networks set")
  }
  
  func testUpdateTestNetworksEnabledSelectMode() {
    Preferences.Wallet.showTestNetworks.value = true
    
    let (keyringService, rpcService, walletService, swapService) = setupServices()
    
    let networkStore = NetworkStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      swapService: swapService
    )
    
    // wait for all chains to populate in `NetworkStore`
    let allChainsException = expectation(description: "networkStore-allChains")
    networkStore.$allChains
      .dropFirst()
      .sink { allChains in
        allChainsException.fulfill()
      }
      .store(in: &cancellables)
    wait(for: [allChainsException], timeout: 1)
    
    let store = NetworkSelectionStore(networkStore: networkStore)
    XCTAssertTrue(store.primaryNetworks.isEmpty, "Test setup failed, expected empty primary networks")
    XCTAssertTrue(store.secondaryNetworks.isEmpty, "Test setup failed, expected empty secondary networks")
    
    store.update()
    
    let expectedPrimaryNetworks: [NetworkPresentation] = [
      .init(network: .network(.mockSolana), subNetworks: [.mockSolana, .mockSolanaTestnet], isPrimaryNetwork: true),
      .init(network: .network(.mockMainnet), subNetworks: [.mockMainnet, .mockGoerli, .mockSepolia], isPrimaryNetwork: true)
    ]
    let expectedSecondaryNetworks: [NetworkPresentation] = [
      .init(network: .network(.mockPolygon), subNetworks: [], isPrimaryNetwork: false)
    ]
    XCTAssertEqual(store.primaryNetworks, expectedPrimaryNetworks, "Unexpected primary networks set")
    XCTAssertEqual(store.secondaryNetworks, expectedSecondaryNetworks, "Unexpected secondary networks set")
  }
  
  func testUpdateFilterMode() {
    Preferences.Wallet.showTestNetworks.value = false

    let (keyringService, rpcService, walletService, swapService) = setupServices()
    
    let networkStore = NetworkStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      swapService: swapService
    )
    
    // wait for all chains to populate in `NetworkStore`
    let allChainsException = expectation(description: "networkStore-allChains")
    networkStore.$allChains
      .dropFirst()
      .sink { allChains in
        allChainsException.fulfill()
      }
      .store(in: &cancellables)
    wait(for: [allChainsException], timeout: 1)
    
    let store = NetworkSelectionStore(
      mode: .filter,
      networkStore: networkStore
    )
    XCTAssertTrue(store.primaryNetworks.isEmpty, "Test setup failed, expected empty primary networks")
    XCTAssertTrue(store.secondaryNetworks.isEmpty, "Test setup failed, expected empty secondary networks")
    
    store.update()
    
    let expectedPrimaryNetworks: [NetworkPresentation] = [
      .allNetworks,
      .init(network: .network(.mockSolana), subNetworks: [], isPrimaryNetwork: true),
      .init(network: .network(.mockMainnet), subNetworks: [], isPrimaryNetwork: true)
    ]
    let expectedSecondaryNetworks: [NetworkPresentation] = [
      .init(network: .network(.mockPolygon), subNetworks: [], isPrimaryNetwork: false)
    ]
    XCTAssertEqual(store.primaryNetworks, expectedPrimaryNetworks, "Unexpected primary networks set")
    XCTAssertEqual(store.secondaryNetworks, expectedSecondaryNetworks, "Unexpected secondary networks set")
  }
  
  func testUpdateTestNetworksEnabledFilterMode() {
    Preferences.Wallet.showTestNetworks.value = true
    
    let (keyringService, rpcService, walletService, swapService) = setupServices()
    
    let networkStore = NetworkStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      swapService: swapService
    )
    
    // wait for all chains to populate in `NetworkStore`
    let allChainsException = expectation(description: "networkStore-allChains")
    networkStore.$allChains
      .dropFirst()
      .sink { allChains in
        allChainsException.fulfill()
      }
      .store(in: &cancellables)
    wait(for: [allChainsException], timeout: 1)
    
    let store = NetworkSelectionStore(
      mode: .filter,
      networkStore: networkStore
    )
    XCTAssertTrue(store.primaryNetworks.isEmpty, "Test setup failed, expected empty primary networks")
    XCTAssertTrue(store.secondaryNetworks.isEmpty, "Test setup failed, expected empty secondary networks")
    
    store.update()
    
    let expectedPrimaryNetworks: [NetworkPresentation] = [
      .allNetworks,
      .init(network: .network(.mockSolana), subNetworks: [.mockSolana, .mockSolanaTestnet], isPrimaryNetwork: true),
      .init(network: .network(.mockMainnet), subNetworks: [.mockMainnet, .mockGoerli, .mockSepolia], isPrimaryNetwork: true)
    ]
    let expectedSecondaryNetworks: [NetworkPresentation] = [
      .init(network: .network(.mockPolygon), subNetworks: [], isPrimaryNetwork: false)
    ]
    XCTAssertEqual(store.primaryNetworks, expectedPrimaryNetworks, "Unexpected primary networks set")
    XCTAssertEqual(store.secondaryNetworks, expectedSecondaryNetworks, "Unexpected secondary networks set")
  }
  
  func testSetSelectedNetwork() async {
    let (keyringService, rpcService, walletService, swapService) = setupServices()
    
    let networkStore = NetworkStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      swapService: swapService
    )
    
    let store = NetworkSelectionStore(networkStore: networkStore)
    let success = await store.selectNetwork(.network(.mockGoerli))
    XCTAssertTrue(success, "Expected success for selecting Ropsten because we have ethereum accounts.")
    XCTAssertNil(store.detailNetwork, "Expected to reset detail network to nil to pop detail view")
  }
  
  func testSetSelectedNetworkNoAccounts() async {
    let (keyringService, rpcService, walletService, swapService) = setupServices()
    
    let networkStore = NetworkStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      swapService: swapService
    )
    
    let store = NetworkSelectionStore(networkStore: networkStore)
    let success = await store.selectNetwork(.network(.mockSolana))
    XCTAssertFalse(success, "Expected failure for selecting Solana because we have no Solana accounts.")
    XCTAssertTrue(store.isPresentingNextNetworkAlert, "Expected to set isPresentingNextNetworkAlert to true to show alert asking user to create Solana account")
    XCTAssertNil(store.detailNetwork, "Expected to reset detail network to nil to pop detail view")
  }
  
  func testSelectNetworkFilterMode() async {
    let (keyringService, rpcService, walletService, swapService) = setupServices()
    
    let networkStore = NetworkStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      swapService: swapService
    )
    
    let store = NetworkSelectionStore(
      mode: .filter,
      networkStore: networkStore
    )
    let success = await store.selectNetwork(.network(.mockMainnet))
    XCTAssertTrue(success, "Expected success for selecting Ethereum Mainnet.")
    XCTAssertEqual(networkStore.networkFilter, .network(.mockMainnet))
  }
  
  func testSelectNetworkFilterModeAllNetworks() async {
    let (keyringService, rpcService, walletService, swapService) = setupServices()
    
    let networkStore = NetworkStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      swapService: swapService
    )
    
    let store = NetworkSelectionStore(
      mode: .filter,
      networkStore: networkStore
    )
    let success = await store.selectNetwork(.allNetworks)
    XCTAssertTrue(success, "Expected success for selecting All Networks.")
    XCTAssertEqual(networkStore.networkFilter, .allNetworks)
  }
  
  func testAlertResponseCreateAccount() {
    let (keyringService, rpcService, walletService, swapService) = setupServices()
    
    let networkStore = NetworkStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      swapService: swapService
    )
    
    let store = NetworkSelectionStore(networkStore: networkStore)
    store.detailNetwork = .init(network: .network(.mockSolana), subNetworks: [.mockSolana], isPrimaryNetwork: true)
    
    store.handleCreateAccountAlertResponse(shouldCreateAccount: true)
    
    XCTAssertFalse(store.isPresentingNextNetworkAlert, "Expected to set isPresentingNextNetworkAlert to false to hide alert")
    XCTAssertTrue(store.isPresentingAddAccount, "Expected to set isPresentingAddAccount to true to present add network")
  }
  
  func testAlertResponseDontCreateAccount() {
    let (keyringService, rpcService, walletService, swapService) = setupServices()
    
    let networkStore = NetworkStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      swapService: swapService
    )
    
    let store = NetworkSelectionStore(networkStore: networkStore)
    store.detailNetwork = .init(network: .network(.mockSolana), subNetworks: [.mockSolana], isPrimaryNetwork: true)
    store.isPresentingNextNetworkAlert = true
    
    store.handleCreateAccountAlertResponse(shouldCreateAccount: false)
    
    XCTAssertFalse(store.isPresentingNextNetworkAlert, "Expected to set isPresentingNextNetworkAlert to false to hide alert")
    XCTAssertNil(store.nextNetwork, "Expected to reset nextNetwork to nil as user does not want to create an account")
  }
  
  func testDismissAddAccount() async {
    let (keyringService, rpcService, walletService, swapService) = setupServices()
    
    let networkStore = NetworkStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      swapService: swapService
    )
    
    let store = NetworkSelectionStore(networkStore: networkStore)
    
    let didSwitchNetworks = await store.handleDismissAddAccount()
    XCTAssertFalse(didSwitchNetworks, "Expected to not switch networks as no account was created")
  }
  
  func testDismissAddAccountAfterCreation() async {
    let (_, rpcService, walletService, swapService) = setupServices()
    
    var accountInfosDict: [BraveWallet.CoinType: [BraveWallet.AccountInfo]] = [
      .eth: [.mockEthAccount]
    ]
    
    let keyringService = BraveWallet.TestKeyringService()
    keyringService._keyringInfo = { keyringId, completion in
      let accountInfos: [BraveWallet.AccountInfo]
      switch keyringId {
      case BraveWallet.CoinType.eth.keyringId:
        accountInfos = accountInfosDict[.eth, default: []]
      case BraveWallet.CoinType.sol.keyringId:
        accountInfos = accountInfosDict[.sol, default: []]
      case BraveWallet.CoinType.fil.keyringId:
        accountInfos = accountInfosDict[.fil, default: []]
      default:
        accountInfos = []
      }
      let keyring: BraveWallet.KeyringInfo = .init(
        id: keyringId,
        isKeyringCreated: true,
        isLocked: false,
        isBackedUp: false,
        accountInfos: accountInfos
      )
      completion(keyring)
    }
    keyringService._addObserver = { _ in }
    keyringService._isLocked = { $0(false) }
    
    let networkStore = NetworkStore(
      keyringService: keyringService,
      rpcService: rpcService,
      walletService: walletService,
      swapService: swapService
    )
    
    let store = NetworkSelectionStore(networkStore: networkStore)
    
    let success = await store.selectNetwork(.network(.mockSolana))
    XCTAssertFalse(success, "Expected failure to select network due to no accounts")
    XCTAssertTrue(store.isPresentingNextNetworkAlert, "Expected to present next network alert")
    
    store.handleCreateAccountAlertResponse(shouldCreateAccount: true)
    
    XCTAssertFalse(store.isPresentingNextNetworkAlert, "Expected to set isPresentingNextNetworkAlert to false to hide alert")
    XCTAssertTrue(store.isPresentingAddAccount, "Expected to set isPresentingAddAccount to true to present add network")
    
    // simulate an account created
    accountInfosDict[.sol] = [.mockSolAccount]
    
    let didSwitchNetworks = await store.handleDismissAddAccount()
    XCTAssertTrue(didSwitchNetworks, "Expected to switch networks as an account was created")
  }
}
