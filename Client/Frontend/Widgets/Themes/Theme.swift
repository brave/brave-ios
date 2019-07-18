/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol Themeable {
    
    var themeableChildren: [Themeable]? { get }
    func applyTheme(_ theme: Theme)

}

extension Themeable {
    // Should be explicity done on each Themeable view, but doing this to avoid tons of compile errors
    var themeableChildren: [Themeable]? { return nil }
    
    func applyTheme(_ theme: Theme) {
        self.themeableChildren?.forEach { $0.applyTheme(theme) }
    }
}

class Theme: Equatable, Decodable {

    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ThemeCodingKeys.self)
        uuid = try container.decode(String.self, forKey: .uuid)
        title = try container.decode(String.self, forKey: .title)
        url = try container.decode(URL.self, forKey: .url)
        description = try container.decode(String.self, forKey: .description)
        thumbnail = try container.decode(URL.self, forKey: .thumbnail)
        isDark = try container.decode(Bool.self, forKey: .isDark)
        enabled = try container.decode(Bool.self, forKey: .enabled)

        colors = try container.decode(Color.self, forKey: .colors)
        images = try container.decode(Image.self, forKey: .images)
    }
    
    let uuid: String
    let title: String
    let url: URL
    let description: String
    let thumbnail: URL
    let isDark: Bool
    let enabled: Bool
    
    let colors: Color
    struct Color: Decodable {
        
        init(from decoder: Decoder) throws {
            
            let container = try decoder.container(keyedBy: ThemeCodingKeys.ColorCodingKeys.self)
            let headerStr = try container.decode(String.self, forKey: .header)
            let footerStr = try container.decode(String.self, forKey: .footer)
            let homeStr = try container.decode(String.self, forKey: .home)
            let addressBarStr = try container.decode(String.self, forKey: .addressBar)
            let borderStr = try container.decode(String.self, forKey: .border)

            header = UIColor(colorString: headerStr)
            footer = UIColor(colorString: footerStr)
            home = UIColor(colorString: homeStr)
            addressBar = UIColor(colorString: addressBarStr)
            border = UIColor(colorString: borderStr)
            
            stats = try container.decode(Stat.self, forKey: .stats)
            tints = try container.decode(Tint.self, forKey: .tints)
        }
        
        let header: UIColor
        let footer: UIColor
        let home: UIColor
        let addressBar: UIColor
        let border: UIColor
        
        let stats: Stat
        struct Stat: Decodable {
            init(from decoder: Decoder) throws {

                let container = try decoder.container(keyedBy: ThemeCodingKeys.ColorCodingKeys.StatCodingKeys.self)
                let adsStr = try container.decode(String.self, forKey: .ads)
                let trackersStr = try container.decode(String.self, forKey: .trackers)
                let httpseStr = try container.decode(String.self, forKey: .httpse)
                let timeSavedStr = try container.decode(String.self, forKey: .timeSaved)

                ads = UIColor(colorString: adsStr)
                trackers = UIColor(colorString: trackersStr)
                httpse = UIColor(colorString: httpseStr)
                timeSaved = UIColor(colorString: timeSavedStr)
            }

            let ads: UIColor
            let trackers: UIColor
            let httpse: UIColor
            let timeSaved: UIColor
        }
        
        let tints: Tint
        struct Tint: Decodable {
            init(from decoder: Decoder) throws {

                let container = try decoder.container(keyedBy: ThemeCodingKeys.ColorCodingKeys.TintCodingKeys.self)
                let homeStr = try container.decode(String.self, forKey: .home)
                let headerStr = try container.decode(String.self, forKey: .header)
                let footerStr = try container.decode(String.self, forKey: .footer)
                let addressBarStr = try container.decode(String.self, forKey: .addressBar)

                home = UIColor(colorString: homeStr)
                header = UIColor(colorString: headerStr)
                footer = UIColor(colorString: footerStr)
                addressBar = UIColor(colorString: addressBarStr)
            }

            let home: UIColor
            let header: UIColor
            let footer: UIColor
            let addressBar: UIColor
        }
    }
    
    let images: Image
    struct Image: Decodable {
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ThemeCodingKeys.ImageCodingKeys.self)
            header = try container.decode(URL.self, forKey: .header)
            footer = try container.decode(URL.self, forKey: .footer)
            home = try container.decode(URL.self, forKey: .home)
        }

        let header: URL
        let footer: URL
        let home: URL
    }
    
    lazy var available: [Theme] = {
        return [Theme.regular, Theme.private]
    }()
    
    /// Textual representation suitable for debugging.
    var debugDescription: String {
        return description
    }

    /// Returns whether the theme is private or not.
    var isPrivate: Bool {
        switch self {
        case Theme.regular:
            return false
        case Theme.private:
            return true
        default:
            return true
        }
    }
    
    /// Returns the theme of the given Tab, if the tab is nil returns a regular theme.
    ///
    /// - parameter tab: An object representing a Tab.
    /// - returns: A Tab theme.
    static func of(_ tab: Tab?) -> Theme {
        if let tab = tab {
            switch TabType.of(tab) {
            case .regular:
                return .regular
            case .private:
                return .private

            }
        }
        return PrivateBrowsingManager.shared.isPrivateBrowsing ? .private : .regular
    }
    
    // Maybe wrap in a `mode` struct, however, most UI will only care about theme.data
    /// Regular browsing.
    static let regular: Theme = {
        let themeData = normalTheme().data(using: String.Encoding.utf8)!
        return try! JSONDecoder().decode(Theme.self, from: themeData)
    }()
    
    /// Private browsing.
    static let `private`: Theme = {
        let themeData = privateTheme().data(using: String.Encoding.utf8)!
        return try! JSONDecoder().decode(Theme.self, from: themeData)
    }()
    
    static func == (lhs: Theme, rhs: Theme) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

