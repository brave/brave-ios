// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreData
import Shared

private let log = Logger.browserLogger

public final class BraveVPNAlert: NSManagedObject, CRUD, Identifiable {
    
    @NSManaged public var action: Int32
    @NSManaged public var category: Int32
    @NSManaged public var count: Int32
    @NSManaged public var host: String
    @NSManaged public var message: String
    @NSManaged public var title: String
    @NSManaged public var uuid: String
    @NSManaged public var timestamp: Int64
    
    public var categoryEnum: VPNAlertJSONModel.Category? {
        return .init(rawValue: Int(category))
    }
    
    public var id: String {
        uuid
    }
    
    public static func batchCreate(alerts: [VPNAlertJSONModel]) {
        DataController.perform { context in
            guard let entity = entity(in: context) else {
                log.error("Error fetching the entity 'BlockedResource' from Managed Object-Model")
                
                return
            }
            
            alerts.forEach {
                let vpnAlert = BraveVPNAlert(entity: entity, insertInto: context)
                vpnAlert.action = Int32($0.action.rawValue)
                vpnAlert.category = Int32($0.category.rawValue)
                vpnAlert.count = 1 // FIXME: Handle consolidation.
                vpnAlert.host = $0.host
                vpnAlert.message = $0.message
                vpnAlert.title = $0.title
                vpnAlert.uuid = $0.uuid
                vpnAlert.timestamp = $0.timestamp
            }
        }
    }
    
    public static func trackerCounts() -> Set<CountableEntity> {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "BraveVPNAlert")
        let context = DataController.viewContext
        fetchRequest.entity = BraveVPNAlert.entity(in: context)
        
        let expression = NSExpressionDescription()
        expression.name = "group_by_count"
        expression.expression = .init(forFunction: "count:", arguments: [NSExpression(forKeyPath: "host")])
        expression.expressionResultType = .integer32AttributeType
        
        fetchRequest.propertiesToFetch = ["host", expression]
        fetchRequest.propertiesToGroupBy = ["host"]
        fetchRequest.resultType = .dictionaryResultType
        
        let results = try? context.fetch(fetchRequest)
        
        var ar = Set<CountableEntity>()
        
        for result in results ?? [] {
            guard let host = result["host"] as? String, let count = result["group_by_count"] as? Int else {
                continue
            }
            
            ar.insert(.init(name: host, count: count))
        }
        
        return ar
    }
    
    public static func last(_ count: Int) -> [BraveVPNAlert]? {
        let dateSort = NSSortDescriptor(keyPath: \BraveVPNAlert.timestamp, ascending: false)
        
        return all(sortDescriptors: [dateSort], fetchLimit: count)
    }
    
    public static func count(for host: String) -> Int {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "BraveVPNAlert")
        let context = DataController.viewContext
        fetchRequest.entity = BraveVPNAlert.entity(in: context)
        fetchRequest.predicate = .init(format: "host == %@", host)
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            log.error("countForHost failed: \(error)")
            return 0
        }
    }
    
    public static func totalAlertCounts() -> (trackerCount: Int, locationPingCount: Int, emailTrackerCount: Int) {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "BraveVPNAlert")
        let context = DataController.viewContext
        fetchRequest.entity = BraveVPNAlert.entity(in: context)
        
        do {
            fetchRequest.predicate = .init(format: "category == %d",
                                           VPNAlertJSONModel.Category.privacyTrackerApp.rawValue)
            let trackerCount = try context.count(for: fetchRequest)
            
            fetchRequest.predicate = .init(format: "category == %d",
                                           VPNAlertJSONModel.Category.privacyTrackerAppLocation.rawValue)
            let locationPingCount = try context.count(for: fetchRequest)
            
            fetchRequest.predicate = .init(format: "category == %d",
                                           VPNAlertJSONModel.Category.privacyTrackerMail.rawValue)
            let emailTrackerCount = try context.count(for: fetchRequest)
            
            return (trackerCount, locationPingCount, emailTrackerCount)
        } catch {
            return (0, 0, 0)
        }
    }
    
    private class func entity(in context: NSManagedObjectContext) -> NSEntityDescription? {
        NSEntityDescription.entity(forEntityName: "BraveVPNAlert", in: context)
    }
}
