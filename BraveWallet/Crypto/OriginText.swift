// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveCore
import SwiftUI
import struct Shared.Strings

/// View used to display a URLOrigin, bolding the eTLD+1.
struct OriginText: View {
  
  let urlOrigin: URLOrigin
  
  var body: some View {
    if urlOrigin.url?.absoluteString.hasPrefix(WalletConstants.braveWalletOrigin) == true {
      Text(Strings.Wallet.braveWallet)
    } else {
      let origin = urlOrigin.url?.absoluteString ?? ""
      let eTldPlusOne = urlOrigin.url?.baseDomain ?? ""
      if let range = origin.range(of: eTldPlusOne) {
        let originStart = origin[origin.startIndex..<range.lowerBound]
        let etldPlusOne = origin[range.lowerBound..<range.upperBound]
        let originEnd = origin[range.upperBound...]
        Text(originStart) + Text(etldPlusOne).bold() + Text(originEnd)
      } else {
        Text(origin)
      }
    }
  }
}
