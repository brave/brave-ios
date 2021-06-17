// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreData
import Shared

private let log = Logger.browserLogger

public final class DataSaved: NSManagedObject, CRUD {
    @NSManaged public var savedUrl: String
    @NSManaged public var amount: String
    
    public class func get(with savedUrl: String) -> DataSaved? {
        let predicate = NSPredicate(format: "\(#keyPath(DataSaved.savedUrl)) == %@", savedUrl)
        return first(where: predicate)
    }
    
    public class func all() -> [DataSaved] {
        all() ?? []
    }
    
    public class func delete(with savedUrl: String) {
        if let item = get(with: savedUrl) {
            DataController.perform { context in
                item.delete(context: .existing(context))
                
                if context.hasChanges {
                    try? context.save()
                }
            }
        }
    }
    
    public class func insert(savedUrl: String, amount: String) {
        let context = DataController.viewContext
        
        guard let entity =  NSEntityDescription.entity(forEntityName: "DataSaved", in: context) else {
            log.error("Error fetching the entity 'DataSaved' from Managed Object-Model")

            return
        }
        
        DataController.perform { context in
            let source = DataSaved(entity: entity, insertInto: context)
            source.savedUrl = savedUrl
            source.amount = amount
            
            if context.hasChanges {
                do {
                    assert(Thread.isMainThread)
                    try context.save()
                } catch {
                    log.error("Perform Task Save error for 'DataSaved': \(error)")
                }
            }
        }
    }
    
    private class func entity(in context: NSManagedObjectContext) -> NSEntityDescription? {
        NSEntityDescription.entity(forEntityName: "DataSaved", in: context)
    }
}
