// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import BraveWallet
import BraveShared
import BraveCore

extension BrowserViewController: Web3NameServiceScriptHandlerDelegate {
  func web3NameServiceDecisionHandler(_ proceed: Bool, web3Service: Web3Service, originalURL: URL, visitType: VisitType) {
    let isPrivateMode = PrivateBrowsingManager.shared.isPrivateBrowsing
    guard let rpcService = BraveWallet.JsonRpcServiceFactory.get(privateMode: isPrivateMode) else {
      finishEditingAndSubmit(originalURL, visitType: visitType)
      return
    }
    Task { @MainActor in
      switch web3Service {
      case .solana:
        rpcService.setSnsResolveMethod(proceed ? .enabled : .disabled)
      case .ethereum:
        rpcService.setEnsResolveMethod(proceed ? .enabled : .disabled)
      case .ethereumOffchain:
        rpcService.setEnsOffchainLookupResolveMethod(proceed ? .enabled : .disabled)
      }
      let decentralizedDNSHelper = DecentralizedDNSHelper(rpcService: rpcService, ipfsApi: braveCore.ipfsAPI)
      let result = await decentralizedDNSHelper.lookup(domain: originalURL.host ?? originalURL.absoluteString)
      switch result {
      case let .load(resolvedURL):
        if resolvedURL.isIPFSScheme {
          handleIPFSSchemeURL(resolvedURL, visitType: visitType)
        } else {
          finishEditingAndSubmit(resolvedURL, visitType: visitType)
        }
      case let .loadInterstitial(service):
        // ENS interstitial -> ENS Offchain interstitial possible
        showWeb3ServiceInterstitialPage(service: service, originalURL: originalURL, visitType: visitType)
      case .none:
        // failed to resolve domain or disabled
        finishEditingAndSubmit(originalURL, visitType: visitType)
      }
    }
  }
}
