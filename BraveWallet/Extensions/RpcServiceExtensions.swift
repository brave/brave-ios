// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

extension BraveWalletJsonRpcService {
  /// Obtain the decimal balance of an `BlockchainToken` for a given account
  ///
  /// If the call fails for some reason or the resulting wei cannot be converted,
  /// `completion` will be called with `nil`
  func balance(
    for token: BraveWallet.BlockchainToken,
    in account: BraveWallet.AccountInfo,
    completion: @escaping (Double?) -> Void
  ) {
    let convert: (String, BraveWallet.ProviderError, String) -> Void = { wei, status, _ in
      guard status == .success && !wei.isEmpty else {
        completion(nil)
        return
      }
      let formatter = WeiFormatter(decimalFormatStyle: .balance)
      if let valueString = formatter.decimalString(
        for: wei.removingHexPrefix,
        radix: .hex,
        decimals: Int(token.decimals)
      ) {
        completion(Double(valueString))
      } else {
        completion(nil)
      }
    }
    network { [self] network in
      if token.symbol == network.symbol {
        balance(account.address, coin: .eth, chainId: network.chainId, completion: convert)
      } else if token.isErc20 {
        erc20TokenBalance(
          token.contractAddress(in: network),
          address: account.address,
          chainId: network.chainId,
          completion: convert
        )
      } else if token.isErc721 {
        erc721TokenBalance(
          token.contractAddress,
          tokenId: token.tokenId,
          accountAddress: account.address,
                           chainId: network.chainId,
          completion: convert)
      } else {
        completion(nil)
      }
    }
  }
}
