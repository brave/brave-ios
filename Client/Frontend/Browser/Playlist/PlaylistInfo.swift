// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared

private let log = Logger.browserLogger

struct PlaylistInfo: Codable {
    let name: String
    let src: String
    let pageSrc: String
    let pageTitle: String
    let mimeType: String
    let duration: Float
    let detected: Bool
    
    init(item: PlaylistItem) {
        self.name = item.name ?? ""
        self.src = item.mediaSrc ?? ""
        self.pageSrc = item.pageSrc ?? ""
        self.pageTitle = item.pageTitle ?? ""
        self.mimeType = item.mimeType ?? ""
        self.duration = item.duration
        self.detected = false
    }
    
    init(name: String, src: String, pageSrc: String, pageTitle: String, mimeType: String, duration: Float, detected: Bool) {
        self.name = name
        self.src = src
        self.pageSrc = pageSrc
        self.pageTitle = pageTitle
        self.mimeType = mimeType
        self.duration = duration
        self.detected = detected
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = (try? container.decode(String.self, forKey: .name)) ?? ""
        self.src = (try? container.decode(String.self, forKey: .src)) ?? ""
        self.pageSrc = (try? container.decode(String.self, forKey: .pageSrc)) ?? ""
        self.pageTitle = (try? container.decode(String.self, forKey: .pageTitle)) ?? ""
        self.mimeType = (try? container.decode(String.self, forKey: .mimeType)) ?? ""
        self.duration = (try? container.decode(Float.self, forKey: .duration)) ?? 0.0
        self.detected = (try? container.decode(Bool.self, forKey: .detected)) ?? false
    }
    
    static func from(message: WKScriptMessage) -> PlaylistInfo? {
        if !JSONSerialization.isValidJSONObject(message.body) {
            return nil
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: message.body, options: [.fragmentsAllowed])
            return try JSONDecoder().decode(PlaylistInfo.self, from: data)
        } catch {
            log.error("Error Decoding PlaylistInfo: \(error)")
        }
        
        return nil
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case src
        case pageSrc
        case pageTitle
        case mimeType
        case duration
        case detected
    }
}
