// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct VPNAlertModel: Decodable {
    enum Action: Int {
        case drop
    }
    
    enum Category: Int {
        case securityPhishing
        case privacyTrackerAppLocation
        case privacyTrackerApp
        case encryptionAllowInvalidHttps
        case adsAggresive
    }
    
    enum CodingKeys: String, CodingKey {
        case uuid, action, category, host, message, timestamp, title
    }
    
    let uuid: String
    let action: Action
    let category: Category
    let host: String
    let message: String
    let timestamp: Date
    let title: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.host = try container.decode(String.self, forKey: .host)
        self.message = try container.decode(String.self, forKey: .message)
        self.title = try container.decode(String.self, forKey: .title)
        
        let timestampInt = try container.decode(Int.self, forKey: .timestamp)
        self.timestamp = Date(timeIntervalSince1970: TimeInterval(timestampInt))
        
        let actionString = try container.decode(String.self, forKey: .action)
        switch actionString {
        case "drop":
            self.action = .drop
        default:
            throw "Casting `action` failed, incorrect value: \(actionString)"
        }
        
        let categoryString = try container.decode(String.self, forKey: .category)
        switch categoryString {
        case "security-phishing":
            self.category = .securityPhishing
        case "privacy-tracker-app-location":
            self.category = .privacyTrackerAppLocation
        case "privacy-tracker-app":
            self.category = .privacyTrackerApp
        case "encryption-allows-invalid-https":
            self.category = .encryptionAllowInvalidHttps
        case "ads/aggressive":
            self.category = .adsAggresive
        default:
            throw "Casting `category` failed, incorrect value: \(categoryString)"
        }
    }
}
