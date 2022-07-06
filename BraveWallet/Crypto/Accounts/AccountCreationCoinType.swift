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
      return Strings.Wallet.coinTypeEthereum
    case .sol:
      return Strings.Wallet.coinTypeSolana
    case .fil:
      return Strings.Wallet.coinTypeFilecoin
    @unknown default:
      return Strings.Wallet.coinTypeUnknown
    }
  }
  
  var localizedDescription: String {
    switch self {
    case .eth:
      return Strings.Wallet.coinTypeEthereumDescription
    case .sol:
      return Strings.Wallet.coinTypeSolanaDescription
    case .fil:
      return Strings.Wallet.coinTypeFilecoinDescription
    @unknown default:
      return Strings.Wallet.coinTypeUnknown
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
