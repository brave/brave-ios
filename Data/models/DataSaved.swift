// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreData

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
        let context = DataController.viewContext
        
        if let item = get(with: savedUrl) {
            item.delete(context: .existing(context))
            if context.hasChanges {
                try? context.save()
            }
        }
    }
    
    public class func insert(savedUrl: String, amount: String) {
        let context = DataController.viewContext
        
        guard let entity =  NSEntityDescription.entity(forEntityName: "DataSaved", in: context) else {
            return
        }
        
        let source = DataSaved(entity: entity, insertInto: context)
        source.savedUrl = savedUrl
        source.amount = amount
        
        if context.hasChanges {
            try? context.save()
        }
    }
    
    private class func entity(in context: NSManagedObjectContext) -> NSEntityDescription? {
        NSEntityDescription.entity(forEntityName: "DataSaved", in: context)
    }
}
