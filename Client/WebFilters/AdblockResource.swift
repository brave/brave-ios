// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared

private let log = Logger.browserLogger

enum AdblockResourceType: String {
    case dat = "dat"
    case json = "json"
}

struct AdblockResourceManager {
    let endpoint: String
    let folderName: String
    
    // temporary
    // static let defaultEndpoint = "https://adblock-data.s3.brave.com/"
    private static let defaultEndpoint = "https://github.com/iccub/brave-blocklists-test/raw/master/ios/"
    private static let defaultFolderName = "abp-data"
    
    init(endpoint: String = defaultEndpoint, folderName: String = defaultFolderName) {
        self.endpoint = endpoint
        self.folderName = folderName
    }
}

protocol AdblockResourceProtocol {
    /// Adblocking consists of two separate files.
    /// A .dat file for counting how many ads are blocked
    /// and a json file which does the ad blocking via webkit's content blocker.
    var resourceType: AdblockResourceType { get }
    
    func createNetworkLoader(forLocale: String, name: String,
                             resourceManager: AdblockResourceManager) -> LocalizedNetworkDataFileLoader?
}

extension AdblockResourceProtocol {
    func createNetworkLoader(forLocale locale: String, name: String,
                             resourceManager manager: AdblockResourceManager = AdblockResourceManager()) -> LocalizedNetworkDataFileLoader? {        
        let endpoint = manager.endpoint
        let folderName = manager.folderName
        
        let extensionType = ".\(resourceType.rawValue)"
        
        guard let resourceUrl = URL(string: endpoint + name + extensionType) else {
            log.error("Could not parse url for getting an adblocker resource")
            return nil
        }

        let fileName = name + extensionType
        
        let loader = LocalizedNetworkDataFileLoader(url: resourceUrl, file: fileName, localDirName: folderName)
        loader.lang = locale
        return loader
    }
}
