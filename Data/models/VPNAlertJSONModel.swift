// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public struct VPNAlertJSONModel: Decodable {
    public enum Action: Int {
        case drop
        case log
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
    public let timestamp: Int64
    public let title: String
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.uuid = try container.decode(String.self, forKey: .uuid)
        
        let hostString = try container.decode(String.self, forKey: .host)
        
        // If possible we only add the base domain part of the host.
        // Reason is we do the same for regular ad blocking resources
        // This makes it easier to group together and show total counts for vpn + regular blocked resources.
        self.host = URL(string: "https://" + hostString)?.baseDomain ?? hostString
        self.message = try container.decode(String.self, forKey: .message)
        self.title = try container.decode(String.self, forKey: .title)
        
        let decodedTimestamp = Int64(try container.decode(Int.self, forKey: .timestamp))
        
        // The VPN alerts array we receive is pretty spammy.
        // In order to avoid having many duplicates 'seconds' are cleared from the timestamp.
        self.timestamp = decodedTimestamp - decodedTimestamp % 60
        
        let actionString = try container.decode(String.self, forKey: .action)
        switch actionString {
        case "drop":
            self.action = .drop
        case "log":
            self.action = .log
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
