// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

#if DEBUG

class MockEthTxService: BraveWallet.TestEthTxService {

  override func nonce(forHardwareTransaction txMetaId: String, completion: @escaping (String?) -> Void) {
    completion(nil)
  }
  
  override func transactionMessage(toSign txMetaId: String, completion: @escaping (String?) -> Void) {
    completion(nil)
  }
  
  override func processHardwareSignature(_ txMetaId: String, v: String, r: String, s: String, completion: @escaping (Bool) -> Void) {
    completion(false)
  }
  
  override func makeErc721Transfer(fromData from: String, to: String, tokenId: String, contractAddress: String, completion: @escaping (Bool, [NSNumber]) -> Void) {
    completion(false, [])
  }
  
  override func addUnapprovedTransaction(_ txData: BraveWallet.TxData, from: String, completion: @escaping (Bool, String, String) -> Void) {
    completion(true, "txMetaId", "")
  }
  
  override func addUnapproved1559Transaction(_ txData: BraveWallet.TxData1559, from: String, completion: @escaping (Bool, String, String) -> Void) {
    completion(true, "txMetaId", "")
  }
  
  override func makeErc20TransferData(_ toAddress: String, amount: String, completion: @escaping (Bool, [NSNumber]) -> Void) {
    completion(true, .init())
  }
  
  override func makeErc20ApproveData(_ spenderAddress: String, amount: String, completion: @escaping (Bool, [NSNumber]) -> Void) {
    completion(true, .init())
  }
}

#endif
