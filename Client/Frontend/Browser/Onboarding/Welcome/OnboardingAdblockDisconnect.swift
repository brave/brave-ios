// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared

private let log = Logger.browserLogger

struct OnboardingDisconnectItem: Codable {
    let properties: [String]
    let resources: [String]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        properties = try container.decode([String].self, forKey: .properties)
        resources = try container.decode([String].self, forKey: .resources)
    }
    
    private enum CodingKeys: String, CodingKey {
        case properties
        case resources
    }
}

struct OnboardingDisconnectList: Decodable {
    let license: String
    let entities: [String: OnboardingDisconnectItem]
    
    static func loadFromFile() -> OnboardingDisconnectList? {
        do {
            if let path = Bundle.main.path(forResource: "disconnect-entitylist", ofType: "json"),
               let contents = try String(contentsOfFile: path).data(using: .utf8) {
                return try JSONDecoder().decode(OnboardingDisconnectList.self, from: contents)
            }
        } catch {
            log.error("Error Decoding OnboardingDisconectList: \(error)")
        }
        return nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let childContainer = try container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .entities)

        license = try container.decode(String.self, forKey: .license)
        var entities = [String: OnboardingDisconnectItem]()

        for key in childContainer.allKeys {
            guard let codingKey = AnyCodingKey(stringValue: key.stringValue) else {
                throw NSError()
            }

            let entity = try childContainer.decode(OnboardingDisconnectItem.self, forKey: codingKey)
            entities[key.stringValue] = entity
        }

        self.entities = entities
    }
    
    private enum CodingKeys: String, CodingKey {
        case license
        case entities
    }
    
    private struct AnyCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = Int(stringValue)
        }
        
        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = String(intValue)
        }
    }
}
