// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import BraveCore

extension BraveWallet.AccountInfo: Identifiable {
  public var id: String {
    address
  }
  public var isPrimary: Bool {
    !isImported
  }
}

extension BraveWallet.TransactionInfo: Identifiable {
  // Already has `id` property
}

public enum AssetImageName: String {
  case ethereum = "eth-asset-icon"
  case solana = "sol-asset-icon"
  case filecoin = "filecoin-asset-icon"
  case polygon = "matic"
  case binance = "bnb-asset-icon"
  case celo = "celo"
  case avalanche = "avax"
  case fantom = "fantom"
  case aurora = "aurora"
  case optimism = "optimism"
}

extension BraveWallet.NetworkInfo: Identifiable {
  public var id: String {
    chainId
  }
  
  var shortChainName: String {
    chainName.split(separator: " ").first?.capitalized ?? chainName
  }

  public var nativeToken: BraveWallet.BlockchainToken {
    .init(
      contractAddress: "",
      name: symbolName,
      logo: nativeTokenLogoName ?? "",
      isErc20: false,
      isErc721: false,
      isErc1155: false,
      isNft: false,
      symbol: symbol,
      decimals: decimals,
      visible: false,
      tokenId: "",
      coingeckoId: "",
      chainId: chainId,
      coin: coin
    )
  }
  
  public var nativeTokenLogoName: String? {
    if let logoBySymbol = assetIconNameBySymbol(symbol) {
      return logoBySymbol
    } else if let logoByChainId = assetIconNameByChainId(chainId) {
      return logoByChainId
    } else {
      return iconUrls.first
    }
  }
  
  public var nativeTokenLogoImage: UIImage? {
    guard let logo = nativeTokenLogoName else { return nil }
    return UIImage(named: logo, in: .module, with: nil)
  }
  
  public var networkLogoName: String? {
    return assetIconNameByChainId(chainId) ?? iconUrls.first
  }
  
  public var networkLogoImage: UIImage? {
    guard let logo = networkLogoName else { return nil }
    return UIImage(named: logo, in: .module, with: nil)
  }
  
  private func assetIconNameByChainId(_ chainId: String) -> String? {
    switch chainId.uppercased() {
    case
      BraveWallet.MainnetChainId.uppercased(),
      BraveWallet.GoerliChainId.uppercased(),
      BraveWallet.SepoliaChainId.uppercased():
      return AssetImageName.ethereum.rawValue
    case
      BraveWallet.SolanaMainnet.uppercased(),
      BraveWallet.SolanaDevnet.uppercased(),
      BraveWallet.SolanaTestnet.uppercased():
      return AssetImageName.solana.rawValue
    case
      BraveWallet.FilecoinMainnet.uppercased(),
      BraveWallet.FilecoinTestnet.uppercased(),
      BraveWallet.FilecoinEthereumMainnetChainId.uppercased(),
      BraveWallet.FilecoinEthereumTestnetChainId.uppercased():
      return AssetImageName.filecoin.rawValue
    case BraveWallet.PolygonMainnetChainId.uppercased():
      return AssetImageName.polygon.rawValue
    case BraveWallet.BinanceSmartChainMainnetChainId.uppercased():
      return AssetImageName.binance.rawValue
    case BraveWallet.CeloMainnetChainId.uppercased():
      return AssetImageName.celo.rawValue
    case BraveWallet.AvalancheMainnetChainId.uppercased():
      return AssetImageName.avalanche.rawValue
    case BraveWallet.FantomMainnetChainId.uppercased():
      return AssetImageName.fantom.rawValue
    case BraveWallet.AuroraMainnetChainId.uppercased():
      return AssetImageName.aurora.rawValue
    case BraveWallet.OptimismMainnetChainId.uppercased():
      return AssetImageName.optimism.rawValue
    default:
      return nil
    }
  }
  
  private func assetIconNameBySymbol(_ symbol: String) -> String? {
    if symbol.caseInsensitiveCompare("ETH") == .orderedSame {
      return AssetImageName.ethereum.rawValue
    } else if symbol.caseInsensitiveCompare("SOL") == .orderedSame {
      return AssetImageName.solana.rawValue
    } else if symbol.caseInsensitiveCompare("FIL") == .orderedSame {
      return AssetImageName.filecoin.rawValue
    }
    return nil
  }
}

extension BraveWallet.SignMessageRequest {
  static var previewRequest: BraveWallet.SignMessageRequest {
    .init(
      originInfo: .init(origin: .init(url: URL(string: "https://app.uniswap.org")!), originSpec: "", eTldPlusOne: "uniswap.org"),
      id: 1,
      address: "",
      domain: "example.com",
      message: "To avoid digital cat burglars, sign below to authenticate with CryptoKitties.",
      isEip712: false,
      domainHash: "",
      primaryHash: "",
      messageBytes: [],
      coin: .eth
    )
  }
}

extension BraveWallet.BlockchainToken: Identifiable {
  public var id: String {
    contractAddress.lowercased() + chainId + symbol + tokenId
  }

  public func contractAddress(in network: BraveWallet.NetworkInfo) -> String {
    switch network.coin {
    case .eth:
      // ETH special swap address
      // Only checking token.symbol with selected network.symbol is sufficient
      // since there is no swap support for custom networks.
      return symbol == network.symbol ? BraveWallet.ethSwapAddress : contractAddress
    case .sol:
      // SOL special swap address
      // Only checking token.symbol with selected network.symbol is sufficient
      // since there is no swap support for custom networks.
      return symbol == network.symbol ? BraveWallet.solSwapAddress : contractAddress
    default:
      return contractAddress
    }
  }
}

extension BraveWallet {
  /// The address that is expected when you are swapping ETH via SwapService APIs
  public static let ethSwapAddress: String = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
  
  /// The address that is expected when you are swapping SOL via Jupiter Swap APIs
  public static let solSwapAddress: String = "So11111111111111111111111111111111111111112"
}

extension BraveWallet.CoinType: Identifiable {
  public var id: Int {
    rawValue
  }
}

extension BraveWallet.OnRampProvider: Identifiable {
  public var id: Int {
    rawValue
  }
}

extension BraveWallet.OnRampCurrency: Identifiable {
  public var id: String {
    currencyCode
  }
  
  var symbol: String {
    CurrencyCode.symbol(for: currencyCode)
  }
}

extension BraveWallet.CoinMarket: Identifiable {
  var uniqueId: String {
    "\(symbol)\(marketCapRank)"
  }
}
