/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Strings
import SwiftUI
import BraveCore

extension BraveWallet.CoinType: Identifiable {
  public var id: Int {
    hashValue
  }
  
  var localizedTitle: String {
    switch self {
    case .eth:
      return "Ethereum"
    case .sol:
      return "Solana"
    case .fil:
      return "Filecoin"
    @unknown default:
      return "Unkown"
    }
  }
  
  var localizedDescription: String {
    switch self {
    case .eth:
      return "Supports EVM compatible assets on the Ethereum blockchain (ERC-20, ERC-721, ERC-1551, ERC-1155)"
    case .sol:
      return "Supports SPL compatible assets on the Solana blockchain"
    case .fil:
      return "Store FIL asset"
    @unknown default:
      return "Unknown"
    }
  }
}

private struct IsPresentingCoinTypesKey: EnvironmentKey {
  static var defaultValue: Binding<Bool> {
    Binding(get: { false }, set: { _ in })
  }
}

extension EnvironmentValues {
  var isPresentingCoinTypes: Binding<Bool> {
    get { self[IsPresentingCoinTypesKey.self] }
    set { self[IsPresentingCoinTypesKey.self] = newValue }
  }
}
