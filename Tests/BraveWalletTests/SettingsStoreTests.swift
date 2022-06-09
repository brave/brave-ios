// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import Combine
import BraveCore
import BraveShared
import BigNumber
@testable import BraveWallet

class SettingsStoreTests: XCTestCase {
  
  /// Sets up TestKeyringService, TestBraveWalletService and TestTxService with some default values.
  private func setupServices() -> (BraveWallet.TestKeyringService, BraveWallet.TestBraveWalletService, BraveWallet.TestTxService) {
    let mockAccountInfos: [BraveWallet.AccountInfo] = [.previewAccount]
    let mockUserAssets: [BraveWallet.BlockchainToken] = [.previewToken.then { $0.visible = true }]
    
    let keyringService = BraveWallet.TestKeyringService()
    keyringService._keyringInfo = { _, completion in
      let keyring: BraveWallet.KeyringInfo = .init(
        id: BraveWallet.DefaultKeyringId,
        isKeyringCreated: true,
        isLocked: false,
        isBackedUp: true,
        accountInfos: mockAccountInfos)
      completion(keyring)
    }
    keyringService._addObserver = { _ in }
    keyringService._isLocked = { $0(false) }
    keyringService._setAutoLockMinutes = { _, _ in }
    keyringService._autoLockMinutes = { $0(5) } // default is 5mins
    
    let walletService = BraveWallet.TestBraveWalletService()
    walletService._userAssets = { _, _, completion in
      completion(mockUserAssets)
    }
    walletService._addObserver = { _ in }
    walletService._setDefaultBaseCurrency = { _ in }
    walletService._defaultBaseCurrency = { $0(CurrencyCode.usd.code) } // default is USD
    
    let txService = BraveWallet.TestTxService()
    
    return (keyringService, walletService, txService)
  }
  
  /// Test `init` will populate default values from keyring service / wallet service
  func testInit() {
    let (keyringService, walletService, txService) = setupServices()
    keyringService._autoLockMinutes = { $0(1) }
    walletService._defaultBaseCurrency = { $0(CurrencyCode.cad.code) }

    let sut = SettingsStore(
      keyringService: keyringService,
      walletService: walletService,
      txService: txService
    )

    XCTAssertEqual(sut.autoLockInterval, .minute)
    XCTAssertEqual(sut.currencyCode.code, CurrencyCode.cad.code)
  }

  /// Test `reset()` will call `reset()` on wallet service, update web3 preferences to default values, and update autolock & currency code values.
  func testReset() {
    let (keyringService, walletService, txService) = setupServices()
    var keyringServiceAutolockMinutes: Int32 = 1
    keyringService._autoLockMinutes = { $0(keyringServiceAutolockMinutes) }
    walletService._defaultBaseCurrency = { $0(CurrencyCode.cad.code) }

    var walletServiceResetCalled = false
    walletService._reset = {
      walletServiceResetCalled = true
    }

    assert(
      Preferences.Wallet.WalletType.none.rawValue != Preferences.Wallet.defaultWallet.defaultValue,
      "Test assumes default wallet value is not `none`") 
    Preferences.Wallet.defaultWallet.value = Preferences.Wallet.WalletType.none.rawValue
    XCTAssertEqual(
      Preferences.Wallet.defaultWallet.value,
      Preferences.Wallet.WalletType.none.rawValue,
      "Failed to update default wallet")
    Preferences.Wallet.allowEthereumProviderAccountRequests.value = !Preferences.Wallet.allowEthereumProviderAccountRequests.defaultValue
    XCTAssertEqual(
      Preferences.Wallet.allowEthereumProviderAccountRequests.value,
      !Preferences.Wallet.allowEthereumProviderAccountRequests.defaultValue,
      "Failed to update allow ethereum requests")
    Preferences.Wallet.displayWeb3Notifications.value = !Preferences.Wallet.displayWeb3Notifications.defaultValue
    XCTAssertEqual(
      Preferences.Wallet.displayWeb3Notifications.value,
      !Preferences.Wallet.displayWeb3Notifications.defaultValue,
      "Failed to update display web3 notifications")

    let sut = SettingsStore(
      keyringService: keyringService,
      walletService: walletService,
      txService: txService
    )
    
    XCTAssertEqual(sut.autoLockInterval, .minute)
    XCTAssertEqual(sut.currencyCode.code, CurrencyCode.cad.code)

    // reset internally in services, mock reset here.
    keyringServiceAutolockMinutes = 5
    
    // Begin test
    sut.reset()
    
    // simulate service observation updates
    sut.autoLockMinutesChanged()
    sut.onDefaultBaseCurrencyChanged(CurrencyCode.usd.code)
    
    XCTAssertEqual(sut.autoLockInterval, .fiveMinutes)
    XCTAssertEqual(sut.currencyCode.code, CurrencyCode.usd.code)

    XCTAssert(
      walletServiceResetCalled,
      "WalletService reset() not called")
    XCTAssertEqual(
      Preferences.Wallet.defaultWallet.value,
      Preferences.Wallet.defaultWallet.defaultValue,
      "Default Wallet was not reset to default")
    XCTAssertEqual(
      Preferences.Wallet.allowEthereumProviderAccountRequests.value,
      Preferences.Wallet.allowEthereumProviderAccountRequests.defaultValue,
      "Allow ethereum requests was not reset to default")
    XCTAssertEqual(
      Preferences.Wallet.displayWeb3Notifications.value,
      Preferences.Wallet.displayWeb3Notifications.defaultValue,
      "Display web3 notifications was not reset to default")
    /// Testing against `Domain.clearAllEthereumPermissions` has proven flakey
    /// on CI, verified in `ManageSiteConnectionsStoreTests`, `DomainTests`.
    /// Testing against `KeyringStore.resetKeychainStoredPassword`
    /// accesses keychain, requiring host app or testable keychain wrapper
    // TODO: Add testable keychain wrapper
  }

  /// Test `resetTransaction()` will call `reset()` on TxService
  func testResetTransaction() {
    let (keyringService, walletService, txService) = setupServices()
    var txServiceResetCalled = false
    txService._reset = {
      txServiceResetCalled = true
    }
    
    let sut = SettingsStore(
      keyringService: keyringService,
      walletService: walletService,
      txService: txService
    )
    
    sut.resetTransaction()
    
    XCTAssert(txServiceResetCalled, "TxService reset() not called")
  }
}
