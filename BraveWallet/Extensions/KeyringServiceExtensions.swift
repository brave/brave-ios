// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

extension BraveWalletKeyringService {
  func defaultKeyringInfo(_ completion: @escaping (BraveWallet.KeyringInfo) -> Void) {
    keyringInfo(BraveWallet.DefaultKeyringId, completion: completion)
  }
  
  @MainActor func defaultKeyringInfo() async -> BraveWallet.KeyringInfo {
    await withCheckedContinuation { continuation in
      keyringInfo(BraveWallet.DefaultKeyringId) { keyring in
        continuation.resume(returning: keyring)
      }
    }
  }
}
