// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreData
import Shared

private let log = Logger.browserLogger

/// Stores the alerts data we receive from Brave VPN.
/// The alert is a resource blocked by the VPN service
public final class BraveVPNAlert: NSManagedObject, CRUD, Identifiable {

  /// Currently unused. This is persisted in case we need it in the future.
  public enum Action: Int {
    case drop
    case log
  }

  public enum TrackerType: Int {
    /// A request asking for users location
    case location
    /// A regular tracker
    case app
    /// An email tracker
    case mail
  }

  /// Currently unused. This is persisted in case we need it in the future.
  @NSManaged public var action: Int32
  /// What type of tracker was blocked.
  @NSManaged public var category: Int32
  /// Base domain of the blocked resource. A pair of `host` and `timestamp` must be unique(to prevent duplicates).
  @NSManaged public var host: String
  /// When a given resource was blocked. A pair of `host` and `timestamp` must be unique(to prevent duplicates).
  @NSManaged public var timestamp: Int64
  /// Message about the blocked resource. Note: this is not localized, always in English.
  @NSManaged public var message: String
  /// Currently unused. This is persisted in case we need it in the future.
  @NSManaged public var title: String
  /// Unique identifier of the blocked resource.
  @NSManaged public var uuid: String

  /// Category value is stored as a number in the database. This converts it and returns a proper `TrackerType` enum value for it.
  public var categoryEnum: TrackerType? {
    return .init(rawValue: Int(category))
  }

  public var id: String {
    // UUID is a unique constraint, this should be enough for identifying the alert.
    uuid
  }

  /// Inserts new VPN alerts to the database. VPN alerts that already exist are skipped.
  public static func batchInsertIfNotExists(alerts: [BraveVPNAlertJSONModel]) {
    DataController.perform { context in
      guard let entity = entity(in: context) else {
        log.error("Error fetching the entity 'BlockedResource' from Managed Object-Model")

        return
      }

      alerts.forEach {
        let vpnAlert = BraveVPNAlert(entity: entity, insertInto: context)

        // UUID is our first unique key
        vpnAlert.uuid = $0.uuid
        // Pair of host and timestamp are our second unique key.
        // This greatly reduces amount of alerts we save and removes many of duplicated entries.
        vpnAlert.host = $0.host
        vpnAlert.timestamp = $0.timestamp

        vpnAlert.category = Int32($0.category.rawValue)
        vpnAlert.message = $0.message

        // Title and action are currently not used
        vpnAlert.title = $0.title
        vpnAlert.action = Int32($0.action.rawValue)
      }
    }
  }

  /// Returns a list of blocked trackers and how many of them were blocked.
  /// Note: Unlike `BlockedRequest` we do not know what app/website contained a certain tracker.
  /// Sometimes multiple trackers from the same host are recorded.
  /// For `BlockedRequest` items we count trackers from a single domain only once.
  public static var allByHostCount: Set<CountableEntity> {
    let context = DataController.viewContext
    let fetchRequest = braveVPNAlertFetchRequest(for: context)

    let expression = NSExpressionDescription()
    expression.name = "group_by_count"
    expression.expression = .init(forFunction: "count:", arguments: [NSExpression(forKeyPath: "host")])
    expression.expressionResultType = .integer32AttributeType

    fetchRequest.propertiesToFetch = ["host", expression]
    fetchRequest.propertiesToGroupBy = ["host"]
    fetchRequest.resultType = .dictionaryResultType

    var hostsByCount = Set<CountableEntity>()

    do {
      let foundHosts = try context.fetch(fetchRequest)

      for hostWithCount in foundHosts {
        guard let host = hostWithCount["host"] as? String,
          let count = hostWithCount["group_by_count"] as? Int
        else {
          continue
        }

        hostsByCount.insert(.init(name: host, count: count))
      }

      return hostsByCount
    } catch {
      log.error("allByHostCount error: \(error)")
      return hostsByCount
    }
  }

  /// Returns the newest recorded alerts. `count` argument tells up to how many records to fetch.
  public static func last(_ count: Int) -> [BraveVPNAlert]? {
    let timestampSort = NSSortDescriptor(keyPath: \BraveVPNAlert.timestamp, ascending: false)

    return all(sortDescriptors: [timestampSort], fetchLimit: count)
  }

  /// Returns amount of alerts blocked for each type.
  public static var alertTotals: (trackerCount: Int, locationPingCount: Int, emailTrackerCount: Int) {
    let context = DataController.viewContext
    let fetchRequest = braveVPNAlertFetchRequest(for: context)

    do {
      fetchRequest.predicate = .init(
        format: "category == %d",
        BraveVPNAlert.TrackerType.app.rawValue)
      let trackerCount = try context.count(for: fetchRequest)

      fetchRequest.predicate = .init(
        format: "category == %d",
        BraveVPNAlert.TrackerType.location.rawValue)
      let locationPingCount = try context.count(for: fetchRequest)

      fetchRequest.predicate = .init(
        format: "category == %d",
        BraveVPNAlert.TrackerType.mail.rawValue)
      let emailTrackerCount = try context.count(for: fetchRequest)

      return (trackerCount, locationPingCount, emailTrackerCount)
    } catch {
      log.error("alertTotals error: \(error)")
      return (0, 0, 0)
    }
  }
  
  public static func clearData() {
    deleteAll()
  }

  private static func braveVPNAlertFetchRequest(for context: NSManagedObjectContext) -> NSFetchRequest<NSDictionary> {
    let _fetchRequest = NSFetchRequest<NSDictionary>(entityName: "BraveVPNAlert")
    _fetchRequest.entity = BraveVPNAlert.entity(in: context)
    return _fetchRequest
  }

  private class func entity(in context: NSManagedObjectContext) -> NSEntityDescription? {
    NSEntityDescription.entity(forEntityName: "BraveVPNAlert", in: context)
  }
}
