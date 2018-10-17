/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import CoreData
import Foundation
import BraveShared

public final class Domain: NSManagedObject, CRUD {
    
    @NSManaged public var url: String?
    @NSManaged public var visits: Int32
    @NSManaged public var topsite: Bool // not currently used. Should be used once proper frecency code is in.
    @NSManaged public var blockedFromTopSites: Bool // don't show ever on top sites
    @NSManaged public var favicon: FaviconMO?

    @NSManaged public var shield_allOff: NSNumber?
    @NSManaged public var shield_adblockAndTp: NSNumber?
    @NSManaged public var shield_httpse: NSNumber?
    @NSManaged public var shield_noScript: NSNumber?
    @NSManaged public var shield_fpProtection: NSNumber?
    @NSManaged public var shield_safeBrowsing: NSNumber?

    @NSManaged public var historyItems: NSSet?
    @NSManaged public var bookmarks: NSSet?

    // Currently required, because not `syncable`
    static func entity(_ context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: "Domain", in: context)!
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }

    public class func getOrCreateForUrl(_ url: URL, context: NSManagedObjectContext) -> Domain {
        let domainString = url.domainURL.absoluteString
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = Domain.entity(context)
        fetchRequest.predicate = NSPredicate(format: "url == %@", domainString)
        var result: Domain!
        context.performAndWait {
            do {
                var domain: Domain
                let domains = try context.fetch(fetchRequest) as? [Domain]
                if let item = domains?.first {
                    domain = item
                } else {
                    domain = Domain(entity: Domain.entity(context), insertInto: context)
                    domain.url = domainString
                }
                
                result = domain
            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }
        }
        return result
    }

    class func blockFromTopSites(_ url: URL, context: NSManagedObjectContext) {
        let domain = getOrCreateForUrl(url, context: context)
        domain.blockedFromTopSites = true
        DataController.save(context: context)
    }

    class func blockedTopSites(_ context: NSManagedObjectContext) -> [Domain] {
        let blockedFromTopSitesKeyPath = #keyPath(Domain.blockedFromTopSites)
        let predicate = NSPredicate(format: "\(blockedFromTopSitesKeyPath) = YES")
        return all(where: predicate) ?? []
    }

    class func topSitesQuery(_ limit: Int, context: NSManagedObjectContext) -> [Domain] {
        let visitsKeyPath = #keyPath(Domain.visits)
        let blockedFromTopSitesKeyPath = #keyPath(Domain.blockedFromTopSites)
        let minVisits = 5
        
        let predicate = NSPredicate(format: "\(visitsKeyPath) > %i AND \(blockedFromTopSitesKeyPath) != YES", minVisits)
        let sortDescriptors = [NSSortDescriptor(key: visitsKeyPath, ascending: false)]
        
        return all(where: predicate, sortDescriptors: sortDescriptors) ?? []
    }

    public class func setBraveShield(forUrl url: URL, state: (BraveShieldState.Shield, Bool)) {
        let context = DataController.newBackgroundContext()
        
        let domain = Domain.getOrCreateForUrl(url, context: context)
        let (shield, setting) = (state.0, state.1 as NSNumber)
        switch shield {
            case .AllOff: domain.shield_allOff = setting
            case .AdblockAndTp: domain.shield_adblockAndTp = setting
            case .HTTPSE: domain.shield_httpse = setting
            case .SafeBrowsing: domain.shield_safeBrowsing = setting
            case .FpProtection: domain.shield_fpProtection = setting
            case .NoScript: domain.shield_noScript = setting
        }
        
        DataController.save(context: context)
        
        // After save update app state
        BraveShieldState.set(forUrl: url, state: state)
    }

    // If `static` nature here is removed, this logic can be placed inside ShieldState's init
    public class func loadShieldsIntoMemory() {
        BraveShieldState.clearAllInMemoryDomainStates()

        // Should consider fetching Domains and passing list to shield states to flush themselves.
        //  Or just place all of this directly on shield states, (reset memory states)
        for domain in Domain.all() ?? [] {
            guard let urlString = domain.url, let url = URL(string: urlString) else { continue }
            
            if let shield = domain.shield_allOff {
                BraveShieldState.set(forUrl: url, state: (.AllOff, shield.boolValue))
            }
            if let shield = domain.shield_adblockAndTp {
                BraveShieldState.set(forUrl: url, state: (.AdblockAndTp, shield.boolValue))
            }
            if let shield = domain.shield_safeBrowsing {
                BraveShieldState.set(forUrl: url, state: (.SafeBrowsing, shield.boolValue))
            }
            if let shield = domain.shield_httpse {
                BraveShieldState.set(forUrl: url, state: (.HTTPSE, shield.boolValue))
            }
            if let shield = domain.shield_fpProtection {
                BraveShieldState.set(forUrl: url, state: (.FpProtection, shield.boolValue))
            }
            if let shield = domain.shield_noScript {
                BraveShieldState.set(forUrl: url, state: (.NoScript, shield.boolValue))
            }
        }
    }

    class func deleteNonBookmarkedAndClearSiteVisits(context: NSManagedObjectContext, _ completionOnMain: @escaping () -> Void) {
        
        context.perform {
            let fetchRequest = NSFetchRequest<Domain>()
            fetchRequest.entity = Domain.entity(context)
            do {
                let results = try context.fetch(fetchRequest)
                results.forEach {
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
                    context.delete(obj)
                }
            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }

            DataController.save(context: context)
            DispatchQueue.main.async {
                completionOnMain()
            }
        }
    }
}
