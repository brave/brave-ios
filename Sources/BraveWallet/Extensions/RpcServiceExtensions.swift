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
    network: BraveWallet.NetworkInfo,
    decimalFormatStyle: WeiFormatter.DecimalFormatStyle = .balance,
    completion: @escaping (Double?) -> Void
  ) {
    switch network.coin {
    case .eth:
      ethBalance(
        for: token,
        in: account.address,
        network: network,
        completion: { wei, status, _ in
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
            completion(Double(valueString))
          } else {
            completion(nil)
          }
        }
      )
    case .sol:
      if network.isNativeAsset(token) {
        solanaBalance(account.address, chainId: network.chainId) { lamports, status, errorMessage in
          guard status == .success else {
            completion(nil)
            return
          }
          let formatter = WeiFormatter(decimalFormatStyle: decimalFormatStyle)
          if let valueString = formatter.decimalString(
            for: "\(lamports)",
            radix: .decimal,
            decimals: Int(token.decimals)
          ) {
            completion(Double(valueString))
          } else {
            completion(nil)
          }
        }
      } else {
        splTokenAccountBalance(
          account.address,
          tokenMintAddress: token.contractAddress,
          chainId: network.chainId
        ) { amount, _, _, status, errorMessage in
          guard status == .success else {
            completion(nil)
            return
          }
          let formatter = WeiFormatter(decimalFormatStyle: decimalFormatStyle)
          if let valueString = formatter.decimalString(
            for: "\(amount)",
            radix: .decimal,
            decimals: Int(token.decimals)
          ) {
            completion(Double(valueString))
          } else {
            completion(nil)
          }
        }
      }
    case .fil:
      completion(nil)
    @unknown default:
      completion(nil)
    }
  }
  
  /// Obtain the decimal balance of an `BlockchainToken` for a given account
  ///
  /// If the call fails for some reason or the resulting wei cannot be converted,
  /// `completion` will be called with `nil`
  @MainActor func balance(
    for token: BraveWallet.BlockchainToken,
    in account: BraveWallet.AccountInfo,
    network: BraveWallet.NetworkInfo
  ) async -> Double? {
    await withCheckedContinuation { continuation in
      balance(for: token, in: account, network: network) { value in
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
    network: BraveWallet.NetworkInfo,
    decimalFormatStyle: WeiFormatter.DecimalFormatStyle,
    completion: @escaping (BDouble?) -> Void
  ) {
    switch network.coin {
    case .eth:
      ethBalance(
        for: token,
        in: accountAddress,
        network: network,
        completion: { wei, status, _ in
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
      )
    case .sol:
      if network.isNativeAsset(token) {
        solanaBalance(accountAddress, chainId: network.chainId) { lamports, status, errorMessage in
          guard status == .success else {
            completion(nil)
            return
          }
          let formatter = WeiFormatter(decimalFormatStyle: decimalFormatStyle)
          if let valueString = formatter.decimalString(
            for: "\(lamports)",
            radix: .decimal,
            decimals: Int(token.decimals)
          ) {
            completion(BDouble(valueString))
          } else {
            completion(nil)
          }
        }
      } else {
        splTokenAccountBalance(
          accountAddress,
          tokenMintAddress: token.contractAddress,
          chainId: network.chainId
        ) { amount, _, _, status, errorMessage in
          guard status == .success else {
            completion(nil)
            return
          }
          let formatter = WeiFormatter(decimalFormatStyle: decimalFormatStyle)
          if let valueString = formatter.decimalString(
            for: "\(amount)",
            radix: .decimal,
            decimals: Int(token.decimals)
          ) {
            completion(BDouble(valueString))
          } else {
            completion(nil)
          }
        }
      }
    case .fil:
      completion(nil)
    @unknown default:
      completion(nil)
    }
  }
  
  @MainActor func balance(
    for token: BraveWallet.BlockchainToken,
    in accountAddress: String,
    network: BraveWallet.NetworkInfo,
    decimalFormatStyle: WeiFormatter.DecimalFormatStyle
  ) async -> BDouble? {
    await withCheckedContinuation { continuation in
      balance(for: token, in: accountAddress, network: network, decimalFormatStyle: decimalFormatStyle) { value in
        continuation.resume(returning: value)
      }
    }
  }
  
  private func ethBalance(
    for token: BraveWallet.BlockchainToken,
    in accountAddress: String,
    network: BraveWallet.NetworkInfo,
    completion: @escaping (String, BraveWallet.ProviderError, String) -> Void
  ) {
    if network.isNativeAsset(token) {
      balance(
        accountAddress,
        coin: .eth,
        chainId: network.chainId,
        completion: completion
      )
    } else if token.isErc20 {
      erc20TokenBalance(
        token.contractAddress(in: network),
        address: accountAddress,
        chainId: network.chainId,
        completion: completion
      )
    } else if token.isErc721 {
      erc721TokenBalance(
        token.contractAddress,
        tokenId: token.tokenId,
        accountAddress: accountAddress,
        chainId: network.chainId,
        completion: completion
      )
    } else {
      let errorMessage = "Unable to fetch ethereum balance for \(token.symbol) token in account address '\(accountAddress)'"
      completion("", .internalError, errorMessage)
    }
  }
  
  /// Returns an array of all networks for the supported coin types.
  @MainActor func allNetworksForSupportedCoins() async -> [BraveWallet.NetworkInfo] {
    await withTaskGroup(of: [BraveWallet.NetworkInfo].self) { @MainActor [weak self] group -> [BraveWallet.NetworkInfo] in
      guard let self = self else { return [] }
      for coinType in WalletConstants.supportedCoinTypes {
        group.addTask { @MainActor in
          let chains = await self.allNetworks(coinType)
          return chains.filter { // localhost not supported
            $0.chainId != BraveWallet.LocalhostChainId
          }
        }
      }
      let allChains = await group.reduce([BraveWallet.NetworkInfo](), { $0 + $1 })
      return allChains.sorted { lhs, rhs in
        // sort solana chains to the front of the list
        lhs.coin == .sol && rhs.coin != .sol
      }
    }
  }
}
