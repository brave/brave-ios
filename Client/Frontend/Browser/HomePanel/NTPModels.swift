// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

protocol NTPBackgroundProtocol {
    /// Wallpapers to show on new tab page.
    var wallpapers: [NTPBackground] { get }
    /// Brand's logo to show on new tab page.
    var logo: NTPLogo? { get }
}

/// This is for conformance only. At the moment it's basically the same as `NTPBackgroundProtocol`,
/// but in the future we might add custom NTP theming that doesn't change background images.
protocol NTPThemeable {}

struct NTPSponsor: Codable, NTPBackgroundProtocol, NTPThemeable {
    let wallpapers: [NTPBackground]
    var logo: NTPLogo?
}

/// A background image that can be showed on new tab page.
/// A class instead of a struct since it includes a mutating property (`image`). If a struct this will lead to any `willSet` / `didSet`
///     observers being called again, since the struct instance will have been mutated.
class NTPBackground: Codable {
    let imageUrl: String
    
    /// Required instead of `CGPoint` due to x/y being optionals
    let focalPoint: FocalPoint?
    
    /// Only available for normal wallpapers, not for sponsored images
    let credit: Credit?
    
    /// Whether the background is a packaged resource or a remote one, impacts how it should be loaded
    let packaged: Bool?
    
    init(imageUrl: String, focalPoint: FocalPoint?) {
        self.imageUrl = imageUrl
        self.focalPoint = focalPoint
        self.credit = nil
        self.packaged = nil
    }
    
    struct Credit: Codable {
        let name: String
        let url: String?
    }
    
    struct FocalPoint: Codable {
        let x: CGFloat?
        let y: CGFloat?
    }
    
    lazy var image: UIImage? = {
        // Remote resources are downloaded files, so must be loaded differently
        packaged == true ? UIImage(named: imageUrl) : UIImage(contentsOfFile: imageUrl)
    }()
}

struct NTPLogo: Codable {
    let imageUrl: String
    let alt: String
    let companyName: String
    /// Url to take the user to after the logo is tapped.
    let destinationUrl: String
    
    lazy var image: UIImage? = {
        UIImage(contentsOfFile: imageUrl)
    }()
}
