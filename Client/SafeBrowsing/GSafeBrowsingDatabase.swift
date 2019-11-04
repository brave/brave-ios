// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreData
import CommonCrypto
import Shared

private let log = Logger.browserLogger

extension ThreatHash {
    func matches(_ hashPrefix: Data) -> Int {
        guard let hash = hashData else {
            return 0
        }
        
        var hashLength = hash.count
        if hash.subdata(in: 0..<4) == hashPrefix.subdata(in: 0..<4) && hashLength <= 4 {
            return hash.count
        }
        
        if hashLength > hashPrefix.count {
            hashLength = hashPrefix.count
        }
        
        if hash.isEmpty {
            return 0
        }
        
        for i in 4..<hashLength {
            if hash == hashPrefix.subdata(in: 0..<i) {
                return i
            }
        }
        return 0
    }
}

class SafeBrowsingDatabase {
    private let dbLock = NSRecursiveLock()
    var last = Date().timeIntervalSince1970
    
    init() {
        let threats: NSFetchRequest<Threat> = Threat.fetchRequest()
        do {
            let threats = try self.mainContext.fetch(threats)
            try threats.forEach({
                var hashes = $0.hashes?.compactMap({ ($0 as? ThreatHash)?.hashData })
                hashes?.sort(by: { $0.lexicographicallyPrecedes($1) })
                
                if let checksum = $0.checksum, let hashes = hashes {
                    if !validate(checksum, hashes) {
                        throw SafeBrowsingError("Database Corrupted")
                    }
                }
            })
        } catch {
            //Remove everything and re-create the database
            self.destroy()
            self.persistentContainer = self.create()
            
            log.error("Safe-Browsing: \(error)")
        }
    }
    
    private lazy var persistentContainer: NSPersistentContainer = {
        return self.create()
    }()
    
