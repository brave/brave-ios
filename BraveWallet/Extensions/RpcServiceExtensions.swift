// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import BigNumber

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
    network(account.coin) { [self] network in
      if token.symbol == network.symbol {
        balance(account.address, coin: account.coin, chainId: network.chainId, completion: convert)
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
  
  /// Obtain the decimal balance of an `BlockchainToken` for a given account
  ///
  /// If the call fails for some reason or the resulting wei cannot be converted,
  /// `completion` will be called with `nil`
  @MainActor func balance(
    for token: BraveWallet.BlockchainToken,
    in account: BraveWallet.AccountInfo
  ) async -> Double? {
    await withCheckedContinuation { continuation in
      balance(for: token, in: account) { value in
        continuation.resume(returning: value)
      }
    }
  }
  
  /// Obtain the decimal balance in `BDouble` of an `BlockchainToken` for a given account
  /// with certain decimal format style
  ///
  /// If the call fails for some reason or the resulting wei cannot be converted,
  /// `completion` will be called with `nil`
  func balance(
    for token: BraveWallet.BlockchainToken,
    in accountAddress: String,
    with coin: BraveWallet.CoinType,
    decimalFormatStyle: WeiFormatter.DecimalFormatStyle,
    completion: @escaping (BDouble?) -> Void
  ) {
    let convert: (String, BraveWallet.ProviderError, String) -> Void = { wei, status, _ in
      guard status == .success && !wei.isEmpty else {
        completion(nil)
        return
      }
      let formatter = WeiFormatter(decimalFormatStyle: decimalFormatStyle)
      if let valueString = formatter.decimalString(
        for: wei.removingHexPrefix,
        radix: .hex,
        decimals: Int(token.decimals)
      ) {
        completion(BDouble(valueString))
      } else {
        completion(nil)
      }
    }
    network(coin) { [self] network in
      if token.symbol == network.symbol {
        balance(accountAddress, coin: coin, chainId: network.chainId, completion: convert)
      } else if token.isErc20 {
        erc20TokenBalance(
          token.contractAddress(in: network),
          address: accountAddress,
          chainId: network.chainId,
          completion: convert
        )
      } else if token.isErc721 {
        erc721TokenBalance(
          token.contractAddress,
          tokenId: token.tokenId,
          accountAddress: accountAddress,
          chainId: network.chainId,
          completion: convert)
      } else {
        completion(nil)
      }
    }
  }
}
