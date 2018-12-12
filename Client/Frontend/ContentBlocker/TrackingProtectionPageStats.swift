/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This file is largely verbatim from Focus iOS (Blockzilla/Lib/TrackingProtection).
// The preload and postload js files are unmodified from Focus.

import Shared
import Deferred
import Data

struct TPPageStats {
    let adCount: Int
    let trackerCount: Int
    let scriptCount: Int
    let fingerprintingCount: Int
    let httpsCount: Int

    var total: Int { return adCount + trackerCount + scriptCount + fingerprintingCount + httpsCount }
    
    init(adCount: Int = 0, trackerCount: Int = 0, scriptCount: Int = 0, fingerprintingCount: Int = 0, httpsCount: Int = 0) {
        self.adCount = adCount
        self.trackerCount = trackerCount
        self.scriptCount = scriptCount
        self.fingerprintingCount = fingerprintingCount
        self.httpsCount = httpsCount
    }
    
    func addingFingerprintingBlock() -> TPPageStats {
        return TPPageStats(adCount: adCount, trackerCount: trackerCount, scriptCount: scriptCount, fingerprintingCount: fingerprintingCount + 1, httpsCount: httpsCount)
    }

    func addingScriptBlock() -> TPPageStats {
        return TPPageStats(adCount: adCount, trackerCount: trackerCount, scriptCount: scriptCount + 1, fingerprintingCount: fingerprintingCount, httpsCount: httpsCount)
    }
    
    func create(byAddingListItem listItem: BlocklistName) -> TPPageStats {
        switch listItem {
        case .ad: return TPPageStats(adCount: adCount + 1, trackerCount: trackerCount, scriptCount: scriptCount, fingerprintingCount: fingerprintingCount, httpsCount: httpsCount)
        case .tracker: return TPPageStats(adCount: adCount, trackerCount: trackerCount + 1, scriptCount: scriptCount, fingerprintingCount: fingerprintingCount, httpsCount: httpsCount)
        case .https: return TPPageStats(adCount: adCount, trackerCount: trackerCount, scriptCount: scriptCount, fingerprintingCount: fingerprintingCount, httpsCount: httpsCount + 1)
        default:
            break
        }
        return self
    }
}

enum TPStatsResourceType: String {
    case script
    case image
}

class TPStatsBlocklistChecker {
    static let shared = TPStatsBlocklistChecker()

    func isBlocked(request: URLRequest, domain: Domain, resourceType: TPStatsResourceType? = nil) -> Deferred<BlocklistName?> {
        let deferred = Deferred<BlocklistName?>()
        
        guard let url = request.url, let host = url.host, !host.isEmpty else {
            // TP Stats init isn't complete yet
            deferred.fill(nil)
            return deferred
        }
        
        DispatchQueue.global().async {
            let enabledLists = BlocklistName.blocklists(forDomain: domain).on
            if let resourceType = resourceType {
                switch resourceType {
                case .script:
                    break
                case .image:
                    if enabledLists.contains(.image) {
                        deferred.fill(.image)
                        return
                    }
                }
            }
            
            let isAdOrTrackerListEnabled = enabledLists.contains(.ad) || enabledLists.contains(.tracker)
            
            if isAdOrTrackerListEnabled && AdBlockStats.shared.shouldBlock(request) {
                deferred.fill(BlocklistName.ad)
                return
            }
            
            if enabledLists.contains(.https) && HttpsEverywhereStats.shared.shouldUpgrade(url) {
                deferred.fill(BlocklistName.https)
                return
            }
            
            deferred.fill(nil)
        }
        return deferred
    }
}
