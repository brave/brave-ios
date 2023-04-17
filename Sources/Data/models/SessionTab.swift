// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import CoreData
import os.log

public final class SessionTab: NSManagedObject, CRUD {
  @NSManaged public var index: Int32
  @NSManaged public var interactionState: Data
  @NSManaged private(set) public var isPrivate: Bool
  @NSManaged private(set) public var isSelected: Bool
  @NSManaged public var lastUpdated: Date
  @NSManaged public var screenshotData: Data
  @NSManaged public var title: String
  @NSManaged public var url: URL
  @NSManaged private(set) public var tabId: UUID
  
  @NSManaged private(set) public var sessionTabGroup: SessionTabGroup?
  @NSManaged private(set) public var sessionWindow: SessionWindow
  
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
  
  public init(context: NSManagedObjectContext,
              sessionWindow: SessionWindow,
              sessionTabGroup: SessionTabGroup?,
              index: Int32,
              interactionState: Data,
              isPrivate: Bool,
              isSelected: Bool,
              lastUpdated: Date,
              screenshotData: Data,
              title: String,
              url: URL,
              tabId: UUID = UUID()) {
    guard let entity = Self.entity(context) else {
      fatalError("No such Entity: SessionTab")
    }
    
    if let sessionTabGroup = sessionTabGroup, sessionTabGroup.sessionWindow.windowId != sessionWindow.windowId {
      fatalError("Cannot add a tab to a different window and group. The group must belong to the same window as the tab")
    }
    
    super.init(entity: entity, insertInto: context)
    self.sessionWindow = sessionWindow
    self.sessionTabGroup = sessionTabGroup
    self.index = index
    self.interactionState = interactionState
    self.isPrivate = isPrivate
    self.isSelected = isSelected
    self.lastUpdated = lastUpdated
    self.screenshotData = screenshotData
    self.title = title
    self.url = url
    self.tabId = tabId
  }
}

// MARK: - Public

extension SessionTab {
  public var screenshot: UIImage? {
    get {
      return screenshotData.isEmpty ? nil : UIImage(data: screenshotData)
    }
    
    set {
      self.screenshotData = newValue?.jpegData(compressionQuality: 0.3) ?? Data()
    }
  }
  
  public static func exists(tabId: UUID) -> Bool {
    let predicate = NSPredicate(format: "\(#keyPath(SessionTab.tabId)) == %@", argumentArray: [tabId])
    return Self.count(predicate: predicate, context: DataController.viewContext) != 0
  }
  
  /// Returns the tab with the specificed tabId
  public static func from(tabId: UUID) -> SessionTab? {
    return Self.from(tabId: tabId, in: DataController.viewContext)
  }
  
  public static func all() -> [SessionTab] {
    let sortDescriptors = [NSSortDescriptor(key: #keyPath(SessionTab.index), ascending: true)]
    return all(sortDescriptors: sortDescriptors) ?? []
  }
  
  public static func all(noOlderThan timeInterval: TimeInterval) -> [SessionTab] {
    let lastUpdatedKeyPath = #keyPath(SessionTab.lastUpdated)
    let date = Date().advanced(by: -timeInterval) as NSDate
  
    let sortDescriptors = [NSSortDescriptor(key: #keyPath(SessionTab.index), ascending: true)]
    let predicate = NSPredicate(format: "\(lastUpdatedKeyPath) = nil OR \(lastUpdatedKeyPath) > %@", date)
    return all(where: predicate, sortDescriptors: sortDescriptors) ?? []
  }
  
  public func delete() {
    delete(context: .new(inMemory: false))
  }
  
  public static func deleteAll() {
    deleteAll(context: .new(inMemory: false))
  }
  
  public static func deleteAll(olderThan timeInterval: TimeInterval) {
    let lastUpdatedKeyPath = #keyPath(SessionTab.lastUpdated)
    let date = Date().advanced(by: -timeInterval) as NSDate
    let predicate = NSPredicate(format: "\(lastUpdatedKeyPath) != nil AND \(lastUpdatedKeyPath) < %@", date)
    self.deleteAll(predicate: predicate)
  }
  
  /// Marks the specified tab as selected
  /// Since only one tab can be active at a time, all other tabs are marked as deselected
  public static func setSelected(tabId: UUID) {
    DataController.perform { context in
      guard let tab = Self.from(tabId: tabId, in: context) else { return }

      let predicate = NSPredicate(format: "isSelected == true")
      all(where: predicate, context: context)?.forEach {
        $0.isSelected = false
      }

      tab.isSelected = true
    }
  }
  
  public static func touch(tabId: UUID) {
    DataController.perform { context in
      Self.from(tabId: tabId, in: context)?.lastUpdated = .now
    }
  }
  
  public static func update(tabId: UUID, interactionState: Data, title: String, url: URL) {
    DataController.perform { context in
      guard let sessionTab = Self.from(tabId: tabId, in: context) else { return }
      sessionTab.interactionState = interactionState
      sessionTab.title = title
      sessionTab.url = url
      sessionTab.lastUpdated = .now
    }
  }
  
  public static func updateScreenshot(tabId: UUID, screenshot: UIImage?) {
    DataController.perform { context in
      guard let sessionTab = Self.from(tabId: tabId, in: context) else { return }
      sessionTab.screenshot = screenshot
    }
  }
  
  public static func saveTabOrder(tabIds: [UUID]) {
    DataController.perform { context in
      for (index, tabId) in tabIds.enumerated() {
        guard let tab = Self.from(tabId: tabId, in: context) else {
          Logger.module.error("Error: SessionTab missing managed object")
          continue
        }
        tab.index = Int32(index)
      }
    }
  }
  
  public static func updateAll(tabs: [(tabId: UUID, interactionState: Data, title: String, url: URL)]) {
    DataController.performOnMainContext { context in
      for (index, tab) in tabs.enumerated() {
        guard let sessionTab = Self.from(tabId: tab.tabId, in: context) else { return }
        sessionTab.interactionState = tab.interactionState
        sessionTab.title = tab.title
        sessionTab.url = tab.url
        sessionTab.index = Int32(index)
      }
      
      do {
        try context.save()
      } catch {
        Logger.module.error("Error: SessionTabs not saved!")
      }
    }
  }
}

// MARK: - Private

extension SessionTab {
  private static func from(tabId: UUID, in context: NSManagedObjectContext) -> SessionTab? {
    let predicate = NSPredicate(format: "\(#keyPath(SessionTab.tabId)) == %@", argumentArray: [tabId])
    return first(where: predicate, context: context)
  }
  
  private static func entity(_ context: NSManagedObjectContext) -> NSEntityDescription? {
    return NSEntityDescription.entity(forEntityName: "SessionTab", in: context)
  }
}
