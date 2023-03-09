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
    switch web3Service {
    case .solana:
      if proceed {
        Task { @MainActor in
          rpcService.setSnsResolveMethod(.enabled)
          if let host = originalURL.host, let resolvedUrl = await resolveSNSHost(host, rpcService: rpcService) {
            // resolved url
            finishEditingAndSubmit(resolvedUrl, visitType: visitType)
          }
        }
      } else {
        rpcService.setSnsResolveMethod(.disabled)
        finishEditingAndSubmit(originalURL, visitType: visitType)
      }
    case .ethereum:
      if proceed {
        Task { @MainActor in
          rpcService.setEnsResolveMethod(.enabled)
          if let host = originalURL.host {
            let (contentHash, isOffchainConsentRequired, status, _) = await rpcService.ensGetContentHash(host)
            if isOffchainConsentRequired {
              showWeb3ServiceInterstitialPage(service: .ethereumOffchain, originalURL: originalURL, visitType: .unknown)
              return
            }
            if status == .success,
               !contentHash.isEmpty,
               let ipfsUrl = braveCore.ipfsAPI.contentHashToCIDv1URL(for: contentHash) {
              handleIPFSSchemeURL(ipfsUrl, visitType: .unknown)
              return
            }
          }
        }
      } else {
        rpcService.setEnsResolveMethod(.disabled)
        finishEditingAndSubmit(originalURL, visitType: visitType)
      }
    case .ethereumOffchain:
      if proceed {
        Task { @MainActor in
          rpcService.setEnsOffchainLookupResolveMethod(.enabled)
          if let host = originalURL.host {
            let (contentHash, isOffchainConsentRequired, status, _) = await rpcService.ensGetContentHash(host)
            if isOffchainConsentRequired { // TODO: is this here possible?
              showWeb3ServiceInterstitialPage(service: .ethereumOffchain, originalURL: originalURL, visitType: .unknown)
              return
            }
            if status == .success,
               !contentHash.isEmpty,
               let ipfsUrl = braveCore.ipfsAPI.contentHashToCIDv1URL(for: contentHash) {
              handleIPFSSchemeURL(ipfsUrl, visitType: .unknown)
              return
            }
          }
        }
      } else {
        rpcService.setEnsOffchainLookupResolveMethod(.disabled)
        finishEditingAndSubmit(originalURL, visitType: visitType)
      }
    }
  }
}
