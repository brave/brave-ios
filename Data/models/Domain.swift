/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import UIKit
import CoreData
import Foundation

class Domain: NSManagedObject {
    
    @NSManaged var url: String?
    @NSManaged var visits: Int32
    @NSManaged var topsite: Bool // not currently used. Should be used once proper frecency code is in.
    @NSManaged var blockedFromTopSites: Bool // don't show ever on top sites
    @NSManaged var favicon: FaviconMO?

    @NSManaged var shield_allOff: NSNumber?
    @NSManaged var shield_adblockAndTp: NSNumber?
    @NSManaged var shield_httpse: NSNumber?
    @NSManaged var shield_noScript: NSNumber?
    @NSManaged var shield_fpProtection: NSNumber?
    @NSManaged var shield_safeBrowsing: NSNumber?

    @NSManaged var historyItems: NSSet?
    @NSManaged var bookmarks: NSSet?

    // Currently required, because not `syncable`
    static func entity(_ context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: "Domain", in: context)!
    }

    override func awakeFromInsert() {
        super.awakeFromInsert()
    }

    // Always use this function to save or lookup domains in the table
    class func domainAndScheme(fromUrl url: URL?) -> String {
        let domainUrl = (url?.scheme ?? "http") + "://" + (url?.normalizedHost ?? "")
        return domainUrl
    }

    class func getOrCreateForUrl(_ url: URL, context: NSManagedObjectContext) -> Domain? {
        let domainString = Domain.domainAndScheme(fromUrl: url)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = Domain.entity(context)
        fetchRequest.predicate = NSPredicate(format: "url == %@", domainString)
        var result: Domain? = nil
        context.performAndWait {
            do {
                let results = try context.fetch(fetchRequest) as? [Domain]
                if let item = results?.first {
                    result = item
                } else {
                    result = Domain(entity: Domain.entity(context), insertInto: context)
                    result?.url = domainString
                }
            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }
        }
        return result
    }

    class func blockFromTopSites(_ url: URL, context: NSManagedObjectContext) {
        if let domain = getOrCreateForUrl(url, context: context) {
            domain.blockedFromTopSites = true
            DataController.saveContext(context: context)
        }
    }

    class func blockedTopSites(_ context: NSManagedObjectContext) -> [Domain] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = Domain.entity(context)
        fetchRequest.predicate = NSPredicate(format: "blockedFromTopSites == %@", NSNumber(value: true as Bool))
        do {
            if let results = try context.fetch(fetchRequest) as? [Domain] {
                return results
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return [Domain]()
    }

    class func topSitesQuery(_ limit: Int, context: NSManagedObjectContext) -> [Domain] {
        assert(!Thread.isMainThread)

        let minVisits = 5

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.fetchLimit = limit
        fetchRequest.entity = Domain.entity(context)
        fetchRequest.predicate = NSPredicate(format: "visits > %i AND blockedFromTopSites != %@", minVisits, NSNumber(value: true as Bool))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "visits", ascending: false)]
        do {
            if let results = try context.fetch(fetchRequest) as? [Domain] {
                return results
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return [Domain]()
    }

    class func setBraveShield(forDomain domainString: String, state: (BraveShieldState.Shield, Bool?), context: NSManagedObjectContext) {
        guard let url = URL(string: domainString) else { return }
        let domain = Domain.getOrCreateForUrl(url, context: context)
        let shield = state.0
        switch (shield) {
            case .AllOff: domain?.shield_allOff = state.1 as NSNumber?
            case .AdblockAndTp: domain?.shield_adblockAndTp = state.1 as NSNumber?
            case .HTTPSE: domain?.shield_httpse = state.1 as NSNumber?
            case .SafeBrowsing: domain?.shield_safeBrowsing = state.1 as NSNumber?
            case .FpProtection: domain?.shield_fpProtection = state.1 as NSNumber?
            case .NoScript: domain?.shield_noScript = state.1 as NSNumber?
        }
        DataController.saveContext(context: context)
    }

    class func loadShieldsIntoMemory(_ completionOnMain: @escaping ()->()) {
        BraveShieldState.perNormalizedDomain.removeAll()

        let context = DataController.shared.workerContext
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            fetchRequest.entity = Domain.entity(context)
            do {
                let results = try context.fetch(fetchRequest)
                for obj in results {
                    let domain = obj as! Domain
                    guard let urlString = domain.url, let url = URL(string: urlString) else { continue }
                    let normalizedUrl = url.normalizedHost ?? ""

                    print(normalizedUrl)
                    if let shield = domain.shield_allOff {
                        BraveShieldState.setInMemoryforDomain(normalizedUrl, setState: (.AllOff, shield.boolValue))
                    }
                    if let shield = domain.shield_adblockAndTp {
                        BraveShieldState.setInMemoryforDomain(normalizedUrl, setState: (.AdblockAndTp, shield.boolValue))
                    }
                    if let shield = domain.shield_safeBrowsing {
                        BraveShieldState.setInMemoryforDomain(normalizedUrl, setState: (.SafeBrowsing, shield.boolValue))
                    }
                    if let shield = domain.shield_httpse {
                        BraveShieldState.setInMemoryforDomain(normalizedUrl, setState: (.HTTPSE, shield.boolValue))
                    }
                    if let shield = domain.shield_fpProtection {
                        BraveShieldState.setInMemoryforDomain(normalizedUrl, setState: (.FpProtection, shield.boolValue))
                    }
                    if let shield = domain.shield_noScript {
                        BraveShieldState.setInMemoryforDomain(normalizedUrl, setState: (.NoScript, shield.boolValue))
                    }
                }
            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }

            postAsyncToMain {
                completionOnMain()
            }
        }
    }

    class func deleteNonBookmarkedAndClearSiteVisits(_ completionOnMain: @escaping ()->()) {
        let context = DataController.shared.workerContext
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            fetchRequest.entity = Domain.entity(context)
            do {
                let results = try context.fetch(fetchRequest)
                (results as? [Domain])?.forEach {
                    if let bms = $0.bookmarks, bms.count > 0 {
                        // Clear visit count
                        $0.visits = 0
                    } else {
                        // Delete
                        context.delete($0)
                    }
                }
                for obj in results {
                    // Cascading delete on favicon, it will also get deleted
                    context.delete(obj as! NSManagedObject)
                }
            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }

            DataController.saveContext(context: context)
            postAsyncToMain {
                completionOnMain()
            }
        }
    }
}
