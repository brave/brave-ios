// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared

class BackgroundImage {
    
    struct Background {
        let image: UIImage
        let center: CGFloat
        let credit: (name: String, url: String?)?
    }

    // Data is static to avoid duplicate loads
    
    let info: Background?
    let hasSponsor: Bool
    
    init() {
        
        let sponsor: Bool = {
            guard let json = BackgroundImage.loadImageJSON(sponsored: true),
                let region = NSLocale.current.regionCode else {
                return false
            }
                
            let allRegionsWithSponsoredImages = json.compactMap { item in
                item["regions"] as? [String]
            }.reduce([], +)
            
            return allRegionsWithSponsoredImages.contains(region)
        }()
        
        self.hasSponsor = sponsor
        self.info = BackgroundImage.randomBackground(hasSponsor: sponsor)
    }
    
    private static func randomBackground(hasSponsor: Bool) -> Background? {
        // Determine what type of background to display
        let sponsorshipShowRate = 4 // e.g. 4 == 25%
        let useSponsor = hasSponsor && Int.random(in: 0..<sponsorshipShowRate) == 0
        
        guard let json = BackgroundImage.loadImageJSON(sponsored: useSponsor) else { return nil }
        if json.count == 0 { return nil }
        
        // Not idea, as this requires loading the file each time to find a background, but not much to avoid this
        //  as this VC is re-created often, and some 'parent' would need to own the datasource for these contents
        //  if/when a larger NTP refactor takes place, this should be pulled out to avoid duplication.
        
        let randomBackgroundIndex = 11 // Int.random(in: 0..<json.count)
        let backgroundJSON = json[randomBackgroundIndex]
        let center = backgroundJSON["center"] as? CGFloat ?? 0
        
        guard
            let imageName = backgroundJSON["image"] as? String,
            let image = UIImage(named: imageName) else {
                return nil
        }
        
        if let credit = backgroundJSON["credit"] as? [String: String],
            let name = credit["name"] {
            return Background(image: image, center: center, credit: (name, credit["url"]))
        }
        
        return Background(image: image, center: center, credit: nil)
    }
    
    private static func loadImageJSON(sponsored: Bool) -> [[String: Any]]? {
        let resource = "ntp-" + (sponsored ? "sponsored" : "data")
        guard let filePath = Bundle.main.path(forResource: resource, ofType: "json") else {
            return nil
        }
        
        do {
            let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let json = try JSONSerialization.jsonObject(with: fileData, options: []) as? [[String: Any]]
            return json
        } catch {
            Logger.browserLogger.error("Failed to get bundle path for \"ntp-data.json\"")
        }
        
        return nil
    }
}
