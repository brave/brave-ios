/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ codingKey: CodingKey) {
        self.stringValue = codingKey.stringValue
        self.intValue = codingKey.intValue
    }

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

private struct SearchDefaultLocale: Codable {
    let visibleDefaultEngines: [String]?
    let searchDefault: String?
}

private struct SearchLocale: Codable {
    let visibleDefaultEngines: [String]?
    let searchDefault: SearchDefaultLocale?
    let regions: [String: SearchDefaultLocale]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        visibleDefaultEngines = try container.decodeIfPresent([String].self, forKey: AnyCodingKey(stringValue: "visibleDefaultEngines"))
        searchDefault = try container.decodeIfPresent(SearchDefaultLocale.self, forKey: AnyCodingKey(stringValue: "searchDefault"))

        var subLocale = [String: SearchDefaultLocale]()
        for key in container.allKeys {
            if let value = try? container.decode(SearchDefaultLocale.self, forKey: key) {
                subLocale[key.stringValue] = value
            }
        }

        self.regions = subLocale.isEmpty ? nil : subLocale
    }
}

private struct SearchPluginList: Codable {
    let allLocales: SearchLocale
    let `default`: SearchDefaultLocale
    let locales: [String: SearchLocale]
    let regionOverrides: [String: [String: String]]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        allLocales = try container.decode(SearchLocale.self, forKey: .allLocales)
        `default` = try container.decode(SearchDefaultLocale.self, forKey: .default)
        locales = try container.decode([String: SearchLocale].self, forKey: .locales)
        regionOverrides = try container.decode([String: [String: String]].self, forKey: .regionOverrides)
    }
}

/*
 This only makes sense if you look at the structure of List.json
*/
class DefaultSearchPrefs {
    fileprivate let defaultSearchList: [String]
    fileprivate let allLocalesSearchList: [String]
    fileprivate let locales: [String: SearchLocale]
    fileprivate let regionOverrides: [String: [String: String]]
    fileprivate let globalDefaultEngine: String

    public init?(with filePath: URL) {
        guard let searchManifest = try? Data(contentsOf: filePath) else {
            assertionFailure("Search list not found. Check bundle")
            return nil
        }

        guard let json = try? JSONDecoder().decode(SearchPluginList.self, from: searchManifest) else {
            assertionFailure("Cannot parse List.json")
            return nil
        }

        // Split up the JSON into useful parts
        locales = json.locales
        regionOverrides = json.regionOverrides

        // These are the fallback defaults
        guard let searchList = json.default.visibleDefaultEngines, let engine = json.default.searchDefault else {
            assertionFailure("Defaults are not set up correctly in List.json")
            return nil
        }
        defaultSearchList = searchList

        // These are to be used by all locales
        guard let allLocalesSearchList = json.allLocales.visibleDefaultEngines else {
            assertionFailure("All locales are not set up correctly in List.json")
            return nil
        }
        self.allLocalesSearchList = allLocalesSearchList

        globalDefaultEngine = engine
    }

    /*
     Returns an array of the visibile engines. It overrides any of the returned engines from the regionOverrides list
     Each langauge in the locales list has a default list of engines and then a region override list.
     */
    open func visibleDefaultEngines(locales: [String], region: String, selected: [String] = []) -> [String] {
        let engineList = locales.compactMap({
            self.locales[$0]
        }).compactMap({
            $0.regions?[region]?.visibleDefaultEngines ?? $0.regions?["default"]?.visibleDefaultEngines
        }).last?.compactMap({ $0 })

        // If the engineList is empty then go ahead and use the default
        var usersEngineList = engineList ?? defaultSearchList

        // Append "all locales" search engines to the users engine list
        usersEngineList += allLocalesSearchList
        
        // Append preferences
        usersEngineList += engineNames(fromShortNames: selected)

        // Overrides for specfic regions.
        if let overrides = regionOverrides[region] {
            usersEngineList = usersEngineList.map({ overrides[$0] ?? $0 })
        }
        
        return usersEngineList.unique { $0 == $1 }
    }
    
    private func engineNames(fromShortNames shortNames: [String]) -> [String] {
        guard let path = Bundle.main.path(forResource: "ShortNameToFileMapping", ofType: "json") else {
            assertionFailure("Search list not found. Check bundle")
            return []
        }
        
        do {
            let filePath = URL(fileURLWithPath: path)
            let jsonData = try Data(contentsOf: filePath)
            let mappings = try JSONDecoder().decode([String: String].self, from: jsonData)
            return shortNames.compactMap { mappings[$0] }
        } catch {
            // Fail silently, nothing needed for recovery here really
        }
        
        return []
    }

    /*
     Returns the default search given the possible locales and region
     The list.json locales list contains searchDefaults for a few locales.
     Create a list of these and return the last one. The globalDefault acts as the fallback in case the list is empty.
     */
    open func searchDefault(for possibleLocales: [String], and region: String) -> String {
        return possibleLocales.compactMap({
            locales[$0]
        }).reduce(globalDefaultEngine) { defaultEngine, locale -> String in
            return locale.regions?[region]?.searchDefault ?? defaultEngine
        }
    }
}
