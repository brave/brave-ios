// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared

private let log = Logger.browserLogger

enum FileType: String { case dat, json, tgz }

enum AdblockerType {
    case general
    case httpse
    case regional(locale: String)
    
    var locale: String? {
        switch self {
        case .regional(let locale): return locale
        default: return nil
        }}
    
    var associatedFiles: [FileType] { return [.json, fileForStatsLibrary] }
    
    private var fileForStatsLibrary: FileType {
        switch self {
        case .general, .regional: return .dat
        case .httpse: return .tgz
        }
    }
    
    var identifier: String {
        switch self {
        case .general: return BlocklistName.adFileName
        case .httpse: return BlocklistName.httpseFileName
        case .regional(let locale): return locale
        }
    }
    
    var blockListName: BlocklistName? {
        switch self {
        case .general: return BlocklistName.ad
        case .httpse: return BlocklistName.https
        case .regional(let locale): return ContentBlockerRegion.with(localeCode: locale)
        }
    }
    
    static func type(fromResource name: String) -> AdblockerType? {
        switch name {
        case AdblockResourcesMappings.generalAdblockName:
            return .general
        case AdblockResourcesMappings.generalHttpseName:
            return .httpse
        default: // Regional lists
            if let locale = AdblockResourcesMappings.resourceNameToLocale(name) {
                return .regional(locale: locale)
            }
            
            log.error("No locale was found for resource: \(name)")
            assertionFailure()
            return nil
        }
    }
}
