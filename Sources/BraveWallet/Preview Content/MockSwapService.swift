// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

#if DEBUG

class MockSwapService: BraveWalletSwapService {
  func isSwapSupported(_ chainId: String, completion: @escaping (Bool) -> Void) {
    completion(true)
  }

  func transactionPayload(_ params: BraveWallet.SwapParams, completion: @escaping (Bool, BraveWallet.SwapResponse?, String?) -> Void) {
    completion(
      true,
      .init(price: "", guaranteedPrice: "", to: "", data: "", value: "", gas: "", estimatedGas: "", gasPrice: "", protocolFee: "", minimumProtocolFee: "", buyTokenAddress: "", sellTokenAddress: "", buyAmount: "", sellAmount: "", allowanceTarget: "", sellTokenToEthRate: "", buyTokenToEthRate: ""),
      nil)
  }
  func priceQuote(_ params: BraveWallet.SwapParams, completion: @escaping (Bool, BraveWallet.SwapResponse?, String?) -> Void) {
    completion(
      true,
      .init(price: "", guaranteedPrice: "", to: "", data: "", value: "", gas: "", estimatedGas: "", gasPrice: "", protocolFee: "", minimumProtocolFee: "", buyTokenAddress: "", sellTokenAddress: "", buyAmount: "", sellAmount: "", allowanceTarget: "", sellTokenToEthRate: "", buyTokenToEthRate: ""),
      nil)
  }
  
  func jupiterQuote(_ params: BraveWallet.JupiterQuoteParams, completion: @escaping (Bool, BraveWallet.JupiterQuote?, String?) -> Void) {
    completion(false, nil, nil)
  }
  
  func jupiterSwapTransactions(_ params: BraveWallet.JupiterSwapParams, completion: @escaping (Bool, BraveWallet.JupiterSwapTransactions?, String?) -> Void) {
    completion(false, nil, nil)
  }
  
  func hasJupiterFees(forTokenMint mint: String, completion: @escaping (Bool) -> Void) {
    completion(false)
  }  
}

#endif
