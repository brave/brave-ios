// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

enum ThreatType: String, Codable, CaseIterable {
    case unspecified = "THREAT_TYPE_UNSPECIFIED"
    case malware = "MALWARE"
    case socialEngineering = "SOCIAL_ENGINEERING"
    case unwantedSoftware = "UNWANTED_SOFTWARE"
    case potentiallyHarmfulApplication = "POTENTIALLY_HARMFUL_APPLICATION"
}

enum PlatformType: String, Codable, CaseIterable {
    case unknown = "PLATFORM_TYPE_UNSPECIFIED"
    case ios = "IOS"
    case `any` = "ANY_PLATFORM"
    case all = "ALL_PLATFORMS"
}

enum ThreatEntryType: String, Codable, CaseIterable {
    case unspecified = "THREAT_ENTRY_TYPE_UNSPECIFIED"
    case url = "URL"
    case exe = "EXECUTABLE"
}

enum CompressionType: String, Codable, CaseIterable {
    case unspecified = "COMPRESSION_TYPE_UNSPECIFIED"
    case raw = "RAW"
    case rice = "RICE"
}

enum ResponseType: String, Codable, CaseIterable {
    case unspecified = "RESPONSE_TYPE_UNSPECIFIED"
    case partialUpdate = "PARTIAL_UPDATE"
    case fullUpdate = "FULL_UPDATE"
}

struct ClientInfo: Codable {
    let clientId: String
    let clientVersion: String
}

struct Constraints: Codable {
    let maxUpdateEntries: UInt32?
    let maxDatabaseEntries: UInt32?
    let region: String
    let supportedCompressions: [CompressionType]
    let language: String?
    let deviceLocation: String?
}

struct ListUpdateRequest: Codable {
    let threatType: ThreatType
    let platformType: PlatformType
    let threatEntryType: ThreatEntryType
    let state: String
    let constraints: Constraints
}

struct RawHashes: Codable {
    let prefixSize: UInt8
    let rawHashes: String
}

struct RawIndices: Codable {
    let indices: [UInt32]
}

struct RiceDeltaEncoding: Codable {
    let firstValue: String
    let riceParameter: UInt8
    let numEntries: UInt32
    let encodedData: String
}

struct ThreatEntrySet: Codable {
    let compressionType: CompressionType
    let rawHashes: RawHashes?
    let rawIndices: RawIndices?
    let riceHashes: RiceDeltaEncoding?
    let riceIndices: RiceDeltaEncoding?
}

struct ThreatEntry: Codable {
    let hash: String?
    let url: String?
    let digest: String?
}

struct ThreatInfo: Codable {
    let threatTypes: [ThreatType]
    let platformTypes: [PlatformType]
    let threatEntryTypes: [ThreatEntryType]
    let threatEntries: [ThreatEntry]
}

struct MetadataEntry: Codable {
    let key: String
    let value: String
}

struct ThreatEntryMetadata: Codable {
    let entries: [MetadataEntry]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.entries = try container.decodeIfPresent([MetadataEntry].self, forKey: .entries) ?? []
    }
}

struct ThreatMatch: Codable {
    let threatType: ThreatType
    let platformType: PlatformType
    let threatEntryType: ThreatEntryType
    let threat: ThreatEntry
    let threatEntryMetadata: ThreatEntryMetadata?
    let cacheDuration: String
}

struct Checksum: Codable {
    let sha256: String
}

struct ListUpdateResponse: Codable {
    let threatType: ThreatType
    let threatEntryType: ThreatEntryType
    let platformType: PlatformType
    let responseType: ResponseType
    let additions: [ThreatEntrySet]
    let removals: [ThreatEntrySet]
    let newClientState: String
    let checksum: Checksum
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.threatType = try container.decode(ThreatType.self, forKey: .threatType)
        self.threatEntryType = try container.decode(ThreatEntryType.self, forKey: .threatEntryType)
        self.platformType = try container.decode(PlatformType.self, forKey: .platformType)
        self.responseType = try container.decode(ResponseType.self, forKey: .responseType)
        self.additions = try container.decodeIfPresent([ThreatEntrySet].self, forKey: .additions) ?? []
        self.removals = try container.decodeIfPresent([ThreatEntrySet].self, forKey: .removals) ?? []
        self.newClientState = try container.decode(String.self, forKey: .newClientState)
        self.checksum = try container.decode(Checksum.self, forKey: .checksum)
    }
}

struct FetchRequest: Codable {
    let client: ClientInfo
    let listUpdateRequests: [ListUpdateRequest]
}

struct FetchResponse: Codable {
    let listUpdateResponses: [ListUpdateResponse]
    let minimumWaitDuration: String
}

struct FindRequest: Codable {
    let client: ClientInfo
    let threatInfo: ThreatInfo
}

struct FindResponse: Codable {
    let matches: [ThreatMatch]
    let negativeCacheDuration: String
    
    init() {
        matches = []
        negativeCacheDuration = "0s"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.matches = try container.decodeIfPresent([ThreatMatch].self, forKey: .matches) ?? []
        self.negativeCacheDuration = try container.decodeIfPresent(String.self, forKey: .negativeCacheDuration) ?? "0s"
    }
}

class SafeBrowsingError: NSError {
    public init(_ message: String, code: Int = -1) {
        super.init(domain: "SafeBrowsingError", code: code, userInfo: [
            NSLocalizedDescriptionKey: message,
            NSLocalizedFailureErrorKey: message
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

struct ResponseError: Codable {
    let code: Int
    let message: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NestedKeys.self)
        let errorContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .error)
        
        self.code = try errorContainer.decode(Int.self, forKey: .code)
        self.message = try errorContainer.decode(String.self, forKey: .message)
    }
    
    private enum NestedKeys: String, CodingKey {
        case error
    }
}
