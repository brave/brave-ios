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
    @NSManaged public var host: String
    @NSManaged public var resourceType: Int32
    @NSManaged public var timestamp: Date
    
    static let thisWeek = getDate(-7)
    
    public static func create(host: String, domain: String, resourceType: BlockedResourceType, timestamp: Date = Date()) {
        DataController.perform { context in
            guard let entity = entity(in: context) else {
                log.error("Error fetching the entity 'BlockedResource' from Managed Object-Model")

                return
            }
            
            let blockedResource = BlockedResource(entity: entity, insertInto: context)
            blockedResource.host = host
            blockedResource.domain = domain
            blockedResource.resourceType = resourceType.rawValue
            blockedResource.timestamp = timestamp
        }
    }
    
    private static func countExpression(for name: String) -> NSExpressionDescription {
        let expression = NSExpressionDescription()
        let nameExpr = NSExpression(forKeyPath: name)

        expression.name = "count" + name
        expression.expression = NSExpression(forFunction: "count:", arguments: [nameExpr])
        expression.expressionResultType = .integer32AttributeType
        
        return expression
    }
    
    public static func mostBlockedTracker(inLastDays days: Int) -> (String, Int)? {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "BlockedResource")
        let context = DataController.viewContext
        fetchRequest.entity = BlockedResource.entity(in: context)
        
        let hostKeypath = #keyPath(BlockedResource.host)
        
        let expression = NSExpressionDescription()

        expression.name = "host_count"
        expression.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "host")])
        expression.expressionResultType = .integer32AttributeType
        
        fetchRequest.propertiesToFetch = [hostKeypath, expression]
        fetchRequest.propertiesToGroupBy = [hostKeypath]
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.returnsDistinctResults = true
        fetchRequest.fetchLimit = 1
        
        fetchRequest.predicate = NSPredicate(format: "timestamp >= %@", getDate(-days) as CVarArg)
        
        fetchRequest.sortDescriptors = [.init(key: "host_count", ascending: false)]
        
        do {
            let result = try context.fetch(fetchRequest)
            
            guard let host = result.first?["host"] as? String, let count = result.first?["host_count"] as? Int else {
                return nil
            }
            
            return (host, count)
        } catch {
            log.error(error)
            return nil
            
        }
    }
    
    public static func allBlockedResources() -> [String: Int] {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "BlockedResource")
        let context = DataController.viewContext
        fetchRequest.entity = BlockedResource.entity(in: context)
        
        let hostKeypath = #keyPath(BlockedResource.host)
        
        let count = countExpression(for: "host")
        
        fetchRequest.propertiesToFetch = [hostKeypath, count]
        fetchRequest.propertiesToGroupBy = [hostKeypath]
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.returnsDistinctResults = true
        
        do {
            let result = try context.fetch(fetchRequest)
            var flatResults: [String: Int] = [:]
            
            for r in result {
                guard let host = r["host"] as? String, let count = r["count"] as? Int else { continue }
                
                flatResults[host] = count // TODO: Multiply by consolidation count
            }
            
            return flatResults
        } catch {
            log.error(error)
            return [:]
        }
    }
    
    private class func entity(in context: NSManagedObjectContext) -> NSEntityDescription? {
        NSEntityDescription.entity(forEntityName: "BlockedResource", in: context)
    }
}
