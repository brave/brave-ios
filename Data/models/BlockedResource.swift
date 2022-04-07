// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreData
import Shared

private let log = Logger.browserLogger

public enum BlockedResourceType: Int32 {
  case ad = 0
  case tracker = 1
}

public final class BlockedResource: NSManagedObject, CRUD {
  @NSManaged public var consolidationCount: Int32
  @NSManaged public var domain: String
  @NSManaged public var faviconUrl: String
  @NSManaged public var host: String
  @NSManaged public var timestamp: Date

  public enum Source {
    case shields
    case vpn
    case both
  }

  private static let entityName = "BlockedResource"
  private static let hostKeyPath = #keyPath(BlockedResource.host)
  private static let domainKeyPath = #keyPath(BlockedResource.domain)
  private static let timestampKeyPath = #keyPath(BlockedResource.timestamp)

  public static func batchInsert(items: [(host: String, domain: URL, date: Date)]) {

    DataController.perform { context in
      guard let entity = entity(in: context) else {
        log.error("Error fetching the entity 'BlockedResource' from Managed Object-Model")
        return
      }

      items.forEach {
        guard let baseDomain = $0.domain.baseDomain else {
          return
        }

        let blockedResource = BlockedResource(entity: entity, insertInto: context)
        blockedResource.host = $0.host
        blockedResource.domain = baseDomain
        blockedResource.faviconUrl = $0.domain.domainURL.absoluteString
        blockedResource.timestamp = $0.date
      }
    }
  }

  public static func mostBlockedTracker(inLastDays days: Int?) -> (String, Int)? {

    var mostFrequentTracker = ("", 0)

    do {
      let results = try groupByFetch(property: hostKeyPath, daysRange: days)

      for result in results {
        guard let host = result[hostKeyPath] as? String else {
          continue
        }

        let result = try distinctValues(property: hostKeyPath, propertyToFetch: domainKeyPath, value: host, daysRange: days).count

        if result > mostFrequentTracker.1 {
          mostFrequentTracker = (host, result)
        }
      }

      return mostFrequentTracker.1 > 0 ? mostFrequentTracker : nil
    } catch {
      log.error(error)
      return nil
    }
  }

  public static func allTimeMostFrequentTrackers() -> Set<CountableEntity> {
    var maxNumberOfSites = Set<CountableEntity>()

    do {
      let results = try groupByFetch(property: hostKeyPath, daysRange: nil)

      for result in results {
        guard let host = result[hostKeyPath] as? String else {
          continue
        }

        let shieldsCount = try distinctValues(property: hostKeyPath, propertyToFetch: domainKeyPath, value: host, daysRange: nil).count

        maxNumberOfSites.insert(.init(name: host, count: shieldsCount))
      }

      return maxNumberOfSites
    } catch {
      log.error(error)
      return maxNumberOfSites
    }
  }

  public static func riskiestWebsite(inLastDays days: Int?) -> (String, Int)? {
    var maxNumberOfSites = ("", 0)

    do {
      let results = try groupByFetch(property: domainKeyPath, daysRange: days)

      for result in results {
        guard let domain = result[domainKeyPath] as? String else {
          continue
        }

        let result = try distinctValues(property: domainKeyPath, propertyToFetch: hostKeyPath, value: domain, daysRange: nil).count

        if result > maxNumberOfSites.1 {
          maxNumberOfSites = (domain, result)
        }
      }

      return maxNumberOfSites.1 > 0 ? maxNumberOfSites : nil
    } catch {
      log.error(error)
      return nil
    }
  }