private extension Theme {
    
    static func normalTheme() -> String {
        return """
        
        {
        "uuid": "FAIDSFJELWEF",
        "title": "Default light",
        "url": "www.brave.com",
        "description": "The standard default light theme",
        "thumbnail": "https://www.google.com",
        "isDark": false,
        "enabled": true,
        
        "colors": {
        "header": "0xffffff",
        "footer": "0xffffff",
        "home": "0xffffff",
        "addressBar": "0xD7D7E0",
        "border": "0x000000",
        "tints": {
        "home": "0x434351",
        "header": "0x434351",
        "footer": "0x434351",
        "addressBar": "0x434351"
        },
        "transparencies": {
        "addressBarAlpha": 1.0,
        "borderAlpha": 0.2,
        },
        "stats": {
        "ads": "0xFA4214",
        "trackers": "0xFA4214",
        "httpse": "0x9339D4",
        "timeSaved": "0x222326"
        }
        },
        "images": {
        "header": "https://www.google.com",
        "footer": "https://www.google.com",
        "home": "https://www.google.com",
        }
        }


        
        """
    }
    
    static func privateTheme() -> String {
        return """

        {
        "uniqueKey": "382",
        "description": "Default private theme"
        }

        """
    }
}

fileprivate enum ThemeCodingKeys: String, CodingKey {
    case uuid
    case title
    case url
    case description
    case thumbnail
    case isDark
    case enabled
    
    case colors
    enum ColorCodingKeys: String, CodingKey {
        case header
        case footer
        case home
        case addressBar
        case border
        
        case tints
        enum TintCodingKeys: String, CodingKey {
            case home
            case header
            case footer
            case addressBar
        }
        
        case transparencies
        enum TransparencyCodingKeys: String, CodingKey {
            case addressBarAlpha
            case borderAlpha
        }
        
        case stats
        enum StatCodingKeys: String, CodingKey {
            case ads
            case trackers
            case httpse
            case timeSaved
        }
    }
    
    case images
    enum ImageCodingKeys: String, CodingKey {
        case header
        case footer
        case home
    }
}

/**
 
 {
 "title": "Rust",
 "url": "", // Creator url
 "description": "", // Any details or information about theme -user facing
 "thumb": "Rust", // Theme manager thumb, can be url/uri
 "isDark": false, // Simple flag for dark or light type themes
 "enabled": true, // Displays in theme manager
 
 "colors": {
 "header": "0xffffff",
 "footer": "0xffffff",
 "home": "0xffffff",
 "addressBar": "0xE2591F", // address bar bg
 "border": "0xE2591F", // header and footer border color
 "tints": {
 "home": "0xE2591F",
 "header": "0xE2591F", // Icon tint
 "footer": "0xE2591F", // Icon tint
 "addressBar": "0xE2591F" // Inner url bar icon tint and font color
 },
 "transparencies": {
 "addressBarAlpha": 0.2, // address bar bg alpha (allows blending to background)
 "borderAlpha": 0.2, // header and footer border alpha (allows blending)
 },
 "stats": {
 "ads": "0xE2591F", // color for ads label on home screen
 "trackers": "0xE2591F", // color for trackers label on home screen
 "httpse": "0xE2591F", // color for httpse upgrades on home screen
 "timeSaved": "0xE2591F" // color for time saved label on home screen
 }
 },
 "images": {
 "header": "",
 "footer": "",
 "home": "", // Background image can be url/uri
 }
 }
 
 */
