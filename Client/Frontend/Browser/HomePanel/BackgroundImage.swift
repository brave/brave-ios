// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared

class BackgroundImage {
    
    struct Background {
        let imageFileName: String
        let center: CGFloat
        let credit: (name: String, url: String?)?
        
        lazy var image: UIImage? = {
            return UIImage(named: imageFileName)
        }()
    }

    // Data is static to avoid duplicate loads
    
    let info: Background?
    static var hasSponsor: Bool { sponsors?.count ?? 0 > 0 }
    private static var sponsors: [Background]?
    private static var standardBackgrounds: [Background]?
    
    init(sponsoredFilePath: String = "ntp-sponsored", backgroundFilePath: String = "ntp-data") {
        
        if !Preferences.NewTabPage.backgroundImages.value {
            // Do absolutely nothing
            self.info = nil
            return
        }
        
        // Setting up normal backgrounds
        if BackgroundImage.standardBackgrounds == nil {
            BackgroundImage.standardBackgrounds = BackgroundImage.generateStandardData(file: backgroundFilePath)
        }
        
        // Setting up sponsored backgrounds
        if BackgroundImage.sponsors == nil && Preferences.NewTabPage.backgroundSponsoredImages.value {
            BackgroundImage.sponsors = BackgroundImage.generateSponsoredData(file: sponsoredFilePath)
        }
        
        self.info = BackgroundImage.randomBackground()
    }
    
    private static func generateSponsoredData(file: String) -> [Background] {
        guard let json = BackgroundImage.loadImageJSON(file: file),
            let region = NSLocale.current.regionCode else {
                return []
        }
        
        let dateFormatter = DateFormatter().then {
            $0.locale = Locale(identifier: "en_US_POSIX")
            $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            $0.calendar = Calendar(identifier: .gregorian)
        }
        
        let today = Date()
        // Filter down to only regional supported items
        let regionals = json.filter { ($0["regions"] as? [String])?.contains(region) == true }
        
        // Filter down to sponsors that fit the date requirements
        let live = regionals.filter { item in
            guard let dates = item["dates"] as? [String: String],
                let start = dateFormatter.date(from: dates["start"] ?? ""),
                let end = dateFormatter.date(from: dates["end"] ?? "") else {
                    return false
            }
            
            return today > start && today < end
        }
        
        return generateBackgroundData(data: live)
    }
    
    private static func generateStandardData(file: String) -> [Background] {
        guard let json = BackgroundImage.loadImageJSON(file: file) else { return [] }
        return generateBackgroundData(data: json)
    }
    
    private static func generateBackgroundData(data: [[String: Any]]) -> [Background] {
        return data.compactMap { item in
            guard let image = item["image"] as? String,
                let center = item["center"] as? CGFloat else { return nil }
            
            if let credit = item["credit"] as? [String: String],
                let name = credit["name"] {
                return Background(imageFileName: image, center: center, credit: (name, credit["url"]))
            }
            
            return Background(imageFileName: image, center: center, credit: nil)
        }
    }
    
    private static func randomBackground() -> Background? {
        // Determine what type of background to display
        let sponsorshipShowRate = 4 // e.g. 4 == 25%
        let useSponsor = hasSponsor && Int.random(in: 0..<sponsorshipShowRate) == 0
        guard let dataSet = useSponsor ? sponsors : standardBackgrounds else { return nil }
        if dataSet.count == 0 { return nil }
        
        let randomBackgroundIndex = Int.random(in: 0..<dataSet.count)
        return dataSet[randomBackgroundIndex]
    }
    
    private static func loadImageJSON(file: String) -> [[String: Any]]? {
        guard let filePath = Bundle.main.path(forResource: file, ofType: "json") else {
            return nil
        }
        
        do {
            let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let json = try JSONSerialization.jsonObject(with: fileData, options: []) as? [[String: Any]]
            return json
        } catch {
            Logger.browserLogger.error("Failed to get bundle path for \(file)")
        }
        
        return nil
    }
}
