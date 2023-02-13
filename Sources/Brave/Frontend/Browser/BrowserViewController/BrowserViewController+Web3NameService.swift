// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import BraveWallet
import BraveShared

extension BrowserViewController: Web3NameServiceScriptHandlerDelegate {
  func web3NameServiceDecisionHandler(_ proceed: Bool, originalURL: URL, visitType: VisitType) {
    if proceed {
      Preferences.Wallet.resolveSNSDomainNames.value = Preferences.Wallet.Web3DomainOption.enabled.rawValue
      Task { @MainActor in
        if let host = originalURL.host, let resolvedUrl = await resolveSNSHost(host) {
          // resolved url
          finishEditingAndSubmit(resolvedUrl, visitType: visitType)
        }
      }
    } else {
      Preferences.Wallet.resolveSNSDomainNames.value = Preferences.Wallet.Web3DomainOption.disabled.rawValue
      finishEditingAndSubmit(originalURL, visitType: visitType)
    }
  }
}
