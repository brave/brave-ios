// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import struct Shared.Strings
import SwiftUI
import BraveCore

/// Used to determine where a user is navigated to when they tap on a buy, send or swap button
enum BuySendSwapDestination: Identifiable, CaseIterable, Equatable, Hashable {
  
  static var allCases: [BuySendSwapDestination] = [.buy(), .send(), .swap()]
  
  case buy(BraveWallet.ERCToken? = nil)
  case send(BraveWallet.ERCToken? = nil)
  case swap(BraveWallet.ERCToken? = nil)
  
  var id: String {
    switch self {
    case .buy:
      return "buy"
    case .send:
      return "send"
    case .swap:
      return "swap"
    }
  }
  
  var localizedTitle: String {
    switch self {
    case .buy:
      return Strings.Wallet.buy
    case .send:
      return Strings.Wallet.send
    case .swap:
      return Strings.Wallet.swap
    }
  }
  
  var localizedDescription: String {
    switch self {
    case .buy:
      return Strings.Wallet.buyDescription
    case .send:
      return Strings.Wallet.sendDescription
    case .swap:
      return Strings.Wallet.swapDescription
    }
  }
}

private struct BuySendSwapDestinationKey: EnvironmentKey {
  static var defaultValue: Binding<BuySendSwapDestination?> {
    Binding(get: { nil }, set: { _ in })
  }
}

extension EnvironmentValues {
  /// The destination to set when the user wants to access the buy, send or swap widget from anywhere in the
  /// view hierarchy
  var buySendSwapDestination: Binding<BuySendSwapDestination?> {
    get { self[BuySendSwapDestinationKey.self] }
    set { self[BuySendSwapDestinationKey.self] = newValue }
  }
}
