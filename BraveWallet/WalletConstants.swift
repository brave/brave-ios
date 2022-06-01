// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

struct WalletConstants {
  /// The Brave swap fee as a % value
  ///
  /// This value will be formatted to a string such as 0.875%)
  static let braveSwapFee: Double = 0.00875

  /// The wei value used for unlimited allowance in an ERC 20 transaction.
  static let MAX_UINT256 = "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
  
  /// The OriginInfo used for transactions/requests from Brave Wallet.
  static let braveOrigin: BraveWallet.OriginInfo = .init(
    origin: .init(url: URL(string: "chrome://wallet/")!),
    originSpec: "chrome://wallet",
    eTldPlusOne: ""
  )
}
