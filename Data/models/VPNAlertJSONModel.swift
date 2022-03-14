// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public struct VPNAlertJSONModel: Decodable {
    public enum Action: Int {
        case drop
        case detected
    }
    
    public enum Category: Int {
        case privacyTrackerAppLocation
        case privacyTrackerApp
        case privacyTrackerMail
    }
    
    enum CodingKeys: String, CodingKey {
        case uuid, action, category, host, message, timestamp, title
    }
    
    public let uuid: String
    public let action: Action
    public let category: Category
    public let host: String
    public let message: String
    public let timestamp: Date
    public let title: String
    
    public init(from decoder: Decoder) throws {
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
        case "privacy-tracker-mail":
            self.category = .privacyTrackerMail
        case "privacy-tracker-app-location":
            self.category = .privacyTrackerAppLocation
        case "privacy-tracker-app":
            self.category = .privacyTrackerApp
        default:
            throw "Casting `category` failed, incorrect value: \(categoryString)"
        }
    }
}
