/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import BraveShared

protocol Themeable {
    
    var themeableChildren: [Themeable?]? { get }
    func applyTheme(_ theme: Theme)

}

extension Themeable {
    // TODO: Remove, should be explicity done on each Themeable view, but doing this to avoid tons of compile errors
    var themeableChildren: [Themeable?]? { return nil }
    
    func applyTheme(_ theme: Theme) {
        styleChildren(theme: theme)
    }
    
    func styleChildren(theme: Theme) {
        self.themeableChildren?.forEach { $0?.applyTheme(theme) }
    }
}

class Theme: Equatable, Decodable {
    
    enum DefaultTheme: String, CaseIterable, RepresentableOptionType {
        case system = "Z71ED37E-EC3E-436E-AD5F-B22748306A6B"
        case light = "ACE618A3-D6FC-45A4-94F2-1793C40AE927"
        case dark = "B900A41F-2C02-4664-9DE4-C170956339AC"
        case `private` = "C5CB0D9A-5467-432C-AB35-1A78C55CFB41"
        
        // TODO: Theme: Remove with `rawValue`
        var id: String {
            return self.rawValue
        }
        
        var theme: Theme {
           return Theme.from(id: self.id)
        }
        
        static var normalThemes: [Theme] {
            return [DefaultTheme.light.theme, DefaultTheme.dark.theme].compactMap { $0 }
        }
        
        public var displayString: String {
            if self == .system {
                return "System Theme"
            }
            return self.theme.title
        }
    }
    
    fileprivate static let ThemeDirectory = Bundle.main.resourceURL!.appendingPathComponent("Themes")

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
            let accentStr = try container.decode(String.self, forKey: .accent)

            header = UIColor(colorString: headerStr)
            footer = UIColor(colorString: footerStr)
            home = UIColor(colorString: homeStr)
            addressBar = UIColor(colorString: addressBarStr)
            border = UIColor(colorString: borderStr)
            accent = UIColor(colorString: accentStr)
            
            stats = try container.decode(Stat.self, forKey: .stats)
            tints = try container.decode(Tint.self, forKey: .tints)
            transparencies = try container.decode(Transparency.self, forKey: .transparencies)
        }
        
        let header: UIColor
        let footer: UIColor
        let home: UIColor
        let addressBar: UIColor
        let border: UIColor
        let accent: UIColor
        
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
        
        let transparencies: Transparency
        struct Transparency: Decodable {
            let addressBarAlpha: CGFloat
            let borderAlpha: CGFloat
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

    // This should be removed probably
    /// Returns whether the theme is private or not.
    var isPrivate: Bool {
        return self.isDark
    }
    
    /// Returns the theme of the given Tab, if the tab is nil returns a regular theme.
    ///
    /// - parameter tab: An object representing a Tab.
    /// - returns: A Tab theme.
    static func of(_ tab: Tab?) -> Theme {
        guard let tab = tab else {
            // TODO: Theme: Fix this
            return PrivateBrowsingManager.shared.isPrivateBrowsing ? .private : .regular
        }
        
        let themeType = { () -> Preferences.Option<String> in
            switch TabType.of(tab) {
            case .regular:
                return Preferences.General.themeNormalMode
            case .private:
                return Preferences.General.themePrivateMode
            }
        }()
        
        let chosenTheme = DefaultTheme(rawValue: themeType.value)
        return chosenTheme?.theme ?? DefaultTheme.system.theme
    }
    
    static var themeMemoryBank: [String: Theme] = [:]
    static func from(id: String) -> Theme {
        var id = id
        if id == DefaultTheme.system.id {
            // TODO: Pull system default, not 'light' necessarily
            id = DefaultTheme.light.id
        }
        
        if let inMemoryTheme = themeMemoryBank[id] {
            return inMemoryTheme
        }
        
        let themePath = Theme.ThemeDirectory.appendingPathComponent(id).appendingPathExtension("json").path
        guard
            let themeData = FileManager.default.contents(atPath: themePath),
            let theme = try? JSONDecoder().decode(Theme.self, from: themeData) else {
                // TODO: Theme: Maybe throw error, but fallback to `system` / default / light
                fatalError("Theme file not found for: \(id)... no good")
        }
        
        themeMemoryBank[id] = theme
        return theme
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
    
    static let allThemes: [Theme] = {
        do {
            let filenames = try FileManager.default.contentsOfDirectory(at: Theme.ThemeDirectory, includingPropertiesForKeys: [])
            
            let final = filenames.filter {
                $0.pathExtension == "json"
            }.compactMap { fullPath -> Theme? in
                var path = fullPath.lastPathComponent
                path.removeLast(5) // Removing JSON extension
                return try? Theme.from(id: path)
            }.filter {
                $0.enabled
            }
            
            return final
        } catch {
            fatalError("`Themes` directory is not available!")
        }
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
        "accent": "0xccdded",
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
        "uuid": "FAIDSFJELWEF3",
        "title": "Default private",
        "url": "www.brave.com",
        "description": "The standard default private theme",
        "thumbnail": "https://www.google.com",
        "isDark": true,
        "enabled": true,
        
        "colors": {
        "header": "0x1B0C32",
        "footer": "0x1B0C32",
        "home": "0x210950",
        "addressBar": "0x3D2742",
        "border": "0xffffff",
        "accent": "0xcf68ff",
        "tints": {
        "home": "0xE7E6E9",
        "header": "0xE7E6E9",
        "footer": "0xE7E6E9",
        "addressBar": "0xE7E6E9"
        },
        "transparencies": {
        "addressBarAlpha": 1.0,
        "borderAlpha": 0.2,
        },
        "stats": {
        "ads": "0xFA4214",
        "trackers": "0xFA4214",
        "httpse": "0x9339D4",
        "timeSaved": "0xffffff"
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
        case accent
        
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
