// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import CoreData
import Shared
import os.log

public final class WalletVisibleAssetGroup: NSManagedObject, CRUD {
  @NSManaged public var groupId: String
  @NSManaged public var visibleAssets: Set<WalletVisibleAsset>?
  
  public static func addGroup(_ groupId: String, completion: ((_ group: NSManagedObjectID) -> Void)? = nil) {
    DataController.perform(context: .new(inMemory: false)) { context in
      let group = WalletVisibleAssetGroup(context: context)
      group.groupId = groupId
      
      let groupObjectId = group.objectID
      DispatchQueue.main.async {
        completion?(groupObjectId)
      }
    }
  }
  
  public static func getGroup(groupId: String, context: NSManagedObjectContext? = nil) -> WalletVisibleAssetGroup? {
    WalletVisibleAssetGroup.first(where: NSPredicate(format: "groupId == %@", groupId), context: context ?? DataController.viewContext)
  }
  
  public static func getAllGroups(context: NSManagedObjectContext? = nil) -> [WalletVisibleAssetGroup]? {
    WalletVisibleAssetGroup.all(context: context ?? DataController.viewContext)
  }
  
  public static func removeGroup(_ groupId: String, completion: (() -> Void)? = nil) {
    WalletVisibleAssetGroup.deleteAll(
      predicate: NSPredicate(format: "groupId == %@", groupId),
      includesPropertyValues: false,
      completion: completion
    )
  }
  
  public static func removeAllGroup(completion: (() -> Void)? = nil) {
    WalletVisibleAssetGroup.deleteAll(
      includesPropertyValues: false,
      completion: completion
    )
  }
}

extension WalletVisibleAssetGroup {
  private static func entity(_ context: NSManagedObjectContext) -> NSEntityDescription {
    NSEntityDescription.entity(forEntityName: "WalletVisibleAssetGroup", in: context)!
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
