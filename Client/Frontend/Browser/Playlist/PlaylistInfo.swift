// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared

private let log = Logger.browserLogger

struct PlaylistYTInfo: Codable {
    let videoId: String
    let title: String
    let hlsManifestUrl: String?
    let lengthSeconds: String
    let expiresInSeconds: String
    let formats: [Format]
    let captionTracks: [CaptionTrack]?
    let translationLanguages: [TranslationLanguage]?
    
    // If there are no captions natively available, we can possibly ask the API to provide the translated ones with the URL below..
    // Though, it might just be better to disable captions if none are provided..
    static let defaultCaptionsBaseUrl = "https://www.youtube.com/api/timedtext?v={VIDEO_ID}\\u0026sparams=v\\u0026key=yt8\\u0026lang={LANGUAGE_CODE}\\u0026tlang={TRANSLATED_LANGUAGE}"
    
    struct Format: Codable {
        let url: String?
        let mimeType: String
        let quality: String
        let qualityLabel: String
        let signatureCipher: String?
    }
    
    struct CaptionTrack: Codable {
        let baseUrl: String
        let name: Name?
        let vssId: String?
        let languageCode: String
    }
    
    struct TranslationLanguage: Codable {
        let languageName: Name?
        let languageCode: String
    }
    
    struct Name: Codable {
        let name: String
        private let key: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            var name: String?
            var key: String?
            [CodingKeys.text, CodingKeys.simpleText, CodingKeys.languageName, CodingKeys.name].forEach({
                if let decodedName = try? container.decodeIfPresent(String.self, forKey: $0) {
                    name = decodedName
                    key = $0.rawValue
                }
            })
            
            self.name = name ?? ""
            self.key = key ?? CodingKeys.simpleText.rawValue
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.name, forKey: CodingKeys(rawValue: self.key)!)
        }
        
        private enum CodingKeys: String, CodingKey {
            case text
            case simpleText
            case languageName
            case name
        }
    }
}

struct PlaylistInfo: Codable {
    let name: String
    let src: String
    let pageSrc: String
    let pageTitle: String
    let mimeType: String
    let duration: Float
    let detected: Bool
    let ytInfo: PlaylistYTInfo?
    
    init(item: PlaylistItem) {
        self.name = item.name ?? ""
        self.src = item.mediaSrc ?? ""
        self.pageSrc = item.pageSrc ?? ""
        self.pageTitle = item.pageTitle ?? ""
        self.mimeType = item.mimeType ?? ""
        self.duration = item.duration
        self.detected = false
        
        if let other = item.other, let ytInfo = try? JSONDecoder().decode(PlaylistYTInfo.self, from: other) {
            self.ytInfo = ytInfo
        } else {
            self.ytInfo = nil
        }
    }
    
    init(name: String, src: String, pageSrc: String, pageTitle: String, mimeType: String, duration: Float, detected: Bool, ytInfo: PlaylistYTInfo?) {
        self.name = name
        self.src = src
        self.pageSrc = pageSrc
        self.pageTitle = pageTitle
        self.mimeType = mimeType
        self.duration = duration
        self.detected = detected
        self.ytInfo = ytInfo
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
        
        do {
            self.ytInfo = try container.decode(PlaylistYTInfo.self, forKey: .ytInfo)
        } catch {
            print(error)
            self.ytInfo = nil
        }
    }
    
    func getYtInfoEncoded() -> Data? {
        if let ytInfo = self.ytInfo {
            return try? JSONEncoder().encode(ytInfo)
        }
        return nil
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
        case ytInfo
    }
}
