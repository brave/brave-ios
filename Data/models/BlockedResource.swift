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
    
    public static func mostBlockedTracker(inLastDays days: Int?) -> (String, Int)? {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "BlockedResource")
        let context = DataController.viewContext
        fetchRequest.entity = BlockedResource.entity(in: context)
        
        let hostKeypath = #keyPath(BlockedResource.host)
        
        let expression = NSExpressionDescription()

        expression.name = "hostcount"
        expression.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "host")])
        expression.expressionResultType = .integer32AttributeType
        
        let countVariableExpr = NSExpression(forVariable: "hostcount")

        fetchRequest.propertiesToFetch = [hostKeypath, expression]
        fetchRequest.propertiesToGroupBy = [hostKeypath]
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.returnsDistinctResults = true
        
        if let days = days {
            fetchRequest.havingPredicate =
            NSPredicate(format: "timestamp >= %@ AND %@ > 1", getDate(-days) as CVarArg, countVariableExpr)
        } else {
            fetchRequest.havingPredicate = NSPredicate(format: "%@ > 1", countVariableExpr)
        }
        
        var maxNumberOfSites = ("", 0)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            for result in results {
                guard let host = result["host"] as? String else {
                    continue
                }
                
                var predicate: NSPredicate?
                if let days = days {
                    predicate = NSPredicate(format: "timestamp >= %@ AND host == %@", getDate(-days) as CVarArg, host)
                } else {
                    predicate = NSPredicate(format: "host == %@", host)
                }
                
                let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "BlockedResource")
                let context = DataController.viewContext
                fr.entity = BlockedResource.entity(in: context)
                
                let domainKeyPath = #keyPath(BlockedResource.domain)

                fr.propertiesToFetch = [domainKeyPath]
                fr.resultType = .dictionaryResultType
                fr.returnsDistinctResults = true
                fr.predicate = predicate
                
                // Dev note: Unfortunately context.count() can't be used here.
                // It ignores `returnDistinctResults` property.
                let result = try context.fetch(fr).count
                
                if result > maxNumberOfSites.1 {
                    maxNumberOfSites = (host, result)
                }
            }
            
            return maxNumberOfSites.1 > 0 ? maxNumberOfSites : nil
        } catch {
            log.error(error)
            return nil
            
        }
    }
    
    public static func allTimeMostFrequentTrackers() -> [(String, Int)] {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "BlockedResource")
        let context = DataController.viewContext
        fetchRequest.entity = BlockedResource.entity(in: context)
        
        let hostKeypath = #keyPath(BlockedResource.host)
        
        let expression = NSExpressionDescription()

        expression.name = "hostcount"
        expression.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "host")])
        expression.expressionResultType = .integer32AttributeType
        
        let countVariableExpr = NSExpression(forVariable: "hostcount")

        fetchRequest.propertiesToFetch = [hostKeypath, expression]
        fetchRequest.propertiesToGroupBy = [hostKeypath]
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.returnsDistinctResults = true
        
        fetchRequest.havingPredicate = NSPredicate(format: "%@ > 1", countVariableExpr)
        
        var maxNumberOfSites = [(String, Int)]()
        
        do {
            let results = try context.fetch(fetchRequest)
            
            for result in results {
                guard let host = result["host"] as? String else {
                    continue
                }
                
                let predicate = NSPredicate(format: "host == %@", host)
                
                let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "BlockedResource")
                let context = DataController.viewContext
                fr.entity = BlockedResource.entity(in: context)
                
                let domainKeyPath = #keyPath(BlockedResource.domain)

                fr.propertiesToFetch = [domainKeyPath]
                fr.resultType = .dictionaryResultType
                fr.returnsDistinctResults = true
                fr.predicate = predicate
                
                // Dev note: Unfortunately context.count() can't be used here.
                // It ignores `returnDistinctResults` property.
                let result = try context.fetch(fr).count
                
                
                maxNumberOfSites.append((host, result))
            }
            
            return maxNumberOfSites.sorted(by: { $0.1 > $1.1 })
        } catch {
            log.error(error)
            return []
            
        }
    }
    
    public static func riskiestWebsite(inLastDays days: Int?) -> (String, Int)? {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "BlockedResource")
        let context = DataController.viewContext
        fetchRequest.entity = BlockedResource.entity(in: context)
        
        let domainKeyPath = #keyPath(BlockedResource.domain)
        
        let expression = NSExpressionDescription()

        expression.name = "domaincount"
        expression.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "domain")])
        expression.expressionResultType = .integer32AttributeType
        
        let countVariableExpr = NSExpression(forVariable: "domaincount")
        
        fetchRequest.propertiesToFetch = [domainKeyPath, expression]
        fetchRequest.propertiesToGroupBy = [domainKeyPath]
        fetchRequest.resultType = .dictionaryResultType
        
        if let days = days {
            fetchRequest.havingPredicate =
            NSPredicate(format: "timestamp >= %@ AND %@ > 1", getDate(-days) as CVarArg, countVariableExpr)
        } else {
            fetchRequest.havingPredicate = NSPredicate(format: "%@ > 1", countVariableExpr)
        }
        
        var maxNumberOfSites = ("", 0)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            for result in results {
                guard let domain = result["domain"] as? String else {
                    continue
                }
                
                var predicate: NSPredicate?
                if let days = days {
                    predicate = NSPredicate(format: "timestamp >= %@ and domain == %@", getDate(-days) as CVarArg, domain)
                } else {
                    predicate = NSPredicate(format: "domain == %@", domain)
                }
                
                let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "BlockedResource")
                let context = DataController.viewContext
                fr.entity = BlockedResource.entity(in: context)
                
                let hostKeyPath = #keyPath(BlockedResource.host)

                fr.propertiesToFetch = [hostKeyPath]
                fr.resultType = .dictionaryResultType
                fr.returnsDistinctResults = true
                fr.predicate = predicate
                
                // Dev note: Unfortunately context.count() can't be used here.
                // It ignores `returnDistinctResults` property.
                let fetch = try context.fetch(fr)
                let result = fetch.count
                
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
    
    public static func allTimeMostRiskyWebsites() -> [(String, Int)] {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "BlockedResource")
        let context = DataController.viewContext
        fetchRequest.entity = BlockedResource.entity(in: context)
        
        let domainKeyPath = #keyPath(BlockedResource.domain)
        
        let expression = NSExpressionDescription()

        expression.name = "domaincount"
        expression.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "domain")])
        expression.expressionResultType = .integer32AttributeType
        
        let countVariableExpr = NSExpression(forVariable: "domaincount")
        
        fetchRequest.propertiesToFetch = [domainKeyPath, expression]
        fetchRequest.propertiesToGroupBy = [domainKeyPath]
        fetchRequest.resultType = .dictionaryResultType
        
        fetchRequest.havingPredicate = NSPredicate(format: "%@ > 1", countVariableExpr)
        
        var maxNumberOfSites = [(String, Int)]()
        
        do {
            let results = try context.fetch(fetchRequest)
            
            for result in results {
                guard let domain = result["domain"] as? String else {
                    continue
                }
                
                let predicate = NSPredicate(format: "domain == %@", domain)
                
                let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "BlockedResource")
                let context = DataController.viewContext
                fr.entity = BlockedResource.entity(in: context)
                
                let hostKeyPath = #keyPath(BlockedResource.host)

                fr.propertiesToFetch = [hostKeyPath]
                fr.resultType = .dictionaryResultType
                fr.returnsDistinctResults = true
                fr.predicate = predicate
                
                // Dev note: Unfortunately context.count() can't be used here.
                // It ignores `returnDistinctResults` property.
                let fetch = try context.fetch(fr)
                let result = fetch.count
                
                maxNumberOfSites.append((domain, result))
            }
            
            return maxNumberOfSites.sorted(by: { $0.1 > $1.1 })
        } catch {
            log.error(error)
            return []
        }
    }
    
    private class func entity(in context: NSManagedObjectContext) -> NSEntityDescription? {
        NSEntityDescription.entity(forEntityName: "BlockedResource", in: context)
    }
}