  public static func allTimeMostRiskyWebsites() -> [(domain: String, faviconUrl: String, count: Int)] {
    var maxNumberOfSites = [(domain: String, faviconUrl: String, count: Int)]()

    do {
      let fetchRequest = NSFetchRequest<NSDictionary>(entityName: entityName)
      let context = DataController.viewContext
      fetchRequest.entity = BlockedResource.entity(in: context)

      let expression = NSExpressionDescription()
      expression.name = "favicon"
      expression.expression = .init(forFunction: "lowercase:", arguments: [NSExpression(forKeyPath: "faviconUrl")])
      expression.expressionResultType = .stringAttributeType

      fetchRequest.propertiesToFetch = ["domain", expression]
      fetchRequest.propertiesToGroupBy = ["domain"]
      fetchRequest.resultType = .dictionaryResultType

      let results = try context.fetch(fetchRequest)

      for result in results {
        guard let domain = result[domainKeyPath] as? String, let favicon = result["favicon"] as? String else {
          continue
        }

        let result = try distinctValues(property: domainKeyPath, propertyToFetch: hostKeyPath, value: domain, daysRange: nil).count

        maxNumberOfSites.append((domain, favicon, result))
      }

      return maxNumberOfSites.sorted(by: { $0.count > $1.count })
    } catch {
      log.error(error)
      return []
    }
  }

  /// A helper method for to group up elements and then count them.
  /// Note: This query skips single elements(< 1)
  private static func groupByFetch(property: String, daysRange days: Int?) throws -> [NSDictionary] {
    let fetchRequest = NSFetchRequest<NSDictionary>(entityName: entityName)
    let context = DataController.viewContext
    fetchRequest.entity = BlockedResource.entity(in: context)

    let expression = NSExpressionDescription()
    expression.name = "group_by_count"
    expression.expression = .init(forFunction: "count:", arguments: [NSExpression(forKeyPath: property)])
    expression.expressionResultType = .integer32AttributeType

    // This expression is required. Otherwise we can not pass this custom expression to the NSPredicate.
    let countVariableExpr = NSExpression(forVariable: "group_by_count")

    fetchRequest.propertiesToFetch = [property, expression]
    fetchRequest.propertiesToGroupBy = [property]
    fetchRequest.resultType = .dictionaryResultType

    if let days = days {
      fetchRequest.havingPredicate =
        NSPredicate(format: "\(timestampKeyPath) >= %@ AND %@ > 1", getDate(-days) as CVarArg, countVariableExpr)
    } else {
      fetchRequest.havingPredicate = NSPredicate(format: "%@ > 1", countVariableExpr)
    }

    let results = try context.fetch(fetchRequest)
    return results
  }
  
  public static func clearData() {
    deleteAll()
  }

  /// Helper method which returns unique values for a given query.
  /// - Parameters:
  ///     - property: What property do we query for.
  ///     - propertyToFetch: What property we do want to fetch from our model.
  ///     - value: Value of property we query for.
  ///     - daysRange: If not nil it constraits returned results, retrieves results no older than this param. If nil, we check for all entries.
  private static func distinctValues(
    property: String,
    propertyToFetch: String,
    value: String,
    daysRange days: Int?
  ) throws -> [NSFetchRequestResult] {
    var predicate: NSPredicate?
    if let days = days {
      predicate = NSPredicate(
        format: "\(timestampKeyPath) >= %@ AND \(property) == %@", getDate(-days) as CVarArg, value)
    } else {
      predicate = NSPredicate(format: "\(property) == %@", value)
    }

    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
    let context = DataController.viewContext
    fetchRequest.entity = BlockedResource.entity(in: context)

    fetchRequest.propertiesToFetch = [propertyToFetch]
    fetchRequest.resultType = .dictionaryResultType
    fetchRequest.returnsDistinctResults = true
    fetchRequest.predicate = predicate

    // Dev note: Unfortunately context.count() can't be used here.
    // It ignores `returnDistinctResults` property.
    let result = try context.fetch(fetchRequest)
    return result
  }

  private class func entity(in context: NSManagedObjectContext) -> NSEntityDescription? {
    NSEntityDescription.entity(forEntityName: entityName, in: context)
  }
}
