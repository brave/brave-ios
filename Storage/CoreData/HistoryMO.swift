/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import CoreData
import Shared

private func getDate(_ dayOffset: Int) -> Date {
    let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    let nowComponents = calendar.dateComponents([Calendar.Component.year, Calendar.Component.month, Calendar.Component.day], from: Date())
    let today = calendar.date(from: nowComponents)!
    return (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: dayOffset, to: today, options: [])!
}

public class HistoryMO: NSManagedObject {

    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var visitedOn: Date?
    @NSManaged public var syncUUID: UUID?
    @NSManaged public var domain: DomainMO?
    @NSManaged public var sectionIdentifier: String?
    
    public static let Today = getDate(0)
    public static let Yesterday = getDate(-1)
    public static let ThisWeek = getDate(-7)
    public static let ThisMonth = getDate(-31)

    // Currently required, because not `syncable`
    public static func entity(_ context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: "History", in: context)!
    }

    public class func add(_ title: String, url: URL) {
        let context = DataManager.shared.workerContext
        context.perform {
            var item = HistoryMO.getExisting(url, context: context)
            if item == nil {
                item = HistoryMO(entity: HistoryMO.entity(context), insertInto: context)
                item!.domain = DomainMO.getOrCreateForUrl(url, context: context)
                item!.url = url.absoluteString
            }
            item?.title = title
            item?.domain?.visits += 1
            item?.visitedOn = Date()
            item?.sectionIdentifier = Strings.Today

            DataManager.saveContext(context: context)
        }
    }

    public class func frc() -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let context = DataManager.shared.mainThreadContext
        
        fetchRequest.entity = HistoryMO.entity(context)
        fetchRequest.fetchBatchSize = 20
        fetchRequest.fetchLimit = 200
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"visitedOn", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "visitedOn >= %@", HistoryMO.ThisMonth as CVarArg)

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:context, sectionNameKeyPath: "sectionIdentifier", cacheName: nil)
    }

    public override func awakeFromFetch() {
        if sectionIdentifier != nil {
            return
        }

        if visitedOn?.compare(HistoryMO.Today) == ComparisonResult.orderedDescending {
            sectionIdentifier = Strings.Today
        } else if visitedOn?.compare(HistoryMO.Yesterday) == ComparisonResult.orderedDescending {
            sectionIdentifier = Strings.Yesterday
        } else if visitedOn?.compare(HistoryMO.ThisWeek) == ComparisonResult.orderedDescending {
            sectionIdentifier = Strings.Last_week
        } else {
            sectionIdentifier = Strings.Last_month
        }
    }

    public class func getExisting(_ url: URL, context: NSManagedObjectContext) -> HistoryMO? {
        assert(!Thread.isMainThread)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = HistoryMO.entity(context)
        fetchRequest.predicate = NSPredicate(format: "url == %@", url.absoluteString)
        var result: HistoryMO? = nil
        do {
            let results = try context.fetch(fetchRequest) as? [HistoryMO]
            if let item = results?.first {
                result = item
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return result
    }

    public class func frecencyQuery(_ context: NSManagedObjectContext, containing:String? = nil) -> [HistoryMO] {
        assert(!Thread.isMainThread)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.fetchLimit = 100
        fetchRequest.entity = HistoryMO.entity(context)
        
        var predicate = NSPredicate(format: "visitedOn > %@", HistoryMO.ThisWeek as CVarArg)
        if let query = containing {
            predicate = NSPredicate(format: predicate.predicateFormat + " AND url CONTAINS %@", query)
        }
        
        fetchRequest.predicate = predicate

        do {
            if let results = try context.fetch(fetchRequest) as? [HistoryMO] {
                return results
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return []
    }
    
    public class func deleteAll(_ completionOnMain: @escaping ()->()) {
        let context = DataManager.shared.workerContext
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            fetchRequest.entity = HistoryMO.entity(context)
            fetchRequest.includesPropertyValues = false
            do {
                let results = try context.fetch(fetchRequest)
                for result in results {
                    context.delete(result as! NSManagedObject)
                }

            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }

            // No save, save in Domain

            DomainMO.deleteNonBookmarkedAndClearSiteVisits {
                completionOnMain()
            }
        }
    }

}
