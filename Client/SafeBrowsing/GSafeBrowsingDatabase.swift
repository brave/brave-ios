// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreData
import CommonCrypto
import Shared

private let log = Logger.browserLogger

extension Data {
    func rawString() -> String {
        if count > 0 {
            let hexChars = Array("0123456789ABCDEF".utf8) as [UInt8]
            return withUnsafeBytes { bytes -> String in
                var output = [UInt8](repeating: 0, count: bytes.count * 2 + 1)
                var index: Int = 0
                for byte in bytes {
                    let hi  = Int((byte & 0xF0) >> 0x04)
                    let low = Int(byte & 0x0F)
                    output[index] = hexChars[hi]
                    output[index + 1] = hexChars[low]
                    index += 0x02
                }
                return String(cString: &output)
            }
        }
        return ""
    }
}

extension String {
    func rawData() -> Data {
        let length = self.count
        if length & 1 != 0 {
            return Data()
        }
        
        var data = Data()
        data.reserveCapacity(length / 2)
        var index = self.startIndex
        for _ in 0..<length / 2 {
            let nextIndex = self.index(index, offsetBy: 2)
            if let byte = UInt8(self[index..<nextIndex], radix: 16) {
                data.append(byte)
            } else {
                return Data()
            }
            index = nextIndex
        }
        return data
    }
}

class SafeBrowsingDatabase {
    private let dbLock = NSRecursiveLock()
    
    // For fetches
    private var lastFetchDate = Date.distantPast
    private var lastFetchWaitDuration: Double = 0.0
    private var numberOfFetchRetries: Int16 = 0
    
    // For finds
    private var lastFindDate = Date.distantPast
    private var lastFindWaitDuration: Double = 0.0
    private var numberOfFindRetries: Int16 = 0
    
    private var updateTimer: Timer?
    
