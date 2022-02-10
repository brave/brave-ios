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
    func testPrefilledToken() {
        var store = BuyTokenStore(
            blockchainRegistry: MockBlockchainRegistry(),
            rpcService: MockJsonRpcService(),
            prefilledToken: nil
        )
        XCTAssertNil(store.selectedBuyToken)
        
        store = BuyTokenStore(
            blockchainRegistry: MockBlockchainRegistry(),
            rpcService: MockJsonRpcService(),
            prefilledToken: .previewToken
        )
        XCTAssertEqual(store.selectedBuyToken?.symbol.lowercased(), BraveWallet.BlockchainToken.previewToken.symbol.lowercased())
    }
    
}
