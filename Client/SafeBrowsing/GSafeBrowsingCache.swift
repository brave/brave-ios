// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

private struct ThreatCache: Hashable, Equatable {
    let expiryDate: TimeInterval
    let hash: String
    let threatType: ThreatType
    
    static func == (lhs: ThreatCache, rhs: ThreatCache) -> Bool {
        return lhs.hash == rhs.hash && lhs.threatType == rhs.threatType
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
        hasher.combine(threatType)
    }
}

enum SBCacheHitType {
    case miss
    case positive
    case negative
}

struct SBCacheResult {
    let threats: [ThreatType]
    let cacheResult: SBCacheHitType
}

class SafeBrowsingCache {
    private let cacheLock = NSRecursiveLock()
    private var positiveCache = [String: Set<ThreatCache>]()
    private var negativeCache = [String: TimeInterval]()
    
    func find(_ hash: String) -> SBCacheResult {
        cacheLock.lock(); defer { cacheLock.unlock() }
        
        if let threats = positiveCache[hash] {
            var results = [ThreatType]()
            
            for threat in threats {
                if Date().timeIntervalSince1970 < threat.expiryDate {
                    results.append(threat.threatType)
                } else {
                    return SBCacheResult(threats: [], cacheResult: .miss)
                }
            }
            
            if !results.isEmpty {
                return SBCacheResult(threats: results, cacheResult: .positive)
            }
        }
        
        for i in 4..<32 {
            if let result = negativeCache[String(hash.prefix(i))] {
                if result < Date().timeIntervalSince1970 {
                    return SBCacheResult(threats: [], cacheResult: .negative)
                }
            }
        }
        
        return SBCacheResult(threats: [], cacheResult: .miss)
    }
    
    func update(_ request: FindRequest, _ response: FindResponse) {
        cacheLock.lock(); defer { cacheLock.unlock() }
        
        response.matches.forEach({
            guard let fullHash = $0.threat.hash else {
                return
            }
            
            if Data(base64Encoded: fullHash)?.count ?? 0 != 32 {
                return
            }
            
            if positiveCache[fullHash] == nil {
                positiveCache[fullHash] = []
            }
            
            positiveCache[fullHash]?.insert(ThreatCache(expiryDate: Date().timeIntervalSince1970 + TimeInterval($0.cacheDuration), hash: fullHash, threatType: $0.threatType))
        })
        
        if let negative = response.negativeCacheDuration?.replacingOccurrences(of: "s", with: ""), let negativeCacheDuration = TimeInterval(negative) {
            
            request.threatInfo.threatEntries.forEach({
                guard let partialHash = $0.hash else {
                    return
                }
                
                negativeCache[partialHash] = Date().timeIntervalSince1970 + negativeCacheDuration
            })
        }
    }
    
    func purge() {
        cacheLock.lock(); defer { cacheLock.unlock() }
        
        for (fullHash, threats) in positiveCache {
            for threat in threats {
                if Date().timeIntervalSince1970 > threat.expiryDate {
                    var shouldDelete = true
                    for i in 4..<32 {
                        if let negativeMatch = negativeCache[String(fullHash.prefix(i))] {
                            if Date().timeIntervalSince1970 < negativeMatch {
                                shouldDelete = false
                                break
                            }
                        }
                    }
                    
                    if shouldDelete {
                        positiveCache[fullHash] = []
                    }
                }
            }
            
            if positiveCache[fullHash].flatMap({ $0 })?.isEmpty == true {
                positiveCache.removeValue(forKey: fullHash)
            }
        }
        
        for (partialHash, time) in negativeCache {
            if Date().timeIntervalSince1970 > time {
                negativeCache.removeValue(forKey: partialHash)
            }
        }
    }
}
