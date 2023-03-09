// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared
import BraveWallet

public enum Web3Service: String, CaseIterable {
  case solana
  case ethereum
  case ethereumOffchain
  
  public var id: String { rawValue }
}

extension Web3Service {
  
  var errorTitle: String {
    switch self {
    case .solana:
      return Strings.Wallet.snsDomainInterstitialPageTitle
    case .ethereum:
      return Strings.Wallet.ensDomainInterstitialPageTitle
    case .ethereumOffchain:
      return Strings.Wallet.ensOffchainDomainInterstitialPageTitle
    }
  }
  
  var errorDescription: String {
    switch self {
    case .solana:
      let termsOfUseUrl = WalletConstants.snsTermsOfUseURL.absoluteString
      let privacyPolicyUrl = WalletConstants.snsPrivacyPolicyURL.absoluteString
      return String.localizedStringWithFormat(
        Strings.Wallet.snsDomainInterstitialPageDescription,
        termsOfUseUrl,
        Strings.Wallet.web3DomainInterstitialPageTAndU,
        privacyPolicyUrl,
        Strings.Wallet.web3DomainInterstitialPagePrivacyPolicy)
    case .ethereum:
      let termsOfUseUrl = WalletConstants.ensTermsOfUseURL.absoluteString
      let privacyPolicyUrl = WalletConstants.ensPrivacyPolicyURL.absoluteString
      return String.localizedStringWithFormat(
        Strings.Wallet.ensDomainInterstitialPageDescription,
        termsOfUseUrl,
        Strings.Wallet.web3DomainInterstitialPageTAndU,
        privacyPolicyUrl,
        Strings.Wallet.web3DomainInterstitialPagePrivacyPolicy)
    case .ethereumOffchain:
      let learnMore = WalletConstants.braveWalletENSOffchainURL.absoluteString
      return String.localizedStringWithFormat(
        Strings.Wallet.ensOffchainDomainInterstitialPageDescription,
        learnMore,
        Strings.Wallet.learnMoreButton)
    }
  }
  
  var disableButtonTitle: String {
    Strings.Wallet.web3DomainInterstitialPageButtonDisable
  }
  
  var proceedButtonTitle: String {
    switch self {
    case .solana:
      return Strings.Wallet.snsDomainInterstitialPageButtonProceed
    case .ethereum:
      return Strings.Wallet.ensDomainInterstitialPageButtonProceed
    case .ethereumOffchain:
      return Strings.Wallet.ensOffchainDomainInterstitialPageButtonProceed
    }
  }
}

public class Web3DomainHandler: InternalSchemeResponse {
  
  let service: Web3Service
  
  public init(for service: Web3Service) {
    self.service = service
  }
  
  public func response(forRequest request: URLRequest) -> (URLResponse, Data)? {
    guard let url = request.url else { return nil }
    let response = InternalSchemeHandler.response(forUrl: url)
    guard let path = Bundle.module.path(forResource: "Web3Domain", ofType: "html")
    else {
      return nil
    }
    
    guard var html = try? String(contentsOfFile: path) else {
      assert(false)
      return nil
    }
    
    let variables = [
      "page_title": request.url?.displayURL?.absoluteDisplayString ?? "",
      "error_title": service.errorTitle,
      "error_description": service.errorDescription,
      "button_disable": service.disableButtonTitle,
      "button_procced": service.proceedButtonTitle,
      "message_handler": Web3NameServiceScriptHandler.messageHandlerName,
      "service_id": service.id
    ]
    
    variables.forEach { (arg, value) in
      html = html.replacingOccurrences(of: "%\(arg)%", with: value)
    }
    
    guard let data = html.data(using: .utf8) else {
      return nil
    }
    
    return (response, data)
  }
  
  public static func path(for service: Web3Service) -> String {
    switch service {
    case .solana:
      return "web3/sns"
    case .ethereum:
      return "web3/ens"
    case .ethereumOffchain:
      return "web3/ensOffchain"
    }
  }
}
