// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import CoreData
import Shared
import BraveCore
import os.log

public final class WalletUserAssetBalance: NSManagedObject, CRUD {
  @NSManaged public var contractAddress: String
  @NSManaged public var symbol: String
  @NSManaged public var chainId: String
  @NSManaged public var tokenId: String
  @NSManaged public var balance: String
  @NSManaged public var accountAddress: String
  
  /// This is the same as `BraveWallet.BlockchainToken.id` that is defined inside `BraveWalletSwiftUIExtension` under `BraveWallet` bundle
  /// This needs to be updated if `BraveWallet.BlockchainToken.id` is changed
  public var balanceId: String {
    contractAddress.lowercased() + chainId + symbol + tokenId
  }
  
  @available(*, unavailable)
  public init() {
    fatalError("No Such Initializer: init()")
  }
  
  @available(*, unavailable)
  public init(context: NSManagedObjectContext) {
    fatalError("No Such Initializer: init(context:)")
  }
  
  @objc
  private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
    super.init(entity: entity, insertInto: context)
  }
  
  public init(context: NSManagedObjectContext, asset: BraveWallet.BlockchainToken, balance: String, account: String) {
    let entity = Self.entity(context)
    super.init(entity: entity, insertInto: context)
    self.contractAddress = asset.contractAddress
    self.chainId = asset.chainId
    self.symbol = asset.symbol
    self.tokenId = asset.tokenId
    self.balance = balance
    self.accountAddress = account
  }
  
  /// - Parameters:
  ///     - asset: An optional value of `BraveWallet.BlockchainToken`, nil value will remove the restriction of asset matching
  ///     - account: An optional value of `String`. It is the account's address value. nil value will remove the restriction of account address matching
  ///     - context: An optional value of `NSManagedObjectContext`
  ///
  /// - Returns: An optional of list of `WalletUserAssetBalance` that matches given parameters.
  public static func getBalance(
    for asset: BraveWallet.BlockchainToken? = nil,
    account: String? = nil,
    context: NSManagedObjectContext? = nil
  ) -> [WalletUserAssetBalance]? {
    if asset == nil, account == nil { // all `WalletAssetBalnce` with no restriction on assets or accounts
      return WalletUserAssetBalance.all()
    } else if let asset, account == nil {
      return WalletUserAssetBalance.all(
        where: NSPredicate(format: "contractAddress == %@ && chainId == %@ && symbol == %@ && tokenId == %@", asset.contractAddress, asset.chainId, asset.symbol, asset.tokenId),
        context: context ?? DataController.viewContext
      )
    } else if asset == nil, let account {
      return WalletUserAssetBalance.all(
        where: NSPredicate(format: "accountAddress == %@", account),
        context: context ?? DataController.viewContext
      )
    } else if let asset, let account {
      return WalletUserAssetBalance.all(
        where: NSPredicate(format: "contractAddress == %@ && chainId == %@ && symbol == %@ && tokenId == %@ && accountAddress == %@", asset.contractAddress, asset.chainId, asset.symbol, asset.tokenId, account),
        context: context ?? DataController.viewContext
      )
    }
    return nil
  }
  
  public static func updateBalance(
    for asset: BraveWallet.BlockchainToken,
    balance: String,
    account: String,
    completion: (() -> Void)? = nil
  ) {
    DataController.perform(context: .new(inMemory: false), save: false) { context in
      if let asset = WalletUserAssetBalance.first(where: NSPredicate(format: "contractAddress == %@ && chainId == %@ && symbol == %@ && tokenId == %@ && accountAddress == %@", asset.contractAddress, asset.chainId, asset.symbol, asset.tokenId, account), context: context) {
        asset.balance = balance
      } else {
        _ = WalletUserAssetBalance(context: context, asset: asset, balance: balance, account: account)
      }
      
      WalletUserAssetBalance.saveContext(context)
      
      DispatchQueue.main.async {
        completion?()
      }
    }
  }
  
  public static func removeBalance(
    for asset: BraveWallet.BlockchainToken,
    account: String? = nil,
    completion: (() -> Void)? = nil
  ) {
    let predict: NSPredicate
    if let accountAddress = account {
      predict = NSPredicate(format: "contractAddress == %@ && chainId == %@ && symbol == %@ && tokenId == %@ && accountAddress == %@", asset.contractAddress, asset.chainId, asset.symbol, asset.tokenId, accountAddress)
    } else {
      predict = NSPredicate(format: "contractAddress == %@ && chainId == %@ && symbol == %@ && tokenId == %@", asset.contractAddress, asset.chainId, asset.symbol, asset.tokenId)
    }
    WalletUserAssetBalance.deleteAll(
      predicate: predict,
      completion: completion
    )
  }
}

extension WalletUserAssetBalance {
  private static func entity(_ context: NSManagedObjectContext) -> NSEntityDescription {
    NSEntityDescription.entity(forEntityName: "WalletUserAssetBalance", in: context)!
  }
  
  private static func saveContext(_ context: NSManagedObjectContext) {
    if context.concurrencyType == .mainQueueConcurrencyType {
      Logger.module.warning("Writing to view context, this should be avoided.")
    }
    
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        assertionFailure("Error saving DB: \(error.localizedDescription)")
      }
    }
  }
}
