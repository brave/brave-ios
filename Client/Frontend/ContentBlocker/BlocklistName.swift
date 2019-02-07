// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import WebKit
import Shared
import Deferred
import Data
import BraveShared

private let log = Logger.browserLogger

class BlocklistName: CustomStringConvertible, ContentBlocker {
    
    static let ad = BlocklistName(filename: "block-ads")
    static let tracker = BlocklistName(filename: "block-trackers")
    static let https = BlocklistName(filename: "upgrade-http")
    static let image = BlocklistName(filename: "block-images")
    static let cookie = BlocklistName(filename: "block-cookies")
    
    static var allLists: Set<BlocklistName> { return [.ad, .tracker, .https, .image] }
    
    let filename: String
    var rule: WKContentRuleList?
    
    init(filename: String) {
        self.filename = filename
    }
    
    var description: String {
        return "<\(type(of: self)): \(self.filename)>"
    }
    
    private static let blocklistFileVersionMap: [BlocklistName: Preferences.Option<String?>] = [
        BlocklistName.ad: Preferences.BlockFileVersion.adblock,
        BlocklistName.https: Preferences.BlockFileVersion.httpse
    ]
    
    lazy var fileVersionPref: Preferences.Option<String?>? = {
        return BlocklistName.blocklistFileVersionMap[self]
    }()
    
    lazy var fileVersion: String? = {
        guard let _ = BlocklistName.blocklistFileVersionMap[self] else { return nil }
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }()
    
    static func blocklists(forDomain domain: Domain, locale: String? = Locale.current.languageCode) -> (on: Set<BlocklistName>, off: Set<BlocklistName>) {
        if domain.shield_allOff == 1 {
            var offList = allLists
            // Make sure to consider the regional list which needs to be disabled as well
            if let locale = locale, let regionalBlocker = ContentBlockerRegion.with(localeCode: locale) {
                offList.insert(regionalBlocker)
            }
            return ([], offList)
        }
        
        var onList = Set<BlocklistName>()
        
        if domain.isShieldExpected(.AdblockAndTp) {
            onList.formUnion([.ad, .tracker])
            
            if Preferences.Shields.useRegionAdBlock.value, let locale = locale,
                let regionalBlocker = ContentBlockerRegion.with(localeCode: locale) {
                onList.insert(regionalBlocker)
            }
        }
        
        // For lists not implemented, always return exclude from `onList` to prevent accidental execution
        
        // TODO #159: Setup image shield
        
        if domain.isShieldExpected(.HTTPSE) {
            onList.insert(.https)
        }
        
        var offList = allLists.subtracting(onList)
        // Make sure to consider the regional list since the user may disable it globally
        if let locale = locale, let regionalBlocker = ContentBlockerRegion.with(localeCode: locale),
            !onList.contains(regionalBlocker) {
            offList.insert(regionalBlocker)
        }
        
        return (onList, offList)
    }
    
    static func compileAll(ruleStore: WKContentRuleListStore) -> Deferred<Void> {
        let allCompiledDeferred = Deferred<Void>()
        var allOfThem = BlocklistName.allLists.map {
            $0.buildRule(ruleStore: ruleStore)
        }
        //Compile block-cookie additionally 
        allOfThem.append(BlocklistName.cookie.buildRule(ruleStore: ruleStore))
        all(allOfThem).upon { _ in
            allCompiledDeferred.fill(())
        }
        
        return allCompiledDeferred
    }
}
