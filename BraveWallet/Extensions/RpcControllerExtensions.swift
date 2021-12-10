// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

extension BraveWalletEthJsonRpcController {
#if swift(>=5.5) && canImport(_Concurrency)
  @MainActor func balance(
    for token: BraveWallet.ERCToken,
    in account: BraveWallet.AccountInfo
  ) async -> Double? {
    await withCheckedContinuation { continuation in
      balance(for: token, in: account, completion: { result in
        continuation.resume(returning: result)
      })
    }
  }
#endif
  /// Obtain the decimal balance of an `ERCToken` for a given account
  ///
  /// If the call fails for some reason or the resulting wei cannot be converted,
  /// `completion` will be called with `nil`
  func balance(
    for token: BraveWallet.ERCToken,
    in account: BraveWallet.AccountInfo,
    completion: @escaping (Double?) -> Void
  ) {
    let convert: (Bool, String) -> Void = { success, wei in
      guard success && !wei.isEmpty else {
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
    // This will probably need to be changed to check if its native chain rather than ETH
    // https://github.com/brave/brave-ios/issues/4429
    if token.isETH {
      balance(account.address, completion: convert)
    } else if token.isErc20 {
      chainId { [self] chainId in
        erc20TokenBalance(
          token.contractAddress(in: chainId),
          address: account.address,
          completion: convert
        )
      }
    } else if token.isErc721 {
      erc721TokenBalance(token.contractAddress, tokenId: token.tokenId, accountAddress: account.address,
                         completion: convert)
    } else {
      completion(nil)
    }
  }
}