    init() {
        do {
            let databaseInfoRequest: NSFetchRequest<ThreatDatabaseInfo> = ThreatDatabaseInfo.fetchRequest()
            databaseInfoRequest.fetchLimit = 1
            
            let databaseInfo = try self.mainContext.fetch(databaseInfoRequest)
            self.lastFetchDate = databaseInfo.first?.lastFetchDate ?? Date.distantPast
            self.lastFetchWaitDuration = databaseInfo.first?.fetchWaitDuration ?? 0.0
            self.numberOfFetchRetries = databaseInfo.first?.numberOfFetchRetries ?? 0
            
            self.lastFindDate = databaseInfo.first?.lastFindDate ?? Date.distantPast
            self.lastFindWaitDuration = databaseInfo.first?.findWaitDuration ?? 0.0
            self.numberOfFindRetries = databaseInfo.first?.numberOfFindRetries ?? 0
            
            let request: NSFetchRequest<Threat> = Threat.fetchRequest()
            let threats = try self.mainContext.fetch(request)
            try threats.forEach({
                let hashes = ($0.hashes ?? []).compactMap({ ($0 as? ThreatHash)?.hashData })
                //hashes.sort(by: { $0.lexicographicallyPrecedes($1) })

                if let checksum = $0.checksum {
                    if !self.validate(checksum, hashes) {
                        throw SafeBrowsingError("Database Corrupted")
                    }
                }
            })
            self.mainContext.reset()
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
        saveContext(mainContext)
    }
    
    private func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                log.error("Error Saving Context: \(error)")
            }
        }
    }
    
    func canFind() -> Bool {
        return Date().timeIntervalSince(self.lastFindDate) >= self.lastFindWaitDuration
    }
    
    func canUpdate() -> Bool {
        return Date().timeIntervalSince(self.lastFetchDate) >= self.lastFetchWaitDuration
    }
    
    func enterBackoffMode(_ mode: BackoffMode) {
        if mode == .find {
            let duration = calculateBackoffTime(self.numberOfFindRetries)
            self.numberOfFindRetries += 1
            
            if duration > 0 {
                self.lastFindDate = Date()
                self.lastFindWaitDuration = duration
                self.updateDatabaseInfo { error in
                    if let error = error {
                        log.error(error)
                    }
                }
            }
        } else if mode == .update {
            let duration = calculateBackoffTime(self.numberOfFetchRetries)
            self.numberOfFetchRetries += 1
            
            if duration > 0 {
                self.lastFetchDate = Date()
                self.lastFetchWaitDuration = duration
                self.updateDatabaseInfo { error in
                    if let error = error {
                        log.error(error)
                    }
                }
            }
        }
    }
    
    func getState(_ type: ThreatType) -> String {
        var state = ""
        let backgroundContext = { () -> NSManagedObjectContext in
            let context = self.persistentContainer.newBackgroundContext()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            return context
        }()
        
        backgroundContext.performAndWait {
            let request: NSFetchRequest<Threat> = Threat.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "threatType == %@", type.rawValue)
            state = (try? backgroundContext.fetch(request))?.first?.state ?? ""
        }
        return state
    }
    
    func find(_ hash: String, completion: @escaping (String) -> Void) {
        guard let data = Data(base64Encoded: hash) else {
            return completion("")
        }
        
        if data.count != Int(CC_SHA256_DIGEST_LENGTH) {
            return completion("") //ERROR Hash must be a full hash..
        }
        
        let backgroundContext = { () -> NSManagedObjectContext in
            let context = self.persistentContainer.newBackgroundContext()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            return context
        }()
        
        backgroundContext.perform {
            let minPrefixLength = 4
            let prefix = data.subdata(in: 0..<minPrefixLength).rawString()
            
            let request: NSFetchRequest<ThreatHash> = ThreatHash.fetchRequest()
            request.fetchLimit = 1
            
            let optimizedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "SELF.%K MATCHES %@", argumentArray: ["hashPrefix", ".{\(minPrefixLength)}"]),
                NSPredicate(format: "SELF.%K BEGINSWITH %@", argumentArray: ["hashPrefix", prefix])
                ])
            
            let fullLengthPredicate = NSPredicate(format: "SELF.%K LIKE %@", argumentArray: ["hashPrefix", prefix])
            
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [optimizedPredicate, fullLengthPredicate])
            
            if let threatHash = (try? backgroundContext.fetch(request))?.first {
                return completion(data.subdata(in: 0..<threatHash.hashPrefix!.count).base64EncodedString())
            }
            
            completion("")
        }
    }
    
    func find(_ hashes: [String], completion: @escaping ([String]) -> Void) {
        var results = [String]()
        let group = DispatchGroup()

        hashes.forEach({ hash in
            group.enter()
            guard let data = Data(base64Encoded: hash) else {
                return group.leave()
            }
            
            if data.count != Int(CC_SHA256_DIGEST_LENGTH) {
                return group.leave() //ERROR Hash must be a full hash..
            }

            let backgroundContext = { () -> NSManagedObjectContext in
                let context = self.persistentContainer.newBackgroundContext()
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                return context
            }()

            backgroundContext.perform {
                let minPrefixLength = 4
                let prefix = data.subdata(in: 0..<minPrefixLength).rawString()

                let request: NSFetchRequest<ThreatHash> = ThreatHash.fetchRequest()

                let optimizedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "SELF.%K MATCHES %@", argumentArray: ["hashPrefix", ".{\(minPrefixLength)}"]),
                    NSPredicate(format: "SELF.%K BEGINSWITH %@", argumentArray: ["hashPrefix", prefix])
                ])

                let fullLengthPredicate = NSPredicate(format: "SELF.%K LIKE %@", argumentArray: ["hashPrefix", prefix])

                request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [optimizedPredicate, fullLengthPredicate])

                let threatHashes = (try? backgroundContext.fetch(request)) ?? []
                results.append(contentsOf: threatHashes.map({ data.subdata(in: 0..<$0.hashPrefix!.count).base64EncodedString() }))

                group.leave()
            }
        })

        group.notify(queue: .global(qos: .background)) {
            completion(results)
        }
    }
    
    func update(_ fetchResponse: FetchResponse, completion: @escaping (Error?) -> Void) {
        dbLock.lock(); defer { dbLock.unlock() }
        
        self.lastFetchDate = Date()
        self.lastFetchWaitDuration = Double(fetchResponse.minimumWaitDuration)
        self.numberOfFetchRetries = 0
        self.updateDatabaseInfo(completion)
        
        fetchResponse.listUpdateResponses.forEach({ response in
            if response.additions.isEmpty && response.removals.isEmpty {
                return completion(nil) //Nothing to update
            }
            
            switch response.responseType {
            case .partialUpdate:
                var count = 0
                self.backgroundContext.performAndWait {
                    let request: NSFetchRequest<NSFetchRequestResult> = Threat.fetchRequest()
                    count = (try? self.backgroundContext.count(for: request)) ?? 0
                }
                
                if count == 0 {
                    return completion(SafeBrowsingError("Partial Update received for non-existent table"))
                }
                
            case .fullUpdate:
                if !response.removals.isEmpty {
                    return completion(SafeBrowsingError("Indices to be removed included in a Full Update"))
                }
                
                self.backgroundContext.performAndWait { [weak self] in
                    guard let self = self else { return completion(nil) }
                    let request = { () -> NSBatchDeleteRequest in
                        let request: NSFetchRequest<NSFetchRequestResult> = Threat.fetchRequest()
                        request.predicate = NSPredicate(format: "threatType == %@", response.threatType.rawValue)
                        
                        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                        deleteRequest.resultType = .resultTypeObjectIDs
                        return deleteRequest
                    }()
                    
                    if let result = (try? self.backgroundContext.execute(request)) as? NSBatchDeleteResult {
                        if let deletedObjects = result.result as? [NSManagedObjectID] {
                            NSManagedObjectContext.mergeChanges(
                                fromRemoteContextSave: [NSDeletedObjectsKey: deletedObjects],
                                into: [self.mainContext, self.backgroundContext]
                            )
                        }
                    } else {
                        let request: NSFetchRequest<Threat> = Threat.fetchRequest()
                        request.predicate = NSPredicate(format: "threatType == %@", response.threatType.rawValue)
                        
                        (try? self.backgroundContext.fetch(request))?.forEach({
                            self.backgroundContext.delete($0)
                        })
                    }
                    
                    self.saveContext(self.backgroundContext)
                    self.backgroundContext.reset()
                }
                
            default:
                return completion(SafeBrowsingError("Unknown Response Type"))
            }
            
            let backgroundContext = { () -> NSManagedObjectContext in
                let context = self.persistentContainer.newBackgroundContext()
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                return context
            }()
            
            backgroundContext.performAndWait { [weak self] in
                guard let self = self else { return }
                let request: NSFetchRequest<Threat> = Threat.fetchRequest()
                request.predicate = NSPredicate(format: "threatType == %@", response.threatType.rawValue)
                request.fetchLimit = 1
                
                let threat: Threat = (try? backgroundContext.fetch(request))?.first ?? Threat(context: backgroundContext)
                
                threat.threatType = response.threatType.rawValue
                threat.state = response.newClientState
                
                var hashes = (threat.hashes ?? []).compactMap({ ($0 as? ThreatHash)?.hashData })
                
                //Hashes must be sorted
                //hashes.sort(by: { $0.lexicographicallyPrecedes($1) })
                
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
                            hashes.append(data.subdata(in: startIndex..<endIndex))
                        }
                    }
                })
                
                //Hashes must be sorted
                hashes.sort(by: { $0.lexicographicallyPrecedes($1) })
                
                threat.hashes?.forEach({
                    if let hash = $0 as? ThreatHash {
                        backgroundContext.delete(hash)
                    }
                })
                
                threat.hashes = NSOrderedSet(array: hashes.map({
                    let hash = ThreatHash(context: backgroundContext)
                    hash.hashPrefix = $0.rawString()
                    hash.hashData = $0
                    return hash
                }))
                
                if !response.checksum.sha256.isEmpty {
                    threat.checksum = response.checksum.sha256
                }
                
                if !self.validate(response.checksum.sha256, hashes) {
                    backgroundContext.rollback()
                    return completion(SafeBrowsingError("Threat List Checksum Mismatch"))
                }
                
                self.saveContext(backgroundContext)
            }
        })
    }
    
    func scheduleUpdate(onNeedsUpdating: @escaping () -> Void) {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: self.lastFetchWaitDuration, repeats: false) {
            $0.invalidate()
            DispatchQueue.main.async {
                onNeedsUpdating()
            }
        }
    }
    
    private func calculateBackoffTime(_ numberOfRetries: Int16) -> Double {
        let minutes = Double(1 << Int(numberOfRetries)) * (15.0 * (Double.random(in: 0..<1) + 1))
        return min(minutes, 24 * 60) * 60
    }
    
    private func updateDatabaseInfo(_ completion: (Error?) -> Void) {
        self.backgroundContext.performAndWait {
            do {
                let databaseInfoRequest: NSFetchRequest<ThreatDatabaseInfo> = ThreatDatabaseInfo.fetchRequest()
                databaseInfoRequest.fetchLimit = 1
                
                let databaseInfo = (try self.backgroundContext.fetch(databaseInfoRequest)).first ?? ThreatDatabaseInfo(context: self.backgroundContext)
                
                databaseInfo.fetchWaitDuration = self.lastFetchWaitDuration
                databaseInfo.lastFetchDate = self.lastFetchDate
                databaseInfo.numberOfFetchRetries = self.numberOfFetchRetries
                
                databaseInfo.findWaitDuration = self.lastFindWaitDuration
                databaseInfo.lastFindDate = self.lastFindDate
                databaseInfo.numberOfFindRetries = self.numberOfFindRetries
                
                self.saveContext(self.backgroundContext)
                self.backgroundContext.reset()
                completion(nil)
            } catch {
                completion(error)
            }
        }
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
