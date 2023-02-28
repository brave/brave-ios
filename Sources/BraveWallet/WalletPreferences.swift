// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveShared
import struct Shared.Strings
import BraveCore

extension Preferences {
  public final class Wallet {
    public enum WalletType: Int, Identifiable, CaseIterable {
      case none
      case brave
      
      public var id: Int {
        rawValue
      }
      
      public var name: String {
        switch self {
        case .none:
          return Strings.Wallet.walletTypeNone
        case .brave:
          return Strings.Wallet.braveWallet
        }
      }
    }
    /// The default wallet to use for Ethereum to be communicate with web3
    public static let defaultEthWallet = Option<Int>(key: "wallet.default-wallet", default: WalletType.brave.rawValue)
    /// The default wallet to use for Solana to be communicate with web3
    public static let defaultSolWallet = Option<Int>(key: "wallet.default-sol-wallet", default: WalletType.brave.rawValue)
    /// Whether or not webpages can use the Ethereum Provider API to communicate with users Ethereum wallet
    public static let allowEthProviderAccess: Option<Bool> = .init(
      key: "wallet.allow-eth-provider-access",
      default: true
    )
    /// Whether or not webpages can use the Solana Provider API to communicate with users Solana wallet
    public static let allowSolProviderAccess: Option<Bool> = .init(
      key: "wallet.allow-sol-provider-access",
      default: true
    )
    /// The option to display web3 notification
    public static let displayWeb3Notifications = Option<Bool>(key: "wallet.display-web3-notifications", default: true)
    /// The option to determine if we show or hide test networks in network lists
    public static let showTestNetworks = Option<Bool>(key: "wallet.show-test-networks", default: false)
    /// The option for users to turn off aurora popup
    public static let showAuroraPopup = Option<Bool>(key: "wallet.show-aurora-popup", default: true)
    
    /// Reset Wallet Preferences based on coin type
    public static func reset(for coin: BraveWallet.CoinType) {
      switch coin {
      case .eth:
        Preferences.Wallet.defaultEthWallet.reset()
        Preferences.Wallet.allowEthProviderAccess.reset()
      case .sol:
        Preferences.Wallet.defaultSolWallet.reset()
        Preferences.Wallet.allowSolProviderAccess.reset()
      case .fil:
        // not supported
        fallthrough
      @unknown default:
        return
      }
    }
  }
}

extension BraveWallet.ResolveMethod: Identifiable, CaseIterable {
  public static var allCases: [BraveWallet.ResolveMethod] = [.ask, .enabled, .disabled]
  
  public var id: Int { rawValue }
  
  public var name: String {
    switch self {
    case .ask:
      return Strings.Wallet.web3DomainOptionAsk
    case .enabled:
      return Strings.Wallet.web3DomainOptionEnabled
    case .disabled:
      return Strings.Wallet.web3DomainOptionDisabled
    @unknown default:
      return Strings.Wallet.web3DomainOptionAsk
    }
  }
}
