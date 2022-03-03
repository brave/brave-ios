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
    @NSManaged public var url: String
    @NSManaged public var resourceType: Int32
    @NSManaged public var timestamp: Date
    
    public static func create(url: URL, domain: URL, resourceType: BlockedResourceType, timestamp: Date = Date()) {
        DataController.perform { context in
            guard let entity = entity(in: context) else {
                log.error("Error fetching the entity 'BlockedResource' from Managed Object-Model")

                return
            }
            
            let blockedResource = BlockedResource(entity: entity, insertInto: context)
            blockedResource.url = url.absoluteString
            blockedResource.domain = domain.absoluteString
            blockedResource.resourceType = resourceType.rawValue
            blockedResource.timestamp = timestamp
        }
    }
    
    private class func entity(in context: NSManagedObjectContext) -> NSEntityDescription? {
        NSEntityDescription.entity(forEntityName: "BlockedResource", in: context)
    }
}
