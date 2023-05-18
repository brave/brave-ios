// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import CoreData
import Shared
import BraveCore
import os.log

public final class WalletVisibleAsset: NSManagedObject, CRUD {
  @NSManaged public var contractAddress: String
  @NSManaged public var name: String
  @NSManaged public var logo: String
  @NSManaged public var isERC20: Bool
  @NSManaged public var isERC721: Bool
  @NSManaged public var isERC1155: Bool
  @NSManaged public var isNFT: Bool
  @NSManaged public var symbol: String
  @NSManaged public var decimals: Int32
  @NSManaged public var visible: Bool
  @NSManaged public var tokenId: String
  @NSManaged public var coingeckoId: String
  @NSManaged public var chainId: String
  @NSManaged public var coin: Int16
  @NSManaged public var visibleAssetGroup: WalletVisibleAssetGroup?
  
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
  
  public init(context: NSManagedObjectContext, asset: BraveWallet.BlockchainToken) {
    let entity = Self.entity(context)
    super.init(entity: entity, insertInto: context)
    self.contractAddress = asset.contractAddress
    self.name = asset.name
    self.logo = asset.logo
    self.isERC20 = asset.isErc20
    self.isERC721 = asset.isErc721
    self.isERC1155 = asset.isErc1155
    self.isNFT = asset.isNft
    self.symbol = asset.symbol
    self.decimals = asset.decimals
    self.visible = asset.visible
    self.tokenId = asset.tokenId
    self.coingeckoId = asset.coingeckoId
    self.coin = Int16(asset.coin.rawValue)
  }
  
//  public static func addVisibleAsset(_ asset: BraveWallet.BlockchainToken, completion: (() -> Void)? = nil) {
//    DataController.perform(context: .new(inMemory: false), save: false) { context in
//      let walletVisibleAsset = WalletVisibleAsset(context: context, asset: asset)
////      walletVisibleAsset.visibleAssetGroup = WalletVisibleAssetGroup.getVisibleAssetGroup(groupId: "\(asset.coin).\(asset.chainId)")
//      WalletVisibleAsset.saveContext(context)
//      
//      DispatchQueue.main.async {
//        completion?()
//      }
//    }
//  }
  
  public static func migrateVisibleAssets(_ assets: [String: [BraveWallet.BlockchainToken]], completion: (() -> Void)? = nil) {
    for groupId in assets.keys {
      guard let assetsInOneGroup = assets[groupId] else { return }
      WalletVisibleAssetGroup.addGroup(groupId) { group in
        DataController.perform(context: .existing(DataController.viewContext), save: false) { context in
          context.perform {
            for asset in assetsInOneGroup {
              let visibleAsset = WalletVisibleAsset(context: context, asset: asset)
              visibleAsset.visibleAssetGroup = group
            }
            WalletVisibleAsset.saveContext(context)
            
            DispatchQueue.main.async {
              completion?()
            }
          }
        }
      }
    }
  }
  
  private static func entity(_ context: NSManagedObjectContext) -> NSEntityDescription {
    NSEntityDescription.entity(forEntityName: "WalletVisibleAsset", in: context)!
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
