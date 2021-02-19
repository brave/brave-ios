// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreData

public final class RSSFeedSource: NSManagedObject, CRUD {
    @NSManaged public var title: String?
    @NSManaged public var feedUrl: String
    
    public class func get(with feedUrl: String) -> RSSFeedSource? {
        getInternal(with: feedUrl)
    }
    
    public class func all() -> [RSSFeedSource] {
        all() ?? []
    }
    
    public class func delete(with feedUrl: String) {
        deleteInternal(feedUrl: feedUrl, context: .existing(DataController.viewContext))
    }
    
    public class func insert(title: String?, feedUrl: String) {
        insertInternal(title: title, feedUrl: feedUrl, context: .existing(DataController.viewContext))
    }
    
    class func getInternal(with feedUrl: String, context: NSManagedObjectContext = DataController.viewContext) -> RSSFeedSource? {
        let predicate = NSPredicate(format: "\(#keyPath(RSSFeedSource.feedUrl)) == %@", feedUrl)
        return first(where: predicate, context: context)
    }
    
    class func insertInternal(title: String?, feedUrl: String, context: WriteContext = .new(inMemory: false)) {
        DataController.perform(context: context) { context in
            let source = RSSFeedSource(entity: entity(in: context), insertInto: context)
            
            source.title = title
            source.feedUrl = feedUrl
        }
    }
    
    class func deleteInternal(feedUrl: String, context: WriteContext = .new(inMemory: false)) {
        if let item = getInternal(with: feedUrl, context: DataController.viewContext) {
            item.delete(context: context)
        }
    }
    
    private class func entity(in context: NSManagedObjectContext) -> NSEntityDescription {
        NSEntityDescription.entity(forEntityName: "RSSFeedSource", in: context)!
    }
}
