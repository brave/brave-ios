/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import CoreData
import Foundation
import Storage

class FaviconMO: NSManagedObject {
    
    @NSManaged var url: String?
    @NSManaged var width: Int16
    @NSManaged var height: Int16
    @NSManaged var type: Int16
    @NSManaged var domain: Domain?

    // Necessary override due to bad classname, maybe not needed depending on future CD
    static func entity(_ context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: "Favicon", in: context)!
    }

    class func get(forFaviconUrl urlString: String, context: NSManagedObjectContext) -> FaviconMO? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = FaviconMO.entity(context)
        fetchRequest.predicate = NSPredicate(format: "url == %@", urlString)
        var result: FaviconMO? = nil
        do {
            let results = try context.fetch(fetchRequest) as? [FaviconMO]
            if let item = results?.first {
                result = item
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return result
    }

    class func add(_ favicon: Favicon, forSiteUrl siteUrl: URL) {
        let context = DataController.shared.workerContext
        context.perform {
            var item = FaviconMO.get(forFaviconUrl: favicon.url, context: context)
            if item == nil {
                item = FaviconMO(entity: FaviconMO.entity(context), insertInto: context)
                item!.url = favicon.url
            }
            if item?.domain == nil {
                item!.domain = Domain.getOrCreateForUrl(siteUrl, context: context)
            }

            let w = Int16(favicon.width ?? 0)
            let h = Int16(favicon.height ?? 0)
            let t = Int16(favicon.type.rawValue)

            if w != item!.width && w > 0 {
                item!.width = w
            }

            if h != item!.height && h > 0 {
                item!.height = h
            }

            if t != item!.type {
                item!.type = t
            }

            DataController.saveContext(context: context)
        }
    }
}
