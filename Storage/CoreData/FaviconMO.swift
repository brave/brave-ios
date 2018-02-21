/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import CoreData

public class FaviconMO: NSManagedObject {
    
    @NSManaged public var url: String?
    @NSManaged public var width: Int16
    @NSManaged public var height: Int16
    @NSManaged public var type: Int16
    @NSManaged public var domain: DomainMO?

    // Necessary override due to bad classname, maybe not needed depending on future CD
    public static func entity(_ context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: "Favicon", in: context)!
    }

    public class func get(forFaviconUrl urlString: String, context: NSManagedObjectContext) -> FaviconMO? {
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

    public class func add(_ favicon: Favicon, forSiteUrl siteUrl: URL) {
        let context = DataManager.shared.workerContext
        context.perform {
            var item = FaviconMO.get(forFaviconUrl: favicon.url, context: context)
            if item == nil {
                item = FaviconMO(entity: FaviconMO.entity(context), insertInto: context)
                item!.url = favicon.url
            }
            if item?.domain == nil {
                item!.domain = DomainMO.getOrCreateForUrl(siteUrl, context: context)
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

            DataManager.saveContext(context: context)
        }
    }
}
