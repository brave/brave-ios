// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import Combine
import BraveCore
@testable import BraveWallet

class SendTokenStoreTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    
    func testFetchAssets() {
        let store = SendTokenStore(
            keyringController: TestKeyringController(),
            rpcController: TestEthJsonRpcController(),
            walletService: TestBraveWalletService(),
            transactionController: TestEthTxController()
        )
        let ex = expectation(description: "fetch-assets")
        XCTAssertNil(store.selectedSendToken) // Initial state
        store.$selectedSendToken.dropFirst().sink { token in
            defer { ex.fulfill() }
            guard let token = token else {
                XCTFail("Token was nil")
                return
            }
            XCTAssert(token.isETH) // Should end up showing ETH as the default asset
        }.store(in: &cancellables)
        store.fetchAssets()
        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
        }
    }
    
    func testMakeSendTransaction() {
        let store = SendTokenStore(
            keyringController: TestKeyringController(),
            rpcController: TestEthJsonRpcController(),
            walletService: TestBraveWalletService(),
            transactionController: TestEthTxController()
        )
    }
}