    private lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    private lazy var mainContext: NSManagedObjectContext = {
        let context = persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    
    private func save() {
        let context = mainContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                log.error("Error Saving Context: \(error)")
            }
        }
    }
    
    func getState(_ type: ThreatType) -> String {
        dbLock.lock(); defer { dbLock.unlock() }
        
        let request: NSFetchRequest<Threat> = Threat.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "threatType == %@", type.rawValue)
        return (try? mainContext.fetch(request))?.first?.state ?? ""
    }
    
    func find(_ hash: String) -> [String] {
        dbLock.lock(); defer { dbLock.unlock() }
        
        var hashes = [String]()
        let data = Data(base64Encoded: hash)!
        if data.count != Int(CC_SHA256_DIGEST_LENGTH) {
            return [] //ERROR Hash must be a full hash..
        }
        
        let request: NSFetchRequest<ThreatHash> = ThreatHash.fetchRequest()
        let threatHashes = (try? mainContext.fetch(request)) ?? []
        
        for threat in threatHashes {
            let n = threat.matches(data)
            if n > 0 {
                let hashPrefix = data.subdata(in: 0..<n)
                hashes.append(hashPrefix.base64EncodedString())
            }
        }
        
        return hashes
    }
    
    func find(_ hashes: [String]) -> [String] {
        return hashes.flatMap({ self.find($0) })
    }
    
    func update(_ fetchResponse: FetchResponse, completion: (Error?) -> Void) {
        dbLock.lock(); defer { dbLock.unlock() }
        
        fetchResponse.listUpdateResponses.forEach({ response in
            if response.additions.isEmpty && response.removals.isEmpty {
                return //Nothing to update
            }
            
            switch response.responseType {
            case .partialUpdate:
                let request: NSFetchRequest<NSFetchRequestResult> = Threat.fetchRequest()
                let count = (try? mainContext.count(for: request)) ?? 0
                if count == 0 {
                    return completion(SafeBrowsingError("Partial Update received for non-existent table"))
                }
                
            case .fullUpdate:
                if !response.removals.isEmpty {
                    return completion(SafeBrowsingError("Indices to be removed included in a Full Update"))
                }
                
                let request: NSFetchRequest<Threat> = Threat.fetchRequest()
                request.predicate = NSPredicate(format: "threatType == %@", response.threatType.rawValue)
                (try? mainContext.fetch(request))?.forEach({
                    self.mainContext.delete($0)
                })
                
                if mainContext.hasChanges {
                    self.save()
                }
                
            default:
                return completion(SafeBrowsingError("Unknown Response Type"))
            }
            
            self.backgroundContext.performAndWait { [weak self] in
                guard let self = self else { return }
                let context = self.backgroundContext
                
                let request: NSFetchRequest<Threat> = Threat.fetchRequest()
                request.predicate = NSPredicate(format: "threatType == %@", response.threatType.rawValue)
                request.fetchLimit = 1
                
                var threat: Threat! = (try? context.fetch(request))?.first
                if threat == nil {
                    threat = Threat(context: context)
                }
                
                threat.threatType = response.threatType.rawValue
                threat.state = response.newClientState
                
                var hashes = (threat.hashes ?? []).compactMap({ ($0 as? ThreatHash)?.hashData })
                
                //Hashes must be sorted
                hashes.sort(by: { $0.lexicographicallyPrecedes($1) })
                
                response.removals.forEach({
                    $0.rawIndices?.indices.forEach({
                        if Int($0) > 0 && Int($0) < hashes.count {
                            hashes[Int($0)] = Data()
                        }
                    })
                })
                
                hashes = hashes.filter({ !$0.isEmpty })
                
                response.additions.forEach({
                    guard let rawHashes = $0.rawHashes else {
                        return
                    }
                    
                    if let data = Data(base64Encoded: rawHashes.rawHashes) {
                        let strideSize = Int(rawHashes.prefixSize)
                        
                        for i in stride(from: 0, to: data.count, by: strideSize) {
                            let startIndex = data.index(data.startIndex, offsetBy: i)
                            let endIndex = data.index(startIndex, offsetBy: strideSize)
                            
                            let subData = data.subdata(in: startIndex..<endIndex)
                            hashes.append(subData)
                        }
                    }
                })
                
                //Hashes must be sorted
                hashes.sort(by: { $0.lexicographicallyPrecedes($1) })
                
                threat.hashes?.forEach({
                    if let hash = $0 as? ThreatHash {
                        context.delete(hash)
                    }
                })
                
                threat.hashes = NSSet(array: hashes.map({
                    let hash = ThreatHash(context: context)
                    hash.hashData = $0
                    return hash
                }))
                
                if !response.checksum.sha256.isEmpty {
                    threat.checksum = response.checksum.sha256
                }
                
                if !validate(response.checksum.sha256, hashes) {
                    context.rollback()
                    return completion(SafeBrowsingError("Threat List Checksum Mismatch"))
                }
                
                if context.hasChanges {
                    do {
                        try context.save()
                    } catch {
                        completion(error)
                    }
                    
                    context.reset()
                }
            }
        })
    }
    
    private func hash(_ data: [Data]) -> Data {
        var ctx = CC_SHA256_CTX()
        CC_SHA256_Init(&ctx)
        
        for data in data {
            data.withUnsafeBytes {
                _ = CC_SHA256_Update(&ctx, $0.baseAddress, CC_LONG(data.count))
            }
        }
        
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&hash, &ctx)
        return Data(bytes: hash, count: hash.count)
    }
    
    private func validate(_ checksum: String, _ hashes: [Data]) -> Bool {
        return checksum == self.hash(hashes).base64EncodedString()
    }
    
    // MARK: - CoreData Stack
    
    private lazy var cachedPersistentContainer = {
        return NSPersistentContainer(name: "SafeBrowsing")
    }()
    
    private func create() -> NSPersistentContainer {
        dbLock.lock(); defer { dbLock.unlock() }
        
        cachedPersistentContainer.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            guard let self = self else { return }
            
            if error != nil {
                self.destroy()
                
                self.cachedPersistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
                    if let error = error as NSError? {
                        fatalError("Safe-Browsing Load persistent store error: \(error)")
                    }
                })
            }
        })
        return cachedPersistentContainer
    }
    
    private func destroy() {
        dbLock.lock(); defer { dbLock.unlock() }
        
        cachedPersistentContainer.persistentStoreDescriptions.forEach({
            try? cachedPersistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: $0.url!, ofType: NSSQLiteStoreType, options: nil)
        })
    }
}
