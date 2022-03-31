// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import Data

/// A permission request for a specific dapp
public struct WebpagePermissionRequest {
  /// A users response type
  public enum Response {
    /// The user rejected the prompt by dismissing the screen
    case rejected
    /// The user granted access to a set of accounts
    case granted(accounts: [String])
  }
  /// The origin that requested this permission
  let requestingOrigin: URL
  /// The type of request
  let coinType: BraveWallet.CoinType
  /// A handler to be called when the user either approves or rejects the connection request
  let decisionHandler: (Response) -> Void
}

/// Handles dapp permission requests when connecting your wallet for the current session.
///
/// When a request begins you should first check if any pending requests exist for the origin using
/// ``hasPendingRequest(for:coinType)`` and if none exist, use ``beginRequest(for:coinType)`` to add one.
/// When the user completes the request you can call ``WebpagePermissionRequest.decisionHandler(_:)`` with
/// the users response.
public class WalletProviderPermissionRequestsManager {
  /// A shared instance of the permissions manager
  public static let shared: WalletProviderPermissionRequestsManager = .init()
  
  private var requests: [WebpagePermissionRequest] = []
  
  private init() { }
  
  /// Adds a permission request for a specific origin and coin type. Optionally you can be notified of the
  /// users response by providing a closure
  public func beginRequest(
    for origin: URL,
    coinType: BraveWallet.CoinType,
    completion: ((WebpagePermissionRequest.Response) -> Void)? = nil
  ) -> WebpagePermissionRequest {
    let request = WebpagePermissionRequest(requestingOrigin: origin, coinType: coinType) { [weak self] decision in
      guard let self = self else { return }
      if case .granted(let accounts) = decision {
        Domain.setEthereumPermissions(forUrl: origin, accounts: accounts, grant: true)
      }
      self.requests.removeAll(where: { $0.requestingOrigin == origin && $0.coinType == coinType })
      completion?(decision)
    }
    requests.append(request)
    return request
  }
  
  public func hasPendingRequest(for origin: URL, coinType: BraveWallet.CoinType) -> Bool {
    requests.contains(where: { $0.requestingOrigin == origin && $0.coinType == coinType })
  }
  
  /// Returns a list of pending requests waiting for a given origin
  public func pendingRequests(for origin: URL) -> [WebpagePermissionRequest] {
    requests.filter({ $0.requestingOrigin == origin })
  }
}
