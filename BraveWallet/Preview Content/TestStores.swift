// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

#if DEBUG

extension WalletStore {
  static var previewStore: WalletStore {
    .init(
      keyringService: TestKeyringService(),
      rpcService: TestJsonRpcService(),
      walletService: TestBraveWalletService(),
      assetRatioService: TestAssetRatioService(),
      swapService: TestSwapService(),
      blockchainRegistry: TestBlockchainRegistry(),
      txService: TestEthTxService()
    )
  }
}

extension CryptoStore {
  static var previewStore: CryptoStore {
    .init(
      keyringService: TestKeyringService(),
      rpcService: TestJsonRpcService(),
      walletService: TestBraveWalletService(),
      assetRatioService: TestAssetRatioService(),
      swapService: TestSwapService(),
      blockchainRegistry: TestBlockchainRegistry(),
      txService: TestEthTxService()
    )
  }
}

extension NetworkStore {
  static var previewStore: NetworkStore {
    .init(
      rpcService: TestJsonRpcService()
    )
  }
}

extension KeyringStore {
  static var previewStore: KeyringStore {
    .init(keyringService: TestKeyringService())
  }
  static var previewStoreWithWalletCreated: KeyringStore {
    let store = KeyringStore(keyringService: TestKeyringService())
    store.createWallet(password: "password")
    return store
  }
}

extension BuyTokenStore {
  static var previewStore: BuyTokenStore {
    .init(
      blockchainRegistry: TestBlockchainRegistry(),
      rpcService: TestJsonRpcService(),
      prefilledToken: .previewToken
    )
  }
}

extension SendTokenStore {
  static var previewStore: SendTokenStore {
    .init(
      keyringService: TestKeyringService(),
      rpcService: TestJsonRpcService(),
      walletService: TestBraveWalletService(),
      txService: TestEthTxService(),
      blockchainRegistry: TestBlockchainRegistry(),
      prefilledToken: .previewToken
    )
  }
}

extension AssetDetailStore {
  static var previewStore: AssetDetailStore {
    .init(
      assetRatioService: TestAssetRatioService(),
      keyringService: TestKeyringService(),
      rpcService: TestJsonRpcService(),
      txService: TestEthTxService(),
      blockchainRegistry: TestBlockchainRegistry(),
      token: .previewToken
    )
  }
}

extension SwapTokenStore {
  static var previewStore: SwapTokenStore {
    .init(
      keyringService: TestKeyringService(),
      blockchainRegistry: TestBlockchainRegistry(),
      rpcService: TestJsonRpcService(),
      assetRatioService: TestAssetRatioService(),
      swapService: TestSwapService(),
      txService: TestEthTxService(),
      prefilledToken: nil
    )
  }
}

extension UserAssetsStore {
  static var previewStore: UserAssetsStore {
    .init(
      walletService: TestBraveWalletService(),
      blockchainRegistry: TestBlockchainRegistry(),
      rpcService: TestJsonRpcService()
    )
  }
}

extension AccountActivityStore {
  static var previewStore: AccountActivityStore {
    .init(
      account: .previewAccount,
      walletService: TestBraveWalletService(),
      rpcService: TestJsonRpcService(),
      assetRatioService: TestAssetRatioService(),
      txService: TestEthTxService()
    )
  }
}

extension TransactionConfirmationStore {
  static var previewStore: TransactionConfirmationStore {
    .init(
      assetRatioService: TestAssetRatioService(),
      rpcService: TestJsonRpcService(),
      txService: TestEthTxService(),
      blockchainRegistry: TestBlockchainRegistry(),
      walletService: TestBraveWalletService()
    )
  }
}

#endif
