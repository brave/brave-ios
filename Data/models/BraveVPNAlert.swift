// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreData
import Shared

private let log = Logger.browserLogger

public final class BraveVPNAlert: NSManagedObject, CRUD {
    enum Action: Int {
        case drop
        case detected
    }
    
    public enum Category: Int {
        case securityPhishing
        case privacyTrackerAppLocation
        case privacyTrackerApp
        case encryptionAllowInvalidHttps
        case adsAggresive
    }
    
    @NSManaged public var action: Int32
    @NSManaged public var category: Int32
    @NSManaged public var count: Int32
    @NSManaged public var host: String
    @NSManaged public var message: String
    @NSManaged public var title: String
    @NSManaged public var uuid: String
    @NSManaged public var timestamp: Date
    
    public static func create() {
        DataController.perform { context in
            guard let entity = entity(in: context) else {
                log.error("Error fetching the entity 'BlockedResource' from Managed Object-Model")

                return
            }
            
//            let blockedResource = BlockedResource(entity: entity, insertInto: context)
//            blockedResource.url = url.absoluteString
//            blockedResource.domain = domain.absoluteString
//            blockedResource.resourceType = resourceType.rawValue
//            blockedResource.timestamp = timestamp
        }
    }
    
    private class func entity(in context: NSManagedObjectContext) -> NSEntityDescription? {
        NSEntityDescription.entity(forEntityName: "BraveVPNAlert", in: context)
    }
}
