// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared

class BackgroundImage {
    
    struct Background: Decodable {
        let image: String
        /// Required instead of `CGPoint` due to x/y being optionals
        let focalPoint: FocalPoint?
        // TODO: Probably need to re-enable _somehow_
//        let isSponsored: Bool
        let credit: Credit?
        
        struct Credit: Decodable {
            let name: String
            let url: String?
        }
        
        struct FocalPoint: Decodable {
            let x: CGFloat?
            let y: CGFloat?
        }
        
        lazy var imageLiteral: UIImage? = {
            return UIImage(named: image)
        }()
    }
    
    struct Sponsor: Decodable {
        let wallpapers: [Background]
        let logo: Logo
        let dates: Dates
        
        struct Logo: Decodable {
            let image: String
            let alt: String
            let companyName: String
            let destinationUrl: String
            let regions: [String: Region]
            
            struct Region: Decodable {
                let image: String
                let alt: String
                let destinationUrl: String
            }
        }
        
        struct Dates: Decodable {
            let start: String
            let end: String
        }
    }

    // Data is static to avoid duplicate loads
    
    /// This is the number of backgrounds that must appear before a background can be repeated.
    /// So if background `3` is shown, it cannot be shown until this many backgrounds are shown, then `3` can be shown again.
    /// This does not apply to sponsored images.
    /// This is reset on each launch, so `3` can be shown again if app is removed from memory.
    /// This number _must_ be less than the number of backgrounds!
    private static let numberOfDuplicateAvoidance = 6
    private static let sponsorshipShowRate = 4 // e.g. 4 == 25% or "every 4th image"
    
    private lazy var sponsor: Sponsor? = {
        let sponsoredFilePath = "ntp-sponsored"
        guard let sponsoredData = self.loadData(file: sponsoredFilePath) else { return nil }
        // TODO: Wrap
        let sponsor = try? JSONDecoder().decode(Sponsor.self, from: sponsoredData)
        // Only set a sponsor if there are valid backgrounds
        return sponsor?.wallpapers.isEmpty == true ? nil : sponsor
    }()
    
    private lazy var standardBackgrounds: [Background] = {
        let backgroundFilePath = "ntp-data"
        guard let backgroundData = self.loadData(file: backgroundFilePath) else { return [] }
        // TODO: Wrap
        let backgrounds = try? JSONDecoder().decode([Background].self, from: backgroundData)
        return backgrounds ?? []
    }()
    
    // This is used to prevent the same handful of backgrounds from being shown.
    //  It will track the last N pictures that have been shown and prevent them from being shown
    //  until they are 'old' and dropped from this array.
    // Currently only supports normal backgrounds, as sponsored images are not supposed to be duplicate.
    // This can 'easily' be adjusted to support both sets by switching to String, and using filePath to identify uniqueness.
    private var lastBackgroundChoices = [Int]()
    
    func randomBackground() -> Background? {
        // Determine what type of background to display
        let useSponsor = Preferences.NewTabPage.backgroundSponsoredImages.value
            && sponsor != nil
            && Int.random(in: 0..<BackgroundImage.sponsorshipShowRate) == 0
        guard let dataSet = useSponsor ? sponsor?.wallpapers : standardBackgrounds else { return nil }
        if dataSet.isEmpty { return nil }
        
        let availableRange = 0..<dataSet.count
        var randomBackgroundIndex = Int.random(in: availableRange)
        if !useSponsor {
            /// This takes all indeces and filters out ones that were shown recently
            let availableBackgroundIndeces = availableRange.filter {
                !lastBackgroundChoices.contains($0)
            }
            // Chooses a new random index to use from the available indeces
            // -1 will result in a `nil` return
            randomBackgroundIndex = availableBackgroundIndeces.randomElement() ?? -1
            assert(randomBackgroundIndex >= 0, "randomBackgroundIndex was nil, this is terrible.")
            
            // This index is now added to 'past' tracking list to prevent duplicates
            lastBackgroundChoices.append(randomBackgroundIndex)
            // Trimming to fixed length to release older backgrounds
            lastBackgroundChoices = lastBackgroundChoices.suffix(BackgroundImage.numberOfDuplicateAvoidance)
        }
        
        // Item is returned based on our random index.
        // Could generally use `randomElement()`, but for non-sponsored images, certain indeces are ignored.
        return dataSet[safe: randomBackgroundIndex]
    }
    
    private func loadData(file: String) -> Data? {
        guard let filePath = Bundle.main.path(forResource: file, ofType: "json") else {
            return nil
        }
        
        do {
            let backgroundData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            return backgroundData
        } catch {
            Logger.browserLogger.error("Failed to get bundle path for \(file)")
        }
        
        return nil
    }
}
